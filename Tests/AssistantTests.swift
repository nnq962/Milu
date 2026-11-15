import Foundation
import Testing
@testable import Milu

/// Trợ lý AI: the chats kept in the history, and the dictation keeping what was said before a pause.
@MainActor
struct AssistantTests {
    // MARK: - Nhập bằng giọng nói

    @Test func aRevisedSentenceIsNotARestart() {
        #expect(!DictationText.restarted(from: "Tháng này tôi tiêu", to: "Tháng này tôi tiêu bao nhiêu"))
        // Revised to fewer words, still opening the same way.
        #expect(!DictationText.restarted(from: "Tháng này tôi tiêu bao nhiêu", to: "Tháng này tôi"))
    }

    @Test func wordsStartedOverAfterAPauseAreARestart() {
        #expect(DictationText.restarted(from: "Tháng này tôi tiêu bao nhiêu", to: "Ghi cà phê"))
    }

    @Test func nothingHeardYetIsNoRestart() {
        #expect(!DictationText.restarted(from: "", to: "Xin chào"))
    }

    // MARK: - Lịch sử trò chuyện

    private func ask(_ chats: AssistantChats, _ question: String) {
        guard let index = chats.conversations.firstIndex(where: { $0.id == chats.currentID }) else { return }
        chats.conversations[index].messages.append(ChatMessage(role: .user, text: question))
    }

    /// Saved chats that cannot be read at launch (locked with the iPhone) are not written over, and
    /// come back, with any chat started since, once they can be read (audit 2026-11-15).
    @Test func lockedChatsAreNotWrittenOverAndComeBack() async throws {
        let folder = URL.temporaryDirectory.appending(path: "chats-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "AssistantChats.json")
        let old = Conversation(messages: [ChatMessage(role: .user, text: "Tháng này tiêu bao nhiêu?")])
        let saved = try JSONEncoder().encode([old])
        try saved.write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: url.path)

        let chats = AssistantChats(saving: true, fileURL: url)
        #expect(chats.history.isEmpty)
        ask(chats, "Ghi cà phê 35k")
        try await Task.sleep(for: .seconds(1))
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
        #expect(try Data(contentsOf: url) == saved)

        chats.readUnread()
        #expect(Set(chats.history.map(\.title)) == ["Tháng này tiêu bao nhiêu?", "Ghi cà phê 35k"])
        try await Task.sleep(for: .seconds(1))
        let written = try JSONDecoder().decode([Conversation].self, from: Data(contentsOf: url))
        #expect(written.count == 2)
    }

    @Test func aNewChatOpensEmptyAndStaysOutOfTheHistory() {
        let chats = AssistantChats(saving: false)
        #expect(chats.conversations.count == 1)
        #expect(chats.history.isEmpty)
    }

    @Test func aChatEntersTheHistoryWithItsFirstQuestion() {
        let chats = AssistantChats(saving: false)
        ask(chats, "Ai đang nợ tôi?")
        #expect(chats.history.map(\.title) == ["Ai đang nợ tôi?"])
    }

    @Test func noSecondEmptyChat() {
        let chats = AssistantChats(saving: false)
        chats.startNew()
        #expect(chats.conversations.count == 1)
        ask(chats, "Ai đang nợ tôi?")
        chats.startNew()
        chats.startNew()
        #expect(chats.conversations.count == 2)
    }

    @Test func deletingTheOpenChatOpensANewOne() {
        let chats = AssistantChats(saving: false)
        ask(chats, "Ai đang nợ tôi?")
        let asked = chats.currentID
        chats.delete(asked!)
        #expect(chats.history.isEmpty)
        #expect(chats.currentID != asked)
        #expect(chats.conversations.count == 1)
    }

    @Test func theHistoryListsTheLatestFirst() {
        let chats = AssistantChats(saving: false)
        ask(chats, "Câu cũ")
        chats.startNew()
        ask(chats, "Câu mới")
        #expect(chats.history.map(\.title) == ["Câu mới", "Câu cũ"])
    }

    @Test func aChatWithACardComesBackFromJSON() throws {
        let transaction = FinanceTransaction(amount: 45_000, category: .food, accountID: UUID(),
                                             date: Date(timeIntervalSince1970: 1_793_000_000))
        var chat = Conversation.new()
        chat.messages = [ChatMessage(role: .user, text: "Ghi ăn trưa 45k"),
                         ChatMessage(role: .assistant, text: "Đã ghi", card: .recorded(transaction, removed: false))]
        let decoded = try JSONDecoder().decode(Conversation.self, from: JSONEncoder().encode(chat))
        #expect(decoded == chat)
    }

    @Test func historySectionsGoTodayYesterdayWeekEarlier() {
        let now = Date(timeIntervalSince1970: 1_793_000_000)
        func chat(daysAgo: Int) -> Conversation {
            var chat = Conversation.new()
            chat.messages = [ChatMessage(role: .user, text: "\(daysAgo)",
                                         date: now.addingTimeInterval(-Double(daysAgo) * 86_400))]
            return chat
        }
        let sections = ChatHistorySheet.sections(of: [chat(daysAgo: 0), chat(daysAgo: 1), chat(daysAgo: 4), chat(daysAgo: 30)],
                                                 now: now)
        #expect(sections.map(\.title) == ["Hôm nay", "Hôm qua", "7 ngày qua", "Trước đó"])
    }
}
