import SwiftUI

/// Trợ lý AI: a screen of its own over everything, sliding up from Tổng quan and closed with ✕ or
/// a swipe down, so the input bar is the only thing at the bottom (user request 2026-10-30: tab
/// bar and input together looked crowded). Wrap it in a `NavigationStack`.
///
/// The page itself (the messages, the field, the keyboard) is UIKit's, in `ChatScreen` (user
/// choice 2026-11-11); this view keeps the data, the bar's buttons, the top bar and the sheets.
/// No effects of our own yet: the hand-made SwiftUI ones are in the history, commit 38c7c23.
struct AssistantView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota
    @Environment(AssistantChats.self) private var chats
    @Environment(CloudSyncMonitor.self) private var sync
    @State private var draft = ""
    /// A question is out and Milu's answer not in yet.
    @State private var isThinking = false
    /// The chat that question was asked in: "Đang nghĩ…" and ■ show there only, and ■ says it
    /// stopped there (audit 2026-11-15: another chat opened meanwhile showed both, and got the notice).
    @State private var answeringChatID: Conversation.ID?
    /// What Milu has done so far on that answer, shown under "Đang nghĩ…".
    @State private var progress = AssistantProgress()
    /// Asking for Milu's answer, until it is in; ■ cancels it.
    @State private var answering: Task<Void, Never>?
    /// Whether the question being answered took a lượt (`AIQuota.spend`), to give it back.
    @State private var answerPaid = false
    /// When Milu's answer last came in: a tap meant for ■ that lands just after, on the mic,
    /// does not start listening (Simulator, 2026-11-11).
    @State private var answeredAt: Date = .distantPast
    /// Set on the first question; `OnboardingRewards` pays "Hỏi Milu một câu" in Làm quen với Milu.
    @AppStorage(StorageKey.askedAI) private var hasAskedAI = false
    @State private var viewingTransaction: FinanceTransaction?
    /// The chat card whose "Xoá" was tapped, until the alert is answered: deleting always asks
    /// first, in chat too (strict review 2026-10-31: it deleted at once).
    @State private var pendingRemoval: ChatMessage?
    /// A card's transaction the store would not delete (a closed goal's, an archived account's).
    @State private var cannotDelete: FinanceTransaction?
    @State private var dictation = SpeechDictation()
    @State private var isShowingHistory = false
    @AppStorage(StorageKey.profileName) private var profileName = ""

    private var currentIndex: Int {
        chats.conversations.firstIndex { $0.id == chats.currentID } ?? chats.conversations.count - 1
    }

    private var messages: [ChatMessage] { chats.conversations[currentIndex].messages }
    /// Milu is answering in the chat on screen.
    private var isThinkingHere: Bool { isThinking && answeringChatID == chats.conversations[currentIndex].id }
    private var hasQuestions: Bool { chats.conversations[currentIndex].hasQuestions }

    var body: some View {
        let isDictating = dictation.isRecording || dictation.isTranscribing
        ChatScreen(
            conversation: chats.conversations[currentIndex],
            isThinking: isThinkingHere,
            progress: progress,
            draft: $draft,
            isDictating: isDictating,
            showsLeading: dictation.isRecording,
            // The field stays with no lượt left: recording and deleting are free (user choice
            // 2026-11-12); a question that needs a lượt is told so in the chat.
            isOutOfQuestions: false,
            leading: AnyView(roundButton("xmark", label: "Huỷ nhập giọng nói") {
                dictation.stop()
            }),
            stop: AnyView(roundButton("stop.fill", label: "Xong, chuyển thành chữ") {
                finishDictation(thenSend: false)
            }),
            action: AnyView(actionButton(isDictating: isDictating)),
            fieldOverlay: AnyView(dictationStatus),
            outOfQuestions: AnyView(EmptyView()),
            greeting: AnyView(greeting),
            onAction: handle
        )
        // The page runs under the bars and the keyboard; the chat sets its own room for them.
        .ignoresSafeArea()
        // Under the keyboard too: its rounded glass showed the window's white at its corners
        // (user report 2026-10-31).
        .background { PageBackground().ignoresSafeArea() }
        .foregroundStyle(Palette.label)
        // No title in the middle (user request 2026-11-09: AI apps show none); the name stays
        // for VoiceOver and the back button.
        .navigationTitle("Milu")
        .toolbarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            // An empty slot, not EmptyView: with nothing there, iOS shows the title.
            ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1).accessibilityHidden(true) }
            ToolbarItem(placement: .topBarTrailing) { historyButton }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItem(placement: .topBarTrailing) { newChatButton }
        }
        .sheet(isPresented: $isShowingHistory) { ChatHistorySheet() }
        .sheet(item: $viewingTransaction) { TransactionDetailSheet(transactionID: $0.id) }
        .systemAlert("Xoá giao dịch?", isPresented: Binding(
            get: { pendingRemoval != nil },
            set: { if !$0 { pendingRemoval = nil } }
        )) {
            Button("Huỷ", role: .cancel) {}
            Button("Xoá", role: .destructive) {
                Haptics.warning()
                if let message = pendingRemoval { remove(message) }
            }
        }
        .systemAlert("Chưa xoá được", isPresented: Binding(
            get: { cannotDelete != nil },
            set: { if !$0 { cannotDelete = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cannotDelete.flatMap { store.readOnlyReason($0) } ?? "Giao dịch này không xoá được nữa.")
        }
        .systemAlert("Không dùng được micro", isPresented: Binding(
            get: { dictation.failure != nil },
            set: { if !$0 { dictation.failure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(dictationMessage)
        }
        .onAppear { dictation.prepare() }
        .onDisappear { dictation.stop() }
        // Milu Pro's prices, for "Pro giá bao nhiêu?" (`GetAppInfo`): loaded once, as its page does.
        .task { await ProStore.shared.loadProducts() }
    }

    // MARK: - Đầu trang

    private var historyButton: some View {
        Button { isShowingHistory = true } label: {
            BarSymbol("clock.arrow.circlepath")
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Lịch sử trò chuyện")
    }

    /// ✎ a new chat, as in the AI apps; nothing to do while this one is still empty.
    private var newChatButton: some View {
        Button { startNewConversation() } label: {
            BarSymbol("square.and.pencil")
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .disabled(!hasQuestions)
        .accessibilityLabel("Cuộc trò chuyện mới")
    }

    // MARK: - Lời chào

    /// A new chat: the greeting and three questions to start with (`AssistantGreeting`).
    private var greeting: some View {
        AssistantGreeting(
            title: greetingTitle,
            quotaLine: quota.isUnlimited ? nil : "Còn \(quota.remaining) lượt hỏi tuần này · ghi, xoá giao dịch không tốn lượt",
            chatID: chats.currentID,
            ask: { question in
                guard !isThinking else { return }
                ask(question)
            },
            fill: { words in draft = words }
        )
    }

    /// "Chào Minh!", or "Chào bạn!" with no name set in Cài đặt.
    private var greetingTitle: String {
        let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return "Chào \(name.isEmpty ? "bạn" : name)!"
    }

    // MARK: - Ô nhập

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    /// Every button in the field: one size, so they sit on one line.
    private static let buttonSize = ControlHeight.small
    private static let inset = Spacing.s
    private static let inputRadius = buttonSize / 2 + inset

    /// In the field's place while listening (the sound) or turning it into words. The one goes
    /// first, quickly, then the other comes, as the words and the wave do in the field: iOS ends
    /// the listening and starts the turning into words in two updates, and keyed to the first
    /// alone the words came in at once over the fading wave (frames, 2026-11-11).
    private var dictationStatus: some View {
        let phase = dictation.isRecording ? 1 : dictation.isTranscribing ? 2 : 0
        let fades = !UIAccessibility.isReduceMotionEnabled
        let swap: AnyTransition = fades
            ? .asymmetric(insertion: .opacity.animation(.easeOut(duration: 0.2).delay(0.1)),
                          removal: .opacity.animation(.easeOut(duration: 0.12)))
            : .identity
        return ZStack {
            if dictation.isRecording {
                VoiceWaveform(dictation: dictation)
                    .transition(swap)
            } else if dictation.isTranscribing {
                Text("Milu đang hiểu ý bạn…")
                    .textRole(.body)
                    .foregroundStyle(Palette.secondaryLabel)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(swap)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(fades ? .easeOut(duration: 0.2) : nil, value: phase)
    }

    /// The mic, or ↑ once there is something to send. Between the two, the blue disc grows out
    /// from the middle (or shrinks back into it) while the one glyph shrinks and fades as the
    /// other grows in, each in its own colour: iOS's symbol replace ran one after the other and
    /// left a white mic on the blue for a moment (frames, 2026-11-11). Dimmed while it cannot be
    /// used (Milu answering, the words not in yet), the mic as well as ↑.
    ///
    /// While Milu thinks it is ■ on the disc: the answer stops coming (user request 2026-11-11).
    private func actionButton(isDictating: Bool) -> some View {
        // ■ in every chat while an answer is out: in another one, nothing could be asked and
        // nothing said why (audit round 2, 2026-11-15). "Đang nghĩ…" stays in its own chat.
        let stops = isThinking && !isDictating
        let sends = !stops && (isDictating || canSend)
        let disc = sends || stops
        let enabled = stops || (sends ? (dictation.isRecording || (!isDictating && canSend)) : true)
        return Button {
            if stops { stopAnswer() } else if sends { submit() } else { startDictation() }
        } label: {
            ZStack {
                Circle()
                    .fill(Palette.primary)
                    .scaleEffect(disc ? 1 : 0.4)
                    .opacity(disc ? 1 : 0)
                Image(systemName: "mic")
                    .font(.system(size: IconSize.control))
                    .foregroundStyle(Palette.secondaryLabel)
                    .scaleEffect(disc ? 0.4 : 1)
                    .opacity(disc ? 0 : 1)
                Image(systemName: "arrow.up")
                    .font(.system(size: IconSize.bar, weight: .semibold))
                    .foregroundStyle(Palette.onPrimary)
                    .scaleEffect(sends ? 1 : 0.4)
                    .opacity(sends ? 1 : 0)
                Image(systemName: "stop.fill")
                    .font(.system(size: IconSize.inline, weight: .semibold))
                    .foregroundStyle(Palette.onPrimary)
                    .scaleEffect(stops ? 1 : 0.4)
                    .opacity(stops ? 1 : 0)
            }
            .frame(width: Self.buttonSize, height: Self.buttonSize)
            .opacity(enabled ? 1 : 0.4)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .animation(Motion.gentle(.spring(duration: 0.3, bounce: 0.25)), value: sends)
        .animation(Motion.gentle(.spring(duration: 0.3, bounce: 0.25)), value: stops)
        .animation(Motion.gentle(.easeOut(duration: 0.2)), value: enabled)
        .accessibilityLabel(stops ? "Dừng câu trả lời" : sends ? "Gửi tin nhắn" : "Nhập bằng giọng nói")
    }

    /// ■ while Milu thinks: no answer comes, the three dots go, the question stays.
    private func stopAnswer() {
        answering?.cancel()
        answering = nil
        // Stopped before any answer: the lượt is given back.
        if answerPaid { quota.refund() }
        answerPaid = false
        // Said in the chat where the answer would have been (user request 2026-11-12: the dots
        // only went, as if nothing had been asked).
        let index = chats.conversations.firstIndex { $0.id == answeringChatID } ?? currentIndex
        withAnimation(Motion.gentle(.easeOut(duration: 0.2))) {
            chats.conversations[index].messages.append(ChatMessage(role: .notice, text: "Bạn đã dừng câu trả lời"))
            isThinking = false
        }
        answeringChatID = nil
    }

    /// ✕ and ■ while listening: a glyph on a grey disc.
    private func roundButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: IconSize.inline + 2, weight: .semibold))
                .foregroundStyle(Palette.label)
                .frame(width: Self.buttonSize, height: Self.buttonSize)
                .background(Palette.fill, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// Milu's answer to a question asked with no lượt left, in its voice; first what it did all
    /// the same, when it recorded or found a transaction to delete.
    private func outOfQuestionsReply(after action: AssistantReply.Action?) -> String {
        let renews = "Lượt mới có từ **thứ Hai \(quota.renewsOn.shortDay)** nha."
        let first = switch action {
        case .recorded: "Khoản bạn nhờ ghi thì Milu ghi rồi, ở bên dưới nhé. Còn câu hỏi thì tuần này bạn hết lượt rồi 😏 "
        case .confirmDelete: "Khoản cần xoá ở bên dưới, bạn bấm xác nhận là xong. Còn câu hỏi thì tuần này bạn hết lượt rồi 😏 "
        case nil: "Tuần này bạn hỏi Milu hết lượt rồi 😏 "
        }
        // Pro is on sale: a free user is pointed to it; a subscriber already has it (audit round 2,
        // 2026-11-15: both were told to "wait for Milu Pro").
        let more = MiluPlan.isPro ? "" : "\n• Muốn hỏi nhiều hơn thì nâng cấp Milu Pro nhé."
        return first + renews + "\n\n" + "• Ghi hay xoá giao dịch thì vẫn thoải mái, không tốn lượt." + more
    }

    /// ■ came after Milu had recorded a transaction: said under "Bạn đã dừng", with its card.
    private func showRecordedAfterStop(_ transaction: FinanceTransaction, in chatID: Conversation.ID) {
        guard let index = chats.conversations.firstIndex(where: { $0.id == chatID }) else { return }
        withAnimation(Motion.gentle(.easeOut(duration: 0.2))) {
            chats.conversations[index].messages.append(
                ChatMessage(role: .assistant, text: "Trước khi bạn dừng, Milu đã ghi khoản này rồi. Sai thì bạn xoá nhé:",
                            card: .recorded(transaction, removed: false)))
        }
    }

    private var dictationMessage: String {
        switch dictation.failure {
        case .denied: "Hãy cho phép Milu dùng micro và nhận dạng giọng nói trong Cài đặt."
        case .unavailable: "Nhận dạng giọng nói tiếng Việt hiện chưa sẵn sàng trên thiết bị này."
        case .audio, nil: "Không mở được micro. Bạn thử lại sau nhé."
        }
    }

    // MARK: - Hành động

    /// Closes the keyboard: the field's focus and iOS's first responder, as the forms do (a
    /// focus set to false alone left the vertical field's keyboard up, Simulator 2026-11-09).
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func startDictation() {
        guard Date.now.timeIntervalSince(answeredAt) > 0.5 else { return }
        // The names the server's recognizer favours: the user's accounts, then every bank and wallet.
        var seen = Set<String>()
        dictation.hotwords = (store.accounts.map(\.name) + Institution.all.map(\.shortName)).filter { seen.insert($0).inserted }
        Task { await dictation.start() }
    }

    /// ■ or ↑ while listening: the words go after what was typed, and ↑ sends them too.
    private func finishDictation(thenSend: Bool) {
        Task {
            guard let heard = await dictation.finish() else { return }
            draft = [draft.trimmingCharacters(in: .whitespacesAndNewlines), heard]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            dictation.endTranscribing()
            if thenSend { send() }
        }
    }

    /// ↑ in the field.
    private func submit() {
        if dictation.isRecording {
            finishDictation(thenSend: true)
        } else if !dictation.isTranscribing {
            send()
        }
    }

    private func startNewConversation() {
        draft = ""
        dismissKeyboard()
        // The chat page slides the old one away and brings the greeting in (`ChatViewController`).
        chats.startNew()
    }

    /// The least time from the question to its answer: the question's flight (0.41 s) and a beat
    /// of the three dots after it.
    private static let shortestWait: TimeInterval = 0.9

    /// Sends what is in the field and asks the assistant (`AssistantServices`) for the answer.
    private func send() {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking else { return }
        ask(question)
        draft = ""
    }

    /// "Hỏi lại" under an answer: its question asked once more, at the chat's end.
    private func retry(_ answer: ChatMessage) {
        guard !isThinking, let row = messages.firstIndex(where: { $0.id == answer.id }),
              let question = messages[..<row].last(where: { $0.role == .user })?.text else { return }
        ask(question)
    }

    /// `question` into the chat, and the assistant asked for its answer, the steps it takes on
    /// the way shown under "Đang nghĩ…" (`progress`).
    private func ask(_ question: String) {
        // What Milu may say of the app, the lượt as they are before this question: one about
        // the app takes none, so that is what is left after it too.
        let app = AppFacts.current(quota: quota, sync: sync)
        // With none left it is asked all the same: it may only record or delete, or ask about the
        // app, which are free.
        let paid = quota.spend()
        answerPaid = paid
        // A tick as the question leaves (`Haptics`).
        Haptics.selection()
        dictation.stop()
        let chatID = chats.conversations[currentIndex].id
        let history = messages
        withAnimation(Motion.gentle(.easeOut(duration: 0.2))) {
            chats.conversations[currentIndex].messages.append(ChatMessage(role: .user, text: question))
            isThinking = true
        }
        answeringChatID = chatID
        progress.steps = []
        hasAskedAI = true
        let service = AssistantServices.make(store: store, app: app)

        let askedAt = Date.now
        let progress = progress
        answering = Task {
            var reply: AssistantReply
            /// How long it thought and what it did, for the line over the answer.
            var thought: ChatMessage.Thought?
            do {
                let answer = try await service.reply(to: question, history: history) { step in
                    withAnimation(Motion.gentle(.spring(duration: 0.3, bounce: 0))) { progress.steps.append(step) }
                }
                // Stopped (■) while the answer was on its way: it is dropped, unless Milu had already
                // recorded something, which stays in: its card shows under "Bạn đã dừng", to see or
                // undo it (audit 2026-11-15: hidden, it looked unrecorded and was recorded again).
                if Task.isCancelled {
                    if case .recorded(let transaction) = answer.action { showRecordedAfterStop(transaction, in: chatID) }
                    return
                }
                reply = answer
                thought = ChatMessage.Thought(seconds: max(1, Int(Date.now.timeIntervalSince(askedAt).rounded())),
                                              steps: progress.steps.map(\.done))
            } catch is CancellationError {
                return
            } catch {
                if Task.isCancelled { return }
                // No answer came (no connection, the server): the lượt given back.
                reply = AssistantReply(text: (error as? LocalizedError)?.errorDescription
                    ?? "Milu chưa trả lời được. Bạn thử lại sau nhé.", counts: false)
            }
            // Only recording, deleting or asking about the app, or no answer: free (user choice
            // 2026-11-12). A question asked with no lượt left is answered with when they come back.
            switch AnswerCharge(paid: paid, counts: reply.counts) {
            case .free: if paid { quota.refund() }
            case .paid: quota.settle()
            case .outOfQuestions:
                // What it recorded, or the transaction to delete, still shows: the one is in
                // already, the other waits for a yes (audit 2026-11-15: hidden, it was recorded again).
                reply = AssistantReply(text: outOfQuestionsReply(after: reply.action), action: reply.action)
                thought = nil
            }
            // Never before the question has landed: with no connection the error came back at
            // once and showed while the question was still rising (user report 2026-11-12).
            let wait = Self.shortestWait - Date.now.timeIntervalSince(askedAt)
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            if Task.isCancelled { return }
            // One tick as Milu's words show, an answer or an error alike (user report
            // 2026-11-12: an answer came silent and an error buzzed twice).
            Haptics.selection()
            let card: ChatMessage.Card? = switch reply.action {
            case .recorded(let transaction): .recorded(transaction, removed: false)
            case .confirmDelete(let transaction): .confirmDelete(transaction, state: .pending)
            case nil: nil
            }
            // Into the chat it was asked in, even if another is open by now.
            withAnimation(Motion.gentle(.easeOut(duration: 0.2))) {
                if let index = chats.conversations.firstIndex(where: { $0.id == chatID }) {
                    chats.conversations[index].messages.append(
                        ChatMessage(role: .assistant, text: reply.text, card: card, thought: thought))
                }
                isThinking = false
            }
            answeringChatID = nil
            // VoiceOver says the answer as it comes, as it would read it in the chat (audit
            // 2026-11-15: nothing was said, and the user had to look for it); only in that chat.
            if chats.currentID == chatID {
                AccessibilityNotification.Announcement(Self.spoken(reply.text)).post()
            }
            answeredAt = .now
            answering = nil
        }
    }

    private func handle(_ action: CardAction, in message: ChatMessage) {
        if action == .retry { return retry(message) }
        let index = currentIndex
        guard let row = chats.conversations[index].messages.firstIndex(where: { $0.id == message.id }),
              let card = message.card else { return }
        switch (action, card) {
        case (.view, .recorded(let snapshot, _)):
            viewingTransaction = store.transaction(id: snapshot.id)
        case (.remove, .recorded):
            pendingRemoval = message
        case (.confirm, .confirmDelete(let snapshot, .pending)):
            store.delete(snapshot)
            // "Đã xoá" only once it is gone: one the store keeps (a closed goal's, an archived
            // account's) is said so instead (audit 2026-11-15: the card said it was deleted).
            guard store.transaction(id: snapshot.id) == nil else {
                cannotDelete = snapshot
                return
            }
            chats.conversations[index].messages[row].card = .confirmDelete(snapshot, state: .deleted)
        case (.cancel, .confirmDelete(let snapshot, .pending)):
            chats.conversations[index].messages[row].card = .confirmDelete(snapshot, state: .cancelled)
        default:
            break
        }
    }

    /// "Xoá" on a recorded card, once the alert said yes.
    private func remove(_ message: ChatMessage) {
        let index = currentIndex
        guard let row = chats.conversations[index].messages.firstIndex(where: { $0.id == message.id }),
              case .recorded(let snapshot, removed: false) = chats.conversations[index].messages[row].card
        else { return }
        store.delete(snapshot)
        guard store.transaction(id: snapshot.id) == nil else {
            cannotDelete = snapshot
            return
        }
        chats.conversations[index].messages[row].card = .recorded(snapshot, removed: true)
    }

    /// An answer as VoiceOver should say it: without the Markdown marks it is written with.
    static func spoken(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "• ", with: "")
    }
}

/// What an answer costs, once it is in: `paid` is whether the question took a lượt as it left
/// (none were left otherwise), `counts` whether the answer is one that takes one (not recording,
/// deleting or telling of the app, and not an error).
enum AnswerCharge: Equatable {
    /// Takes none: its lượt, if one was taken, goes back.
    case free
    /// Its lượt stays taken.
    case paid
    /// It needed a lượt and none were left: told when they come back instead.
    case outOfQuestions

    init(paid: Bool, counts: Bool) {
        self = !counts ? .free : (paid ? .paid : .outOfQuestions)
    }
}

#Preview {
    NavigationStack { AssistantView() }
        .environment(FinanceStore())
        .environment(AssistantChats(saving: false))
        .environment(AIQuota())
        .environment(CloudSyncMonitor())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
