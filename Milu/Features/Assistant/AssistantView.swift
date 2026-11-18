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
    @State private var draft: String
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
    /// A row of a card waiting for "Lưu", open to be changed (`DraftRowEditor`).
    @State private var editingRow: EditingRow?
    /// The chat card whose "Xoá" was tapped, until the alert is answered: deleting always asks
    /// first, in chat too (strict review 2026-10-31: it deleted at once).
    @State private var pendingRemoval: ChatMessage?
    /// A card's transaction the store would not delete (a closed goal's, an archived account's).
    @State private var cannotDelete: FinanceTransaction?
    @State private var dictation = SpeechDictation()
    /// For a moment in the empty field, why the mic stopped ("Milu chưa nghe thấy gì").
    @State private var fieldNote: String?
    @State private var isShowingHistory = false
    @AppStorage(StorageKey.profileName) private var profileName = ""

    private var currentIndex: Int {
        chats.conversations.firstIndex { $0.id == chats.currentID } ?? chats.conversations.count - 1
    }

    private var messages: [ChatMessage] { chats.conversations[currentIndex].messages }
    /// Milu is answering in the chat on screen.
    private var isThinkingHere: Bool { isThinking && answeringChatID == chats.conversations[currentIndex].id }
    private var hasQuestions: Bool { chats.conversations[currentIndex].hasQuestions }

    /// `prefill`: words already in the field, not sent: a question the quick sheet ("Thêm bằng
    /// AI") passed on, for the user to send (a question takes a lượt, theirs to spend).
    init(prefill: String = "") {
        _draft = State(initialValue: prefill)
    }

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
            isTranscribing: dictation.isTranscribing,
            placeholder: fieldNote ?? ChatViewController.defaultPlaceholder,
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
        .sheet(item: $editingRow) { editing in
            DraftRowEditor(row: editing.row) { changed in
                changeDraft(holding: changed.id) { $0.replacingRow(changed) }
            } onRemove: {
                changeDraft(holding: editing.row.id) { $0.removingRow(editing.row.id) }
            }
        }
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
        .systemAlert(dictation.failure?.isStopped == true ? "Milu ngừng nghe" : "Không dùng được micro", isPresented: Binding(
            get: { dictation.failure != nil },
            set: { if !$0 { dictation.failure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(dictationMessage)
        }
        .onAppear { dictation.prepare() }
        // Ended by itself (user choice 2026-11-17): said and paused, or out of time, it is sent
        // as ↑ sends it; nothing said, the mic goes off and the field says so for a moment.
        .onChange(of: dictation.autoEnd) { _, end in
            guard let end, dictation.isRecording else { return }
            switch end {
            case .paused, .timeUp:
                finishDictation(thenSend: true)
            case .nothingSaid:
                dictation.stop()
                showFieldNote("Milu chưa nghe thấy gì")
            }
        }
        // Listening ended by itself: what was heard goes after what was typed, as ■ puts it.
        .onChange(of: dictation.heardWhenStopped) {
            guard let heard = dictation.takeHeardWhenStopped() else { return }
            draft = [draft.trimmingCharacters(in: .whitespacesAndNewlines), heard]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
        .onDisappear {
            dictation.stop()
            // Closed while Milu answers: the answer stops, said in the chat, its lượt given back
            // (audit round 3, 2026-11-16: it ran on unseen, reopened with no "Đang nghĩ…" nor ■,
            // and the question asked again was recorded twice).
            if isThinking { stopAnswer() }
        }
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
                // No spacing of the stack's own: the countdown, there or not, would leave a gap.
                HStack(spacing: 0) {
                    // On the left, where the oldest sound fades out: the newest stays where it is.
                    ListeningCountdown(startedAt: dictation.startedAt)
                    VoiceWaveform(dictation: dictation)
                }
                .transition(swap)
            } else if dictation.isTranscribing {
                // In the field lit up (`ChatViewController`, user choice 2026-11-17).
                TranscribingStatus()
                    .padding(.leading, Spacing.s)
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
        // only went, as if nothing had been asked); nowhere when that chat was deleted meanwhile
        // (audit round 3, 2026-11-16: it went into the open chat, which had asked nothing).
        let index = chats.conversations.firstIndex { $0.id == answeringChatID }
        withAnimation(Motion.gentle(.easeOut(duration: 0.2))) {
            if let index {
                chats.conversations[index].messages.append(ChatMessage(role: .notice, text: "Bạn đã dừng câu trả lời"))
            }
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
        case .draft: "Khoản bạn nhờ ghi ở bên dưới, bạn kiểm tra rồi bấm **Lưu** nhé. Còn câu hỏi thì tuần này bạn hết lượt rồi 😏 "
        case .confirmDelete: "Khoản cần xoá ở bên dưới, bạn bấm xác nhận là xong. Còn câu hỏi thì tuần này bạn hết lượt rồi 😏 "
        case nil: "Tuần này bạn hỏi Milu hết lượt rồi 😏 "
        }
        // Pro is on sale: a free user is pointed to it; a subscriber already has it (audit round 2,
        // 2026-11-15: both were told to "wait for Milu Pro").
        let more = MiluPlan.isPro ? "" : "\n• Muốn hỏi nhiều hơn thì nâng cấp Milu Pro nhé."
        return first + renews + "\n\n" + "• Ghi hay xoá giao dịch thì vẫn thoải mái, không tốn lượt." + more
    }

    private var dictationMessage: String {
        dictation.failure.map(Self.dictationMessage) ?? Self.dictationMessage(for: .audio)
    }

    /// Why the mic could not be used, or stopped by itself; the quick sheet says it too.
    static func dictationMessage(for failure: SpeechDictation.Failure) -> String {
        switch failure {
        case .denied: "Hãy cho phép Milu dùng micro và nhận dạng giọng nói trong Cài đặt."
        case .unavailable: "Nhận dạng giọng nói tiếng Việt hiện chưa sẵn sàng trên thiết bị này."
        case .audio: "Không mở được micro. Bạn thử lại sau nhé."
        case .stopped(let reason, let heard): stoppedMessage(reason, heard: heard)
        }
    }

    /// Why listening ended, and, only when something was heard, where it went.
    static func stoppedMessage(_ reason: SpeechDictation.StopReason, heard: Bool) -> String {
        let why = switch reason {
        case .leftApp: "Milu ngừng nghe khi bạn rời ứng dụng."
        case .interrupted: "Milu ngừng nghe vì có cuộc gọi hoặc ứng dụng khác dùng âm thanh."
        case .recognizer: "Milu ngừng nghe vì nhận dạng giọng nói gặp lỗi, có thể do mất mạng."
        }
        return heard ? "\(why) Những gì đã nghe được đã ở trong ô nhập." : why
    }

    // MARK: - Hành động

    /// Closes the keyboard: the field's focus and iOS's first responder, as the forms do (a
    /// focus set to false alone left the vertical field's keyboard up, Simulator 2026-11-09).
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// `note` in the empty field for a few seconds, and said by VoiceOver.
    private func showFieldNote(_ note: String) {
        fieldNote = note
        AccessibilityNotification.Announcement(note).post()
        Task {
            try? await Task.sleep(for: .seconds(3))
            if fieldNote == note { fieldNote = nil }
        }
    }

    private func startDictation() {
        guard Date.now.timeIntervalSince(answeredAt) > 0.5 else { return }
        fieldNote = nil
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
        draft = ""
        if answerByShortcut(question) { return }
        ask(question)
    }

    /// "ok", "lưu đi", "huỷ" typed when Milu's last answer holds a card waiting for "Lưu": done
    /// here, as its buttons do, with no question to Milu and no lượt (user choice 2026-11-17).
    private func answerByShortcut(_ question: String) -> Bool {
        guard let answer = DraftShortcut.match(question),
              let last = messages.last(where: { $0.role == .assistant }), last.pendingDraft != nil else { return false }
        let index = currentIndex
        Haptics.selection()
        dictation.stop()
        withAnimation(Motion.gentle(.easeOut(duration: 0.2))) {
            chats.conversations[index].messages.append(ChatMessage(role: .user, text: question))
        }
        let said: String
        switch answer {
        case .save:
            let saved = saveDraft(in: last)
            said = saved?.state == .saved
                ? (saved?.liveRows.count ?? 0) > 1 ? "Đã lưu \(saved?.liveRows.count ?? 0) khoản." : "Đã lưu."
                : "Chưa lưu được, bạn xem các khoản ở trên nhé."
        case .cancel:
            setDraft(of: last.id) { $0.state = .cancelled }
            said = "Đã huỷ, Milu chưa ghi gì."
        }
        withAnimation(Motion.gentle(.easeOut(duration: 0.2))) {
            chats.conversations[index].messages.append(ChatMessage(role: .assistant, text: said, isLocal: true))
        }
        AccessibilityNotification.Announcement(said).post()
        hasAskedAI = true
        return true
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
        // A short trip to another app (to check a figure) does not cut the answer off: iOS gives
        // it a little time in the background (audit round 4, 2026-11-16).
        let backgroundTime = BackgroundTime(name: "milu.answer")
        answering = Task {
            defer { backgroundTime.end() }
            var reply: AssistantReply
            /// How long it thought and what it did, for the line over the answer.
            var thought: ChatMessage.Thought?
            do {
                let answer = try await service.reply(to: question, history: history) { step in
                    withAnimation(Motion.gentle(.spring(duration: 0.3, bounce: 0))) { progress.steps.append(step) }
                }
                // Stopped (■) while the answer was on its way: it is dropped, its card too, as
                // nothing on it is saved before "Lưu" (2026-11-17).
                if Task.isCancelled { return }
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
                // The card to save, or the transaction to delete, still shows: each waits for a yes
                // (audit 2026-11-15: hidden, it was recorded again).
                reply = AssistantReply(text: outOfQuestionsReply(after: reply.action), actions: reply.actions)
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
            let cards: [ChatMessage.Card] = reply.actions.map { action in
                switch action {
                case .draft(let draft): .draft(draft)
                case .confirmDelete(let transaction): .confirmDelete(transaction, state: .pending)
                }
            }
            // Into the chat it was asked in, even if another is open by now. The first card under
            // the answer, each other under its own line (audit round 4, 2026-11-16).
            withAnimation(Motion.gentle(.easeOut(duration: 0.2))) {
                if let index = chats.conversations.firstIndex(where: { $0.id == chatID }) {
                    // A card it replaces ("à không, 50k thôi") waits no more.
                    for case .draft(let draft) in reply.actions {
                        if let replaced = draft.replacing { markReplaced(replaced, inChat: index) }
                    }
                    chats.conversations[index].messages.append(
                        ChatMessage(role: .assistant, text: reply.text, card: cards.first, thought: thought))
                    for card in cards.dropFirst() {
                        let line = if case .confirmDelete = card { "Và khoản cần xoá này:" } else { "Và các khoản này, bấm Lưu nếu đúng:" }
                        chats.conversations[index].messages.append(ChatMessage(role: .assistant, text: line, card: card))
                    }
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
        case (.confirm, .draft(let draft)) where draft.isPending:
            let saved = saveDraft(in: message)
            if let saved, saved.state == .saved {
                AccessibilityNotification.Announcement(saved.liveRows.count > 1 ? "Đã lưu \(saved.liveRows.count) khoản" : "Đã lưu").post()
            }
        case (.cancel, .draft(let draft)) where draft.isPending:
            setDraft(of: message.id) { $0.state = .cancelled }
        case (.editRow(let id), .draft(let draft)) where draft.isPending:
            if let row = draft.row(id) { editingRow = EditingRow(row: row) }
        case (.viewRow(let id), .draft):
            viewingTransaction = store.transaction(id: id)
        case (.view, .draft):
            if let id = messageDraftRowID(message) { viewingTransaction = store.transaction(id: id) }
        case (.remove, .draft):
            pendingRemoval = message
        default:
            break
        }
    }

    /// The one row of a saved card ("Xem", "Xoá" under it).
    private func messageDraftRowID(_ message: ChatMessage) -> UUID? {
        guard case .draft(let draft) = message.card, draft.liveRows.count == 1 else { return nil }
        return draft.liveRows.first?.id
    }

    /// "Lưu" on a card: all of it saved, or none with why on the card (`DraftSaver`).
    @discardableResult
    private func saveDraft(in message: ChatMessage) -> TransactionDraft? {
        guard let draft = message.pendingDraft else { return nil }
        let saved = DraftSaver.save(draft, in: store)
        setDraft(of: message.id) { $0 = saved }
        if saved.state == .saved { Haptics.milestone() } else { Haptics.warning() }
        return saved
    }

    /// Changes the card of a message, in whichever chat holds it.
    private func setDraft(of messageID: ChatMessage.ID, _ change: (inout TransactionDraft) -> Void) {
        for chat in chats.conversations.indices {
            guard let row = chats.conversations[chat].messages.firstIndex(where: { $0.id == messageID }),
                  case .draft(var draft) = chats.conversations[chat].messages[row].card else { continue }
            change(&draft)
            chats.conversations[chat].messages[row].card = .draft(draft)
            return
        }
    }

    /// Changes the card waiting for "Lưu" that holds this row, wherever it is now (a newer card may
    /// have taken its place while its form was open: then the change is dropped with it).
    private func changeDraft(holding rowID: UUID, _ change: (TransactionDraft) -> TransactionDraft) {
        for chat in chats.conversations.indices {
            guard let row = chats.conversations[chat].messages.firstIndex(where: {
                $0.pendingDraft?.row(rowID) != nil
            }), let draft = chats.conversations[chat].messages[row].pendingDraft else { continue }
            chats.conversations[chat].messages[row].card = .draft(change(draft))
            return
        }
    }

    /// The card a newer one replaced, said so, if it still waited.
    private func markReplaced(_ draftID: UUID, inChat chat: Int) {
        guard let row = chats.conversations[chat].messages.firstIndex(where: { $0.pendingDraft?.id == draftID }),
              var draft = chats.conversations[chat].messages[row].pendingDraft else { return }
        draft.state = .replaced
        chats.conversations[chat].messages[row].card = .draft(draft)
    }

    /// A row of a card waiting for "Lưu", open in its form.
    struct EditingRow: Identifiable {
        let row: TransactionDraft.Row
        var id: UUID { row.id }
    }

    /// "Xoá" on a recorded card, or on a card saved with one row, once the alert said yes.
    private func remove(_ message: ChatMessage) {
        let index = currentIndex
        guard let row = chats.conversations[index].messages.firstIndex(where: { $0.id == message.id }) else { return }
        if case .draft(let draft) = chats.conversations[index].messages[row].card, draft.state == .saved,
           let rowID = messageDraftRowID(chats.conversations[index].messages[row]),
           let snapshot = store.transaction(id: rowID) {
            store.delete(snapshot)
            guard store.transaction(id: rowID) == nil else {
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    cannotDelete = snapshot
                }
                return
            }
            setDraft(of: message.id) { draft in
                if let found = draft.rows.firstIndex(where: { $0.id == rowID }) { draft.rows[found].removed = true }
            }
            return
        }
        guard case .recorded(let snapshot, removed: false) = chats.conversations[index].messages[row].card
        else { return }
        store.delete(snapshot)
        guard store.transaction(id: snapshot.id) == nil else {
            // Once the "Xoá giao dịch?" alert has gone: raised from its own button, the second
            // could be dropped, and the tap did nothing (audit round 3, 2026-11-16).
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                cannotDelete = snapshot
            }
            return
        }
        chats.conversations[index].messages[row].card = .recorded(snapshot, removed: true)
    }

    /// An answer as VoiceOver should say it: without the Markdown marks it is written with, its
    /// money and days as words (`SpokenText`).
    static func spoken(_ text: String) -> String {
        SpokenText.of(text.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "• ", with: ""))
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

/// A little time iOS gives the app in the background to finish something, ended once: when the
/// work is done, or when iOS says the time is up.
final class BackgroundTime {
    private var id = UIBackgroundTaskIdentifier.invalid

    init(name: String) {
        id = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in self?.end() }
    }

    func end() {
        guard id != .invalid else { return }
        UIApplication.shared.endBackgroundTask(id)
        id = .invalid
    }
}
