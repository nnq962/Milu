import Foundation

/// A tool the assistant's model may ask for: run here, on the phone's own data, and only its
/// result goes back to the model (user choice 2026-11-12: no database on the server). The server
/// relays whatever tools the app lists, so a new one is a new type here, added to
/// `AssistantTools.all`, and nothing else.
protocol AssistantTool {
    /// snake_case, as models call functions.
    var name: String { get }
    /// What it does and when to use it, in Vietnamese: the model chooses by this.
    var description: String { get }
    /// Its arguments, as JSON Schema.
    var parameters: JSONValue { get }
    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput
}

/// What a tool hands back: the result the model reads, and a card for the chat (a transaction
/// recorded, one to confirm deleting).
struct ToolOutput {
    var result: JSONValue
    var action: AssistantReply.Action? = nil

    static func failure(_ message: String) -> ToolOutput {
        ToolOutput(result: ["ok": false, "error": .string(message)])
    }
}

enum AssistantTools {
    /// Every tool, `get_app_info` reading `app`: the app's facts at the time of the question.
    static func tools(app: AppFacts = AppFacts()) -> [any AssistantTool] {
        [
            SummarizeTransactions(),
            ListTransactions(),
            GetAccounts(),
            GetLoans(),
            GetBudget(),
            GetSavingsGoals(),
            GetRecurring(),
            GetUpcoming(),
            GetMonthlyTrend(),
            ListTransfers(),
            RecordTransaction(),
            DeleteTransaction(),
            GetAppInfo(facts: app),
        ]
    }

    static var all: [any AssistantTool] { tools() }

    static func named(_ name: String, app: AppFacts = AppFacts()) -> (any AssistantTool)? {
        tools(app: app).first { $0.name == name }
    }

    static var specs: [MiluAPI.ToolSpec] {
        all.map { MiluAPI.ToolSpec(name: $0.name, description: $0.description, parameters: $0.parameters) }
    }
}

// MARK: - Reading

