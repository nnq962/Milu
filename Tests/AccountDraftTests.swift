import Foundation
import Testing
@testable import Milu

/// Adding an account with Milu (user request 2026-11-20): a card waits for "Lưu", and what is
/// missing or unsure is asked: the kind, the bank or wallet, the balance, a name already taken.
@MainActor
struct AccountDraftTests {
    private let cash = Account(name: "Ví tiền mặt", type: .cash, balance: 2_350_000)
    private let techcombank = Account(name: "Techcombank", type: .bank, balance: 18_250_000, institutionID: "techcombank")
    private let momo = Account(name: "MoMo", type: .eWallet, balance: 1_120_000, institutionID: "momo")

    private func store() -> FinanceStore {
        FinanceStore(accounts: [cash, techcombank, momo], transactions: [], loans: [], paymentReminders: [],
                     savingsGoals: [], goalTransfers: [], contacts: [])
    }

    private func add(_ accounts: [JSONValue], replaces: String? = nil, in store: FinanceStore, words: [String] = [],
                     open: [AccountDraft] = []) -> ToolOutput {
        var arguments: [String: JSONValue] = ["accounts": .array(accounts)]
        if let replaces { arguments["replaces"] = .string(replaces) }
        let turn = RecordTurn(userWords: words, openAccounts: open, seenAccounts: Set(open.map(\.ref)))
        return AddAccount(turn: turn).run(.object(arguments), in: store)
    }

    private func card(_ output: ToolOutput) -> AccountDraft? {
        if case .accountDraft(let draft) = output.action { return draft }
        return nil
    }

    private func asked(_ output: ToolOutput) -> [String] {
        guard output.result["status"] == "needsInfo", case .array(let items)? = output.result["items"] else { return [] }
        return items.compactMap { $0["missing"]?.string }
    }

    // MARK: Lưu

    @Test func nothingIsAddedBeforeLưuAndSavingTwiceAddsOnce() throws {
        let store = store()
        let output = add([["type": "bank", "institution": "Vietcombank", "balance": 5_000_000]], in: store,
                         words: ["thêm tài khoản Vietcombank 5 triệu"])
        let draft = try #require(card(output))
        let row = try #require(draft.rows.first)
        #expect(row.account.name == "Vietcombank")
        #expect(row.account.type == .bank)
        #expect(row.account.institutionID == "vietcombank")
        #expect(row.account.balance == 5_000_000)
        #expect(row.warning == nil)
        #expect(store.accounts.count == 3)

        let saved = AccountDraftSaver.save(draft, in: store)
        #expect(saved.state == .saved)
        #expect(store.accounts.count == 4)
        #expect(store.account(id: row.id)?.name == "Vietcombank")
        var again = draft
        again.state = .pending
        _ = AccountDraftSaver.save(again, in: store)
        #expect(store.accounts.count == 4)
    }

