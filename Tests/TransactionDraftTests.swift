import Foundation
import Testing
@testable import Milu

/// Recording with Milu, clear before anything is saved (user choice 2026-11-17): a card waits for
/// "Lưu", what is missing is asked, what is wrong or not Milu's is refused.
@MainActor
struct TransactionDraftTests {
    private let cash = Account(name: "Ví tiền mặt", type: .cash, balance: 1_000_000)
    private let vcb = Account(name: "Vietcombank", type: .bank, balance: 5_000_000)
    private let defaults = UserDefaults(suiteName: "transaction-draft-tests")!

    private func store(_ accounts: [Account]? = nil, transactions: [FinanceTransaction] = []) -> FinanceStore {
        FinanceStore(accounts: accounts ?? [cash, vcb], transactions: transactions, loans: [], paymentReminders: [],
                     savingsGoals: [], goalTransfers: [], contacts: [])
    }

    private func record(_ arguments: JSONValue, in store: FinanceStore, words: [String] = [],
                        open: [TransactionDraft] = []) -> ToolOutput {
        RecordTransaction(turn: RecordTurn(userWords: words, open: open, defaults: defaults)).run(arguments, in: store)
    }

    private func card(_ output: ToolOutput) -> TransactionDraft? {
        if case .draft(let draft) = output.action { return draft }
        return nil
    }