/// Totals of spending or income over days, by category and account.
struct SummarizeTransactions: AssistantTool {
    let name = "summarize_transactions"
    let description = """
        Tính tổng chi tiêu hoặc thu nhập trong một khoảng ngày, kèm số giao dịch và phân theo danh mục, \
        theo tài khoản. Dùng cho mọi câu hỏi "bao nhiêu", "tổng", "chi nhiều nhất vào đâu", so sánh các kỳ \
        (gọi một lần cho mỗi kỳ).
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "from": ["type": "string", "description": "Ngày đầu, YYYY-MM-DD"],
            "to": ["type": "string", "description": "Ngày cuối (tính cả ngày này), YYYY-MM-DD"],
            "kind": ["type": "string", "enum": ["expense", "income"], "description": "expense: chi, income: thu"],
            "categories": ["type": "array", "items": ["type": "string"], "description": "Lọc theo tên danh mục; bỏ trống là tất cả"],
            "accounts": ["type": "array", "items": ["type": "string"], "description": "Lọc theo tên tài khoản; bỏ trống là tất cả"],
        ],
        "required": ["from", "to", "kind"],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        guard let interval = ToolDates.interval(arguments) else { return .failure("Ngày không hợp lệ, cần YYYY-MM-DD") }
        let kind = TransactionKind(rawValue: arguments["kind"]?.string ?? "") ?? .expense
        let items = ToolFilters(arguments, store: store)
            .apply(to: store.reportableTransactions(in: interval).filter { $0.kind == kind })
        let total = store.total(kind, of: items)
        let byCategory = (kind == .expense ? store.expensesByCategory(of: items) : store.incomesByCategory(of: items))
            .prefix(8).map { ["name": .string($0.name), "amount": ToolMoney.value($0.amount)] as JSONValue }
        let byAccount = store.totalsByAccount(of: items).prefix(5)
            .map { ["name": .string($0.name), "amount": ToolMoney.value(kind == .expense ? $0.expense : $0.income)] as JSONValue }
        var result: [String: JSONValue] = [
            "from": .string(ToolDates.text(interval.start)),
            "to": .string(ToolDates.text(interval.end.addingTimeInterval(-1))),
            "kind": .string(kind.rawValue),
            "total": ToolMoney.value(total),
            "totalText": .string(total.vnd),
            "count": .number(Double(items.count)),
            "byCategory": .array(Array(byCategory)),
            "byAccount": .array(Array(byAccount)),
        ]
        // A day's average over the days gone by: a month not over yet counts up to today.
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? interval.end
        let days = calendar.dateComponents([.day], from: interval.start, to: min(interval.end, tomorrow)).day ?? 0
        if days > 1 { result["perDay"] = ToolMoney.value(total / Double(days)) }
        // Spending of one group alone: its items too ("Ăn uống" into "Ăn sáng", "Ăn trưa"…).
        if kind == .expense, Set(items.map { store.groupID(of: $0.categoryID) }).count == 1 {
            let byItem = store.expensesByItem(of: items).prefix(8)
            if byItem.count > 1 {
                result["byItem"] = .array(byItem.map { ["name": .string($0.name), "amount": ToolMoney.value($0.amount)] })
            }
        }
        return ToolOutput(result: .object(result))
    }
}

/// Transactions themselves, newest or largest first.
struct ListTransactions: AssistantTool {
    let name = "list_transactions"
    let description = """
        Liệt kê các giao dịch trong một khoảng ngày (mới nhất hoặc lớn nhất trước), lọc theo loại, danh mục, \
        tài khoản hoặc chữ trong ghi chú. Dùng cho "khoản lớn nhất", "đã chi gì", và để tìm giao dịch trước khi xoá \
        (mỗi giao dịch có ref).
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "from": ["type": "string", "description": "Ngày đầu, YYYY-MM-DD"],
            "to": ["type": "string", "description": "Ngày cuối (tính cả ngày này), YYYY-MM-DD"],
            "kind": ["type": "string", "enum": ["expense", "income"], "description": "Bỏ trống là cả hai"],
            "categories": ["type": "array", "items": ["type": "string"]],
            "accounts": ["type": "array", "items": ["type": "string"]],
            "search": ["type": "string", "description": "Chữ có trong ghi chú hoặc tên danh mục, ví dụ: tiền điện"],
            "sort": ["type": "string", "enum": ["newest", "largest"]],
            "limit": ["type": "integer", "description": "Tối đa 20, mặc định 10"],
        ],
        "required": ["from", "to"],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        guard let interval = ToolDates.interval(arguments) else { return .failure("Ngày không hợp lệ, cần YYYY-MM-DD") }
        var items = store.transactions.filter { interval.holds($0.date) && $0.systemCategory == nil }
        if let kind = arguments["kind"]?.string.flatMap(TransactionKind.init(rawValue:)) {
            items = items.filter { $0.kind == kind }
        }
        items = ToolFilters(arguments, store: store).apply(to: items)
        if let search = arguments["search"]?.string?.searchKey, !search.isEmpty {
            items = items.filter { "\($0.note) \(store.categoryName($0.categoryID))".searchKey.contains(search) }
        }
        items.sort(by: arguments["sort"]?.string == "largest" ? { $0.amount > $1.amount } : { $0.date > $1.date })
        let limit = min(max(Int(arguments["limit"]?.number ?? 10), 1), 20)
        return ToolOutput(result: [
            "count": .number(Double(items.count)),
            "transactions": .array(items.prefix(limit).map { ToolTransactions.describe($0, in: store) }),
        ])
    }
}

