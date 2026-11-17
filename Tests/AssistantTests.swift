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

    // MARK: - Mic tự dừng (người dùng chọn 2026-11-17: 30 giây, im 2 giây, chưa nói 6 giây)

    /// Steps of `SpeechDictation.tickInterval`, each with its loudest level and whether new words
    /// came; the end and when it came.
    private func listen(_ steps: [(level: Float, words: Bool)]) -> (end: DictationAutoStop.End, at: Double)? {
        var stop = DictationAutoStop()
        for (index, step) in steps.enumerated() {
            let time = Double(index + 1) * SpeechDictation.tickInterval
            if let end = stop.step(level: step.level, newWords: step.words, at: time) { return (end, time) }
        }
        return nil
    }

    private func quiet(_ seconds: Double, level: Float = 0.05) -> [(level: Float, words: Bool)] {
        Array(repeating: (level, false), count: Int((seconds * 10).rounded()))
    }

    private func speech(_ seconds: Double) -> [(level: Float, words: Bool)] {
        // Loud syllables with short gaps between, a new word now and then.
        (0..<Int((seconds * 10).rounded())).map { index in index % 4 == 3 ? (0.1, false) : (0.65, index % 3 == 0) }
    }

    @Test func nothingSaidStopsAfterSixSeconds() throws {
        let ended = try #require(listen(quiet(10)))
        #expect(ended.end == .nothingSaid)
        #expect(abs(ended.at - 6) < 0.01)
    }

    /// A pause of a second to think is kept; two seconds ends it.
    @Test func twoQuietSecondsAfterSpeakingEndIt() throws {
        #expect(listen(quiet(1) + speech(2) + quiet(1.5) + speech(1)) == nil)
        let ended = try #require(listen(quiet(1) + speech(2) + quiet(5)))
        #expect(ended.end == .paused)
        // The last loud syllable at 2.9 s (the speech ends on a gap), two seconds later.
        #expect(abs(ended.at - 4.9) < 0.01)
    }

    @Test func thirtySecondsAtMost() throws {
        let ended = try #require(listen(speech(40)))
        #expect(ended.end == .timeUp)
        #expect(abs(ended.at - 30) < 0.01)
    }

    /// A café's steady murmur over the quiet-room level is the room, not voice: speaking over it
    /// still counts, and stopping still ends it.
    @Test func aNoisyRoomIsNotVoice() throws {
        let murmur = Array(repeating: (level: Float(0.4), words: false), count: 30)
        let loud = (0..<20).map { index in (level: Float(index % 4 == 3 ? 0.4 : 0.8), words: index % 3 == 0) }
        let ended = try #require(listen(murmur + loud + murmur + murmur))
        #expect(ended.end == .paused)
        // The last loud syllable at 4.9 s, two seconds of murmur after it.
        #expect(abs(ended.at - 6.9) < 0.01)
    }

    /// Words from the recognizer count as speaking, however quiet the voice.
    @Test func wordsAloneCountAsSpeaking() throws {
        let ended = try #require(listen(quiet(1) + [(0.1, true)] + quiet(5)))
        #expect(ended.end == .paused)
    }

    /// A door or a cough is not speaking: still "nothing said" at six seconds.
    @Test func aSingleNoiseIsNotSpeaking() throws {
        let ended = try #require(listen(quiet(1) + [(0.9, false)] + quiet(8)))
        #expect(ended.end == .nothingSaid)
    }

    // MARK: - Lịch sử trò chuyện

    private func ask(_ chats: AssistantChats, _ question: String) {
        guard let index = chats.conversations.firstIndex(where: { $0.id == chats.currentID }) else { return }
        chats.conversations[index].messages.append(ChatMessage(role: .user, text: question))
    }

    /// A chat that did not change is written as it was, the one that did anew: every chat is in the
    /// file, read back as it was (audit round 5, 2026-11-16).
    @Test func savingWritesEveryChatWhenOneChanges() async throws {
        let folder = URL.temporaryDirectory.appending(path: "chats-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "AssistantChats.json")
        let chats = AssistantChats(saving: true, fileURL: url)
        ask(chats, "Tháng này tiêu bao nhiêu?")
        chats.startNew()
        ask(chats, "Ghi cà phê 35k")
        try await Task.sleep(for: .seconds(1))
        ask(chats, "Và gửi xe 5k")
        try await Task.sleep(for: .seconds(1))
        let written = try JSONDecoder().decode([Conversation].self, from: Data(contentsOf: url))
        #expect(written.count == 2)
        #expect(written.map(\.messages.count).sorted() == [1, 2])
        #expect(written.contains { $0.messages.last?.text == "Và gửi xe 5k" })
        #expect(written.contains { $0.title == "Tháng này tiêu bao nhiêu?" })
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

    // MARK: - Tự xoá sau 30 ngày

    /// A chat whose last message is `daysAgo` old.
    private func chat(_ question: String, daysAgo: Double) -> Conversation {
        let date = Date.now.addingTimeInterval(-daysAgo * 86_400)
        return Conversation(startedAt: date, messages: [ChatMessage(role: .user, text: question, date: date),
                                                        ChatMessage(role: .assistant, text: "Được", date: date)])
    }

    /// Counted from the last message (user request 2026-11-17): 29 days kept, 31 gone.
    @Test func aChatUnusedForThirtyDaysLeavesTheHistory() {
        let chats = AssistantChats(saving: false)
        chats.conversations += [chat("Cũ", daysAgo: 31), chat("Còn", daysAgo: 29)]
        #expect(chats.history.map(\.title) == ["Còn"])
        // Started long ago but spoken in yesterday: still in use.
        var used = chat("Đang dùng", daysAgo: 40)
        used.messages.append(ChatMessage(role: .user, text: "Hỏi tiếp", date: .now.addingTimeInterval(-86_400)))
        chats.conversations.append(used)
        #expect(chats.history.map(\.title) == ["Đang dùng", "Còn"])
    }

    @Test func theOpenChatStaysEvenPastThirtyDays() {
        let chats = AssistantChats(saving: false)
        let old = chat("Cũ", daysAgo: 31)
        chats.conversations.append(old)
        chats.currentID = old.id
        #expect(chats.history.map(\.title) == ["Cũ"])
    }

    /// Not read at launch, and gone from the file at the next save.
    @Test func oldChatsAreDeletedFromTheFile() async throws {
        let folder = URL.temporaryDirectory.appending(path: "chats-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "AssistantChats.json")
        try JSONEncoder().encode([chat("Cũ", daysAgo: 45), chat("Mới", daysAgo: 2)]).write(to: url)

        let chats = AssistantChats(saving: true, fileURL: url)
        #expect(chats.history.map(\.title) == ["Mới"])
        ask(chats, "Ghi cà phê 35k")
        try await Task.sleep(for: .seconds(1))
        let written = try JSONDecoder().decode([Conversation].self, from: Data(contentsOf: url))
        #expect(Set(written.map(\.title)) == ["Mới", "Ghi cà phê 35k"])
    }

    // MARK: - Dòng trong lịch sử

    /// The line under a chat's question: Milu's first line, without the markdown.
    @Test func aHistoryRowShowsMilusLastWordsPlain() {
        var chat = Conversation.new()
        chat.messages = [ChatMessage(role: .user, text: "Tháng này chi gì nhiều?"),
                         ChatMessage(role: .assistant, text: "\n**Ăn uống** nhiều nhất, 135.000đ.\n- Di chuyển 100.000đ")]
        #expect(ChatHistorySheet.lastWords(of: chat) == "Ăn uống nhiều nhất, 135.000đ.")

        chat.messages.append(ChatMessage(role: .user, text: "Còn gì nữa?"))
        chat.messages.append(ChatMessage(role: .assistant, text: "- Cà phê 35.000đ\n- Gửi xe 5.000đ"))
        #expect(ChatHistorySheet.lastWords(of: chat) == "Cà phê 35.000đ")

        chat.messages.append(ChatMessage(role: .notice, text: "Milu chưa kịp trả lời câu này"))
        #expect(ChatHistorySheet.lastWords(of: chat) == "Milu chưa kịp trả lời câu này")

        #expect(ChatHistorySheet.lastWords(of: Conversation(messages: [ChatMessage(role: .user, text: "Chào")])) == nil)
    }
}