    /// A name taken while the card waited: nothing added, and why on the row.
    @Test func lưuChecksAgainAndAddsNothingOnAProblem() throws {
        let store = store()
        let draft = try #require(card(add([["type": "bank", "institution": "vcb", "balance": 1_000_000],
                                           ["type": "ewallet", "institution": "zalopay", "balance": 200_000]], in: store)))
        store.add(Account(name: "ZaloPay", type: .eWallet, balance: 0, institutionID: "zalopay"))
        let saved = AccountDraftSaver.save(draft, in: store)
        #expect(saved.state == .pending)
        #expect(saved.problem != nil)
        #expect(saved.rows.last?.problem?.contains("ZaloPay") == true)
        #expect(!store.accounts.contains { $0.name == "Vietcombank" })
    }

    // MARK: Ngân hàng và ví

    @Test func aBankIsFoundByItsShortNameOrAlias() throws {
        let store = store()
        for said in ["vcb", "Vietcombank", "ngân hàng Vietcombank", "tài khoản VCB"] {
            let draft = try #require(card(add([["type": "bank", "institution": .string(said), "balance": 0]], in: store)))
            #expect(draft.rows.first?.account.institutionID == "vietcombank", "\(said)")
            #expect(draft.rows.first?.account.name == "Vietcombank", "\(said)")
        }
        // Named by the model in `name` alone.
        let named = try #require(card(add([["type": "ewallet", "name": "ví zalopay", "balance": 100_000]], in: store)))
        #expect(named.rows.first?.account.institutionID == "zalopay")
        #expect(named.rows.first?.account.name == "ZaloPay")
    }

    @Test func aNameOfItsOwnIsKeptWithTheBankInIt() throws {
        let draft = try #require(card(add([["type": "bank", "name": "Techcombank lương", "balance": 3_000_000]], in: store())))
        #expect(draft.rows.first?.account.institutionID == "techcombank")
        #expect(draft.rows.first?.account.name == "Techcombank lương")
    }

    /// "Ví điện tử Vietcombank": the catalogue's kind wins, and the card says so.
    @Test func theWrongKindIsPutRightAndSaid() throws {
        let draft = try #require(card(add([["type": "ewallet", "institution": "Vietcombank", "balance": 1_000_000]], in: store())))
        let row = try #require(draft.rows.first)
        #expect(row.account.type == .bank)
        #expect(row.notice?.contains("ngân hàng") == true)
        let wallet = try #require(card(add([["type": "cash", "institution": "ZaloPay", "balance": 50_000]], in: store())))
        #expect(wallet.rows.first?.account.type == .eWallet)
    }

    @Test func anUnknownOrUnsureBankIsAsked() {
        let store = store()
        let unknown = add([["type": "bank", "institution": "ABC Bank Xyz", "balance": 1_000_000]], in: store)
        #expect(asked(unknown) == ["institution"])
        #expect(AccountDraftBuilder.question(in: unknown.result)?.contains("không thấy") == true)
        // "moca": Moca, and GrabPay by Moca.
        let unsure = add([["type": "ewallet", "institution": "moca", "balance": 1_000_000]], in: store)
        #expect(asked(unsure) == ["institution"])
        var options: [String] = []
        if case .array(let items)? = unsure.result["items"] { options = items.first?["options"]?.strings ?? [] }
        #expect(options.contains("Moca") && options.contains("GrabPay"))
        #expect(unknown.action == nil && unsure.action == nil)
    }

    @Test func noNameNoKindAsksTheKind() {
        let store = store()
        let nothing = add([["type": "unclear", "balance": 5_000_000]], in: store)
        #expect(asked(nothing) == ["type"])
        let ownName = add([["name": "Quỹ đen", "balance": 2_000_000]], in: store)
        #expect(asked(ownName) == ["type"])
        #expect(AccountDraftBuilder.question(in: ownName.result)?.contains("Quỹ đen") == true)
        let bank = add([["type": "bank", "balance": 5_000_000]], in: store)
        #expect(asked(bank) == ["institution"])
        #expect(AccountDraftBuilder.question(in: bank.result)?.contains("ngân hàng nào") == true)
    }

    @Test func cashTakesTheFormsName() throws {
        let plain = try #require(card(add([["type": "cash", "balance": 500_000]], in: store())))
        #expect(plain.rows.first?.account.name == "Tiền mặt")
        #expect(plain.rows.first?.account.institutionID == nil)
        let named = try #require(card(add([["type": "cash", "name": "Heo đất", "balance": 500_000]], in: store())))
        #expect(named.rows.first?.account.name == "Heo đất")
    }

    /// The kind the model left out, read from the user's words when the sentence has one account
    /// (live test 2026-11-20: "thêm tiền mặt 200k" was asked its kind).
    @Test func theKindSaidIsReadFromTheUsersWords() throws {
        let store = store()
        let cash = try #require(card(add([["type": "unclear", "balance": 200_000]], in: store, words: ["thêm tiền mặt 200k"])))
        #expect(cash.rows.first?.account.type == .cash)
        #expect(cash.rows.first?.account.name == "Tiền mặt")
        let asName = try #require(card(add([["name": "tiền mặt", "balance": 200_000]], in: store)))
        #expect(asName.rows.first?.account.name == "Tiền mặt")
        let piggy = try #require(card(add([["name": "Heo đất", "balance": 1_000_000]], in: store,
                                          words: ["thêm tài khoản tiền mặt tên Heo đất, 1 triệu"])))
        #expect(piggy.rows.first?.account.name == "Heo đất")
        #expect(piggy.rows.first?.account.type == .cash)
        let bank = add([["institution": "Zorro", "balance": 1_000_000]], in: store, words: ["thêm tài khoản ngân hàng Zorro 1 triệu"])
        #expect(AccountDraftBuilder.question(in: bank.result)?.contains("không thấy ngân hàng") == true)
    }

    /// Asked back, the call and its question go with the answer, and to the model next turn.
    @Test func aQuestionBackIsToldToTheModelAsItsCall() throws {
        let store = store()
        let arguments: JSONValue = ["accounts": [["type": "bank", "institution": "Techcombank", "balance": 5_000_000]]]
        let output = AddAccount().run(arguments, in: store)
        let asked = ChatMessage.AskedCall(name: "add_account", arguments: arguments, result: output.result)
        let messages = [ChatMessage(role: .user, text: "thêm tài khoản Techcombank 5 triệu"),
                        ChatMessage(role: .assistant, text: "Bạn có tài khoản “Techcombank” rồi nè", askedCall: asked)]
        let read = try JSONDecoder().decode([ChatMessage].self, from: JSONEncoder().encode(messages))
        #expect(read.last?.askedCall == asked)
        let told = RemoteAssistant.history(read, store: store)
        #expect(told.map(\.role) == ["user", "assistant", "tool", "assistant"])
        #expect(told[1].toolCalls?.first?.name == "add_account")
        #expect(told[2].content.contains("duplicate"))
    }

    /// "thêm tài khoản mới" to the question about a name taken: the app makes the card itself.
    @Test func aYesToANameTakenIsAnsweredByTheApp() throws {
        let store = store()
        let arguments: JSONValue = ["accounts": [["type": "bank", "institution": "Techcombank", "balance": 5_000_000]]]
        let output = AddAccount().run(arguments, in: store)
        let asked = ChatMessage.AskedCall(name: "add_account", arguments: arguments, result: output.result)
        let history = [ChatMessage(role: .user, text: "thêm tài khoản Techcombank 5 triệu"),
                       ChatMessage(role: .assistant, text: "…", askedCall: asked)]
        let reply = try #require(AccountDraftBuilder.answer("thêm tài khoản mới", to: asked, history: history, store: store))
        guard case .accountDraft(let draft)? = reply.actions.first else { Issue.record("no card"); return }
        #expect(draft.rows.first?.account.name == "Techcombank 2")
        #expect(!reply.counts)
        #expect(AccountDraftBuilder.answer("thôi khỏi", to: asked, history: history, store: store) == nil)
        #expect(AccountDraftBuilder.answer("đặt tên Techcombank lương", to: asked, history: history, store: store) == nil)
    }

    /// Not supported: said as coming in an update, once (user request 2026-11-20).
    @Test func notYetIsSaidAsComingLater() {
        let said = RemoteAssistant.withComingLater("Milu chưa hỗ trợ xoá tài khoản nha 🫠")
        #expect(said.hasSuffix(RemoteAssistant.comingLater))
        #expect(RemoteAssistant.withComingLater(said) == said)
        #expect(RemoteAssistant.withComingLater("Milu chưa hỗ trợ việc này, sẽ cập nhật sau nha") == "Milu chưa hỗ trợ việc này, sẽ cập nhật sau nha")
        #expect(RemoteAssistant.withComingLater("Tháng này bạn chi 2 triệu") == "Tháng này bạn chi 2 triệu")
        #expect(!AddAccount.isNeeded(for: "chuyển 500k từ VCB sang MoMo", history: []))
        #expect(!AddAccount.isNeeded(for: "mua áo 500k bằng thẻ tín dụng", history: []))
        #expect(AddAccount.isNeeded(for: "tạo ví zalopay", history: []))
    }

    @Test func soạnThẻIsNotSaid() {
        #expect(RemoteAssistant.answerText("Mình có thể giúp bạn soạn thẻ thêm tài khoản nha!", actions: [])
                == "Mình có thể giúp bạn soạn sẵn thêm tài khoản nha!")
    }

    // MARK: Số dư

    @Test func aBalanceNotSaidIsAskedAndZeroIsOne() throws {
        let store = store()
        let missing = add([["type": "ewallet", "institution": "ZaloPay"]], in: store, words: ["thêm ví zalopay"])
        #expect(asked(missing) == ["balance"])
        #expect(AccountDraftBuilder.question(in: missing.result)?.contains("bao nhiêu tiền") == true)
        let zero = try #require(card(add([["type": "ewallet", "institution": "ZaloPay", "balance": 0]], in: store,
                                          words: ["thêm ví zalopay", "0đ"])))
        #expect(zero.rows.first?.account.balance == 0)
        #expect(zero.rows.first?.warning == nil)
        // Said in words, read by the app.
        let said = try #require(card(add([["type": "ewallet", "institution": "ZaloPay", "balance_said": "2 củ"]], in: store)))
        #expect(said.rows.first?.account.balance == 2_000_000)
    }

    @Test func aBalanceReadOtherwiseIsWarned() throws {
        let draft = try #require(card(add([["type": "bank", "institution": "BIDV", "balance": 500_000, "balance_said": "5 triệu"]],
                                          in: store(), words: ["thêm BIDV 5 triệu"])))
        #expect(draft.rows.first?.warning?.contains("5 triệu") == true)
    }

    /// No credit card kind: a bank account with what is owed below zero (user choice 2026-11-20).
    @Test func aCreditCardIsABankAccountBelowZero() throws {
        let draft = try #require(card(add([["type": "bank", "institution": "VPBank", "balance": 5_000_000, "negative": true]],
                                          in: store(), words: ["thêm thẻ tín dụng VPBank đang nợ 5 triệu"])))
        let row = try #require(draft.rows.first)
        #expect(row.account.type == .bank)
        #expect(row.account.balance == -5_000_000)
        #expect(row.notice?.contains("đang nợ") == true)
        // Said "thẻ tín dụng", the model leaving `negative` out: below zero all the same.
        let unsaid = try #require(card(add([["type": "bank", "institution": "VPBank", "balance": 5_000_000]],
                                           in: store(), words: ["thêm thẻ tín dụng VPBank nợ 5 triệu"])))
        #expect(unsaid.rows.first?.account.balance == -5_000_000)
    }

    // MARK: Trùng tên

    @Test func aNameTakenIsAskedFirstThenNumbered() throws {
        let store = store()
        let first = add([["type": "bank", "institution": "Techcombank", "balance": 5_000_000]], in: store,
                        words: ["thêm tài khoản Techcombank 5 triệu"])
        #expect(asked(first) == ["duplicate"])
        let question = try #require(AccountDraftBuilder.question(in: first.result))
        #expect(question.contains("18.250.000đ"))
        #expect(question.contains("bút chì"))
        #expect(first.action == nil)

        let yes = try #require(card(add([["type": "bank", "institution": "Techcombank", "balance": 5_000_000,
                                          "same_name_ok": true]], in: store,
                                        words: ["thêm tài khoản Techcombank 5 triệu", "thêm tài khoản mới"])))
        #expect(yes.rows.first?.account.name == "Techcombank 2")
        let saidNew = try #require(card(add([["type": "bank", "institution": "Techcombank", "name": "Mới", "balance": 5_000_000,
                                              "same_name_ok": true]], in: store)))
        #expect(saidNew.rows.first?.account.name == "Techcombank 2")
        #expect(yes.rows.first?.notice?.contains("Techcombank 2") == true)
        // A name of the user's own is no twin.
        let own = try #require(card(add([["type": "bank", "institution": "Techcombank", "name": "Techcombank tiết kiệm",
                                          "balance": 5_000_000]], in: store)))
        #expect(own.rows.first?.account.name == "Techcombank tiết kiệm")
    }

    // MARK: Nhiều tài khoản

    @Test func severalInOneSentenceWaitOnOneCardOrAreAskedTogether() throws {
        let store = store()
        let both = try #require(card(add([["type": "bank", "institution": "vcb", "balance": 10_000_000],
                                          ["type": "ewallet", "institution": "zalopay", "balance": 500_000]], in: store,
                                         words: ["thêm vcb 10 triệu với zalopay 500k"])))
        #expect(both.rows.map(\.account.name) == ["Vietcombank", "ZaloPay"])
        let half = add([["type": "bank", "institution": "vcb", "balance": 10_000_000],
                        ["type": "ewallet", "institution": "zalopay"]], in: store)
        #expect(half.action == nil)
        #expect(asked(half) == ["balance"])
        // Two the same in one sentence: the second numbered.
        let twice = try #require(card(add([["type": "cash", "balance": 100_000], ["type": "cash", "balance": 200_000]], in: store)))
        #expect(twice.rows.map(\.account.name) == ["Tiền mặt", "Tiền mặt 2"])
    }

    @Test func severalQuestionsAreSaidTogether() {
        let output = add([["type": "ewallet", "institution": "zalopay"], ["type": "bank"]], in: store())
        let question = AccountDraftBuilder.question(in: output.result) ?? ""
        #expect(question.contains("2 chỗ"))
        #expect(question.components(separatedBy: "\n• ").count == 3)
    }

    // MARK: Sửa bằng lời, xem lại, huỷ

    @Test func aCardChangedInWordsReplacesTheOldOneAndKeepsItsRows() throws {
        let store = store()
        let first = try #require(card(add([["type": "bank", "institution": "BIDV", "balance": 5_000_000]], in: store,
                                          words: ["thêm BIDV 5 triệu"])))
        let changed = try #require(card(add([["type": "bank", "institution": "BIDV", "balance": 3_000_000]],
                                            replaces: first.ref, in: store, words: ["sửa số dư thành 3 triệu"], open: [first])))
        #expect(changed.replacing == first.id)
        #expect(changed.rows.first?.id == first.rows.first?.id)
        #expect(changed.rows.first?.account.balance == 3_000_000)
        #expect(changed.rows.first?.warning == nil)

        let renamed = try #require(card(add([["type": "bank", "institution": "BIDV", "name": "BIDV lương", "balance": 5_000_000]],
                                            replaces: first.ref, in: store, words: ["đổi tên thành BIDV lương"], open: [first])))
        #expect(renamed.rows.first?.account.name == "BIDV lương")
        #expect(renamed.rows.first?.id == first.rows.first?.id)
        // Renamed with the balance not said again: kept (live test 2026-11-20).
        let unsaid = try #require(card(add([["type": "bank", "institution": "BIDV", "name": "BIDV lương"]],
                                           replaces: first.ref, in: store, words: ["đổi tên thành BIDV lương"], open: [first])))
        #expect(unsaid.rows.first?.account.balance == 5_000_000)

        // Asked to see it again: the code alone shows it as it is.
        let shown = try #require(card(add([], replaces: first.ref, in: store, open: [first])))
        #expect(shown.rows == first.rows)
        #expect(shown.replacing == first.id)
    }

    /// Changed twice, the first card's code sent: the one card still waiting is changed.
    @Test func anOldCodeChangesTheCardStillWaiting() throws {
        let store = store()
        let first = try #require(card(add([["type": "bank", "institution": "BIDV", "balance": 5_000_000]], in: store)))
        let second = try #require(card(add([["type": "bank", "institution": "BIDV", "balance": 3_000_000]],
                                           replaces: first.ref, in: store, open: [first])))
        let turn = RecordTurn(userWords: ["đổi tên thành BIDV lương"], openAccounts: [second],
                              seenAccounts: [first.ref, second.ref])
        let third = try #require(card(AddAccount(turn: turn).run(
            ["replaces": .string(first.ref), "accounts": [["type": "bank", "institution": "BIDV", "name": "BIDV lương"]]], in: store)))
        #expect(third.replacing == second.id)
        #expect(third.rows.first?.account.balance == 3_000_000)
    }

    @Test func aCardNoLongerWaitingIsSaidSo() {
        let store = store()
        var done = AccountDraft(rows: [AccountDraft.Row(account: Account(name: "BIDV", type: .bank, balance: 0,
                                                                          institutionID: "bidv"))])
        done.state = .cancelled
        let turn = RecordTurn(seenAccounts: [done.ref])
        let output = AddAccount(turn: turn).run(["replaces": .string(done.ref),
                                                 "accounts": [["type": "bank", "institution": "BIDV", "balance": 1]]], in: store)
        #expect(output.result["status"] == "rejected")
        #expect(output.action == nil)
    }

    /// Numbered once ("Techcombank 2"), changed again with the bank's name: the number stays.
    @Test func aNumberedNameStaysWhenTheCardIsChanged() throws {
        let store = store()
        let first = try #require(card(add([["type": "bank", "institution": "Techcombank", "balance": 5_000_000,
                                            "same_name_ok": true]], in: store)))
        let changed = try #require(card(add([["type": "bank", "institution": "Techcombank", "balance": 3_000_000]],
                                            replaces: first.ref, in: store, open: [first])))
        #expect(changed.rows.first?.account.name == "Techcombank 2")
    }

    /// One just added from this chat, sent again beside a new one: left out; alone, asked about.
    @Test func anAccountJustAddedIsNotAskedAgainBesideANewOne() throws {
        let store = store()
        let bidv = Account(name: "BIDV luong", type: .bank, balance: 3_000_000, institutionID: "bidv")
        store.add(bidv)
        let turn = RecordTurn(userWords: ["them vi zalopay 100k"], addedAccounts: [bidv.id])
        let both: JSONValue = ["accounts": [["type": "bank", "institution": "BIDV", "name": "BIDV luong", "balance": 3_000_000],
                                            ["type": "ewallet", "institution": "ZaloPay", "balance": 100_000]]]
        let draft = try #require(card(AddAccount(turn: turn).run(both, in: store)))
        #expect(draft.rows.map(\.account.name) == ["ZaloPay"])
        let alone: JSONValue = ["accounts": [["type": "bank", "institution": "BIDV", "name": "BIDV luong", "balance": 3_000_000]]]
        #expect(asked(AddAccount(turn: turn).run(alone, in: store)) == ["duplicate"])
    }

    @Test func aGoalIsRefusedWithTheWayByHand() {
        let output = add([["type": "goal", "name": "Du lịch", "balance": 1_000_000]], in: store())
        #expect(output.result["status"] == "rejected")
        let refused = RemoteAssistant.refused(in: output.result, adding: [])
        #expect(refused.first?.howTo?.contains("Hũ tiết kiệm") == true)
    }

    @Test func okAndHuỷTypedWorkUnderACardOfAccounts() {
        #expect(DraftShortcut.match("ok") == .save)
        #expect(DraftShortcut.match("huỷ") == .cancel)
        let waiting = ChatMessage(role: .assistant, text: "…", card: .accountDraft(AccountDraft(rows: [])))
        #expect(waiting.waitsForSave)
        #expect(waiting.pendingDraft == nil)
    }

    // MARK: Chat và máy chủ

    @Test func aCardOfAccountsIsKeptInTheChatsAndReadLeniently() throws {
        let store = store()
        let draft = try #require(card(add([["type": "bank", "institution": "BIDV", "balance": 1_000_000]], in: store)))
        let message = ChatMessage(role: .assistant, text: "Soạn xong rồi nè", card: .accountDraft(draft))
        let data = try JSONEncoder().encode([message])
        let read = try JSONDecoder().decode([ChatMessage].self, from: data)
        #expect(read.first?.card == .accountDraft(draft))
        // A state a newer build wrote: done with, never one to save.
        let newer = String(data: data, encoding: .utf8)!.replacingOccurrences(of: "\"pending\"", with: "\"later\"")
        let lenient = try JSONDecoder().decode([ChatMessage].self, from: Data(newer.utf8))
        #expect(lenient.first?.pendingAccountDraft == nil)
    }

    /// Told to the model as the add_account call that made it, in words the transaction guards of
    /// the server do not take for a card of transactions ("[Thẻ #").
    @Test func theHistoryTellsTheModelOfACardOfAccounts() throws {
        let store = store()
        let draft = try #require(card(add([["type": "bank", "institution": "BIDV", "balance": 1_000_000]], in: store)))
        let messages = [ChatMessage(role: .user, text: "thêm BIDV 1 triệu"),
                        ChatMessage(role: .assistant, text: "Bạn kiểm tra rồi bấm Lưu nhé", card: .accountDraft(draft))]
        let told = RemoteAssistant.history(messages, store: store)
        #expect(told.map(\.role) == ["user", "assistant", "tool", "assistant"])
        #expect(told[1].toolCalls?.first?.name == "add_account")
        #expect(told[2].content.contains("[Thẻ tài khoản #\(draft.ref) · đang chờ"))
        #expect(!told[2].content.contains("[Thẻ #"))
    }

    @Test func addingAnAccountTakesNoLượt() {
        #expect(!RemoteAssistant.counts(["add_account"]))
        #expect(RemoteAssistant.counts(["add_account", "get_accounts"]))
    }

    @Test func anAnswerNeverSaysTheAccountWasAdded() {
        let draft = AccountDraft(rows: [])
        #expect(RemoteAssistant.answerText("Milu đã thêm tài khoản BIDV rồi nè", actions: [.accountDraft(draft)])
                == RemoteAssistant.draftReady)
        #expect(RemoteAssistant.answerText("Đã sửa số dư rồi nha", actions: [], cardWaiting: true,
                                           unchanged: RemoteAssistant.accountsUnchanged) == RemoteAssistant.accountsUnchanged)
    }

    /// Given only to a chat about accounts: the model's room is short.
    @Test func theToolIsGivenOnlyWhenAccountsAreTalkedOf() {
        #expect(AddAccount.isNeeded(for: "thêm tài khoản BIDV 5 triệu", history: []))
        #expect(AddAccount.isNeeded(for: "tạo ví zalopay", history: []))
        #expect(AddAccount.isNeeded(for: "thêm thẻ tín dụng HSBC", history: []))
        #expect(!AddAccount.isNeeded(for: "ăn trưa 45k", history: []))
        #expect(!AddAccount.isNeeded(for: "tháng này chi bao nhiêu vì mình lo quá", history: []))
        let waiting = ChatMessage(role: .assistant, text: "…", card: .accountDraft(AccountDraft(rows: [])))
        #expect(AddAccount.isNeeded(for: "sửa số dư thành 3 triệu", history: [waiting]))
        let asked = ChatMessage(role: .assistant, text: "…",
                                askedCall: ChatMessage.AskedCall(name: "add_account", arguments: [:], result: [:]))
        #expect(AddAccount.isNeeded(for: "500k", history: [asked]))
    }

    /// The model is given the tool, and a tool exists by that name.
    @Test func theToolIsSentToTheModel() {
        #expect(AssistantTools.specs.contains { $0.name == "add_account" })
        #expect(AssistantTools.named("add_account") is AddAccount)
    }
}