/// Every account's balance, and what the user owns and owes in all.
struct GetAccounts: AssistantTool {
    let name = "get_accounts"
    let description = """
        Số dư từng tài khoản (tiền mặt, ngân hàng, ví, thẻ tín dụng), tổng tiền đang có, tiền trong các hũ, \
        tổng tài sản ròng, dư nợ thẻ, tiền cho vay và đi vay còn lại.
        """
    let parameters: JSONValue = ["type": "object", "properties": [:]]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        let accounts = store.accounts.sorted { $0.balance > $1.balance }.map { account -> JSONValue in
            var item: [String: JSONValue] = [
                "name": .string(account.name), "type": .string(account.type.title), "balance": ToolMoney.value(account.balance),
            ]
            // Khoá: kept out of every total, as the user chose for it.
            if account.isLocked { item["notCounted"] = true }
            return .object(item)
        }
        let cardDebt = store.countedAccounts.filter { $0.balance < 0 }.reduce(0) { $0 - $1.balance }
        let owed = cardDebt + store.totalBorrowed
        return ToolOutput(result: [
            "accounts": .array(accounts),
            // As Tài khoản's "Tổng số dư": the payment accounts and the goals, no credit cards.
            "moneyOnHand": ToolMoney.value(store.paymentBalance),
            "savedInGoals": ToolMoney.value(store.totalSaved),
            "creditDebt": ToolMoney.value(cardDebt),
            "lent": ToolMoney.value(store.totalLent),
            "borrowed": ToolMoney.value(store.totalBorrowed),
            "netWorth": ToolMoney.value(store.netWorth),
            "say": .string("""
                Tài sản ròng \(store.netWorth.vnd): tiền đang có \(store.paymentBalance.vnd) (kể cả \(store.totalSaved.vnd) \
                trong hũ), người khác còn nợ bạn \(store.totalLent.vnd), bạn còn nợ \(owed.vnd) (thẻ tín dụng \
                \(cardDebt.vnd), đi vay \(store.totalBorrowed.vnd)).
                """),
        ])
    }
}

/// Money lent and borrowed, still owed.
struct GetLoans: AssistantTool {
    let name = "get_loans"
    let description = """
        Nợ nần: các khoản cho vay (người khác nợ mình) và đi vay (mình nợ người khác), còn lại bao nhiêu, đã \
        trả bao nhiêu, vay từ ngày nào, hạn trả, lãi mỗi tháng, của ai; kèm dư nợ thẻ tín dụng. Mặc định chỉ các \
        khoản chưa trả xong.
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "direction": ["type": "string", "enum": ["lent", "borrowed"], "description": "lent: mình cho vay, borrowed: mình đi vay; bỏ trống là cả hai"],
            "include_settled": ["type": "boolean", "description": "true để kể cả các khoản đã trả xong"],
        ],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        let direction = arguments["direction"]?.string.flatMap(LoanDirection.init(rawValue:))
        let settledToo = arguments["include_settled"] == true || arguments["include_settled"]?.string == "true"
        let loans = store.loans.filter { (settledToo || !$0.isSettled) && (direction == nil || $0.direction == direction) }
            .sorted { $0.outstanding > $1.outstanding }
        let today = Calendar.current.startOfDay(for: .now)
        // Credit cards owed too: "nợ nần ra sao" came here and left the card out (2026-11-15).
        let cards = store.countedAccounts.filter { $0.balance < 0 }
        let cardDebt = cards.reduce(0) { $0 - $1.balance }
        let owed = store.totalBorrowed + cardDebt
        return ToolOutput(result: [
            "lentOutstanding": ToolMoney.value(store.totalLent),
            "borrowedOutstanding": ToolMoney.value(store.totalBorrowed),
            "creditCardDebt": ToolMoney.value(cardDebt),
            "creditCards": .array(cards.map { ["name": .string($0.name), "debt": ToolMoney.value(-$0.balance)] }),
            "say": .string("""
                Bạn còn nợ \(owed.vnd) (đi vay \(store.totalBorrowed.vnd), thẻ tín dụng \(cardDebt.vnd)); \
                người khác còn nợ bạn \(store.totalLent.vnd).
                """),
            "loans": .array(loans.prefix(20).map { loan -> JSONValue in
                var item: [String: JSONValue] = [
                    "name": .string(loan.name),
                    "direction": .string(loan.direction == .lent ? "lent" : "borrowed"),
                    "principal": ToolMoney.value(loan.principal),
                    "outstanding": ToolMoney.value(loan.outstanding),
                    "paid": ToolMoney.value(max(loan.principal - loan.outstanding, 0)),
                    "since": .string(ToolDates.text(loan.date)),
                ]
                if loan.isSettled { item["settledOn"] = .string(ToolDates.text(store.settledDate(of: loan))) }
                if let due = loan.dueDate {
                    item["dueDate"] = .string(ToolDates.text(due))
                    if !loan.isSettled, Calendar.current.startOfDay(for: due) < today { item["late"] = true }
                }
                if loan.monthlyInterestRate > 0 {
                    item["interestRatePerMonth"] = .string("\(loan.monthlyInterestRate.formatted(.number.locale(.vietnam)))%")
                    item["interestPerMonth"] = ToolMoney.value(loan.monthlyInterest)
                }
                if let person = loan.contactID.flatMap(store.contact(id:))?.name, person != loan.name {
                    item["person"] = .string(person)
                }
                return .object(item)
            }),
        ])
    }
}

// MARK: - Changing

/// Records a transaction; the chat shows it on a card to view or delete.
struct RecordTransaction: AssistantTool {
    let name = "record_transaction"
    let description = """
        Ghi một giao dịch chi hoặc thu mới vào app. Gọi ngay khi người dùng muốn ghi, thêm một khoản \
        ("ghi ăn trưa 60k", "nhận lương 25 triệu"); app hiện thẻ để họ xem, sửa hoặc xoá.
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "kind": ["type": "string", "enum": ["expense", "income"]],
            "amount": ["type": "integer", "description": "Số tiền VND, số nguyên dương"],
            "category": ["type": "string", "description": "Tên danh mục trong danh sách; bỏ trống để app tự chọn"],
            "account": ["type": "string", "description": "Tên tài khoản; bỏ trống là tài khoản chính"],
            "date": ["type": "string", "description": "YYYY-MM-DD; bỏ trống là hôm nay"],
            "note": ["type": "string", "description": "Ghi chú ngắn: đã chi hay nhận gì, ví dụ: Ăn trưa"],
        ],
        "required": ["kind", "amount"],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        guard let amount = arguments["amount"]?.number, amount >= 1 else { return .failure("Thiếu số tiền") }
        let kind = TransactionKind(rawValue: arguments["kind"]?.string ?? "") ?? .expense
        let note = String((arguments["note"]?.string ?? "").prefix(200))
        guard let account = ToolNames.account(arguments["account"]?.string, in: store)
            ?? store.paymentAccounts.first ?? store.accounts.first else {
            return .failure("Chưa có tài khoản nào: người dùng cần thêm tài khoản trước")
        }
        let categoryID = ToolNames.category(arguments["category"]?.string, kind: kind, in: store)
            ?? Self.guessCategory(note: note, kind: kind)
        let day = arguments["date"]?.string.flatMap(ToolDates.day) ?? .now
        let transaction = FinanceTransaction(amount: amount.rounded(), categoryID: categoryID, kind: kind,
                                             accountID: account.id, date: ToolDates.keepingTime(on: day),
                                             note: note == store.categoryName(categoryID) ? "" : note)
        store.add(transaction)
        return ToolOutput(result: ["ok": true, "recorded": ToolTransactions.describe(transaction, in: store)],
                          action: .recorded(transaction))
    }

    /// The category the note's words point to, as the offline assistant reads them.
    private static func guessCategory(note: String, kind: TransactionKind) -> String {
        let guess = MockAssistant.category(for: note.searchKey)
        if guess.kind == kind { return guess.rawValue }
        return (kind == .expense ? TransactionCategory.otherExpense : .otherIncome).rawValue
    }
}

