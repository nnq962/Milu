import SwiftUI

/// Trợ lý AI: a screen of its own over everything, sliding up from Tổng quan and closed with ✕ or
/// a swipe down, so the input bar is the only thing at the bottom (user request 2026-10-30: tab
/// bar and input together looked crowded). Pushed, it hid the tab bar, which iOS brought back only
/// once the pop had finished, at once (user report 2026-10-31). Wrap it in a `NavigationStack`.
struct AssistantView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota
    @Environment(AssistantChats.self) private var chats
    @State private var draft = ""
    @State private var isThinking = false
    /// Set on the first question; `OnboardingRewards` pays "Hỏi Milu một câu" in Làm quen với Milu.
    @AppStorage(StorageKey.askedAI) private var hasAskedAI = false
    @State private var viewingTransaction: FinanceTransaction?
    /// The chat card whose "Xoá" was tapped, until the alert is answered: deleting always asks
    /// first, in chat too (strict review 2026-10-31: it deleted at once).
    @State private var pendingRemoval: ChatMessage?
    @State private var dictation = SpeechDictation()
    /// What the field held when the mic started: heard words go after it, ✕ brings it back.
    @State private var draftBeforeDictation = ""
    /// The field's pieces that move into each other between typing and listening.
    @Namespace private var inputSpace
    @FocusState private var isInputFocused: Bool
    /// The chat is scrolled up from its end, far enough to show the ↓ that brings it back.
    @State private var isAwayFromEnd = false
    @State private var isShowingHistory = false
    @AppStorage(StorageKey.profileName) private var profileName = ""

    /// How far above the end, in points, before ↓ shows: past a short slip of the thumb.
    private static let awayDistance: CGFloat = 160

    private var currentIndex: Int {
        chats.conversations.firstIndex { $0.id == chats.currentID } ?? chats.conversations.count - 1
    }

    private var messages: [ChatMessage] { chats.conversations[currentIndex].messages }
    private var hasQuestions: Bool { chats.conversations[currentIndex].hasQuestions }

    /// The very end of the chat, under the last message and the typing dots.
    private static let endID = "end"

    var body: some View {
        Group {
            // A new chat greets in the middle of the page with what to ask, as the AI apps do
            // (user request 2026-11-09: a greeting bubble and a title bar read like a form).
            if hasQuestions { chat } else { greeting }
        }
        // Under the keyboard too: its rounded glass showed the window's white at its corners
        // (user report 2026-10-31).
        .background { PageBackground().ignoresSafeArea() }
        .foregroundStyle(Palette.label)
        // A bar of the system's: the chat scrolls under the glass, behind iOS's own edge fade.
        .bottomBar {
            if quota.isEmpty { outOfQuestions } else { inputBar }
        }
        // No title or subtitle in the middle (user request 2026-11-09: AI apps show none); the
        // name stays for VoiceOver and the back button.
        .navigationTitle("Milu")
        .toolbarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            // An empty slot, not EmptyView: with nothing there, iOS shows the title.
            ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1).accessibilityHidden(true) }
            // Plain buttons: the bar draws their glass, each its own (`ToolbarSpacer`).
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
        .onChange(of: dictation.transcript) { _, text in
            // After what was typed before the mic, not over it.
            if dictation.isRecording {
                draft = [draftBeforeDictation, text].filter { !$0.isEmpty }.joined(separator: " ")
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

    // MARK: - Chat

    private var chat: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    dateChip
                    ForEach(messages) { message in
                        MessageRow(message: message, onAction: handle)
                            .id(message.id)
                    }
                    if isThinking {
                        TypingIndicator().id("typing")
                    }
                }
                // Close to the screen's edges, as the field below (user request 2026-10-31).
                .padding(.horizontal, Spacing.l)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xl)
                // A tap on a message closes the keyboard too; a card's buttons still take theirs.
                .contentShape(Rectangle())
                .onTapGesture { dismissKeyboard() }
                Color.clear.frame(height: 0).id(Self.endID)
            }
            .scrollDismissesKeyboard(.interactively)
            // A tap on the empty page under the chat closes the keyboard (user report 2026-11-09).
            .keyboardDismissArea()
            .onAwayFromEnd(by: Self.awayDistance) { away in
                withAnimation(.spring(duration: 0.3)) { isAwayFromEnd = away }
            }
            // ↓ in glass over the chat, centred just above the field, as in Claude and ChatGPT
            // (user request 2026-10-31): only while scrolled up, and gone once back at the end.
            .overlay(alignment: .bottom) {
                if isAwayFromEnd {
                    Button {
                        withAnimation { proxy.scrollTo(Self.endID, anchor: .bottom) }
                    } label: {
                        // SF's arrow, as iOS draws it (user request 2026-11-09).
                        Image(systemName: "arrow.down")
                            .font(.system(size: IconSize.control, weight: .semibold))
                            .foregroundStyle(Palette.label)
                            // A full 44 of glass: the glass button style drew a 32 circle inside it.
                            .frame(width: ControlHeight.regular, height: ControlHeight.regular)
                            .interactiveGlass(in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, Spacing.s)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                    .accessibilityLabel("Cuộn xuống tin mới nhất")
                }
            }
            .onChange(of: messages) { _, newMessages in
                guard let lastID = newMessages.last?.id else { return }
                withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
            }
            .onChange(of: isThinking) { _, thinking in
                if thinking { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
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

    /// What to ask, each with its picture: tapping one asks it.
    private static let suggestions: [(emoji: String, text: String)] = [
        ("📊", "Tháng này tôi tiêu gì nhiều nhất?"),
        ("📝", "Ghi một khoản chi"),
        ("🤝", "Ai đang nợ tôi?"),
    ]

    @ScaledMetric(relativeTo: .title) private var greetingMark: CGFloat = 72

    /// A new chat: ✨, "Chào Minh!", what Milu does, and three things to ask, in the middle of the
    /// page (scrolling when the text is large).
    private var greeting: some View {
        // The room between the bars, to centre in (a reader is cheap on this short page).
        GeometryReader { room in
        ScrollView {
            VStack(spacing: Spacing.section) {
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
                }
                .padding(.horizontal, Spacing.l)
                VStack(spacing: 0) {
                    ForEach(Array(Self.suggestions.enumerated()), id: \.offset) { index, suggestion in
                        Button { send(suggestion.text) } label: {
                            HStack(spacing: RowMetrics.gap) {
                                RowIcon(name: IconCatalog.emojiName(suggestion.emoji))
                                Text(suggestion.text)
                                    .textRole(.body)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: IconSize.inline, weight: .semibold))
                                    .foregroundStyle(Palette.tertiaryLabel)
                                    .accessibilityHidden(true)
                            }
                            .padding(.horizontal, RowMetrics.horizontal)
                            .padding(.vertical, RowMetrics.vertical)
                            .frame(minHeight: RowMetrics.minHeight)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.row)
                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                        .accessibilityHint("Hỏi Milu câu này")
                    }
                }
                .listCard()
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.xl)
            // In the middle of what shows between the bars.
            .frame(maxWidth: .infinity, minHeight: room.size.height)
            .contentShape(Rectangle())
            .onTapGesture { dismissKeyboard() }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        }
    }

    /// "Chào Minh!", or "Chào bạn!" with no name set in Cài đặt.
    private var greetingTitle: String {
        let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return "Chào \(name.isEmpty ? "bạn" : name)!"
    }

    private var dateChip: some View {
        Text(chats.conversations[currentIndex].startedAt.transactionDayTitle)
            .textRole(.captionStrong)
            .foregroundStyle(Palette.secondaryLabel)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .background(Palette.surfaceMuted, in: Capsule())
            .frame(maxWidth: .infinity)
    }

    // MARK: - Ô nhập

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    /// Every button in the field: 36, one size, so they sit on one line (user report 2026-11-09:
    /// the mic and the send arrow sat out of line).
    private static let buttonSize = ControlHeight.small
    /// The field's inset around its buttons; its corner is the buttons' plus this, so both curves
    /// share one centre, a capsule while one line.
    private static let inset = Spacing.s
    private static let inputRadius = buttonSize / 2 + inset

    /// One Liquid Glass field over the chat, as Claude's (user request 2026-11-09). Typing: the
    /// words, then the mic, or the send arrow once there are words. Listening: what was heard
    /// above, and under it ✕ (drop it), the sound running right to left, ■ (stop and keep the
    /// words to edit) and the send arrow.
    private var inputBar: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if dictation.isRecording {
                if !draft.isEmpty {
                    // The newest words stay in view: a long one loses its start, not its end.
                    Text(draft)
                        .textRole(.body)
                        .lineLimit(4)
                        .truncationMode(.head)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.s)
                        .padding(.top, Spacing.xs)
                        .matchedGeometryEffect(id: "words", in: inputSpace)
                        .transition(.blurReplace)
                }
                HStack(spacing: Spacing.s) {
                    roundButton("xmark", label: "Huỷ nhập giọng nói") { cancelDictation() }
                        .transition(.blurReplace.combined(with: .scale(0.6)))
                    VoiceWaveform(levels: dictation.levels, lastTick: dictation.lastTick)
                        .frame(maxWidth: .infinity)
                        .frame(height: Self.buttonSize)
                        .transition(.opacity)
                    // The mic becomes ■ where it stood, as Claude's does.
                    roundButton("stop.fill", label: "Dừng nghe, giữ chữ để sửa") { dictation.stop() }
                        .matchedGeometryEffect(id: "mic", in: inputSpace)
                    sendButton
                        .matchedGeometryEffect(id: "send", in: inputSpace)
                        .transition(.blurReplace.combined(with: .scale(0.6)))
                }
            } else {
                HStack(alignment: .bottom, spacing: Spacing.s) {
                    TextField("Hỏi Milu", text: $draft, axis: .vertical)
                        .textRole(.body)
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit { send(draft) }
                        .padding(.vertical, Spacing.xs)
                        .padding(.leading, Spacing.s)
                        // As tall as a button while one line, its words on the button's centre.
                        .frame(minHeight: Self.buttonSize)
                        .matchedGeometryEffect(id: "words", in: inputSpace)
                    if canSend {
                        sendButton
                            .matchedGeometryEffect(id: "send", in: inputSpace)
                            .transition(.blurReplace.combined(with: .scale(0.6)))
                    } else {
                        Button {
                            startDictation()
                        } label: {
                            Image(systemName: "mic")
                                .font(.system(size: IconSize.control, weight: .regular))
                                .foregroundStyle(Palette.secondaryLabel)
                                .frame(width: Self.buttonSize, height: Self.buttonSize)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isThinking)
                        .accessibilityLabel("Nhập bằng giọng nói")
                        .matchedGeometryEffect(id: "mic", in: inputSpace)
                        .transition(.blurReplace.combined(with: .scale(0.6)))
                    }
                }
            }
        }
        // One spring for every change of the field, as iOS moves its glass: the buttons trade
        // places, the field grows with the words, nothing jumps (user report 2026-11-09).
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: dictation.isRecording)
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: canSend)
        .animation(.smooth(duration: 0.25), value: draft)
        .sensoryFeedback(.impact(weight: .light), trigger: dictation.isRecording)
        .padding(Self.inset)
        // The field itself is the hit area: a tap anywhere on the glass starts typing.
        .contentShape(RoundedRectangle(cornerRadius: Self.inputRadius, style: .continuous))
        .onTapGesture { if !dictation.isRecording { isInputFocused = true } }
        .interactiveGlass(in: RoundedRectangle(cornerRadius: Self.inputRadius, style: .continuous))
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.s)
    }

    /// ↑ in a filled circle; while listening it stops and sends what was heard.
    private var sendButton: some View {
        Button {
            dictation.stop()
            send(draft)
        } label: {
            Image(systemName: "arrow.up")
                .font(.system(size: IconSize.bar, weight: .semibold))
                .foregroundStyle(Palette.onPrimary)
                .frame(width: Self.buttonSize, height: Self.buttonSize)
                .background(Palette.primary, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .opacity(canSend ? 1 : 0.4)
        .accessibilityLabel("Gửi tin nhắn")
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

    /// In place of the input once this month's questions and the bonus are used up.
    private var outOfQuestions: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            // A glyph in content, not a toolbar's (re-review 2026-10-31).
            AssistantAvatar()
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text("Đã dùng hết lượt AI")
                    .textRole(.bodyStrong)
                // Only when it comes back; Milu Pro is told about on Tổng quan (strict review 2026-10-31).
                // The one short date (`shortDay`).
                Text("Lượt mới vào \(quota.renewsOn.shortDay)")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        // A card like every other, with the shared shadow (strict review 2026-10-31).
        .padding(RowMetrics.horizontal)
        .cardSurface(radius: CardCorners.card)
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.s)
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
        isInputFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func startDictation() {
        draftBeforeDictation = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        dismissKeyboard()
        Task { await dictation.start() }
    }

    /// ✕: stops listening and forgets what was heard.
    private func cancelDictation() {
        dictation.stop()
        draft = draftBeforeDictation
    }

    private func startNewConversation() {
        chats.startNew()
        draft = ""
    }

    private func send(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking, quota.spend() else { return }
        dictation.stop()
        let index = currentIndex
        chats.conversations[index].messages.append(ChatMessage(role: .user, text: question))
        draft = ""
        isThinking = true
        hasAskedAI = true

        Task {
            // Giả lập thời gian "suy nghĩ" của AI
            try? await Task.sleep(for: .seconds(1))
            let reply = MockAssistant(store: store).reply(to: question)
            let card: ChatMessage.Card? = switch reply.action {
            case .recorded(let transaction): .recorded(transaction, removed: false)
            case .confirmDelete(let transaction): .confirmDelete(transaction, state: .pending)
            case nil: nil
            }
            chats.conversations[index].messages.append(ChatMessage(role: .assistant, text: reply.text, card: card))
            isThinking = false
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
