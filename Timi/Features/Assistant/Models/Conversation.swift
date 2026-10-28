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
