import Foundation
import Testing
@testable import Milu

/// Milu's answer shown as it is written (user choice 2026-11-20, "Trả lời dần từng chữ"): the
/// server's events read, the words shown so far, and which answers may come so.
@MainActor
struct StreamingAnswerTests {
    // MARK: - The server's events

    @Test func wordsAddUpEventByEvent() throws {
        var events = MiluAPI.ChatEvents()
        guard case .words(let first) = try events.read(#"data: {"delta": "Tháng này "}"#) else { Issue.record(); return }
        #expect(first == "Tháng này ")
        guard case .words(let second) = try events.read(#"data: {"delta": "bạn chi"}"#) else { Issue.record(); return }
        #expect(second == "Tháng này bạn chi")
    }

    @Test func theLastEventIsTheTurnWhole() throws {
        var events = MiluAPI.ChatEvents()
        _ = try events.read(#"data: {"delta": "Xin chào"}"#)
        let line = #"data: {"message": {"content": "Xin chào nè", "toolCalls": [{"id": "c0", "name": "get_accounts", "arguments": {}}]}, "ms": 812}"#
        guard case .reply(let reply) = try events.read(line) else { Issue.record(); return }
        #expect(reply.content == "Xin chào nè")
        #expect(reply.toolCalls.map(\.name) == ["get_accounts"])
    }

    @Test func blankLinesAndOtherLinesAreSkipped() throws {
        var events = MiluAPI.ChatEvents()
        #expect(try events.read("") == nil)
        #expect(try events.read(": keep-alive") == nil)
        #expect(try events.read(#"data: {"delta": ""}"#) == nil)
    }

    @Test func aFailureOnTheWayIsThrown() {
        var events = MiluAPI.ChatEvents()
        #expect(throws: MiluAPI.Failure.unreachable) {
            try events.read(#"data: {"error": "upstream unavailable", "status": 503}"#)
        }
    }

    // MARK: - The words shown so far

    @Test func aWordHalfInWaits() {
        #expect(RemoteAssistant.shownWhileWriting("Tháng này bạn ch") == "Tháng này bạn")
        #expect(RemoteAssistant.shownWhileWriting("Tháng") == "")
    }

    @Test func listItemsShowAsTheAppSetsThem() {
        let shown = RemoteAssistant.shownWhileWriting("Chi nhiều nhất:\n* Ăn uống  **2.100.000đ**\n- Cà ")
        #expect(shown == "Chi nhiều nhất:\n• Ăn uống **2.100.000đ**\n• Cà")
    }

    @Test func noOpenerOnceItsWordIsIn() {
        #expect(RemoteAssistant.shownWhileWriting("Ủa") == "")
        #expect(RemoteAssistant.shownWhileWriting("Ủa, tháng này bạn ") == "Tháng này bạn")
    }

    @Test func noCardCodeIsShown() {
        #expect(RemoteAssistant.shownWhileWriting("Khoản #ab12 đã ") == "Khoản đã")
    }

    @Test func nothingYetShowsNothing() {
        // Not "Mình chưa trả lời được câu này", the answer of an empty reply.
        #expect(RemoteAssistant.shownWhileWriting("   ") == "")
    }

    // MARK: - Which answers may come so

    @Test func anAnswerFromTheToolsStreams() {
        #expect(RemoteAssistant.streams(toolsRun: ["summarize_transactions"], actions: [], refused: [],
                                        asksBack: false, cardWaiting: false))
    }

    @Test func theFirstRoundDoesNotStream() {
        // Choosing tools: the server checks the words once whole.
        #expect(!RemoteAssistant.streams(toolsRun: [], actions: [], refused: [], asksBack: false, cardWaiting: false))
    }

    @Test func overACardOrAQuestionBackNothingStreams() {
        #expect(!RemoteAssistant.streams(toolsRun: ["list_transactions"], actions: [], refused: [],
                                         asksBack: false, cardWaiting: true))
        #expect(!RemoteAssistant.streams(toolsRun: ["record_transaction"], actions: [], refused: [],
                                         asksBack: true, cardWaiting: false))
    }

    // MARK: - The limit per phone

    @Test func thePhoneKeepsOneRandomID() {
        let id = MiluAPI.deviceID
        #expect(UUID(uuidString: id) != nil)
        #expect(MiluAPI.deviceID == id)
        #expect(UserDefaults.standard.string(forKey: "server.deviceID") == id)
        // Its own key, never one that follows the user through iCloud.
        #expect(!CloudSettings.isSynced("server.deviceID"))
    }

    @Test func tooFastIsToldApartFromBusy() {
        #expect(AssistantServiceError.tooFast.errorDescription != AssistantServiceError.server("đang có nhiều người hỏi cùng lúc").errorDescription)
    }

    // MARK: - Pacing

    @Test func wordsArePacedTheLastOnesKept() async throws {
        var shown: [String] = []
        let pacer = WordsPacer(every: 0.05) { shown.append($0) }
        pacer.take("Một ")
        pacer.take("Một hai ")
        pacer.take("Một hai ba ")
        #expect(shown == ["Một "])
        try await Task.sleep(for: .seconds(0.12))
        #expect(shown == ["Một ", "Một hai ba "])
    }

    @Test func takenBackAtOnce() {
        var shown: [String] = []
        let pacer = WordsPacer(every: 1) { shown.append($0) }
        pacer.take("Một ")
        pacer.take("Một hai ")
        pacer.take("")
        #expect(shown == ["Một ", ""])
    }
}
