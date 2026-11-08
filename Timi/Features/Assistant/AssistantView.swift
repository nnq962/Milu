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
    @FocusState private var isInputFocused: Bool
    /// The chat is scrolled up from its end, far enough to show the ↓ that brings it back.
    @State private var isAwayFromEnd = false

    /// How far above the end, in points, before ↓ shows: past a short slip of the thumb.
    private static let awayDistance: CGFloat = 160

    private var currentIndex: Int {
        chats.conversations.firstIndex { $0.id == chats.currentID } ?? chats.conversations.count - 1
    }

    private var messages: [ChatMessage] { chats.conversations[currentIndex].messages }

    /// The very end of the chat, under the last message and the typing dots.
    private static let endID = "end"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    dateChip
                    ForEach(messages) { message in
                        MessageRow(message: message, onSuggestion: send, onAction: handle)
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
                Color.clear.frame(height: 0).id(Self.endID)
            }
            .scrollDismissesKeyboard(.interactively)
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
                        TimiIcon("hugeicons-arrow-up-02", size: IconSize.control)
                            .rotationEffect(.degrees(180))
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
        // Under the keyboard too: its rounded glass showed the window's white at its corners
        // (user report 2026-10-31).
        .background { PageBackground().ignoresSafeArea() }
        .foregroundStyle(Palette.label)
        // A bar of the system's: the chat scrolls under the glass, behind iOS's own edge fade.
        .bottomBar {
            if quota.isEmpty { outOfQuestions } else { inputBar }
        }
        // iOS draws the title and its subtitle natively, not a glass rectangle (user report 2026-10-30).
        .navigationTitle("Milu")
        // Small and centred, as on every sheet, so ✕ keeps its place on the left.
        .toolbarTitleDisplayMode(.inline)
        .navigationSubtitleIfAvailable("Trợ lý tài chính · Bản thử nghiệm")
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            // A plain menu: the bar draws its glass.
            ToolbarItem(placement: .topBarTrailing) { historyMenu }
        }
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
            if dictation.isRecording { draft = text }
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

    private var historyMenu: some View {
        Menu {
            Button {
                startNewConversation()
            } label: {
                Label("Cuộc trò chuyện mới", image: "hugeicons-pencil-edit-02")
            }
            .disabled(messages.count <= 1)
            let earlier = chats.conversations.filter { $0.id != chats.conversations[currentIndex].id && $0.messages.count > 1 }
            if !earlier.isEmpty {
                Section("Trước đó") {
                    ForEach(earlier.reversed()) { conversation in
                        Button {
                            chats.currentID = conversation.id
                        } label: {
                            Text(conversation.title)
                            Text(conversation.startedAt.formatted(.dateTime.hour().minute().locale(.vietnam)))
                        }
                    }
                }
            }
        } label: {
            BarSymbol("clock.arrow.circlepath")
        }
        .menuStyle(.button)
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Lịch sử trò chuyện")
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

    /// The field's corner while one line: half its height, a capsule; it keeps the radius as it
    /// grows, a rounded rectangle and not an oval.
    private static let inputRadius = ControlHeight.regular / 2 + Spacing.xxs

    /// iOS 26's own input, as in Tin nhắn (user request 2026-10-31): one Liquid Glass field over
    /// the chat, holding only the words and one button at its end. The mic while there is nothing
    /// to send or while listening; the send arrow, tinted, once there are words. Two jobs, one
    /// place, so the button never moves under the thumb.
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            TextField(dictation.isRecording ? "Đang nghe…" : "Hỏi Milu", text: $draft, axis: .vertical)
                .textRole(.body)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { send(draft) }
                .padding(.leading, Spacing.l)
                .padding(.vertical, Spacing.s)
                // Centred on the button while one line, then growing upward.
                .frame(minHeight: ControlHeight.small)

            Group {
                if canSend && !dictation.isRecording {
                    Button {
                        send(draft)
                    } label: {
                        TimiIcon("hugeicons-arrow-up-02", size: IconSize.control)
                            .foregroundStyle(Palette.onPrimary)
                    }
                    .nativeFloatingButton(diameter: ControlHeight.small, tint: Palette.primary)
                    .accessibilityLabel("Gửi tin nhắn")
                } else {
                    Button {
                        Task { await dictation.toggle() }
                    } label: {
                        TimiIcon("hugeicons-mic-01", size: IconSize.control)
                            .foregroundStyle(dictation.isRecording ? Palette.negative : Palette.secondaryLabel)
                            .frame(width: ControlHeight.small, height: ControlHeight.small)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isThinking)
                    .accessibilityLabel(dictation.isRecording ? "Dừng nhập giọng nói" : "Nhập bằng giọng nói")
                }
            }
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
        .animation(.spring(duration: 0.25), value: canSend && !dictation.isRecording)
        .padding(Spacing.xs)
        // The field itself is the hit area: a tap anywhere on the glass starts typing.
        .contentShape(RoundedRectangle(cornerRadius: Self.inputRadius, style: .continuous))
        .onTapGesture { isInputFocused = true }
        .interactiveGlass(in: RoundedRectangle(cornerRadius: Self.inputRadius, style: .continuous))
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.s)
    }

    /// In place of the input once this month's questions and the bonus are used up.
    private var outOfQuestions: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            // A glyph in content, not a toolbar's (re-review 2026-10-31).
            AssistantAvatar()
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text("Đã dùng hết lượt AI")
                    .textRole(.bodyStrong)
                // Only when it comes back; Timi Pro is told about on Tổng quan (strict review 2026-10-31).
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

    private func startNewConversation() {
        chats.conversations.append(.new(name: "Quyet"))
        chats.currentID = chats.conversations.last?.id
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
        .environment(AssistantChats())
        .environment(AIQuota())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
