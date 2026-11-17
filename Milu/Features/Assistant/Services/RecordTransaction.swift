import Foundation

/// What a record call knows of the chat it runs in: the user's latest words, to check the amounts
/// the model read; the cards still waiting for "Lưu", one of which it may replace; and where the
/// last account used is kept (tests give their own).
struct RecordTurn {
    /// This question and the few before it.
    var userWords: [String] = []
    /// Cards waiting for "Lưu" in the chat, the newest last.
    var open: [TransactionDraft] = []
    var defaults: UserDefaults = .standard
    var now: Date = .now
}

/// Makes a card of transactions to record, and records nothing: the user checks every field and
/// taps "Lưu" (user choice 2026-11-17; before, it recorded at once). What is missing is asked,
/// never guessed (`needsInfo`); what Milu does not record is said with how to do it by hand
/// (`rejected`): a transfer, a loan, a goal, a day ahead, an amount out of range.
struct RecordTransaction: AssistantTool {
    var turn = RecordTurn()

    let name = "record_transaction"
    let description = """
        Soạn thẻ ghi khoản chi hoặc thu để người dùng kiểm tra rồi bấm Lưu; công cụ này CHƯA ghi gì. Gọi ngay \
        khi người dùng muốn ghi, thêm một khoản ("ghi ăn trưa 60k", "nhận lương 25 triệu"), kể cả khi còn thiếu \
        thông tin, và gửi mọi khoản của câu trong một lần. Kết quả: needsInfo thì hỏi lại đúng câu `ask` (kèm \
        gợi ý), rồi gọi lại với đủ các khoản; rejected thì nói `reason` và `howTo`; draft thì nói ngắn là người \
        dùng kiểm tra thẻ rồi bấm Lưu, không bao giờ nói đã ghi. Sửa thẻ đang chờ thì gửi lại đủ các khoản của \
        thẻ kèm `replaces`. Chuyển khoản, rút tiền, nạp ví, vay, trả nợ, hũ: Milu chưa ghi được, vẫn gọi ngay với \
        kind transfer, loan hay goal, không hỏi thêm tài khoản hay người nào.
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "transactions": [
                "type": "array",
                "description": "Từng khoản người dùng muốn ghi",
                "items": [
                    "type": "object",
                    "properties": [
                        "kind": ["type": "string", "enum": ["expense", "income", "transfer", "loan", "goal", "unclear"],
                                 "description": """
                                    expense: chi; income: thu; transfer: chuyển tiền giữa hai tài khoản của mình (rút \
                                    tiền, nạp ví, trả thẻ tín dụng); loan: cho vay, đi vay, trả nợ, thu nợ; goal: bỏ \
                                    tiền vào hay rút từ hũ tiết kiệm; unclear: chưa rõ
                                    """],
                        "amount": ["type": "integer", "description": "Số tiền VND, số nguyên dương; bỏ trống nếu người dùng chưa nói"],
                        "amount_said": ["type": "string", "description": "Số tiền đúng như người dùng nói, ví dụ: 1tr2, 60k, 2 củ"],
                        "category": ["type": "string", "description": "Tên hạng mục con trong danh sách; bỏ trống nếu không chắc"],
                        "new_category": [
                            "type": "object",
                            "description": "Chỉ khi không hạng mục nào hợp: tên mục mới và nhóm có sẵn để đặt nó vào",
                            "properties": [
                                "name": ["type": "string"],
                                "group": ["type": "string", "description": "Tên nhóm có sẵn, ví dụ: Học tập"],
                            ],
                        ],
                        "account": ["type": "string", "description": "Tên tài khoản người dùng nói; bỏ trống nếu họ không nói"],
                        "date": ["type": "string", "description": "YYYY-MM-DD; bỏ trống là hôm nay"],
                        "time": ["type": "string", "description": "HH:mm nếu người dùng nói giờ"],
                        "note": ["type": "string", "description": "Ghi chú ngắn: đã chi hay nhận gì, ví dụ: Bún chả"],
                    ],
                ],
            ],
            "replaces": ["type": "string", "description": "Mã thẻ đang chờ Lưu cần sửa, ví dụ k7f2 (từ [Thẻ #k7f2])"],
        ],
        "required": ["transactions"],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        DraftBuilder(turn: turn, store: store).run(arguments)
    }
}

/// What Milu does not record, said plainly as what it cannot do yet (user request 2026-11-17: it
/// asked which accounts a transfer was between, then said "Milu bị từ chối rồi nè"), and where the
/// user does it by hand (the paths as the app shows them).
enum RecordRefusal {
    /// A kind of transaction Milu does not record yet.
    struct Kind: Equatable {
        let reason: String
        /// Each way by hand, a line of its own in the answer.
        let ways: [String]
        /// The ways in one line, as the model is given them.
        var howTo: String { ways.joined(separator: " ") }
    }

    static let transfer = Kind(
        reason: "Milu chưa ghi được chuyển tiền giữa các tài khoản (chuyển khoản, rút tiền, nạp ví): tính năng này chưa có.",
        ways: ["Nút + → Thêm giao dịch → Chuyển khoản."])
    static let loan = Kind(
        reason: "Milu chưa ghi được khoản vay hay trả nợ: tính năng này chưa có.",
        ways: ["Khoản vay mới: nút + → Thêm khoản vay.",
               "Trả hay thu nợ: Giao dịch → Vay nợ → chọn khoản vay → Ghi nhận thu nợ / trả nợ."])
    static let goal = Kind(
        reason: "Milu chưa ghi được tiền bỏ vào hay rút từ hũ tiết kiệm: tính năng này chưa có.",
        ways: ["Tài khoản → chọn hũ → Nạp tiền hoặc Rút tiền."])
    static let kinds = [transfer, loan, goal]
    static let futureHowTo = "Khoản lặp lại hằng tháng thì tạo giao dịch định kỳ: nút + → Thêm giao dịch → Lặp lại."

    /// One item refused, as the record tool's result gives it.
    struct Refused: Equatable {
        let reason: String
        let howTo: String?
    }

    /// The app's own words for what was refused, in place of the model's: why, then each way by
    /// hand on a line of its own; the same refusal said once.
    static func message(_ refused: [Refused]) -> String {
        var said: [Refused] = []
        for item in refused where !said.contains(item) { said.append(item) }
        return said.map { item in
            if let kind = kinds.first(where: { $0.reason == item.reason }) {
                return ([kind.reason + " Bạn ghi tay giúp Milu nhé:"] + kind.ways.map { "• " + $0 }).joined(separator: "\n")
            }
            return [item.reason, item.howTo.map { "• " + $0 }].compactMap { $0 }.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }
}

/// The checks behind `RecordTransaction`, item by item, saving nothing; the keyword assistant uses
/// them too (`MockAssistant`).
struct DraftBuilder {
    let turn: RecordTurn
    let store: FinanceStore

    /// One item's outcome.
    enum Outcome {
        case ready(TransactionDraft.Row)
        case needs(Need)
        case refused(reason: String, howTo: String?)
    }

    /// What to ask the user before an item can go on a card.
    struct Need {
        /// amount, kind, category, account, date or group.
        var missing: String
        var ask: String
        var suggestions: [String] = []
        var options: [String] = []
        var canCreate: JSONValue? = nil
    }

    func run(_ arguments: JSONValue) -> ToolOutput {
        let inputs = Self.items(arguments)
        guard !inputs.isEmpty else {
            return .failure("Không có khoản nào để ghi. Hỏi người dùng muốn ghi khoản gì, bao nhiêu tiền; chưa ghi gì")
        }
        var replacing: TransactionDraft?
        let ref = (arguments["replaces"]?.string ?? "").lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        if !ref.isEmpty {
            guard let card = turn.open.last(where: { $0.ref == ref }) else {
                return ToolOutput(result: [
                    "ok": false, "status": "rejected",
                    "reason": .string("Thẻ #\(ref) không còn chờ Lưu: đã lưu, đã huỷ hoặc đã thay."),
                    "howTo": "Khoản đã lưu thì người dùng bấm Xem trên thẻ để sửa; muốn ghi khoản khác thì soạn thẻ mới, không gửi replaces.",
                ])
            }
            replacing = card
        }
        var rows: [TransactionDraft.Row] = []
        var needs: [JSONValue] = []
        var refused: [JSONValue] = []
        let known = replacing.map { Set($0.liveRows.map(\.transaction.amount)) } ?? []
        for (index, input) in inputs.enumerated() {
            switch resolve(input, knownAmounts: known) {
            case .ready(let row):
                rows.append(row)
            case .needs(let need):
                var item: [String: JSONValue] = ["index": .number(Double(index + 1)), "missing": .string(need.missing),
                                                 "ask": .string(need.ask)]
                if !need.suggestions.isEmpty { item["suggestions"] = .array(need.suggestions.map(JSONValue.string)) }
                if !need.options.isEmpty { item["options"] = .array(need.options.map(JSONValue.string)) }
                if let canCreate = need.canCreate { item["canCreate"] = canCreate }
                needs.append(.object(item))
            case .refused(let reason, let howTo):
                var item: [String: JSONValue] = ["index": .number(Double(index + 1)), "reason": .string(reason)]
                if let howTo { item["howTo"] = .string(howTo) }
                refused.append(.object(item))
            }
        }
        // Asked first, all of it: a card holds the whole sentence or nothing.
        if !needs.isEmpty {
            var result: [String: JSONValue] = [
                "ok": true, "status": "needsInfo", "items": .array(needs),
                "say": "Chưa soạn thẻ, chưa ghi gì. Hỏi người dùng đúng câu ask của từng khoản (kèm gợi ý nếu có), rồi gọi lại với đủ mọi khoản.",
            ]
            if !refused.isEmpty { result["rejected"] = .array(refused) }
            return ToolOutput(result: .object(result))
        }
        guard !rows.isEmpty else {
            return ToolOutput(result: [
                "ok": false, "status": "rejected", "items": .array(refused),
                // The app says it in its own words (`RecordRefusal.message`); the model is told the
                // same, for the chat it is given next.
                "say": "Không ghi gì, không soạn thẻ. Nói thật là Milu chưa làm được (reason), rồi chép nguyên văn cách ghi tay (howTo); không hỏi thêm gì.",
            ])
        }
        let draft = TransactionDraft(rows: rows, replacing: replacing?.id)
        var result: [String: JSONValue] = [
            "ok": true, "status": "draft", "card": .string(draft.ref),
            "rows": .array(rows.enumerated().map { describe($0.element, number: $0.offset + 1) }),
            // No "#ref" said here: the model read it out to the user (Simulator, 2026-11-17).
            "say": .string("Đã soạn thẻ, CHƯA ghi gì. Nói ngắn gọn: người dùng kiểm tra thẻ rồi bấm Lưu; không nói đã ghi, không nói mã thẻ."
                + (refused.isEmpty ? "" : " Nói thêm khoản nào không ghi được, lý do, rồi chép nguyên văn cách ghi tay (howTo).")),
        ]
        if !refused.isEmpty { result["rejected"] = .array(refused) }
        return ToolOutput(result: .object(result), action: .draft(draft))
    }

    /// The items the model sent: `transactions`, or one item at the top as the tool once took it
    /// (and as a model may still send it), or the list written as a JSON string.
    static func items(_ arguments: JSONValue) -> [JSONValue] {
        switch arguments["transactions"] {
        case .array(let items):
            return items.filter { if case .object = $0 { true } else { false } }
        case .string(let text):
            if let data = text.data(using: .utf8), let decoded = try? JSONDecoder().decode(JSONValue.self, from: data),
               case .array(let items) = decoded {
                return items.filter { if case .object = $0 { true } else { false } }
            }
            return []
        case .object:
            return arguments["transactions"].map { [$0] } ?? []
        default:
            let fields = ["kind", "amount", "amount_said", "category", "note", "account", "date"]
            return fields.contains(where: { arguments[$0] != nil }) ? [arguments] : []
        }
    }

    // MARK: - One item

    func resolve(_ input: JSONValue, knownAmounts: Set<Double> = []) -> Outcome {
        let note = String(Category.cleanName(input["note"]?.string ?? "").prefix(200))
        let what = note.isEmpty ? "Khoản này" : "Khoản “\(note)”"
        let categoryText = Category.cleanName(input["category"]?.string ?? "")
        let newCategory = input["new_category"]

        // Kind: a transfer, a loan or a goal is not Milu's to record; one not said comes from the
        // category when that is only spending or only income.
        let kind: TransactionKind
        switch Self.kindWord(input["kind"]?.string) {
        case .expense: kind = .expense
        case .income: kind = .income
        case .transfer: return .refused(reason: RecordRefusal.transfer.reason, howTo: RecordRefusal.transfer.howTo)
        case .loan: return .refused(reason: RecordRefusal.loan.reason, howTo: RecordRefusal.loan.howTo)
        case .goal: return .refused(reason: RecordRefusal.goal.reason, howTo: RecordRefusal.goal.howTo)
        case .unclear:
            guard let inferred = inferredKind(category: categoryText, newGroup: newCategory?["group"]?.string) else {
                return .needs(Need(missing: "kind", ask: "\(what) là khoản chi hay khoản thu?", options: ["Khoản chi", "Khoản thu"]))
            }
            kind = inferred
        case .unknown:
            return .needs(Need(missing: "kind", ask: "\(what) là khoản chi hay khoản thu?", options: ["Khoản chi", "Khoản thu"]))
        }

        // Amount: said, in range, and the one the user said.
        let said = input["amount_said"]?.string ?? ""
        guard let raw = input["amount"]?.number ?? (said.isEmpty ? nil : SaidAmount.parse(said)), raw.isFinite else {
            return .needs(Need(missing: "amount", ask: "\(what) bao nhiêu tiền?"))
        }
        let amount = raw.rounded()
        guard amount >= 1 else { return .refused(reason: "Số tiền phải lớn hơn 0đ.", howTo: nil) }
        guard amount <= MiluAmountField.maxAmount else {
            return .refused(reason: "Số tiền quá lớn: Milu ghi tối đa \(MiluAmountField.maxAmount.vnd) một khoản.", howTo: nil)
        }
        if !said.isEmpty, let read = SaidAmount.parse(said), read != amount {
            return .needs(Need(missing: "amount", ask: "“\(said)” là \(read.vnd) phải không?",
                               suggestions: [read.vnd, amount.vnd]))
        }
        // A number the user never said is asked about, never put on a card (a model's slip). The
        // card being replaced counts as said; with no words to go by (a test), the model's stands.
        let heard = SaidAmount.all(in: turn.userWords.joined(separator: " ")).union(knownAmounts)
        if !turn.userWords.isEmpty, !heard.isEmpty, !heard.contains(amount) {
            let options = heard.filter { $0 >= 1_000 }.sorted().prefix(3).map(\.vnd)
            return .needs(Need(missing: "amount", ask: "\(what) bao nhiêu tiền? Milu chưa chắc là \(amount.vnd).",
                               suggestions: Array(options)))
        }

        // Day and time: read as written, never ahead of today.
        let dateText = input["date"]?.string ?? ""
        let calendar = Calendar.current
        var day = turn.now
        if !dateText.isEmpty {
            guard let parsed = ToolDates.day(dateText) else {
                return .needs(Need(missing: "date", ask: "\(what) vào ngày nào?"))
            }
            day = parsed
        }
        if calendar.startOfDay(for: day) > calendar.startOfDay(for: turn.now) {
            return .refused(reason: "Ngày \(day.shortDay) chưa tới: Milu chỉ ghi khoản đã chi hoặc đã nhận.",
                            howTo: RecordRefusal.futureHowTo)
        }
        let date = Self.moment(on: day, time: input["time"]?.string, now: turn.now)

        // Account: the one said, or the last one used, which the card then says it chose.
        let account: Account
        let chosenByApp: Bool
        switch resolveAccount(input["account"]?.string) {
        case .found(let found, let byApp):
            account = found
            chosenByApp = byApp
        case .problem(let outcome):
            return outcome
        }

        // Category: an item of the user's, or a new one to make on "Lưu".
        var categoryID = ""
        var newItem: TransactionDraft.NewItem?
        switch CategoryResolver(store: store).resolve(category: categoryText, newCategory: newCategory, note: note,
                                                      kind: kind, what: what) {
        case .item(let id): categoryID = id
        case .newItem(let item): newItem = item
        case .needs(let need): return .needs(need)
        }

        let name = newItem?.name ?? store.categoryName(categoryID)
        let transaction = FinanceTransaction(amount: amount, categoryID: categoryID, kind: kind, accountID: account.id,
                                             date: date, note: note.compare(name, options: .caseInsensitive) == .orderedSame ? "" : note)
        var row = TransactionDraft.Row(transaction: transaction, newItem: newItem, accountChosenByApp: chosenByApp)
        row.warning = DraftChecks.duplicate(of: row, in: store)
        return .ready(row)
    }

    enum KindWord { case expense, income, transfer, loan, goal, unclear, unknown }

    /// The kind as the model wrote it, in English or Vietnamese.
    static func kindWord(_ text: String?) -> KindWord {
        let key = (text ?? "").searchKey.trimmingCharacters(in: .whitespaces)
        switch key {
        case "expense", "spending", "chi", "chi tieu", "khoan chi": return .expense
        case "income", "thu", "thu nhap", "khoan thu": return .income
        case "transfer", "chuyen khoan", "chuyen tien": return .transfer
        case "loan", "lend", "borrow", "repay", "debt", "vay", "cho vay", "di vay", "tra no", "thu no": return .loan
        case "goal", "saving", "savings", "hu", "tiet kiem": return .goal
        case "", "unclear", "unknown": return .unclear
        default: return .unknown
        }
    }

    /// The kind a category named means when it is only one: "Lương chính" is income.
    private func inferredKind(category: String, newGroup: String?) -> TransactionKind? {
        let named = [category, newGroup ?? ""].filter { !$0.isEmpty }
        guard !named.isEmpty else { return nil }
        let kinds = Set(named.flatMap { name in
            store.categories.filter { !$0.isHidden && $0.name.searchKey == name.searchKey }.map(\.kind)
        })
        return kinds.count == 1 ? kinds.first : nil
    }

    /// The day said, at the hour said ("12:30", "12h30", "7h"), or else now's time.
    static func moment(on day: Date, time: String?, now: Date) -> Date {
        let calendar = Calendar.current
        if let time, let match = time.lowercased().firstMatch(of: /(\d{1,2})\s*[:h]\s*(\d{1,2})?/),
           let hour = Int(match.1), hour < 24 {
            let minute = match.2.flatMap { Int($0) }.map { min($0, 59) } ?? 0
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }
        guard !calendar.isDate(day, inSameDayAs: now) else { return now }
        let parts = calendar.dateComponents([.hour, .minute], from: now)
        return calendar.date(bySettingHour: parts.hour ?? 12, minute: parts.minute ?? 0, second: 0, of: day) ?? day
    }

    // MARK: - Account

    private enum AccountChoice {
        case found(Account, chosenByApp: Bool)
        case problem(Outcome)
    }

    /// The account said, or the last one used; a locked, archived, unknown or unclear one is asked
    /// about with the ones it can go on, never put on another (audit 2026-11-15).
    private func resolveAccount(_ text: String?) -> AccountChoice {
        let usable = store.usableAccounts
        let options = usable.map(\.name)
        let named = Category.cleanName(text ?? "")
        guard !named.isEmpty else {
            let last = turn.defaults.string(forKey: StorageKey.lastAccountID).flatMap(UUID.init(uuidString:))
            guard let main = usable.first(where: { $0.id == last })
                ?? usable.first(where: { AccountType.paymentTypes.contains($0.type) }) ?? usable.first else {
                return .problem(.refused(reason: "Bạn chưa có tài khoản nào để ghi vào.",
                                         howTo: "Thêm tài khoản ở tab Tài khoản trước."))
            }
            return .found(main, chosenByApp: true)
        }
        switch ToolNames.match(named, in: store.accounts) {
        case .found(let account):
            guard !account.isLocked else {
                return .problem(.needs(Need(
                    missing: "account", ask: "Tài khoản “\(account.name)” đang khoá, không ghi thêm được. Ghi vào tài khoản nào?",
                    options: options)))
            }
            return .found(account, chosenByApp: false)
        case .ambiguous(let accounts):
            return .problem(.needs(Need(missing: "account", ask: "“\(named)” là tài khoản nào?",
                                        options: accounts.filter { !$0.isLocked }.map(\.name))))
        case .none:
            if case .found(let archived) = ToolNames.match(named, in: store.archivedAccounts) {
                return .problem(.needs(Need(
                    missing: "account", ask: "Tài khoản “\(archived.name)” đã lưu trữ. Ghi vào tài khoản nào?", options: options)))
            }
            return .problem(.needs(Need(
                missing: "account", ask: "Bạn không có tài khoản nào tên “\(named)”. Ghi vào tài khoản nào?", options: options)))
        }
    }

    // MARK: - For the model

    /// A row as the model reads it back.
    func describe(_ row: TransactionDraft.Row, number: Int) -> JSONValue {
        let transaction = row.transaction
        var item: [String: JSONValue] = [
            "row": .number(Double(number)),
            "kind": .string(transaction.kind.rawValue),
            "amount": ToolMoney.value(transaction.amount),
            "amountText": .string(transaction.amount.vnd),
            "category": .string(DraftChecks.categoryText(of: row, in: store)),
            "account": .string(store.account(id: transaction.accountID)?.name ?? ""),
            "date": .string(ToolDates.text(transaction.date)),
            "time": .string(DraftChecks.time(transaction.date)),
        ]
        if !transaction.note.isEmpty { item["note"] = .string(transaction.note) }
        if row.accountChosenByApp { item["accountChosenByApp"] = true }
        if let warning = row.warning { item["warning"] = .string(warning) }
        return .object(item)
    }
}

/// Finds the item a transaction goes under, from what the model named and what the user wrote:
/// only one Milu is sure of, else it asks with a few to pick from, and offers to make one when
/// none fits (user choice 2026-11-17). Never a hidden item, as the add form offers none.
struct CategoryResolver {
    let store: FinanceStore

    enum Result {
        case item(String)
        case newItem(TransactionDraft.NewItem)
        case needs(DraftBuilder.Need)
    }

    func resolve(category: String, newCategory: JSONValue?, note: String, kind: TransactionKind, what: String) -> Result {
        let items = store.pickableItems(kind)
        let groups = store.groups(kind)
        let key = category.searchKey

        if !key.isEmpty {
            // The item's own name.
            if let item = items.first(where: { $0.name.searchKey == key }) { return .item(item.id) }
            // A group's name: its only item, or the one the note names, else asked among its items.
            if let group = groups.first(where: { $0.name.searchKey == key }) {
                let members = items.filter { $0.parentID == group.id }
                if members.count == 1, let only = members.first { return .item(only.id) }
                if let named = Self.named(in: note, among: members) { return .item(named.id) }
                if !members.isEmpty {
                    return .needs(DraftBuilder.Need(missing: "category", ask: "\(what) thuộc mục nào trong “\(group.name)”?",
                                                    suggestions: members.prefix(8).map(\.name)))
                }
            }
            // An item of the other kind ("Lương chính" for a spending): which it is, asked.
            let other: TransactionKind = kind == .expense ? .income : .expense
            if let item = store.pickableItems(other).first(where: { $0.name.searchKey == key }) {
                return .needs(DraftBuilder.Need(missing: "kind", ask: "“\(item.name)” là hạng mục \(other == .income ? "thu nhập" : "chi tiêu"). \(what) là khoản chi hay khoản thu?",
                                                options: ["Khoản chi", "Khoản thu"]))
            }
            // Whole words in common, one item only.
            let matches = items.filter { Self.sharesWords(key, $0.name.searchKey) }
            if matches.count == 1, let only = matches.first { return .item(only.id) }
        }

        // A new item the model asked for, when the user has none like it.
        if let newCategory, case .object = newCategory {
            return resolveNew(newCategory, items: items, groups: groups, kind: kind, what: what)
        }

        // The note naming an item, whole words ("ăn trưa với sếp").
        if let named = Self.named(in: [note, category].joined(separator: " "), among: items) { return .item(named.id) }

        // Not sure: a few to pick from, and an offer to make one.
        return .needs(DraftBuilder.Need(
            missing: "category",
            ask: "Milu chưa chắc \(what.lowercasedFirst) thuộc hạng mục nào. Chọn một mục, hoặc tạo mục mới?",
            suggestions: suggestions(for: [note, category].joined(separator: " "), kind: kind, items: items),
            canCreate: .object([
                "name": .string(Self.suggestedName(category: category, note: note)),
                "groups": .array(groups.map { .string($0.name) }),
            ])))
    }

    private func resolveNew(_ input: JSONValue, items: [Category], groups: [Category], kind: TransactionKind,
                            what: String) -> Result {
        let name = Category.cleanName(input["name"]?.string ?? "")
        let groupName = Category.cleanName(input["group"]?.string ?? "")
        // One the user has already, by its name: that one.
        if !name.isEmpty, let item = items.first(where: { $0.name.searchKey == name.searchKey }) { return .item(item.id) }
        guard let group = groups.first(where: { $0.name.searchKey == groupName.searchKey }), !groupName.isEmpty else {
            return .needs(DraftBuilder.Need(missing: "group", ask: "Tạo mục “\(name)” trong nhóm nào?",
                                            options: groups.map(\.name)))
        }
        if let problem = store.newItemProblem(name, inGroup: group.id) {
            // The group has it hidden, or a system name: said, and something else asked for.
            return .needs(DraftBuilder.Need(missing: "category", ask: "\(problem) \(what) thuộc mục nào?",
                                            suggestions: items.filter { $0.parentID == group.id }.prefix(4).map(\.name)))
        }
        return .newItem(TransactionDraft.NewItem(name: name, groupID: group.id))
    }

    /// The item whose whole name the text holds, when only one does ("Gửi xe" in "gửi xe chợ");
    /// never "Khác", which every phrase could be.
    static func named(in text: String, among items: [Category]) -> Category? {
        let words = " " + text.searchKey.split { !$0.isLetter && !$0.isNumber }.joined(separator: " ") + " "
        let found = items.filter { item in
            !item.id.hasSuffix(".other") && words.contains(" " + item.name.searchKey.split { !$0.isLetter && !$0.isNumber }.joined(separator: " ") + " ")
        }
        // The longest name wins a tie it contains ("Cà phê sữa" over "Cà phê").
        guard let longest = found.max(by: { $0.name.count < $1.name.count }) else { return nil }
        let others = found.filter { $0.id != longest.id && !longest.name.searchKey.contains($0.name.searchKey) }
        return others.isEmpty ? longest : nil
    }

    /// Whether one name's words are all the other's ("taxi" and "Taxi, xe ôm").
    static func sharesWords(_ one: String, _ other: String) -> Bool {
        let first = Set(one.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        let second = Set(other.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        guard !first.isEmpty, !second.isEmpty else { return false }
        return first.isSubset(of: second) || second.isSubset(of: first)
    }

    /// Up to three to pick from: items sharing a word with what was said, the group the words
    /// point to, then the ones used lately.
    private func suggestions(for text: String, kind: TransactionKind, items: [Category]) -> [String] {
        var picked: [Category] = []
        func add(_ item: Category) {
            if picked.count < 3, !picked.contains(where: { $0.id == item.id }) { picked.append(item) }
        }
        let words = Set(text.searchKey.split { !$0.isLetter && !$0.isNumber }.map(String.init)).filter { $0.count > 1 }
        for item in items where !item.id.hasSuffix(".other") {
            let itemWords = Set(item.name.searchKey.split { !$0.isLetter && !$0.isNumber }.map(String.init))
            if !itemWords.isDisjoint(with: words) { add(item) }
        }
        let guess = MockAssistant.category(for: text.searchKey)
        if guess.kind == kind {
            for item in items where item.parentID == guess.rawValue && !item.id.hasSuffix(".other") { add(item) }
        }
        for item in store.recentItems(kind) { add(item) }
        return picked.map { item in
            let group = item.parentID.map(store.categoryName) ?? ""
            return group.isEmpty ? item.name : "\(item.name) (\(group))"
        }
    }

    /// A name for a new item: what the model called it, else the note's first words.
    private static func suggestedName(category: String, note: String) -> String {
        let base = category.isEmpty ? note : category
        return String(Category.cleanName(base).prefix(Category.maxNameLength)).capitalizedFirst
    }
}

/// Small things the card and the tool both say.
enum DraftChecks {
    /// "Hôm nay đã có Ăn trưa 60.000đ lúc 12:05": the same kind, amount and item already saved that
    /// day. Told, not stopped: two coffees are two.
    static func duplicate(of row: TransactionDraft.Row, in store: FinanceStore) -> String? {
        let draft = row.transaction
        guard row.newItem == nil, !draft.categoryID.isEmpty else { return nil }
        let calendar = Calendar.current
        guard let twin = store.transactions.first(where: {
            $0.id != draft.id && $0.kind == draft.kind && $0.amount == draft.amount && $0.categoryID == draft.categoryID
                && calendar.isDate($0.date, inSameDayAs: draft.date)
        }) else { return nil }
        let day = calendar.isDateInToday(twin.date) ? "Hôm nay" : "Ngày \(twin.date.shortDay)"
        return "\(day) đã có \(store.categoryName(twin.categoryID)) \(twin.amount.vnd) lúc \(time(twin.date))."
    }

    /// "Ăn trưa", or the item to make: "Học tiếng Nhật (mục mới trong Học tập)".
    static func categoryText(of row: TransactionDraft.Row, in store: FinanceStore) -> String {
        if let item = row.newItem { return "\(item.name) (mục mới trong \(store.categoryName(item.groupID)))" }
        return store.categoryName(row.transaction.categoryID)
    }

    /// "12:05".
    static func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
    }
}

private extension String {
    /// "Khoản này" → "khoản này".
    var lowercasedFirst: String { prefix(1).lowercased() + dropFirst() }
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
