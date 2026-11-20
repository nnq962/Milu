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

    /// The model's number against the user's words: one never said, or read otherwise, goes on the
    /// card with a warning over "Lưu", not asked again (user choice 2026-11-17).
    @Test func anAmountNotSaidIsWarnedOn() {
        let store = store()
        let made = record(["transactions": [lunch(600_000)]], in: store, words: ["ghi ăn trưa 60k"])
        #expect(card(made)?.rows.first?.warning?.contains("600.000") == true)
        #expect(text(made.result).contains("warning"))
        let right = record(["transactions": [lunch(60_000)]], in: store, words: ["ghi ăn trưa 60k"])
        #expect(card(right)?.rows.first?.warning == nil)
        let misread = record(["transactions": [["kind": "expense", "amount": 12_000_000, "amount_said": "1tr2",
                                                "category": "Ăn trưa"]]], in: store)
        #expect(card(misread)?.rows.first?.warning?.contains("1.200.000") == true)
        // "nửa củ" read as 50.000đ and "10 củ" as 1.000.000đ (server, 2026-11-17).
        let half = record(["transactions": [["kind": "expense", "amount": 50_000, "amount_said": "nửa củ",
                                             "category": "Ăn trưa"]]], in: store, words: ["tiền ăn trưa nửa củ"])
        #expect(card(half)?.rows.first?.warning?.contains("500.000") == true)
        let ten = record(["transactions": [["kind": "income", "amount": 1_000_000, "amount_said": "10 củ",
                                            "category": "Lương chính"]]], in: store, words: ["nhận lương 10 củ"])
        #expect(card(ten)?.rows.first?.warning?.contains("10.000.000") == true)
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

    /// Said by voice, the numbers come in words (user report 2026-11-17, iPhone: every amount of
    /// "ăn sáng hết ba mươi nghìn… tối ăn cơm hết năm mươi nghìn" asked again).
    @Test func moneyIsReadInWords() {
        let cases: [(String, Double)] = [
            ("ba mươi nghìn", 30_000), ("năm nghìn", 5_000), ("bốn mươi nghìn", 40_000),
            ("bảy mươi nghìn", 70_000), ("năm mươi nghìn", 50_000), ("mười lăm nghìn", 15_000),
            ("hai mươi mốt nghìn", 21_000), ("hai mươi tư nghìn", 24_000), ("ba mươi lăm ngàn", 35_000),
            ("một trăm năm mươi nghìn", 150_000), ("một trăm linh năm nghìn", 105_000),
            ("hai trăm mười nghìn", 210_000), ("hai trăm nghìn", 200_000), ("hai trăm rưỡi", 250_000),
            ("năm trăm", 500_000), ("một triệu hai", 1_200_000), ("một triệu hai trăm nghìn", 1_200_000),
            ("hai triệu", 2_000_000), ("một củ rưỡi", 1_500_000), ("ba mươi", 30_000),
            ("mười nghìn", 10_000), ("chín mươi chín nghìn", 99_000),
        ]
        for (said, amount) in cases {
            #expect(SaidAmount.parse(said) == amount, "\(said)")
        }
        let sentence = "Sáng nay tôi ăn sáng hết ba mươi nghìn uống trà đá hết năm nghìn xong rồi buổi trưa tôi ăn "
            + "trưa hết bốn mươi nghìn buổi chiều ăn vặt hết bảy mươi nghìn tối ăn cơm hết năm mươi nghìn"
        #expect(SaidAmount.all(in: sentence) == [30_000, 5_000, 40_000, 70_000, 50_000])
        // Words that are no amount stay words.
        #expect(SaidAmount.parse("năm nay ăn tết ở nhà") == nil)
        #expect(SaidAmount.parse("mua quà cho ba mẹ") == nil)
        #expect(SaidAmount.parse("hai ly cà phê") == nil)
    }

    /// The case of the report: amounts in words, an earlier sum in the chat, nothing asked again.
    @Test func amountsInWordsMakeACard() {
        let store = store()
        let words = ["Cho tôi chuyển 500.000 từ tài khoản Vietcombank sang ví điện tử Momo nhé",
                     "sáng nay ăn sáng hết ba mươi nghìn tối ăn cơm hết năm mươi nghìn"]
        let made = record(["transactions": [lunch(30_000), lunch(50_000)]], in: store, words: words)
        #expect(card(made)?.rows.allSatisfy { $0.warning == nil } == true)
    }

    /// Money slang (user question 2026-11-17): "cá", "cành" are thousands, "xị", "lít" hundreds of
    /// thousands, "củ" millions; "lít xăng" is fuel.
    @Test func moneySlangIsRead() {
        let cases: [(String, Double)] = [
            ("200 cá", 200_000), ("200 cành", 200_000), ("35 cành", 35_000), ("1 củ", 1_000_000),
            ("10 củ", 10_000_000), ("3 xị", 300_000), ("2 lít", 200_000), ("2 lít rưỡi", 250_000),
            ("nửa củ", 500_000), ("nửa triệu", 500_000), ("hai lít", 200_000), ("đổ 2 lít xăng 50k", 50_000),
        ]
        for (said, amount) in cases {
            #expect(SaidAmount.parse(said) == amount, "\(said)")
        }
    }

    /// Only a group known: its items to pick, and the item the note names to make (user report
    /// 2026-11-17: "học tiếng Nhật" offered Học phí, Sách, Khoá học, and nothing new).
    @Test func aGroupAloneOffersMakingTheNotesItem() {
        let store = store()
        let japanese = record(["transactions": [["kind": "expense", "amount": 1_200_000, "category": "Học tập",
                                                 "note": "học tiếng Nhật"]]], in: store)
        #expect(japanese.result["status"] == "needsInfo")
        let items = text(japanese.result["items"])
        #expect(items.contains("Học tiếng Nhật"))
        #expect(items.contains("canCreate"))
        #expect(items.contains("Học phí"))
        // The offer says the group, "trong nhóm" (the model said "dưới nhóm", 2026-11-18).
        let snack = record(["transactions": [["kind": "expense", "amount": 20_000, "category": "Ăn uống",
                                              "note": "ăn vặt"]]], in: store)
        #expect(text(snack.result["items"]).contains("trong nhóm “Ăn uống” nè? Hoặc tạo mục mới “Ăn vặt” trong nhóm này luôn?"))
        // "Chi khác" holds "Khác" alone: asked, "Trà đá" offered, nothing put on "Khác" unsaid.
        let tea = record(["transactions": [["kind": "expense", "amount": 5_000, "category": "Chi khác",
                                            "note": "Uống trà đá"]]], in: store)
        #expect(tea.result["status"] == "needsInfo")
        #expect(text(tea.result["items"]).contains("Trà đá"))
        #expect(card(tea) == nil)
    }

    /// Asked back in the chat, the items there are and the one Milu would make, each on its line:
    /// "user làm sao mà nhớ được họ đang có những hạng mục nào" (user, 2026-11-18).
    @Test func aQuestionBackListsTheItemsToPickAndTheNewOne() throws {
        let store = store()
        let snack = record(["transactions": [["kind": "expense", "amount": 20_000, "category": "Ăn uống",
                                              "note": "ăn vặt buổi chiều"]]], in: store)
        let said = try #require(RemoteAssistant.choiceQuestion(in: snack.result, variant: 0))
        #expect(said == """
            Khoản “ăn vặt buổi chiều” 20.000đ này xếp vô mục nào trong nhóm “Ăn uống” nè? 🤔
            • Chọn mục có sẵn: Ăn sáng, Ăn trưa, Ăn tối, Cà phê, Trà sữa, Đi chợ
            • Hoặc tạo mục mới “Ăn vặt” trong nhóm “Ăn uống” luôn cho tiện ✨

            Bạn chọn xong nhắn Milu một tiếng nha 😉
            """)
        // Asked again, said another way.
        #expect(RemoteAssistant.choiceQuestion(in: snack.result, variant: 1)?.hasSuffix("Chốt cái nào thì nhắn Milu nè 🚀") == true)
        // Two asked the same in one sentence: one question, the list once (user 2026-11-18).
        let two = record(["transactions": [
            ["kind": "expense", "amount": 5_000, "category": "Ăn uống", "note": "Trà đá"],
            ["kind": "expense", "amount": 70_000, "category": "Ăn uống", "note": "ăn vặt"],
        ]], in: store)
        let together = try #require(RemoteAssistant.choiceQuestion(in: two.result, variant: 1))
        #expect(together == """
            Có 2 khoản Milu chưa biết xếp vô mục nào nè: **Trà đá 5.000đ** và **Ăn vặt 70.000đ** 👀
            • Chọn mục có sẵn: Ăn sáng, Ăn trưa, Ăn tối, Cà phê, Trà sữa, Đi chợ
            • Hoặc tạo mục mới “Trà đá”, “Ăn vặt” trong nhóm “Ăn uống” luôn cho tiện ✨

            Bạn nhắn Milu từng khoản nha, kiểu: “trà đá tạo mới, ăn vặt vào Ăn sáng” 😉
            """)
        #expect(!together.contains("thẻ"))
        // Lists not the same: still one question, one list, without the group they all share
        // (iPhone 2026-11-18: said twice word for word, "Trà sữa (Ăn uống), Ăn trưa (Ăn uống)…").
        let unlike = record(["transactions": [
            ["kind": "expense", "amount": 5_000, "category": "Trà đá"],
            ["kind": "expense", "amount": 70_000, "category": "Ăn vặt"],
        ]], in: store)
        let one = try #require(RemoteAssistant.choiceQuestion(in: unlike.result, variant: 1))
        #expect(one.hasPrefix("Có 2 khoản Milu chưa biết xếp vô mục nào nè: **Trà đá 5.000đ** và **Ăn vặt 70.000đ** 👀\n• Chọn mục có sẵn: "))
        #expect(one.components(separatedBy: "Chọn mục có sẵn").count == 2)
        #expect(one.contains("• Hoặc tạo mục mới “Trà đá”, “Ăn vặt” luôn cho tiện ✨"))
        #expect(!one.contains("(Ăn uống)"))
        #expect(RemoteAssistant.withoutSharedGroup(["Trà sữa (Ăn uống)", "Cà phê (Ăn uống)"]) == ["Trà sữa", "Cà phê"])
        #expect(RemoteAssistant.withoutSharedGroup(["Trà sữa (Ăn uống)", "Taxi (Di chuyển)"]) == ["Trà sữa (Ăn uống)", "Taxi (Di chuyển)"])
        // Nothing to pick: the model's words stand.
        let noAmount = record(["transactions": [["kind": "expense", "category": "Ăn trưa"]]], in: store)
        #expect(noAmount.result["status"] == "needsInfo")
        #expect(RemoteAssistant.choiceQuestion(in: noAmount.result) == nil)
    }

    @Test func aNewItemIsNamedFromTheNote() {
        let items = store().pickableItems(.expense) + store().groups(.expense)
        #expect(CategoryResolver.newName(from: "ăn vặt buổi chiều", besides: items) == "Ăn vặt")
        #expect(CategoryResolver.newName(from: "sáng nay ăn bánh mì", besides: items) == "Ăn bánh mì")
        #expect(CategoryResolver.newName(from: "Uống trà đá", besides: items) == "Trà đá")
        #expect(CategoryResolver.newName(from: "mua sữa rửa mặt", besides: items) == "Sữa rửa mặt")
        #expect(CategoryResolver.newName(from: "học tiếng Nhật", besides: items) == "Học tiếng Nhật")
        #expect(CategoryResolver.newName(from: "Cà phê", besides: items) == nil)
        #expect(CategoryResolver.newName(from: "", besides: items) == nil)
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
        // A card of the chat no longer waiting: not made again.
        let stale = RecordTransaction(turn: RecordTurn(open: [], seen: [first.ref], defaults: defaults))
            .run(["transactions": [lunch(50_000)], "replaces": .string(first.ref)], in: store)
        #expect(stale.result["status"] == "rejected")
        #expect(!text(stale.result["howTo"]).contains("list_transactions"))
        // A code of no card at all, made up by the model: a new card (eval 2026-11-18).
        let madeUp = try #require(card(record(["transactions": [lunch(55_000)], "replaces": "zzzz"], in: store,
                                              words: ["ăn trưa 60k à nhầm 55k"], open: [])))
        #expect(madeUp.replacing == nil)
    }

    /// Made again with the account Milu chose sent back by name, the user not naming it: still
    /// "Milu tự chọn" (live test 2026-11-18).
    @Test func aCardMadeAgainKeepsTheAccountMiluChose() throws {
        let store = store()
        let first = try #require(card(record(["transactions": [lunch()]], in: store)))
        #expect(first.rows[0].accountChosenByApp)
        let account = try #require(store.account(id: first.rows[0].transaction.accountID)?.name)
        let again: JSONValue = ["kind": "expense", "amount": 50_000, "category": "Ăn trưa", "account": .string(account)]
        let second = try #require(card(record(["transactions": [again], "replaces": .string(first.ref)], in: store,
                                              words: ["à không, 50k thôi"], open: [first])))
        #expect(second.rows[0].accountChosenByApp)
        let named = try #require(card(record(["transactions": [again], "replaces": .string(first.ref)], in: store,
                                             words: ["ghi vào \(account) nhé"], open: [first])))
        #expect(!named.rows[0].accountChosenByApp)
    }

    /// "Tạo mục Ăn vặt đi" said to the offer, the model sending the group again: the item made.
    @Test func sayingMakeItMakesTheOfferedItem() throws {
        let store = store()
        let snack: JSONValue = ["transactions": [["kind": "expense", "amount": 20_000, "category": "Ăn uống", "note": "ăn vặt"]]]
        let made = try #require(card(record(snack, in: store, words: ["ăn vặt 20k", "tạo mục Ăn vặt đi"])))
        #expect(made.rows[0].newItem?.name == "Ăn vặt")
        // An apple ("táo") is not "tạo".
        let apple: JSONValue = ["transactions": [["kind": "expense", "amount": 30_000, "category": "Ăn uống", "note": "mua táo"]]]
        #expect(record(apple, in: store, words: ["mua táo 30k"]).result["status"] == "needsInfo")
        // "Theo đề xuất đi" takes the offer too (iPhone 2026-11-18).
        let proposal = try #require(card(record(snack, in: store, words: ["ăn vặt 20k", "ok theo đề xuất đi"])))
        #expect(proposal.rows[0].newItem?.name == "Ăn vặt")
        #expect(CategoryResolver.saysMake("Tạo mới nha"))
        #expect(CategoryResolver.saysMake("theo đề xuất."))
        #expect(!CategoryResolver.saysMake("mua táo"))
        #expect(!CategoryResolver.saysMake("vào Ăn sáng"))
    }

    /// A card changed by words keeps the new items it was to make (iPhone 2026-11-18: "sửa khoản ăn
    /// tối thêm ghi chú được giảm giá" asked again for Trà đá and Ăn vặt, the edit lost).
    @Test func aCardChangedKeepsItsNewItems() throws {
        let store = store()
        let said: JSONValue = ["transactions": [
            ["kind": "expense", "amount": 30_000, "category": "Ăn sáng"],
            ["kind": "expense", "amount": 5_000, "category": "Ăn uống", "note": "uống trà đá"],
            ["kind": "expense", "amount": 70_000, "category": "Ăn uống", "note": "ăn vặt buổi chiều"],
            ["kind": "expense", "amount": 50_000, "category": "Ăn tối"],
        ]]
        let first = try #require(card(record(said, in: store, words: ["…", "ok tạo theo đề xuất đi"])))
        #expect(first.rows.compactMap(\.newItem?.name) == ["Trà đá", "Ăn vặt"])

        // Told to the model as new items, as it asks for one.
        let told = RemoteAssistant.cardExchange(.draft(first), store: store)
        let arguments = text(told.first?.toolCalls?.first?.arguments)
        #expect(arguments.contains("new_category"))
        #expect(arguments.contains("Trà đá") && arguments.contains("Ăn uống"))

        // Sent back by name alone, in category or in the note, with the change asked for.
        let changed: JSONValue = ["replaces": .string(first.ref), "transactions": [
            ["kind": "expense", "amount": 30_000, "category": "Ăn sáng"],
            ["kind": "expense", "amount": 5_000, "category": "Trà đá"],
            ["kind": "expense", "amount": 70_000, "category": "Ăn uống", "note": "Ăn vặt"],
            ["kind": "expense", "amount": 50_000, "category": "Ăn tối", "note": "được giảm giá"],
        ]]
        let words = ["sửa cho tôi khoản ăn tối thêm ghi chú được giảm giá"]
        let second = try #require(card(record(changed, in: store, words: words, open: [first])))
        #expect(second.replacing == first.id)
        #expect(second.rows.map { $0.newItem?.name } == [nil, "Trà đá", "Ăn vặt", nil])
        #expect(second.rows[3].transaction.note == "được giảm giá")
        // Sent back as their group alone, no note: the one of the same amount.
        let byGroup: JSONValue = ["replaces": .string(first.ref), "transactions": [
            ["kind": "expense", "amount": 5_000, "category": "Ăn uống"],
            ["kind": "expense", "amount": 70_000, "category": "Ăn uống"],
            ["kind": "expense", "amount": 50_000, "category": "Ăn tối", "note": "được giảm giá"],
        ]]
        let third = try #require(card(record(byGroup, in: store, words: words, open: [first])))
        #expect(third.rows.map { $0.newItem?.name } == ["Trà đá", "Ăn vặt", nil])
        // A sum the card does not have, or another item named: not taken for one.
        let otherSum: JSONValue = ["replaces": .string(first.ref), "transactions": [["kind": "expense", "amount": 6_000, "category": "Ăn uống"]]]
        #expect(record(otherSum, in: store, words: words, open: [first]).result["status"] == "needsInfo")
        let named: JSONValue = ["replaces": .string(first.ref), "transactions": [["kind": "expense", "amount": 5_000, "category": "Cà phê"]]]
        #expect(card(record(named, in: store, words: words, open: [first]))?.rows.first?.newItem == nil)
        // As new_category, with no group: the card's group.
        let asNew: JSONValue = ["replaces": .string(first.ref), "transactions": [
            ["kind": "expense", "amount": 5_000, "new_category": ["name": "trà đá"]],
        ]]
        #expect(card(record(asNew, in: store, words: words, open: [first]))?.rows.first?.newItem?.groupID == "food")
        // Not changing that card, "Trà đá" is still asked about, and kept to it then.
        let elsewhere: JSONValue = ["transactions": [["kind": "expense", "amount": 5_000, "category": "Trà đá"]]]
        #expect(record(elsewhere, in: store, words: words).result["status"] == "needsInfo")
    }

    /// A bank or wallet the user named and the model left out: theirs, or asked about, never the
    /// last account used (live test 2026-11-18).
    @Test func aWalletSaidIsNotLeftOut() throws {
        let momo = Account(name: "MoMo", type: .eWallet, balance: 100_000, institutionID: "momo")
        let store = store([cash, vcb, momo])
        let lunch: JSONValue = ["transactions": [["kind": "expense", "amount": 50_000, "category": "Ăn trưa"]]]
        let zalo = record(lunch, in: store, words: ["ăn trưa 50k bằng ví ZaloPay"])
        #expect(zalo.result["status"] == "needsInfo")
        #expect(text(zalo.result["items"]).contains("ZaloPay"))
        let paid = try #require(card(record(lunch, in: store, words: ["ăn trưa 50k qua momo nha"])))
        #expect(paid.rows[0].transaction.accountID == momo.id)
        #expect(!paid.rows[0].accountChosenByApp)
        // "năm à" is no bank: "nam a" only after "bằng", "qua"…
        #expect(DraftBuilder.institutionSaid(in: "tiền học năm à") == nil)
        #expect(DraftBuilder.institutionSaid(in: "cà phê 30k quẹt thẻ VCB")?.id == "vietcombank")
    }

    /// "nhận lương 25 triệu" put on the group "Lương": its own item, Lương chính, not a question.
    @Test func aGroupsOwnItemIsTaken() throws {
        let store = store()
        let pay = try #require(card(record(["transactions": [["kind": "income", "amount": 25_000_000, "category": "Lương",
                                                               "note": "Nhận lương"]]], in: store)))
        #expect(store.category(id: pay.rows[0].transaction.categoryID)?.name == "Lương chính")
        let snack = record(["transactions": [["kind": "expense", "amount": 20_000, "category": "Ăn uống", "note": "ăn vặt"]]],
                           in: store)
        #expect(snack.result["status"] == "needsInfo")
    }

    /// "Tôi quên mất list rồi, cho xem lại": the code alone shows the waiting card again, as it is;
    /// a card no longer waiting is pointed to list_transactions (user report 2026-11-18).
    @Test func aWaitingCardIsShownAgainByItsRefAlone() throws {
        let store = store()
        let first = try #require(card(record(["transactions": [lunch(), ["kind": "expense", "amount": 35_000, "category": "Cà phê"]]],
                                             in: store)))
        let again = try #require(card(record(["replaces": .string(first.ref)], in: store,
                                             words: ["tôi quên mất list rồi, cho xem lại"], open: [first])))
        #expect(again.replacing == first.id)
        #expect(again.rows.map(\.transaction.amount) == first.rows.map(\.transaction.amount))
        #expect(store.transactions.isEmpty)
        let gone = record(["replaces": .string(first.ref)], in: store, open: [])
        #expect(gone.result["status"] == "rejected")
        #expect(text(gone.result["say"]).contains("list_transactions"))
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

    /// Words over a card of another item or sum than the card's: the app's own line (the model
    /// copied its prompt's "Trà sữa 45.000đ" over a Taxi card, eval 2026-11-18).
    @Test func wordsOverACardKeepToTheCard() throws {
        let store = store()
        let draft = try #require(card(record(["transactions": [["kind": "expense", "amount": 45_000,
                                                                "category": "Taxi, xe ôm"]]], in: store)))
        let items = RemoteAssistant.itemNames(store)
        let onCard = RemoteAssistant.cardItems([.draft(draft)], store: store)
        #expect(RemoteAssistant.answerText("Trà sữa **45.000đ** Milu soạn sẵn rồi nè 📝", actions: [.draft(draft)],
                                           items: items, cardItems: onCard) == RemoteAssistant.draftReady)
        #expect(RemoteAssistant.answerText("Grab **50.000đ** soạn xong nè 📝", actions: [.draft(draft)],
                                           items: items, cardItems: onCard) == RemoteAssistant.draftReady)
        #expect(RemoteAssistant.answerText("Cuốc xe **45.000đ** soạn xong nè 📝", actions: [.draft(draft)],
                                           items: items, cardItems: onCard) == "Cuốc xe **45.000đ** soạn xong nè 📝")
    }

    /// Over a delete waiting for its yes, words that read as done give way to the app's own line.
    @Test func wordsOverADeleteDoNotSayItIsDone() {
        let coffee = FinanceTransaction(title: "Cà phê", amount: 55_000, categoryID: "food.coffee", kind: .expense,
                                        accountID: cash.id, date: .now)
        let delete = AssistantReply.Action.confirmDelete(coffee)
        #expect(RemoteAssistant.answerText("Xong rồi nè 🗑️ Bạn bấm xác nhận trên thẻ nha", actions: [delete])
            == RemoteAssistant.emptyAnswer(delete))
        #expect(RemoteAssistant.answerText("Gỡ được khoản cà phê **55.000đ** hôm nay rồi nha ☕", actions: [delete])
            == RemoteAssistant.emptyAnswer(delete))
    }

    /// "Thẻ" is no word for the user (user 2026-11-18): over a card, words saying it give way to
    /// the app's own line; a credit card or an account's name is no card.
    @Test func wordsOverACardDoNotSayThẻ() throws {
        let store = store()
        let draft = try #require(card(record(["transactions": [lunch()]], in: store)))
        #expect(RemoteAssistant.answerText("Soạn thẻ xong rồi nè 📝", actions: [.draft(draft)], accounts: ["Thẻ VPBank Visa"])
            == RemoteAssistant.draftReady)
        #expect(RemoteAssistant.answerText("Ghi vào Thẻ VPBank Visa rồi nè 📝", actions: [.draft(draft)],
                                           accounts: ["Thẻ VPBank Visa"]) == "Ghi vào Thẻ VPBank Visa rồi nè 📝")
        #expect(RemoteAssistant.answerText("Quẹt thẻ tín dụng hả, okela 📝", actions: [.draft(draft)])
            == "Quẹt thẻ tín dụng hả, okela 📝")
        #expect(!RemoteAssistant.cardUnchanged.contains("hẻ"))
    }

    @Test func typedShortcutsAreOnlyWholeShortAnswers() {
        #expect(DraftShortcut.match("ok") == .save)
        #expect(DraftShortcut.match("Lưu đi!") == .save)
        #expect(DraftShortcut.match("Đúng rồi") == .save)
        #expect(DraftShortcut.match("huỷ") == .cancel)
        #expect(DraftShortcut.match("ok nhưng đổi sang Momo") == nil)
        #expect(DraftShortcut.match("ăn trưa 60k") == nil)
        // A few words more that still only say yes or no (eval 2026-11-18).
        #expect(DraftShortcut.match("đúng rồi lưu đi") == .save)
        #expect(DraftShortcut.match("ok lưu cả 2 khoản nha") == .save)
        #expect(DraftShortcut.match("chốt luôn nha Milu") == .save)
        #expect(DraftShortcut.match("thôi không lưu nữa") == .cancel)
        #expect(DraftShortcut.match("đừng lưu nhé") == .cancel)
        #expect(DraftShortcut.match("thôi bỏ đi") == .cancel)
        #expect(DraftShortcut.match("bỏ khoản gửi xe đi") == nil)
        #expect(DraftShortcut.match("chưa lưu à") == nil)
        #expect(DraftShortcut.match("khoan đã, đổi sang momo") == nil)
    }

    /// The app's words about a card, sent back by the model as a row's note, are not the note
    /// (iPhone 2026-11-19: "[Thẻ #9644 · đang chờ người dùng bấm Lưu…]" under "Ăn sáng").
    @Test func theAppsWordsAboutACardAreNoNote() {
        #expect(DraftBuilder.note("[Thẻ #9644 · đang chờ người dùng bấm Lưu, chưa ghi; đổi gì thì gọi record_transaction với replaces]") == "")
        #expect(DraftBuilder.note("Uống với bạn") == "Uống với bạn")
        #expect(DraftBuilder.note(nil) == "")
    }

    /// The model is told of a card as the call that made it, before Milu's words, never as words
    /// of Milu's own (it copied them); and of one still waiting from further back, first.
    @Test func theHistoryTellsTheModelOfCards() throws {
        let store = store()
        let draft = try #require(card(record(["transactions": [lunch()]], in: store)))
        var messages = [ChatMessage(role: .user, text: "ghi ăn trưa 60k"),
                        ChatMessage(role: .assistant, text: "Bạn kiểm tra rồi bấm Lưu nhé", card: .draft(draft))]
        let told = RemoteAssistant.history(messages, store: store)
        #expect(told.map(\.role) == ["user", "assistant", "tool", "assistant"])
        #expect(told[1].toolCalls?.first?.name == "record_transaction")
        #expect(told[2].content.contains("[Thẻ #\(draft.ref) · đang chờ"))
        #expect(told[3].content == "Bạn kiểm tra rồi bấm Lưu nhé")
        #expect(!told.contains { $0.role == "assistant" && $0.content.contains("[Thẻ") })
        for index in 0..<8 { messages.append(ChatMessage(role: index.isMultiple(of: 2) ? .user : .assistant, text: "câu \(index)")) }
        let later = RemoteAssistant.history(messages, store: store)
        #expect(later.first?.toolCalls?.first?.name == "record_transaction")
        #expect(later.dropFirst().first?.content.contains("#\(draft.ref)") == true)
    }

    @Test func anAnswerNeverSaysACardWasSaved() {
        let draft = TransactionDraft(rows: [])
        #expect(RemoteAssistant.answerText("Mình đã ghi khoản này rồi nhé", actions: [.draft(draft)]) == RemoteAssistant.draftReady)
        #expect(RemoteAssistant.answerText("Bạn kiểm tra rồi bấm Lưu nhé", actions: [.draft(draft)]) == "Bạn kiểm tra rồi bấm Lưu nhé")
        #expect(RemoteAssistant.answerText("Mình đã ghi xong", actions: []) == "Mình đã ghi xong")
        // Asking back, no card made: a card said is the tool's own question (2026-11-18).
        let asked = "Khoản “ăn vặt” này xếp vô mục nào trong nhóm “Ăn uống” nè? Hoặc tạo mục mới “Ăn vặt” trong nhóm này luôn?"
        #expect(RemoteAssistant.answerText("Trà sữa **20.000đ** Milu soạn sẵn rồi nè 📝 Bạn chọn mục nha", actions: [],
                                           asked: asked) == asked)
        #expect(RemoteAssistant.answerText("Chưa soạn thẻ, chưa ghi gì. Khoản này thuộc mục nào?", actions: [], asked: asked) == asked)
        #expect(RemoteAssistant.answerText("Khoản này bao nhiêu tiền nè?", actions: [], asked: "Khoản này bao nhiêu tiền?")
            == "Khoản này bao nhiêu tiền nè?")
        // No "Ủa" or "Ê" first (user choice 2026-11-18), whatever the model says.
        #expect(RemoteAssistant.withoutOpener("Ủa, có 1 giao dịch cà phê hôm nay nè") == "Có 1 giao dịch cà phê hôm nay nè")
        #expect(RemoteAssistant.withoutOpener("Ê bạn ơi, tháng này chi hơi nhiều") == "Bạn ơi, tháng này chi hơi nhiều")
        #expect(RemoteAssistant.withoutOpener("Ủa **2.300.000đ** luôn hả") == "**2.300.000đ** luôn hả")
        #expect(RemoteAssistant.withoutOpener("Ừ, Milu soạn xong rồi") == "Ừ, Milu soạn xong rồi")
        // A card waiting, none new, "changed" said: the card did not change.
        #expect(RemoteAssistant.answerText("Thẻ **#adb0** đã được cập nhật **50.000đ** rồi nè", actions: [], cardWaiting: true)
            == RemoteAssistant.cardUnchanged)
        #expect(RemoteAssistant.answerText("Tháng này bạn chi **2.000.000đ**", actions: [], cardWaiting: true)
            == "Tháng này bạn chi **2.000.000đ**")
        // The card's code is the model's alone.
        #expect(RemoteAssistant.answerText("Milu soạn xong **#adb0** rồi nè, bấm Lưu nha", actions: [.draft(draft)])
            == "Milu soạn xong rồi nè, bấm Lưu nha")
        // Over a card, one sentence: not the lines saying again what the card shows.
        #expect(RemoteAssistant.answerText("Milu soạn xong rồi nè 🫠\n• Bạn xem lại 3 khoản chi nha.\n• Bấm **Lưu** nha!",
                                           actions: [.draft(draft)]) == "Milu soạn xong rồi nè 🫠")
        #expect(RemoteAssistant.answerText("Milu soạn lại rồi nè 🫠. Bạn kiểm tra kỹ rồi bấm **Lưu** nha",
                                           actions: [.draft(draft)]) == "Milu soạn lại rồi nè 🫠.")
        #expect(RemoteAssistant.answerText("Milu soạn xong trà sữa **45.000đ** rồi nha 🧋 Bạn kiểm tra rồi bấm **Lưu** nha 😏",
                                           actions: [.draft(draft)]) == "Milu soạn xong trà sữa **45.000đ** rồi nha 🧋")
        #expect(RemoteAssistant.answerText("Ủa **2.000.000đ** luôn 😳. **Bạn** bấm Lưu nha", actions: [.draft(draft)])
            == "**2.000.000đ** luôn 😳.")
        #expect(RemoteAssistant.answerText("Cà phê **35.000đ** soạn xong. Còn rút tiền thì bạn ghi tay nha",
                                           actions: [.draft(draft)], refused: true)
            == "Cà phê **35.000đ** soạn xong. Còn rút tiền thì bạn ghi tay nha")
    }

    /// The way by hand for what Milu refused is always said: added when the model, asking
    /// something back, left it out.
    @Test func aRefusalAlwaysSaysTheWayByHand() {
        let store = store()
        let result = record(["transactions": [["kind": "transfer", "amount": 2_000_000, "note": "Rút tiền"]]], in: store).result
        let refused = RemoteAssistant.refused(in: result, adding: [])
        #expect(refused == [.init(reason: RecordRefusal.transfer.reason, howTo: RecordRefusal.transfer.howTo)])
        let howTos = refused.compactMap(\.howTo)
        let left = RemoteAssistant.withHowTo("Cái này là chuyển tiền, bạn làm thủ công nha 💸", howTos)
        #expect(left.contains("Thêm giao dịch → Chuyển khoản"))
        let said = "Bạn ghi tay ở nút + → Thêm giao dịch → Chuyển khoản nha"
        #expect(RemoteAssistant.withHowTo(said, howTos) == said)
        // Refused beside a card made of the rest: said too.
        let mixed = record(["transactions": [lunch(), ["kind": "goal", "amount": 1_000_000, "note": "Hũ"]]], in: store).result
        #expect(RemoteAssistant.refused(in: mixed, adding: []).map(\.reason) == [RecordRefusal.goal.reason])
    }

    /// What Milu cannot record is said by the app, plainly, never in the model's words (user report
    /// 2026-11-17: "Ủa, Milu bị từ chối rồi nè 😭"): that the feature is not there yet, then each
    /// way by hand on its own line.
    @Test func aRefusalIsSaidPlainlyByTheApp() {
        let store = store()
        let transfer = record(["transactions": [["kind": "transfer", "amount": 500_000, "amount_said": "500k"]]], in: store).result
        let answer = RemoteAssistant.refusedAnswer(RemoteAssistant.refused(in: transfer, adding: []), actions: [])
        #expect(answer == """
            Milu chưa ghi được chuyển tiền giữa các tài khoản (chuyển khoản, rút tiền, nạp ví): tính năng này chưa có. \
            Bạn ghi tay giúp Milu nhé:
            • Nút + → Thêm giao dịch → Chuyển khoản.
            """)
        // A loan has two ways, each a line; the same refusal twice is said once.
        let loans = record(["transactions": [["kind": "loan", "amount": 500_000], ["kind": "loan", "amount": 200_000]]],
                           in: store).result
        let loanAnswer = RemoteAssistant.refusedAnswer(RemoteAssistant.refused(in: loans, adding: []), actions: [])
        #expect(loanAnswer.components(separatedBy: "tính năng này chưa có").count == 2)
        #expect(loanAnswer.components(separatedBy: "\n• ").count == 3)
        // Beside a card of the rest: the refusal, then that the card waits for "Lưu", right over it.
        let mixed = record(["transactions": [lunch(), ["kind": "goal", "amount": 1_000_000, "note": "Hũ"]]], in: store)
        let mixedAnswer = RemoteAssistant.refusedAnswer(RemoteAssistant.refused(in: mixed.result, adding: []),
                                                         actions: [mixed.action!])
        #expect(mixedAnswer.hasPrefix(RecordRefusal.goal.reason))
        #expect(mixedAnswer.hasSuffix(RemoteAssistant.restReady))
        #expect(!mixedAnswer.contains("từ chối"))
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
