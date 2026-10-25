//
//  AssistantView.swift
//  Timi
//

import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant }

    let id = UUID()
    let role: Role
    let text: String
}

struct AssistantView: View {
    @Environment(FinanceStore.self) private var store
    @State private var messages = [ChatMessage(role: .assistant, text: MockAssistant.welcome)]
    @State private var draft = ""
    @State private var isThinking = false
    @FocusState private var isInputFocused: Bool

    private let suggestions = [
        "Tháng này tôi chi bao nhiêu?",
        "Khoản chi lớn nhất là gì?",
        "Gợi ý cách tiết kiệm",
        "Tổng số dư của tôi",
        "Thu nhập tháng này",
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if isThinking {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages) { _, newMessages in
                    guard let lastID = newMessages.last?.id else { return }
                    withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                }
                .onChange(of: isThinking) { _, thinking in
                    if thinking {
                        withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                inputBar
            }
            .navigationTitle("Trợ lý AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cuộc trò chuyện mới", systemImage: "square.and.pencil") {
                        messages = [ChatMessage(role: .assistant, text: MockAssistant.welcome)]
                    }
                    .disabled(messages.count <= 1)
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(suggestion) { send(suggestion) }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.horizontal)
            }
            .disabled(isThinking)

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Hỏi về tài chính của bạn…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .onSubmit { send(draft) }

                Button {
                    send(draft)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isThinking)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func send(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking else { return }

        messages.append(ChatMessage(role: .user, text: question))
        draft = ""
        isThinking = true

        Task {
            // Giả lập thời gian "suy nghĩ" của AI
            try? await Task.sleep(for: .seconds(1))
            let answer = MockAssistant(store: store).reply(to: question)
            messages.append(ChatMessage(role: .assistant, text: answer))
            isThinking = false
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 48)
            } else {
                AssistantAvatar()
            }

            Text(formattedText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(isUser ? .white : .primary)
                .background(
                    isUser ? Color.accentColor : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            if !isUser {
                Spacer(minLength: 32)
            }
        }
    }

    /// Hiển thị **in đậm** và _in nghiêng_ theo cú pháp Markdown, giữ nguyên xuống dòng.
    private var formattedText: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: message.text, options: options)) ?? AttributedString(message.text)
    }
}

struct AssistantAvatar: View {
    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(Theme.brandGradient, in: Circle())
    }
}

struct TypingIndicator: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            AssistantAvatar()
            Image(systemName: "ellipsis")
                .font(.title2.weight(.bold))
                .foregroundStyle(.secondary)
                .symbolEffect(.variableColor.iterative, options: .repeating)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
    }
}

#Preview {
    AssistantView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
