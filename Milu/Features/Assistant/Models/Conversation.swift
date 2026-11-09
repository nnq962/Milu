import Foundation
import OSLog
import SwiftUI

struct ChatMessage: Identifiable, Equatable, Codable {
    enum Role: String, Codable { case user, assistant }

    /// Action card state; the transaction is a snapshot so the card still reads after a delete.
    enum Card: Equatable, Codable {
        case recorded(FinanceTransaction, removed: Bool)
        case confirmDelete(FinanceTransaction, state: DeleteState)
    }

    enum DeleteState: String, Equatable, Codable { case pending, deleted, cancelled }

    var id = UUID()
    let role: Role
    let text: String
    var card: Card? = nil
    /// When it was sent: the history orders chats by their last message.
    var date = Date.now
}

/// One chat thread. A new one starts empty: the page greets with suggestions in its place, and it
/// enters the history with its first question (user request 2026-11-09, as the AI apps do).
struct Conversation: Identifiable, Codable, Equatable {
    var id = UUID()
    var startedAt = Date.now
    var messages: [ChatMessage] = []

    static func new() -> Conversation { Conversation() }

    /// Asked something yet: an empty chat has no place in the history.
    var hasQuestions: Bool { messages.contains { $0.role == .user } }

    /// The first question, as the history lists it.
    var title: String {
        messages.first { $0.role == .user }?.text ?? "Cuộc trò chuyện mới"
    }

    /// The last message's time, or when it started.
    var lastActivity: Date { messages.last?.date ?? startedAt }
}

enum CardAction { case view, remove, confirm, cancel }

/// The chats, kept by the app rather than the page (Trợ lý AI opens anew each time) and saved on
/// this phone, so the history is still there after a relaunch (user request 2026-11-09). Each
/// launch opens on a new chat; the earlier ones are in the history. "Xoá toàn bộ dữ liệu" removes
/// them (`DataReset`).
@Observable
final class AssistantChats {
    var conversations: [Conversation] {
        didSet { save() }
    }
    var currentID: Conversation.ID?

    /// The newest chats kept: an old chat is a few kilobytes, but the list should stay short.
    static let limit = 100

    /// `saving: false` keeps it in memory only (previews, tests).
    init(saving: Bool = true) {
        isSaving = saving
        let saved = saving ? Self.load() : []
        conversations = saved + [.new()]
        currentID = conversations.last?.id
    }

    @ObservationIgnored private let isSaving: Bool

    /// Chats with a question, newest activity first.
    var history: [Conversation] {
        conversations.filter(\.hasQuestions).sorted { $0.lastActivity > $1.lastActivity }
    }

    func delete(_ id: Conversation.ID) {
        conversations.removeAll { $0.id == id }
        if !conversations.contains(where: { $0.id == currentID }) {
            currentID = nil
            startNew()
        }
    }

    /// A new chat to ask in, unless the current one is still empty.
    func startNew() {
        if let current = conversations.first(where: { $0.id == currentID }), !current.hasQuestions { return }
        conversations.removeAll { !$0.hasQuestions }
        let chat = Conversation.new()
        conversations.append(chat)
        currentID = chat.id
    }

    // MARK: - Lưu trên máy

    private static let log = Logger(subsystem: "com.quyetnguyen.Milu", category: "assistant")

    static var fileURL: URL {
        URL.applicationSupportDirectory.appending(path: "AssistantChats.json")
    }

    private func save() {
        guard isSaving else { return }
        let kept = Array(history.prefix(Self.limit))
        do {
            try FileManager.default.createDirectory(at: URL.applicationSupportDirectory,
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(kept).write(to: Self.fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            Self.log.error("Cannot save the chats: \(error)")
        }
    }

    private static func load() -> [Conversation] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            return try JSONDecoder().decode([Conversation].self, from: data)
                .filter(\.hasQuestions)
                .sorted { $0.startedAt < $1.startedAt }
        } catch {
            log.error("Cannot read the chats: \(error)")
            return []
        }
    }

    /// For "Xoá toàn bộ dữ liệu".
    static func deleteSaved() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
