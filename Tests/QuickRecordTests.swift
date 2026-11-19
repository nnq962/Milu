import Foundation
import Testing
@testable import Milu

/// "Thêm bằng AI" from the + (user design 2026-11-17): what the quick sheet shows for an answer,
/// the form it opens for what Milu cannot record yet, the answers it offers to tap, and the one
/// tool it gives the model.
@MainActor
struct QuickRecordTests {
    private func store() -> FinanceStore {
        FinanceStore(accounts: [Account(name: "Ví tiền mặt", type: .cash, balance: 1_000_000)], transactions: [],
                     loans: [], paymentReminders: [], savingsGoals: [], goalTransfers: [], contacts: [])
    }

    private let loan = RecordRefusal.Refused(reason: RecordRefusal.loan.reason, howTo: RecordRefusal.loan.howTo)

    @Test func aSentenceToRecordComesBackAsACard() throws {
        let said = "cà phê 35k"
        guard case .card(let draft, let note) = QuickRecordResult.of(MockAssistant(store: store()).record(said), said: said) else {
            Issue.record("no card")
            return
        }
        #expect(draft.liveRows.first?.transaction.amount == 35_000)
        #expect(draft.isPending)
        #expect(note == nil)
    }

    /// Said plainly, with the transfer form to open, the amount said already in it; the way by
    /// hand left out, the button being it.
    @Test func aTransferOpensItsFormWithTheAmount() {
        let said = "chuyển khoản 500k sang momo"
        #expect(QuickRecordResult.of(MockAssistant(store: store()).record(said), said: said)
            == .refused(QuickRecordForm.transfer(amount: nil).message, form: .transfer(amount: 500_000)))
        // No form for a goal: the way by hand is said.
        let goal = "bỏ 1tr vào hũ du lịch"
        let refused = RecordRefusal.Refused(reason: RecordRefusal.goal.reason, howTo: RecordRefusal.goal.howTo)
        #expect(QuickRecordResult.of(MockAssistant(store: store()).record(goal), said: goal)
            == .refused(RecordRefusal.message([refused]), form: nil))
    }

    /// A new loan on the side the words say; none for a repayment (it goes on a loan already
    /// there) or a goal (which one is the user's to pick).
    @Test func aLoanOpensTheLoanFormOnItsSide() {
        #expect(QuickRecordForm.of([loan], said: "cho Tuấn mượn 500k") == .loan(.lent, amount: 500_000))
        #expect(QuickRecordForm.of([loan], said: "vay anh Hùng 5 triệu") == .loan(.borrowed, amount: 5_000_000))
        #expect(QuickRecordForm.of([loan], said: "trả nợ chị Lan 2 triệu") == nil)
        let goal = RecordRefusal.Refused(reason: RecordRefusal.goal.reason, howTo: RecordRefusal.goal.howTo)
        #expect(QuickRecordForm.of([goal], said: "bỏ 1tr vào hũ du lịch") == nil)
    }

    @Test func aQuestionBackShowsItsChoices() {
        var reply = AssistantReply(text: "Trà sữa 45k thuộc hạng mục nào?", counts: false)
        reply.asksBack = true
        reply.choices = ["Đồ uống", "Ăn vặt"]
        #expect(QuickRecordResult.of(reply, said: "trà sữa 45k")
            == .asking("Trà sữa 45k thuộc hạng mục nào?", choices: ["Đồ uống", "Ăn vặt"]))
        // The tool's own short question, when there is one, over the model's lines.
        reply.text = "Ủa, trà sữa 45k là gì ta? 🤔\n• Bạn chọn trong list nha\n• Nhớ bấm Lưu nha"
        reply.asked = "Milu chưa chắc trà sữa thuộc hạng mục nào. Chọn một mục, hoặc tạo mục mới?"
        #expect(QuickRecordResult.of(reply, said: "trà sữa 45k")
            == .asking("Milu chưa chắc trà sữa thuộc hạng mục nào. Chọn một mục, hoặc tạo mục mới?",
                       choices: ["Đồ uống", "Ăn vặt"]))
        #expect(RemoteAssistant.questions(in: ["status": "needsInfo", "items": [["ask": "50k là chi hay thu?"],
                                                                               ["ask": "50k là chi hay thu?"]]])
            == ["50k là chi hay thu?"])
    }

    /// A question has no place here: the model has no figures to answer from, so its words are not
    /// shown, and the chat is offered instead.
    @Test func noRecordIsSentToTheChat() {
        let reply = AssistantReply(text: "Tháng này bạn chi 2.000.000đ", counts: true)
        #expect(QuickRecordResult.of(reply, said: "tháng này tiêu bao nhiêu") == .notRecord)
    }

    @Test func aCardWithARefusedPartSaysSoOverIt() {
        var reply = AssistantReply(text: "…", action: .draft(TransactionDraft(rows: [])), counts: false)
        reply.refused = [loan]
        guard case .card(_, let note) = QuickRecordResult.of(reply, said: "cà phê 35k, cho Tuấn mượn 200k") else {
            Issue.record("no card")
            return
        }
        #expect(note == RecordRefusal.message([loan]))
    }

    /// The items it suggests, the options, and making the item it proposes: each once, in order.
    @Test func theRecordToolsSuggestionsAreTheAnswersToTap() {
        let result: JSONValue = [
            "status": "needsInfo",
            "items": [
                ["missing": "category", "ask": "…", "suggestions": ["Đồ uống", "Ăn vặt"],
                 "canCreate": ["name": "Trà sữa", "groups": ["Ăn uống"]]],
                ["missing": "kind", "ask": "…", "options": ["Khoản chi", "Khoản thu", "Đồ uống"]],
            ],
        ]
        #expect(RemoteAssistant.choices(in: result) == ["Đồ uống", "Ăn vặt", "Tạo mục “Trà sữa”", "Khoản chi", "Khoản thu"])
        #expect(RemoteAssistant.choices(in: ["status": "draft"]).isEmpty)
    }

    private func card(_ said: String, in store: FinanceStore) throws -> TransactionDraft {
        guard case .card(let draft, _) = QuickRecordResult.of(MockAssistant(store: store).record(said), said: said) else {
            throw CancellationError()
        }
        return draft
    }

    /// Words under the card (user request 2026-11-19): a new card takes its place, a question
    /// keeps it over the question, and anything else leaves it as it was with why.
    @Test func wordsUnderACardChangeItOrLeaveItAsItWas() throws {
        let store = store()
        let draft = try card("cà phê 35k", in: store)
        #expect(QuickRecordFix.of(.card(draft, note: nil), refused: []) == .changed)
        // The same card sent back ("sửa giúp mình cái đó"): nothing was changed on it.
        let again = try card("cà phê 35k", in: store)
        #expect(again.id != draft.id)
        #expect(QuickRecordFix.of(.card(again, note: nil), refused: [], before: draft) == .unchanged(QuickRecordFix.notUnderstood))
        #expect(QuickRecordFix.of(.card(try card("cà phê 40k", in: store), note: nil), refused: [], before: draft) == .changed)
        #expect(QuickRecordFix.of(.asking("Khoản này thuộc mục nào?", choices: []), refused: []) == .asked)
        #expect(QuickRecordFix.of(.notRecord, refused: []) == .unchanged(QuickRecordFix.notUnderstood))
        // Turned into a loan: the card is still there, the way by hand said rather than a form.
        #expect(QuickRecordFix.of(.refused(QuickRecordForm.loan(.lent, amount: nil).message, form: .loan(.lent, amount: 200_000)),
                                  refused: [loan]) == .unchanged(RecordRefusal.message([loan])))
    }

    /// The card a newer one replaced waits no more, so Milu is sent one card to change; the
    /// others in the exchange are as they were.
    @Test func aChangedCardWaitsNoMoreForMilu() throws {
        let store = store()
        let first = try card("cà phê 35k", in: store)
        let other = try card("gửi xe 5k", in: store)
        let history = [ChatMessage(role: .user, text: "cà phê 35k"),
                       ChatMessage(role: .assistant, text: "…", card: .draft(first)),
                       ChatMessage(role: .assistant, text: "…", card: .draft(other))]
        let after = QuickRecordFix.replacing(first.id, in: history)
        #expect(after.compactMap(\.pendingDraft).map(\.id) == [other.id])
        guard case .draft(let replaced) = after[1].card else {
            Issue.record("no card")
            return
        }
        #expect(replaced.state == .replaced)
        #expect(after[0] == history[0])
    }

    /// A row changed in its form is the card Milu is sent, not the one it first made.
    @Test func aCardChangedInItsFormIsTheOneMiluIsSent() throws {
        let store = store()
        let first = try card("cà phê 35k", in: store)
        var row = try #require(first.liveRows.first)
        row.transaction.amount = 40_000
        let history = [ChatMessage(role: .user, text: "cà phê 35k"),
                       ChatMessage(role: .assistant, text: "…", card: .draft(first))]
        let after = QuickRecordFix.updating(first.replacingRow(row), in: history)
        #expect(after[1].pendingDraft?.liveRows.first?.transaction.amount == 40_000)
        let sent = RemoteAssistant.history(after, store: store).map { "\($0)" }.joined()
        #expect(sent.contains("40.000"))
        #expect(!sent.contains("35.000"))
    }

    /// The record tool alone: the quick sheet never answers a question, so never takes a lượt.
    @Test func theQuickSheetGivesTheRecordToolAlone() {
        #expect(AssistantTools.specs(only: [RecordTransaction().name]).map(\.name) == [RecordTransaction().name])
        #expect(AssistantTools.specs(only: nil).count == AssistantTools.specs.count)
        #expect(AssistantTools.specs.count > 1)
    }
}
