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
    @State private var draft = ""
    /// A question is out and Milu's answer not in yet.
    @State private var isThinking = false
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
    @State private var dictation = SpeechDictation()
    @State private var isShowingHistory = false
    @AppStorage(StorageKey.profileName) private var profileName = ""

    private var currentIndex: Int {
        chats.conversations.firstIndex { $0.id == chats.currentID } ?? chats.conversations.count - 1
    }

    private var messages: [ChatMessage] { chats.conversations[currentIndex].messages }
    private var hasQuestions: Bool { chats.conversations[currentIndex].hasQuestions }

    var body: some View {
        let isDictating = dictation.isRecording || dictation.isTranscribing
        ChatScreen(
            conversation: chats.conversations[currentIndex],
            isThinking: isThinking,
            draft: $draft,
            isDictating: isDictating,
            showsLeading: dictation.isRecording,
            // The field stays with no lượt left: recording and deleting are free (user choice
            // 2026-11-12); a question that needs a lượt is told so in the chat.
            isOutOfQuestions: false,
            leading: AnyView(roundButton("xmark", label: "Huỷ nhập giọng nói") {
                Haptics.impact()
                dictation.stop()
            }),
            stop: AnyView(roundButton("stop.fill", label: "Xong, chuyển thành chữ") {
                Haptics.impact()
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
                if let message = pendingRemoval { remove(message) }
            }
        }
        .systemAlert("Không dùng được micro", isPresented: Binding(
            get: { dictation.failure != nil },
            set: { if !$0 { dictation.failure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(dictationMessage)
        }
        .onDisappear { dictation.stop() }
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

    @ScaledMetric(relativeTo: .title) private var greetingMark: CGFloat = 72

    /// A new chat: ✨, "Chào Minh!" and what Milu does, in the middle of the page (scrolling when
    /// the text is large). No questions to pick: the field is where to ask (user request
    /// 2026-11-11).
    private var greeting: some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                Image(IconCatalog.emojiName("✨"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: greetingMark * 0.55, height: greetingMark * 0.55)
                    .frame(width: greetingMark, height: greetingMark)
                    .background(Palette.surfaceMuted, in: Circle())
                    .accessibilityHidden(true)
                Text(greetingTitle)
                    .textRole(.pageTitle)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("Hỏi mình về chi tiêu, khoản vay, hoặc nhờ mình ghi, sửa, xoá giao dịch.")
                    .textRole(.body)
                    .foregroundStyle(Palette.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if !quota.isUnlimited {
                    // What is left this week, and that recording costs none (user choice 2026-11-12).
                    Text("Còn \(quota.remaining) lượt hỏi tuần này · ghi, xoá giao dịch không tốn lượt")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xl)
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical, alignment: .center) { height, _ in height }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
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
        Haptics.impact()
        answering?.cancel()
        answering = nil
        // Stopped before any answer: the lượt is given back.
        if answerPaid { quota.refund() }
        answerPaid = false
        withAnimation(Motion.gentle(.easeOut(duration: 0.2))) { isThinking = false }
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

    /// Milu's answer to a question asked with no lượt left, in its voice.
    private var outOfQuestionsReply: String {
        "Tuần này bạn hỏi Milu hết lượt rồi 😏 Lượt mới có từ **thứ Hai \(quota.renewsOn.shortDay)** nha.\n\n"
            + "• Ghi hay xoá giao dịch thì vẫn thoải mái, không tốn lượt.\n• Muốn hỏi thả ga thì đợi Milu Pro nhé."
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
        Haptics.impact()
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
        Haptics.impact()
        draft = ""
        dismissKeyboard()
        // The chat page slides the old one away and brings the greeting in (`ChatViewController`).
        chats.startNew()
    }

    /// Sends what is in the field and asks the assistant (`AssistantServices`) for the answer.
    private func send() {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking else { return }
        // With none left it is asked all the same: it may only record or delete, which is free.
        let paid = quota.spend()
        answerPaid = paid
        // A soft knock as the question leaves, as the AI apps give.
        Haptics.impact(.soft)
        dictation.stop()
        let chatID = chats.conversations[currentIndex].id
        let history = messages
        withAnimation(Motion.gentle(.easeOut(duration: 0.2))) {
            chats.conversations[currentIndex].messages.append(ChatMessage(role: .user, text: question))
            isThinking = true
        }
        draft = ""
        hasAskedAI = true
        let service = AssistantServices.make(store: store)

        answering = Task {
            var reply: AssistantReply
            do {
                let answer = try await service.reply(to: question, history: history)
                // Stopped (■) while the answer was on its way: it is dropped.
                try Task.checkCancellation()
                reply = answer
            } catch is CancellationError {
                return
            } catch {
                if Task.isCancelled { return }
                // No answer came (no connection, the server): felt as well as read, and the
                // lượt given back.
                Haptics.error()
                reply = AssistantReply(text: (error as? LocalizedError)?.errorDescription
                    ?? "Milu chưa trả lời được. Bạn thử lại sau nhé.", counts: false)
            }
            // Only recording or deleting, or no answer: free (user choice 2026-11-12). A question
            // asked with no lượt left is answered with when they come back.
            if !reply.counts {
                if paid { quota.refund() }
            } else if !paid {
                reply = AssistantReply(text: outOfQuestionsReply)
            }
            let card: ChatMessage.Card? = switch reply.action {
            case .recorded(let transaction): .recorded(transaction, removed: false)
            case .confirmDelete(let transaction): .confirmDelete(transaction, state: .pending)
            case nil: nil
            }
            // Into the chat it was asked in, even if another is open by now.
            withAnimation(Motion.gentle(.easeOut(duration: 0.2))) {
                if let index = chats.conversations.firstIndex(where: { $0.id == chatID }) {
                    chats.conversations[index].messages.append(
                        ChatMessage(role: .assistant, text: reply.text, card: card))
                }
                isThinking = false
            }
            answeredAt = .now
            answering = nil
        }
    }

    private func handle(_ action: CardAction, in message: ChatMessage) {
        let index = currentIndex
        guard let row = chats.conversations[index].messages.firstIndex(where: { $0.id == message.id }),
              let card = message.card else { return }
        switch (action, card) {
        case (.view, .recorded(let snapshot, _)):
            viewingTransaction = store.transaction(id: snapshot.id)
        case (.remove, .recorded):
            Haptics.warning()
            pendingRemoval = message
        case (.confirm, .confirmDelete(let snapshot, .pending)):
            store.delete(snapshot)
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
        chats.conversations[index].messages[row].card = .recorded(snapshot, removed: true)
    }
}

#Preview {
    NavigationStack { AssistantView() }
        .environment(FinanceStore())
        .environment(AssistantChats(saving: false))
        .environment(AIQuota())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
