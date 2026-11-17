import Foundation
import OSLog
import SwiftUI

struct ChatMessage: Identifiable, Equatable, Codable {
    /// `notice`: a line of the app's own in the chat ("Bạn đã dừng câu trả lời"), never sent to Milu.
    enum Role: String, Codable { case user, assistant, notice }

    /// Action card state; the transaction is a snapshot so the card still reads after a delete.
    enum Card: Equatable, Codable {
        /// A transaction Milu recorded at once, before cards asked first (chats saved before
        /// 2026-11-17); nothing makes one now.
        case recorded(FinanceTransaction, removed: Bool)
        case confirmDelete(FinanceTransaction, state: DeleteState)
        /// Transactions waiting for "Lưu" (user choice 2026-11-17), then saved, cancelled or replaced.
        case draft(TransactionDraft)
    }

    enum DeleteState: String, Equatable, Codable { case pending, deleted, cancelled }

    /// How Milu came to an answer: the line over it, "Đã nghĩ 4 giây · 2 bước ›", opening on the
    /// steps (`ThinkingStep.done`).
    struct Thought: Equatable, Codable {
        let seconds: Int
        let steps: [String]
    }

    var id = UUID()
    let role: Role
    let text: String
    var card: Card? = nil
    /// Milu's answers only; none on an error or on a chat saved before 2026-11-15.
    var thought: Thought? = nil
    /// When it was sent: the history orders chats by their last message.
    var date = Date.now
    /// Said by the app itself, not the model: "ok" typed under a card saved it here (no
    /// "Sao chép" or "Hỏi lại" under it).
    var isLocal: Bool? = nil
}

extension ChatMessage {
    private enum CodingKeys: String, CodingKey {
        case id, role, text, card, thought, date, isLocal
    }

    /// Read leniently: a card this build cannot read (one a newer build wrote) is dropped alone.
    /// Read strictly, one such card failed the whole file, and every chat was gone.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        role = try values.decode(Role.self, forKey: .role)
        text = try values.decode(String.self, forKey: .text)
        card = (try? values.decodeIfPresent(Card.self, forKey: .card)) ?? nil
        thought = (try? values.decodeIfPresent(Thought.self, forKey: .thought)) ?? nil
        date = (try? values.decodeIfPresent(Date.self, forKey: .date)) ?? .now
        isLocal = (try? values.decodeIfPresent(Bool.self, forKey: .isLocal)) ?? nil
    }

    /// The card waiting for "Lưu" in this message, if it holds one.
    var pendingDraft: TransactionDraft? {
        if case .draft(let draft) = card, draft.isPending { return draft }
        return nil
    }
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

