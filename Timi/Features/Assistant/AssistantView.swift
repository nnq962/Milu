import SwiftUI

/// Trợ lý AI: a page of its own pushed from Tổng quan, with no tab bar, so the input bar is the
/// only thing at the bottom (user request 2026-10-30: tab bar and input together looked crowded).
struct AssistantView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota
    @Environment(AssistantChats.self) private var chats
    @State private var draft = ""
    @State private var isThinking = false
    /// Ticks "Hỏi AI một câu hỏi" in Làm quen với Timi.
    @AppStorage(StorageKey.askedAI) private var hasAskedAI = false
    @State private var viewingTransaction: FinanceTransaction?
    /// The chat card whose "Xoá" was tapped, until the alert is answered: deleting always asks
    /// first, in chat too (strict review 2026-10-31: it deleted at once).
    @State private var pendingRemoval: ChatMessage?
    @State private var dictation = SpeechDictation()
    @FocusState private var isInputFocused: Bool

    private var currentIndex: Int {
        chats.conversations.firstIndex { $0.id == chats.currentID } ?? chats.conversations.count - 1
    }

    private var messages: [ChatMessage] { chats.conversations[currentIndex].messages }

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
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages) { _, newMessages in
                guard let lastID = newMessages.last?.id else { return }
                withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
            }
            .onChange(of: isThinking) { _, thinking in
                if thinking { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .safeAreaInset(edge: .bottom) {
            if quota.isEmpty { outOfQuestions } else { inputBar }
        }
        // iOS 26 draws the title and its subtitle natively (`TabHeading`), so they slide with the back
        // button rather than showing as a glass rectangle (user report 2026-10-30).
        .navigationTitle("Timi")
        .modifier(TabHeading(subtitle: "Trợ lý tài chính · Bản thử nghiệm"))
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            if #unavailable(iOS 26.0) {
                ToolbarItem(placement: .principal) { HiddenToolbarTitle() }
                ToolbarItem(placement: .topBarLeading) { heading }
            }
            // A plain menu: the bar draws its glass, which then takes part in push and pop.
            ToolbarItem(placement: .topBarTrailing) { historyMenu }
        }
        .sheet(item: $viewingTransaction) { TransactionDetailSheet(transactionID: $0.id) }
        .alert("Xoá giao dịch?", isPresented: Binding(
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
        .alert("Không dùng được micro", isPresented: Binding(
            get: { dictation.failure != nil },
            set: { if !$0 { dictation.failure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(dictationMessage)
        }
        .onDisappear { dictation.stop() }
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Đầu trang

    private var heading: some View {
        VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
            Text("Timi")
                .textRole(.pageTitle)
                .accessibilityAddTraits(.isHeader)
            Text("Trợ lý tài chính · Bản thử nghiệm")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
        .foregroundStyle(Palette.ink)
        .fixedSize()
    }

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
            TimiIcon("hugeicons-clock-01", size: RowMetrics.toolbarGlyph)
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .menuStyle(.button)
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Lịch sử trò chuyện")
    }

    private var dateChip: some View {
        Text(chats.conversations[currentIndex].startedAt.transactionDayTitle)
            .textRole(.captionStrong)
            .foregroundStyle(Palette.secondaryText)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .background(Palette.muted, in: Capsule())
            .frame(maxWidth: .infinity)
    }

    // MARK: - Ô nhập

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    /// Half the one-line height, so one line reads as a capsule.
    private static let inputRadius = (ControlHeight.regular + 2 * Spacing.xxs) / 2

    private var inputBar: some View {
        // Bottom-aligned: as the text grows to four lines, mic and send stay on its last line
        // (re-review 2026-10-31: they floated to the middle).
        HStack(alignment: .bottom, spacing: Spacing.s) {
            Button {
                Task { await dictation.toggle() }
            } label: {
                TimiIcon("hugeicons-mic-01", size: RowMetrics.iconGlyph)
                    .foregroundStyle(dictation.isRecording ? Palette.red : Palette.secondary)
                    // 44 to tap, like every control (strict review 2026-10-31: it was 32×40).
                    .frame(width: ControlHeight.regular, height: ControlHeight.regular)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(dictation.isRecording ? "Dừng nhập giọng nói" : "Nhập bằng giọng nói")

            TextField(dictation.isRecording ? "Đang nghe…" : "Hỏi Timi", text: $draft, axis: .vertical)
                .textRole(.body)
                .lineLimit(1...4)
                // Centred on the 44 buttons while one line, then growing upward.
                .frame(minHeight: ControlHeight.regular)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { send(draft) }

            Button {
                send(draft)
            } label: {
                TimiIcon("hugeicons-arrow-up-02", size: RowMetrics.iconGlyph)
                    .foregroundStyle(Palette.onPrimary)
            }
            .nativeFloatingButton(diameter: ControlHeight.regular, tint: Palette.primary)
            .disabled(!canSend)
            .accessibilityLabel("Gửi tin nhắn")
        }
        // The 44 mic and send buttons set the height, so the field needs little padding: the same
        // on every side, so the send circle sits evenly in the end (re-review 2026-10-31).
        .padding(Spacing.xxs)
        // A capsule while one line; a rounded rectangle of the same end radius once it grows, not
        // an oval (re-review 2026-10-31).
        .background(Palette.input, in: RoundedRectangle(cornerRadius: Self.inputRadius, style: .continuous))
        // The page margin, the same as the messages above (strict review 2026-10-31: 16 here
        // and 20 there put the bar 4pt past the bubbles on each side).
        .padding(.horizontal, Spacing.page)
        .padding(.vertical, Spacing.m)
        // Solid page color, not a self-made blur: iOS owns translucency around system bars.
        .background(Palette.background)
    }

    /// In place of the input once this month's questions and the bonus are used up.
    private var outOfQuestions: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            // A glyph in content, not a toolbar's (re-review 2026-10-31).
            TimiIcon("hugeicons-ai-magic", size: RowMetrics.iconGlyph)
                .foregroundStyle(Palette.primary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text("Đã dùng hết lượt AI")
                    .textRole(.bodyStrong)
                // Only when it comes back; Timi Pro is told about on Tổng quan (strict review 2026-10-31).
                // The one short date (`shortDay`).
                Text("Lượt mới vào \(quota.renewsOn.shortDay)")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        // A white card like every other, with the shared shadow (strict review 2026-10-31).
        .padding(RowMetrics.horizontal)
        .cardSurface(radius: CardCorners.inset, elevated: true)
        .padding(.horizontal, Spacing.page)
        .padding(.vertical, Spacing.m)
        .background(Palette.background)
    }

    private var dictationMessage: String {
        switch dictation.failure {
        case .denied: "Hãy cho phép Timi dùng micro và nhận dạng giọng nói trong Cài đặt."
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
