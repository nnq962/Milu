//
//  AssistantView.swift
//  Timi
//

import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant }

    /// Action card state; the transaction is a snapshot so the card still reads after a delete.
    enum Card: Equatable {
        case recorded(FinanceTransaction, removed: Bool)
        case confirmDelete(FinanceTransaction, state: DeleteState)
    }

    enum DeleteState: Equatable { case pending, deleted, cancelled }

    let id = UUID()
    let role: Role
    let text: String
    var card: Card? = nil
    var showsSuggestions = false
}

/// One chat thread; earlier threads stay available from the history menu until the app quits.
struct Conversation: Identifiable {
    let id = UUID()
    let startedAt: Date
    var messages: [ChatMessage]

    static func new(name: String) -> Conversation {
        Conversation(startedAt: .now, messages: [
            ChatMessage(role: .assistant, text: MockAssistant.welcome(name: name), showsSuggestions: true),
        ])
    }

    var title: String {
        messages.first { $0.role == .user }?.text ?? "Cuộc trò chuyện mới"
    }
}

struct AssistantView: View {
    @Environment(FinanceStore.self) private var store
    @State private var conversations = [Conversation.new(name: "Quyet")]
    @State private var currentID: Conversation.ID?
    @State private var draft = ""
    @State private var isThinking = false
    @State private var editingTransaction: FinanceTransaction?
    @State private var dictation = SpeechDictation()
    @FocusState private var isInputFocused: Bool

    private var currentIndex: Int {
        conversations.firstIndex { $0.id == currentID } ?? conversations.count - 1
    }

    private var messages: [ChatMessage] { conversations[currentIndex].messages }

    var body: some View {
        NavigationStack {
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
            .safeAreaInset(edge: .bottom) { inputBar }
            .navigationTitle("Timi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
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
            .sheet(item: $editingTransaction) { AddTransactionView(editing: $0) }
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
        }
    }

    // MARK: - Đầu trang

    private var heading: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Timi")
                .font(Typography.font(.title2, size: 24, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            Text("Trợ lý tài chính · Bản thử nghiệm")
                .font(Typography.font(.caption, size: 12))
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
                Label("Cuộc trò chuyện mới", image: "solar-pen-new-square-linear")
            }
            .disabled(messages.count <= 1)
            let earlier = conversations.filter { $0.id != conversations[currentIndex].id && $0.messages.count > 1 }
            if !earlier.isEmpty {
                Section("Trước đó") {
                    ForEach(earlier.reversed()) { conversation in
                        Button {
                            currentID = conversation.id
                        } label: {
                            Text(conversation.title)
                            Text(conversation.startedAt.formatted(.dateTime.hour().minute().locale(.vietnam)))
                        }
                    }
                }
            }
        } label: {
            SolarIcon("solar-clock-circle-linear", size: 20)
                .frame(width: 28, height: 28)
        }
        .menuStyle(.button)
        .buttonBorderShape(.circle)
        .tint(Palette.ink)
        .accessibilityLabel("Lịch sử trò chuyện")
    }

