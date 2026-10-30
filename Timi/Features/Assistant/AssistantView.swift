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
    @State private var editingTransaction: FinanceTransaction?
    @State private var dictation = SpeechDictation()
    @FocusState private var isInputFocused: Bool

    private var currentIndex: Int {
        chats.conversations.firstIndex { $0.id == chats.currentID } ?? chats.conversations.count - 1
    }

    private var messages: [ChatMessage] { chats.conversations[currentIndex].messages }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    dateChip
                    ForEach(messages) { message in
                        MessageRow(message: message, onSuggestion: send, onAction: handle)
                            .id(message.id)
                    }
                    if isThinking {
                        TypingIndicator().id("typing")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
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
        .navigationTitle("Timi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) { HiddenToolbarTitle() }
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .topBarLeading) { heading }
                    .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .topBarTrailing) {
                    historyMenu.nativeCircleButton(diameter: 44)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .topBarLeading) { heading }
                ToolbarItem(placement: .topBarTrailing) { historyMenu }
            }
        }
        .sheet(item: $editingTransaction) { TransactionDetailSheet(transactionID: $0.id) }
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
        VStack(alignment: .leading, spacing: 2) {
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
            TimiIcon("hugeicons-clock-01", size: 20)
                .frame(width: 28, height: 28)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Palette.muted, in: Capsule())
            .frame(maxWidth: .infinity)
    }

    // MARK: - Ô nhập

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Button {
                Task { await dictation.toggle() }
            } label: {
                TimiIcon("hugeicons-mic-01", size: 20)
                    .foregroundStyle(dictation.isRecording ? Palette.red : Palette.secondary)
                    .frame(width: 32, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(dictation.isRecording ? "Dừng nhập giọng nói" : "Nhập bằng giọng nói")

            TextField(dictation.isRecording ? "Đang nghe…" : "Hỏi Timi hoặc ghi giao dịch...", text: $draft, axis: .vertical)
                .textRole(.body)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { send(draft) }

            Button {
                send(draft)
            } label: {
                TimiIcon("hugeicons-arrow-up-02", size: 18)
                    .foregroundStyle(Palette.onPrimary)
            }
            .nativeFloatingButton(diameter: 40, tint: Palette.primary)
            .disabled(!canSend)
            .accessibilityLabel("Gửi tin nhắn")
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(Palette.input, in: Capsule())
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // Solid page color, not a self-made blur: iOS owns translucency around system bars.
        .background(Palette.background)
    }

    /// In place of the input once this month's questions and the bonus are used up.
    private var outOfQuestions: some View {
        HStack(alignment: .top, spacing: 12) {
            TimiIcon("hugeicons-ai-magic", size: 22)
                .foregroundStyle(Palette.primary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Đã dùng hết lượt AI")
                    .textRole(.bodyStrong)
                Text("Lượt mới vào \(quota.renewsOn.formatted(.dateTime.day().month(.defaultDigits).locale(.vietnam))). Timi Pro có \(AIQuota.monthlyPro) lượt mỗi tháng, sắp ra mắt.")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: CardCorners.inset, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        case (.edit, .recorded(let snapshot, _)):
            editingTransaction = store.transaction(id: snapshot.id)
        case (.remove, .recorded(let snapshot, _)):
            store.delete(snapshot)
            chats.conversations[index].messages[row].card = .recorded(snapshot, removed: true)
        case (.confirm, .confirmDelete(let snapshot, .pending)):
            store.delete(snapshot)
            chats.conversations[index].messages[row].card = .confirmDelete(snapshot, state: .deleted)
        case (.cancel, .confirmDelete(let snapshot, .pending)):
            chats.conversations[index].messages[row].card = .confirmDelete(snapshot, state: .cancelled)
        default:
            break
        }
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