/// Asks to delete a transaction: the chat shows it with Huỷ / Xoá, nothing goes until then.
struct DeleteTransaction: AssistantTool {
    let name = "delete_transaction"
    let description = """
        Đề nghị xoá một giao dịch theo ref (lấy từ list_transactions). Có ref rồi thì gọi ngay, không hỏi \
        lại người dùng: app không xoá liền mà hiện thẻ để họ bấm xác nhận.
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": ["ref": ["type": "string", "description": "ref của giao dịch, từ list_transactions"]],
        "required": ["ref"],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        guard let ref = arguments["ref"]?.string?.lowercased(), !ref.isEmpty,
              let transaction = store.transactions.first(where: { ToolTransactions.ref($0) == ref }) else {
            return .failure("Không tìm thấy giao dịch với ref này; hãy gọi list_transactions để tìm")
        }
        return ToolOutput(result: ["ok": true, "awaitingConfirmation": true,
                                   "transaction": ToolTransactions.describe(transaction, in: store)],
                          action: .confirmDelete(transaction))
    }
}

// MARK: - Helpers

enum ToolDates {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func text(_ date: Date) -> String { formatter.string(from: date) }

    static func day(_ text: String) -> Date? { formatter.date(from: String(text.prefix(10))) }

    /// `from` to the end of `to`, both days whole.
    static func interval(_ arguments: JSONValue) -> DateInterval? {
        guard let from = arguments["from"]?.string.flatMap(day), let to = arguments["to"]?.string.flatMap(day),
              let end = Calendar.current.date(byAdding: .day, value: 1, to: to), end > from else { return nil }
        return DateInterval(start: from, end: end)
    }

    /// The day given, at this moment's time (a transaction recorded now, said to be yesterday's).
    static func keepingTime(on day: Date) -> Date {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: .now)
        return calendar.date(bySettingHour: time.hour ?? 12, minute: time.minute ?? 0, second: 0, of: day) ?? day
    }
}

enum ToolMoney {
    /// Whole đồng.
    static func value(_ amount: Double) -> JSONValue { .number(amount.rounded()) }
}

enum ToolTransactions {
    /// A short handle the model can give back: the start of the id.
    static func ref(_ transaction: FinanceTransaction) -> String {
        String(transaction.id.uuidString.prefix(8)).lowercased()
    }

    static func describe(_ transaction: FinanceTransaction, in store: FinanceStore) -> JSONValue {
        [
            "ref": .string(ref(transaction)),
            "date": .string(ToolDates.text(transaction.date)),
            "kind": .string(transaction.kind.rawValue),
            "amount": ToolMoney.value(transaction.amount),
            "category": .string(store.categoryName(transaction.categoryID)),
            "account": .string(store.accounts.first { $0.id == transaction.accountID }?.name ?? ""),
            "note": .string(transaction.note.components(separatedBy: .newlines).first ?? ""),
        ]
    }
}

/// Names the model wrote, matched to the phone's own: exact first, then one inside the other,
/// all without accents or case.
enum ToolNames {
    static func account(_ name: String?, in store: FinanceStore) -> Account? {
        guard let key = name?.searchKey, !key.isEmpty else { return nil }
        return store.accounts.first { $0.name.searchKey == key }
            ?? store.accounts.first { $0.name.searchKey.contains(key) || key.contains($0.name.searchKey) }
            ?? store.accounts.first { $0.institution.map { $0.shortName.searchKey == key } == true }
    }

    /// A category of `kind` by name: an item, or a group.
    static func category(_ name: String?, kind: TransactionKind, in store: FinanceStore) -> String? {
        guard let key = name?.searchKey, !key.isEmpty else { return nil }
        let candidates = store.categories.filter { $0.kind == kind && !$0.isHidden && !Category.systemIDs.contains($0.id) }
        return (candidates.first { $0.name.searchKey == key }
            ?? candidates.first { $0.name.searchKey.contains(key) || key.contains($0.name.searchKey) })?.id
    }

    /// Every category id the names mean: a group stands for its items too.
    static func categoryIDs(_ names: [String], in store: FinanceStore) -> Set<String> {
        var ids = Set<String>()
        for name in names {
            let key = name.searchKey
            for category in store.categories where category.name.searchKey == key
                || category.name.searchKey.contains(key) || key.contains(category.name.searchKey) {
                ids.insert(category.id)
            }
        }
        return ids
    }
}

/// The categories and accounts a tool's arguments narrow to.
struct ToolFilters {
    let categoryIDs: Set<String>?
    let accountIDs: Set<Account.ID>?
    let store: FinanceStore

    init(_ arguments: JSONValue, store: FinanceStore) {
        self.store = store
        let categories = arguments["categories"]?.strings ?? []
        categoryIDs = categories.isEmpty ? nil : ToolNames.categoryIDs(categories, in: store)
        let accounts = arguments["accounts"]?.strings ?? []
        accountIDs = accounts.isEmpty ? nil : Set(accounts.compactMap { ToolNames.account($0, in: store)?.id })
    }

    func apply(to items: [FinanceTransaction]) -> [FinanceTransaction] {
        items.filter { transaction in
            if let categoryIDs, !categoryIDs.contains(transaction.categoryID),
               !categoryIDs.contains(store.groupID(of: transaction.categoryID)) { return false }
            if let accountIDs, !accountIDs.contains(transaction.accountID) { return false }
            return true
        }
    }
}