    private var dateChip: some View {
        Text(conversations[currentIndex].startedAt.transactionDayTitle)
            .font(Typography.font(.caption2, size: 11, weight: .medium))
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
                SolarIcon("solar-microphone-3-linear", size: 20)
                    .foregroundStyle(dictation.isRecording ? Palette.red : Palette.secondary)
                    .frame(width: 32, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(dictation.isRecording ? "Dừng nhập giọng nói" : "Nhập bằng giọng nói")

            TextField(dictation.isRecording ? "Đang nghe…" : "Hỏi Timi hoặc ghi giao dịch...", text: $draft, axis: .vertical)
                .font(Typography.font(.subheadline, size: 14))
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { send(draft) }

            Button {
                send(draft)
            } label: {
                SolarIcon("solar-arrow-up-linear", size: 18)
                    .foregroundStyle(.white)
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

    private var dictationMessage: String {
        switch dictation.failure {
        case .denied: "Hãy cho phép Timi dùng micro và nhận dạng giọng nói trong Cài đặt."
        case .unavailable: "Nhận dạng giọng nói tiếng Việt hiện chưa sẵn sàng trên thiết bị này."
        case .audio, nil: "Không mở được micro. Bạn thử lại sau nhé."
        }
    }

    // MARK: - Hành động

    private func startNewConversation() {
        conversations.append(.new(name: "Quyet"))
        currentID = conversations.last?.id
        draft = ""
    }

    private func send(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking else { return }
        dictation.stop()
        let index = currentIndex
        conversations[index].messages.append(ChatMessage(role: .user, text: question))
        draft = ""
        isThinking = true

        Task {
            // Giả lập thời gian "suy nghĩ" của AI
            try? await Task.sleep(for: .seconds(1))
            let reply = MockAssistant(store: store).reply(to: question)
            let card: ChatMessage.Card? = switch reply.action {
            case .recorded(let transaction): .recorded(transaction, removed: false)
            case .confirmDelete(let transaction): .confirmDelete(transaction, state: .pending)
            case nil: nil
            }
            conversations[index].messages.append(ChatMessage(role: .assistant, text: reply.text, card: card))
            isThinking = false
        }
    }

    private func handle(_ action: CardAction, in message: ChatMessage) {
        let index = currentIndex
        guard let row = conversations[index].messages.firstIndex(where: { $0.id == message.id }),
              let card = message.card else { return }
        switch (action, card) {
        case (.edit, .recorded(let snapshot, _)):
            editingTransaction = store.transaction(id: snapshot.id)
        case (.remove, .recorded(let snapshot, _)):
            store.delete(snapshot)
            conversations[index].messages[row].card = .recorded(snapshot, removed: true)
        case (.confirm, .confirmDelete(let snapshot, .pending)):
            store.delete(snapshot)
            conversations[index].messages[row].card = .confirmDelete(snapshot, state: .deleted)
        case (.cancel, .confirmDelete(let snapshot, .pending)):
            conversations[index].messages[row].card = .confirmDelete(snapshot, state: .cancelled)
        default:
            break
        }
    }
}

enum CardAction { case edit, remove, confirm, cancel }

// MARK: - Tin nhắn

private struct MessageRow: View {
    @Environment(FinanceStore.self) private var store
    let message: ChatMessage
    let onSuggestion: (String) -> Void
    let onAction: (CardAction, ChatMessage) -> Void

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 0)
                Text(message.text)
                    .font(Typography.font(.subheadline, size: 14))
                    .lineSpacing(5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Palette.ink, in: UnevenRoundedRectangle(
                        topLeadingRadius: Bubble.radius, bottomLeadingRadius: Bubble.radius,
                        bottomTrailingRadius: Bubble.radius, topTrailingRadius: Bubble.tail, style: .continuous))
                    .containerRelativeFrame(.horizontal, alignment: .trailing) { width, _ in width * Bubble.maxWidth }
            }
        case .assistant:
            HStack(alignment: .top, spacing: 12) {
                AssistantAvatar()
                VStack(alignment: .leading, spacing: 8) {
                    bubble
                    cardButtons
                    if message.showsSuggestions {
                        FlowLayout(spacing: 8) {
                            ForEach(MockAssistant.suggestions, id: \.self) { suggestion in
                                Button(suggestion) { onSuggestion(suggestion) }
                                    .font(Typography.font(.caption, size: 12, weight: .medium))
                                    .foregroundStyle(Palette.ink)
                                    .nativeGlassButton()
                                    .buttonBorderShape(.capsule)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .containerRelativeFrame(.horizontal, alignment: .leading) { width, _ in width * Bubble.maxWidth }
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedText)
                .font(Typography.font(.subheadline, size: 14))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            if let transaction = cardTransaction {
                TransactionCard(transaction: transaction)
            }
            if let status = cardStatus {
                Text(status)
                    .font(Typography.font(.caption, size: 12, weight: .medium))
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .padding(16)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Bubble.tail, bottomLeadingRadius: Bubble.radius,
                                   bottomTrailingRadius: Bubble.radius, topTrailingRadius: Bubble.radius, style: .continuous)
                .fill(Palette.card)
                .shadow(color: Color(red: 28/255, green: 36/255, blue: 48/255).opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    /// Shows the live transaction (after edits) while it exists, else the snapshot.
    private var cardTransaction: FinanceTransaction? {
        switch message.card {
        case .recorded(let snapshot, _), .confirmDelete(let snapshot, _):
            store.transaction(id: snapshot.id) ?? snapshot
        case nil: nil
        }
    }

    private var cardStatus: String? {
        switch message.card {
        case .recorded(_, removed: true): "Đã xoá khoản này, số dư đã được cập nhật lại."
        case .confirmDelete(_, .deleted): "Đã xoá khoản này, số dư đã được cập nhật lại."
        case .confirmDelete(_, .cancelled): "Đã giữ lại khoản này."
        default: nil
        }
    }

    @ViewBuilder
    private var cardButtons: some View {
        switch message.card {
        case .recorded(let snapshot, removed: false) where store.transaction(id: snapshot.id) != nil:
            HStack(spacing: 8) {
                cardButton("Sửa", icon: "solar-pen-linear", color: Palette.ink) { onAction(.edit, message) }
                cardButton("Xoá", icon: "solar-trash-bin-minimalistic-linear", color: Palette.red) { onAction(.remove, message) }
            }
        case .confirmDelete(let snapshot, .pending) where store.transaction(id: snapshot.id) != nil:
            HStack(spacing: 8) {
                Button { onAction(.cancel, message) } label: {
                    Text("Huỷ").frame(maxWidth: .infinity)
                }
                .foregroundStyle(Palette.ink)
                .nativeGlassButton(tint: Palette.muted)
                Button(role: .destructive) { onAction(.confirm, message) } label: {
                    Text("Xoá khoản này").frame(maxWidth: .infinity)
                }
                .foregroundStyle(.white)
                .nativeGlassButton(prominent: true, tint: Palette.red)
            }
            .font(Typography.font(.caption, size: 12, weight: .semibold))
            .buttonBorderShape(.capsule)
        default:
            EmptyView()
        }
    }

    private func cardButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                SolarIcon(icon, size: 14)
                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .font(Typography.font(.caption, size: 12, weight: .semibold))
        .foregroundStyle(color)
        .nativeGlassButton()
        .buttonBorderShape(.capsule)
    }

    /// Hiển thị **in đậm** và _in nghiêng_ theo cú pháp Markdown, giữ nguyên xuống dòng.
    private var formattedText: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: message.text, options: options)) ?? AttributedString(message.text)
    }
}

/// Transaction summary inside an assistant bubble: muted tile, 40pt white icon circle.
private struct TransactionCard: View {
    let transaction: FinanceTransaction

    var body: some View {
        HStack(spacing: 12) {
            IconCircle(icon: transaction.category.icon, iconSize: 18, background: Palette.card)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(transaction.title)
                    .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                    .lineLimit(1)
                Text("\(transaction.category.title) · \(dayText)")
                    .font(Typography.font(.caption2, size: 11))
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(transaction.signedAmountText)
                .font(Typography.font(.subheadline, size: 14, weight: .bold))
                .foregroundStyle(transaction.kind == .income ? Palette.ink : Palette.red)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .cardSurface(radius: CardCorners.flow, color: Palette.muted)
        .accessibilityElement(children: .combine)
    }

    private var dayText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(transaction.date) { return "Hôm nay" }
        if calendar.isDateInYesterday(transaction.date) { return "Hôm qua" }
        return transaction.date.dayMonth
    }
}

private enum Bubble {
    // rounded-2xl with a rounded-md tail corner, scaled for short chat bubbles.
    static let radius: CGFloat = 24
    static let tail: CGFloat = 8
    static let maxWidth: CGFloat = 0.78
}

struct AssistantAvatar: View {
    var body: some View {
        SolarIcon("solar-stars-minimalistic-bold", size: 14)
            .foregroundStyle(Palette.ink)
            .frame(width: 32, height: 32)
            .background(Palette.lime, in: Circle())
            .accessibilityHidden(true)
    }
}

struct TypingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AssistantAvatar()
            SolarIcon("solar-menu-dots-linear", size: 20)
                .foregroundStyle(Palette.secondary)
                .phaseAnimator([false, true]) { content, dimmed in
                    content.opacity(reduceMotion ? 1 : (dimmed ? 0.35 : 1))
                } animation: { _ in
                    .easeInOut(duration: 0.7)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Palette.card, in: UnevenRoundedRectangle(
                    topLeadingRadius: Bubble.tail, bottomLeadingRadius: Bubble.radius,
                    bottomTrailingRadius: Bubble.radius, topTrailingRadius: Bubble.radius, style: .continuous))
            Spacer()
        }
        .accessibilityLabel("Timi đang trả lời")
    }
}

/// Wraps children onto new lines like CSS flex-wrap.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [(indices: [Int], width: CGFloat, height: CGFloat)] {
        var rows: [(indices: [Int], width: CGFloat, height: CGFloat)] = []
        var current: [Int] = []
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let next = current.isEmpty ? size.width : rowWidth + spacing + size.width
            if !current.isEmpty && next > width {
                rows.append((current, rowWidth, rowHeight))
                current = [index]
                rowWidth = size.width
                rowHeight = size.height
            } else {
                current.append(index)
                rowWidth = next
                rowHeight = max(rowHeight, size.height)
            }
        }
        if !current.isEmpty { rows.append((current, rowWidth, rowHeight)) }
        return rows
    }
}

#Preview {
    AssistantView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .font(Typography.body)
}