    private func text(_ value: JSONValue?) -> String {
        value.flatMap { try? JSONEncoder().encode($0) }.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    private func lunch(_ amount: Double = 60_000) -> JSONValue {
        ["kind": "expense", "amount": .number(amount), "category": "Ăn trưa"]
    }

    // MARK: Lưu

    @Test func nothingIsSavedBeforeLưuAndSavingTwiceAddsOnce() throws {
        let store = store()
        let draft = try #require(card(record(["transactions": [lunch()]], in: store)))
        #expect(store.transactions.isEmpty)
        let saved = DraftSaver.save(draft, in: store, defaults: defaults)
        #expect(saved.state == .saved)
        #expect(store.transactions.count == 1)
        var again = draft
        again.state = .pending
        _ = DraftSaver.save(again, in: store, defaults: defaults)
        #expect(store.transactions.count == 1)
    }

    /// "Lưu" checks again: an account archived while the card waited saves nothing, and says why.
    @Test func lưuChecksAgainAndSavesNothingOnAProblem() throws {
        let store = store()
        let output = record(["transactions": [lunch(), ["kind": "expense", "amount": 35_000, "category": "Cà phê",
                                                        "account": "Vietcombank"]]], in: store)
        let draft = try #require(card(output))
        store.archive(vcb)
        let saved = DraftSaver.save(draft, in: store, defaults: defaults)
        #expect(saved.state == .pending)
        #expect(saved.problem != nil)
        #expect(saved.rows.contains { $0.problem != nil })
        #expect(store.transactions.isEmpty)
    }

    // MARK: Hỏi lại

    @Test func aMissingAmountIsAsked() {
        let store = store()
        let output = record(["transactions": [["kind": "expense", "category": "Ăn trưa"]]], in: store)
        #expect(output.result["status"] == "needsInfo")
        #expect(text(output.result["items"]).contains("amount"))
        #expect(output.action == nil)
    }

    /// The model's number against the user's words: one never said is asked about.
    @Test func anAmountNotSaidIsAsked() {
        let store = store()
        let made = record(["transactions": [lunch(600_000)]], in: store, words: ["ghi ăn trưa 60k"])
        #expect(made.result["status"] == "needsInfo")
        let right = record(["transactions": [lunch(60_000)]], in: store, words: ["ghi ăn trưa 60k"])
        #expect(card(right) != nil)
        let misread = record(["transactions": [["kind": "expense", "amount": 12_000_000, "amount_said": "1tr2",
                                                "category": "Học phí"]]], in: store)
        #expect(misread.result["status"] == "needsInfo")
        #expect(text(misread.result["items"]).contains("1.200.000"))
    }

    @Test func moneyIsReadAsSaid() {
        let cases: [(String, Double)] = [
            ("60k", 60_000), ("60 nghìn", 60_000), ("60 ngàn", 60_000), ("1tr2", 1_200_000),
            ("1 triệu 2", 1_200_000), ("1 triệu 200", 1_200_000), ("1,5tr", 1_500_000), ("2 củ", 2_000_000),
            ("1 củ rưỡi", 1_500_000), ("2 trăm rưỡi", 250_000), ("1 tỷ", 1_000_000_000), ("60.000", 60_000),
            ("60000đ", 60_000), ("2k5", 2_500), ("35", 35_000), ("ăn trưa 45k nhé.", 45_000),
            ("1 triệu 2 trăm nghìn", 1_200_000), ("2 ly cà phê 35k", 35_000),
        ]
        for (said, amount) in cases {
            #expect(SaidAmount.parse(said) == amount, "\(said)")
        }
        #expect(SaidAmount.all(in: "cà phê 35k 2 ly").contains(35_000))
        #expect(!SaidAmount.all(in: "cà phê 35k 2 ly").contains(35_200))
        #expect(SaidAmount.parse("ăn trưa") == nil)
    }

    @Test func aCategoryOfTheOtherKindAsksTheKind() {
        let store = store()
        let output = record(["transactions": [["kind": "expense", "amount": 25_000_000, "category": "Lương chính"]]], in: store)
        #expect(output.result["status"] == "needsInfo")
        #expect(text(output.result["items"]).contains("kind"))
    }

    // MARK: Từ chối

    @Test func transfersLoansAndGoalsAreRefusedWithHowTo() {
        let store = store()
        for kind in ["transfer", "loan", "goal"] {
            let output = record(["transactions": [["kind": .string(kind), "amount": 2_000_000, "note": "x"]]], in: store)
            #expect(output.result["status"] == "rejected", "\(kind)")
            #expect(text(output.result["items"]).contains("howTo"), "\(kind)")
        }
        // Said with the rest of a sentence: the rest goes on the card, the refusal is told.
        let mixed = record(["transactions": [lunch(), ["kind": "transfer", "amount": 2_000_000, "note": "Rút tiền"]]],
                           in: store)
        #expect(card(mixed)?.rows.count == 1)
        #expect(mixed.result["rejected"] != nil)
        #expect(store.transactions.isEmpty)
    }

    @Test func anAmountOutOfRangeIsRefused() {
        let store = store()
        let none = record(["transactions": [lunch(0)]], in: store)
        #expect(none.result["status"] == "rejected")
        let huge = record(["transactions": [lunch(MiluAmountField.maxAmount + 1)]], in: store)
        #expect(huge.result["status"] == "rejected")
    }

    // MARK: Nhiều khoản

    @Test func severalItemsShareOneCardAndOneQuestionHoldsThemAll() {
        let store = store()
        let three = record(["transactions": [lunch(), ["kind": "expense", "amount": 35_000, "category": "Cà phê"],
                                             ["kind": "expense", "amount": 5_000, "category": "Gửi xe"]]], in: store)
        #expect(card(three)?.rows.count == 3)
        let oneMissing = record(["transactions": [lunch(), ["kind": "expense", "category": "Cà phê"]]], in: store)
        #expect(oneMissing.result["status"] == "needsInfo")
        #expect(oneMissing.action == nil)
    }

    /// The tool as it once was, one item at the top, still read.
    @Test func oneItemAtTheTopIsStillRead() {
        let store = store()
        #expect(card(record(lunch(), in: store))?.rows.count == 1)
    }

    // MARK: Hạng mục mới

    @Test func aNewItemIsMadeOnlyOnLưu() throws {
        let store = store()
        let output = record(["transactions": [["kind": "expense", "amount": 1_200_000, "note": "học tiếng Nhật",
                                               "new_category": ["name": "Học tiếng Nhật", "group": "Học tập"]]]], in: store)
        let draft = try #require(card(output))
        #expect(draft.rows.first?.newItem?.groupID == "education")
        #expect(store.item(named: "Học tiếng Nhật", inGroup: "education") == nil)
        let saved = DraftSaver.save(draft, in: store, defaults: defaults)
        let item = try #require(store.item(named: "Học tiếng Nhật", inGroup: "education"))
        #expect(saved.state == .saved)
        #expect(store.transactions.first?.categoryID == item.id)
    }

    @Test func aNewItemNeedsAGroupTheUserHas() {
        let store = store()
        let output = record(["transactions": [["kind": "expense", "amount": 1_200_000,
                                               "new_category": ["name": "Học tiếng Nhật", "group": "Ngoại ngữ"]]]], in: store)
        #expect(output.result["status"] == "needsInfo")
        #expect(text(output.result["items"]).contains("group"))
    }

    // MARK: Tài khoản

    @Test func aLockedOrArchivedAccountIsAsked() {
        var locked = cash
        locked.isLocked = true
        let store = store([locked, vcb])
        let onLocked = record(["transactions": [["kind": "expense", "amount": 60_000, "category": "Ăn trưa",
                                                 "account": "Ví tiền mặt"]]], in: store)
        #expect(onLocked.result["status"] == "needsInfo")
        store.archive(vcb)
        let onArchived = record(["transactions": [["kind": "expense", "amount": 60_000, "category": "Ăn trưa",
                                                   "account": "Vietcombank"]]], in: store)
        #expect(onArchived.result["status"] == "needsInfo")
        #expect(text(onArchived.result["items"]).contains("lưu trữ"))
    }

    // MARK: Trùng

    @Test func aTwinSavedThatDayIsTold() throws {
        let twin = FinanceTransaction(amount: 60_000, categoryID: "food.lunch", kind: .expense, accountID: cash.id, date: .now)
        let store = store(transactions: [twin])
        let draft = try #require(card(record(["transactions": [lunch()]], in: store)))
        #expect(draft.rows.first?.warning?.contains("Hôm nay đã có") == true)
    }

    // MARK: Sửa thẻ

    @Test func aCardIsReplacedByItsRef() throws {
        let store = store()
        let first = try #require(card(record(["transactions": [lunch()]], in: store)))
        let second = try #require(card(record(["transactions": [lunch(50_000)], "replaces": .string(first.ref)], in: store,
                                              words: ["à không, 50k thôi"], open: [first])))
        #expect(second.replacing == first.id)
        let stale = record(["transactions": [lunch(50_000)], "replaces": "zzzz"], in: store, open: [first])
        #expect(stale.result["status"] == "rejected")
    }

    /// The amounts of the card being replaced count as said ("đổi khoản cà phê thành 40k").
    @Test func aReplacedCardsAmountsCountAsSaid() throws {
        let store = store()
        let first = try #require(card(record(["transactions": [lunch(), ["kind": "expense", "amount": 35_000, "category": "Cà phê"]]],
                                             in: store)))
        let second = record(["transactions": [lunch(), ["kind": "expense", "amount": 40_000, "category": "Cà phê"]],
                             "replaces": .string(first.ref)], in: store, words: ["đổi cà phê thành 40k"], open: [first])
        #expect(card(second)?.rows.count == 2)
    }

    // MARK: Chat

    @Test func typedShortcutsAreOnlyWholeShortAnswers() {
        #expect(DraftShortcut.match("ok") == .save)
        #expect(DraftShortcut.match("Lưu đi!") == .save)
        #expect(DraftShortcut.match("Đúng rồi") == .save)
        #expect(DraftShortcut.match("huỷ") == .cancel)
        #expect(DraftShortcut.match("ok nhưng đổi sang Momo") == nil)
        #expect(DraftShortcut.match("ăn trưa 60k") == nil)
    }

    /// The model is told of a card under its words, and of one still waiting from further back.
    @Test func theHistoryTellsTheModelOfCards() throws {
        let store = store()
        let draft = try #require(card(record(["transactions": [lunch()]], in: store)))
        var messages = [ChatMessage(role: .user, text: "ghi ăn trưa 60k"),
                        ChatMessage(role: .assistant, text: "Bạn kiểm tra rồi bấm Lưu nhé", card: .draft(draft))]
        let told = RemoteAssistant.history(messages, store: store)
        #expect(told.count == 2)
        #expect(String(describing: told.last).contains("#\(draft.ref)"))
        for index in 0..<8 { messages.append(ChatMessage(role: index.isMultiple(of: 2) ? .user : .assistant, text: "câu \(index)")) }
        let later = RemoteAssistant.history(messages, store: store)
        #expect(String(describing: later.first).contains("#\(draft.ref)"))
    }

    @Test func anAnswerNeverSaysACardWasSaved() {
        let draft = TransactionDraft(rows: [])
        #expect(RemoteAssistant.answerText("Mình đã ghi khoản này rồi nhé", actions: [.draft(draft)]) == RemoteAssistant.draftReady)
        #expect(RemoteAssistant.answerText("Bạn kiểm tra rồi bấm Lưu nhé", actions: [.draft(draft)]) == "Bạn kiểm tra rồi bấm Lưu nhé")
        #expect(RemoteAssistant.answerText("Mình đã ghi xong", actions: []) == "Mình đã ghi xong")
    }

    @Test func theGuesserReadsWholeWords() {
        #expect(MockAssistant.category(for: "xem phim") == .entertainment)
        #expect(MockAssistant.category(for: "tra anh tuan") != .food)
        #expect(MockAssistant.category(for: "gui xe") == .transport)
    }

    @Test func theKeywordAssistantMakesACardToo() {
        let store = store()
        let reply = MockAssistant(store: store).reply(to: "ghi ăn trưa 60k")
        if case .draft(let draft) = reply.action {
            #expect(draft.rows.first?.transaction.amount == 60_000)
        } else {
            Issue.record("expected a card")
        }
        #expect(store.transactions.isEmpty)
        #expect(MockAssistant(store: store).reply(to: "ghi rút 2 triệu ở VCB").action == nil)
    }

    /// A card is kept with the chats; one a newer build wrote that this one cannot read is dropped
    /// alone, never the chat with it.
    @Test func aCardComesBackFromJSONAndAnUnknownOneIsDroppedAlone() throws {
        let store = store()
        let draft = try #require(card(record(["transactions": [lunch()]], in: store)))
        let message = ChatMessage(role: .assistant, text: "Bấm Lưu nhé", card: .draft(draft))
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: JSONEncoder().encode(message))
        #expect(decoded == message)
        let unknown = #"{"id":"\#(UUID().uuidString)","role":"assistant","text":"Xin chào","card":{"later":{"x":1}},"date":0}"#
        let read = try JSONDecoder().decode(ChatMessage.self, from: Data(unknown.utf8))
        #expect(read.text == "Xin chào")
        #expect(read.card == nil)
    }
}