/// What a message's buttons ask of the page: a card's, or "Hỏi lại" under an answer. On a card
/// waiting for "Lưu", `confirm` saves it and `cancel` drops it; a row is edited, or once saved
/// viewed, by its transaction's id.
enum CardAction: Equatable { case view, remove, confirm, cancel, retry, editRow(UUID), viewRow(UUID) }

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

    /// `saving: false` keeps it in memory only (previews, tests). `fileURL`: where they are kept
    /// (tests use their own).
    init(saving: Bool = true, fileURL: URL = AssistantChats.fileURL) {
        isSaving = saving
        url = fileURL
        var saved: [Conversation] = []
        if saving {
            switch Self.load(from: fileURL) {
            case .read(let chats): saved = chats
            case .missing: break
            case .unreadable: isUnread = true
            }
        }
        conversations = saved.map(Self.closingUnanswered) + [.new()]
        currentID = conversations.last?.id
        if isUnread { readOnceUnlocked() }
    }

    /// A chat that ends on a question: the app was closed while Milu answered. Said so under it,
    /// so it does not seem still awaited (its lượt is given back, `AIQuota`).
    private static func closingUnanswered(_ chat: Conversation) -> Conversation {
        guard chat.messages.last?.role == .user else { return chat }
        var chat = chat
        // Dated at the question, so the chat keeps its place in Lịch sử (audit round 3,
        // 2026-11-16: dated at the launch, an old chat jumped to the top under "Hôm nay").
        chat.messages.append(ChatMessage(role: .notice, text: "Milu chưa kịp trả lời câu này",
                                         date: chat.messages.last?.date ?? chat.startedAt))
        return chat
    }

    @ObservationIgnored private let isSaving: Bool
    @ObservationIgnored private let url: URL
    /// The saved chats are there but could not be read: Milu was started in the background while
    /// the iPhone was locked, and the file is locked with it. Nothing is written over them until
    /// they are read (audit 2026-11-15: the first save replaced every chat with the new one).
    @ObservationIgnored private var isUnread = false
    @ObservationIgnored private var unlockObserver: NSObjectProtocol?

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

    /// The save waiting for the chat to settle; a newer change replaces it.
    @ObservationIgnored private var pendingSave: Task<Void, Never>?

    /// A moment after the last change, the file written off the main thread: written at once,
    /// on it, sending a question held the screen for over 100ms as its bubble set off (measured
    /// frame by frame, 2026-11-10). A send and its answer come a second apart; each is saved.
    private func save() {
        guard isSaving, !isUnread else { return }
        pendingSave?.cancel()
        pendingSave = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.4))
            guard !Task.isCancelled, let self else { return }
            self.writeNow()
        }
    }

    /// Each chat as last written: only a chat that changed is encoded again (audit round 5,
    /// 2026-11-16: every save encoded every chat kept, up to 100, on the main thread, in the
    /// middle of an answer's words coming in).
    @ObservationIgnored private var encoded: [Conversation.ID: (chat: Conversation, data: Data)] = [:]

    private func writeNow() {
        let kept = Array(history.prefix(Self.limit))
        let encoder = JSONEncoder()
        var written: [Conversation.ID: (chat: Conversation, data: Data)] = [:]
        // The same as encoding the array at once: "[", the chats, "," between them, "]".
        var data = Data("[".utf8)
        for (index, chat) in kept.enumerated() {
            let part: Data
            if let last = encoded[chat.id], last.chat == chat {
                part = last.data
            } else {
                guard let fresh = try? encoder.encode(chat) else { return }
                part = fresh
            }
            if index > 0 { data.append(UInt8(ascii: ",")) }
            data.append(part)
            written[chat.id] = (chat, part)
        }
        data.append(UInt8(ascii: "]"))
        encoded = written
        let url = url
        Task.detached(priority: .utility) {
            do {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                // Readable from the first unlock after the iPhone starts, so a launch in the
                // background (an iCloud push) reads them too; `.complete` kept them from it.
                try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            } catch {
                Logger(subsystem: "com.quyetnguyen.Milu", category: "assistant")
                    .error("Cannot save the chats: \(error)")
            }
        }
    }

    private enum Saved {
        case read([Conversation])
        /// No file: none kept yet, or erased.
        case missing
        /// A file that cannot be opened now (locked with the iPhone).
        case unreadable
    }

    private static func load(from url: URL) -> Saved {
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            log.error("Cannot open the chats: \(error)")
            return .unreadable
        }
        do {
            return .read(try JSONDecoder().decode([Conversation].self, from: data)
                .filter(\.hasQuestions)
                .sorted { $0.startedAt < $1.startedAt })
        } catch {
            log.error("Cannot read the chats: \(error)")
            return .read([])
        }
    }

    /// Read the saved chats once the iPhone is unlocked, before anything is saved over them.
    private func readOnceUnlocked() {
        unlockObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.readUnread() }
        }
    }

    /// The saved chats first, then any started since; a no-op once they are read.
    func readUnread() {
        guard isUnread, case .read(let saved) = Self.load(from: url) else { return }
        isUnread = false
        if let unlockObserver { NotificationCenter.default.removeObserver(unlockObserver) }
        unlockObserver = nil
        let here = Set(conversations.map(\.id))
        conversations = saved.filter { !here.contains($0.id) }.map(Self.closingUnanswered) + conversations
    }

    /// For "Xoá toàn bộ dữ liệu".
    static func deleteSaved() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
