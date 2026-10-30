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

enum CardAction { case edit, remove, confirm, cancel }

/// The chats of this run, kept by the app rather than the page: Trợ lý AI is pushed from Tổng
/// quan now (user request 2026-10-30), and a page opened anew would start empty each time.
@Observable
final class AssistantChats {
    var conversations = [Conversation.new(name: "Quyet")]
    var currentID: Conversation.ID?
}
