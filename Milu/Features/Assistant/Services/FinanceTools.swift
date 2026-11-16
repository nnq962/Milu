import Foundation

// The rest of the user's money for Trợ lý AI (user request 2026-11-15: "hỏi về tất cả các thông
// tin về tài chính"): the spending limits, savings goals, recurring transactions, what falls due,
// month against month, and transfers. Each reads what the app's own pages show, worked out the way
// they do, and gives back only what the question needs. `say` is one sentence of the main figures,
// already written: the model gave a part for the whole when left to add them up (eval 2026-11-15).

// MARK: - Hạn mức chi tiêu

/// The month's spending limit and each group's, as Hạn mức chi tiêu shows them.
struct GetBudget: AssistantTool {
    /// Where the limits are kept (`@AppStorage`); another in tests.
    var defaults = UserDefaults.standard
    let name = "get_budget"
    let description = """
        Hạn mức chi tiêu: hạn mức cả tháng và từng nhóm hạng mục, đã chi bao nhiêu, còn tiêu được bao nhiêu, \
        mỗi ngày còn được tiêu bao nhiêu đến hết tháng, nhóm nào sắp chạm hay đã vượt. Dùng cho "còn tiêu được \
        bao nhiêu", "có vượt hạn mức không", "hạn mức ăn uống còn bao nhiêu". Trung bình mỗi ngày đã tiêu thì \
        dùng summarize_transactions.
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "month": ["type": "string", "description": "Tháng, YYYY-MM; bỏ trống là tháng này"],
        ],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        let start = arguments["month"]?.string.flatMap(ToolDates.month) ?? .now
        let month = DateInterval.month(of: start)
        let label = ToolDates.monthName(month.start)
        let limit = defaults.double(forKey: StorageKey.monthlyBudget)
        let spent = store.total(.expense, in: month)
        guard limit > 0 else {
            return ToolOutput(result: [
                "month": .string(label),
                "hasLimit": false,
                "spent": ToolMoney.value(spent),
                "say": .string("Bạn chưa đặt hạn mức chi tiêu; \(label) đã chi \(spent.vnd)."),
                "where": "Đặt ở Cài đặt → Hạn mức chi tiêu",
            ])
        }
        let progress = BudgetProgress(limit: limit, spent: spent)
        // A month that is over has money left over, not money still to spend, and is never "near"
        // its limit (audit round 2, 2026-11-15), as Hạn mức chi tiêu says it.
        let isOver = month.end <= .now
        var result: [String: JSONValue] = [
            "month": .string(label),
            "hasLimit": true,
            "limit": ToolMoney.value(limit),
            "spent": ToolMoney.value(spent),
            "used": .string(progress.percentText),
            "status": .string(Self.status(progress, monthOver: isOver)),
        ]
        // What went out a day so far, beside what may go out a day from now: asked "mỗi ngày tiêu
        // trung bình bao nhiêu", the model picked this tool (eval 2026-11-15).
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? month.end
        if let gone = calendar.dateComponents([.day], from: month.start, to: min(month.end, tomorrow)).day, gone > 0 {
            result["spentPerDaySoFar"] = ToolMoney.value(spent / Double(gone))
        }
        var say = "\(label.prefix(1).uppercased() + label.dropFirst()): đã chi \(spent.vnd) trên hạn mức \(limit.vnd) (\(progress.percentText)), "
        if progress.isOver {
            result["over"] = ToolMoney.value(-progress.left)
            say += "vượt \((-progress.left).vnd)."
        } else if isOver {
            result["left"] = ToolMoney.value(progress.left)
            say += "còn dư \(progress.left.vnd)."
        } else {
            result["left"] = ToolMoney.value(progress.left)
            say += "còn tiêu được \(progress.left.vnd)"
            if let daily = progress.dailyAllowance(in: month.start) {
                result["allowedPerDayToMonthEnd"] = ToolMoney.value(daily)
                say += ", khoảng \(daily.rounded().vnd) mỗi ngày đến hết tháng"
            }
            say += "."
        }
        result["say"] = .string(say)
        let groupLimits = (defaults.string(forKey: StorageKey.categoryBudgets).flatMap(CategoryBudgets.init(rawValue:))
            ?? CategoryBudgets()).keeping(store.budgetGroupIDs)
        let groups = groupLimits.limits.map { id, groupLimit -> (String, BudgetProgress) in
            let used = store.expenses(inGroup: id, in: month).reduce(0) { $0 + $1.amount }
            return (store.categoryName(id), BudgetProgress(limit: groupLimit, spent: used))
        }
        .sorted { $0.1.ratio > $1.1.ratio }
        if !groups.isEmpty {
            result["groups"] = .array(groups.map { name, progress in
                [
                    "name": .string(name),
                    "limit": ToolMoney.value(progress.limit),
                    "spent": ToolMoney.value(progress.spent),
                    progress.isOver ? "over" : "left": ToolMoney.value(abs(progress.left)),
                    "used": .string(progress.percentText),
                    "status": .string(Self.status(progress, monthOver: isOver)),
                ]
            })
        }
        return ToolOutput(result: .object(result))
    }

    /// As Hạn mức chi tiêu colours it: amber from 80%, red over.
    private static func status(_ progress: BudgetProgress, monthOver: Bool) -> String {
        if progress.isOver { return "đã vượt" }
        if monthOver { return "trong hạn mức" }
        return progress.isNearing ? "sắp chạm (từ 80%)" : "ổn"
    }
}

// MARK: - Hũ tiết kiệm

/// The savings goals: what each holds, its target, and what it still needs by its deadline.
struct GetSavingsGoals: AssistantTool {
    let name = "get_savings_goals"
    let description = """
        Các hũ tiết kiệm: tên, đã để dành bao nhiêu, mục tiêu, còn thiếu bao nhiêu, đạt bao nhiêu phần trăm, \
        hạn, mỗi tháng cần để thêm bao nhiêu cho kịp hạn, tháng này đã nạp, rút bao nhiêu. Dùng cho câu hỏi về \
        hũ, quỹ, tiết kiệm cho mục tiêu. Nạp, rút hũ của tháng khác thì dùng list_transfers.
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "include_completed": ["type": "boolean", "description": "true để kể cả các hũ đã hoàn thành, đã đóng"],
        ],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        let goals = store.activeGoals
        // This month's moves in and out: "tháng này bỏ vào hũ bao nhiêu" came here (eval 2026-11-15).
        let month = DateInterval.month(of: .now)
        let moves = store.goalTransfers.filter { month.holds($0.date) }
        func moved(_ direction: GoalTransfer.Direction, _ goal: SavingsGoal.ID? = nil) -> Double {
            moves.filter { $0.direction == direction && (goal == nil || $0.goalID == goal) }.reduce(0) { $0 + $1.amount }
        }
        var result: [String: JSONValue] = [
            "count": .number(Double(goals.count)),
            "totalSaved": ToolMoney.value(store.totalSaved),
            "thisMonthIn": ToolMoney.value(moved(.deposit)),
            "thisMonthOut": ToolMoney.value(moved(.withdrawal)),
            "goals": .array(goals.map { goal -> JSONValue in
                var item: [String: JSONValue] = [
                    "name": .string(goal.name),
                    "saved": ToolMoney.value(goal.saved),
                    "target": ToolMoney.value(goal.target),
                    "missing": ToolMoney.value(goal.remaining),
                    "progress": .string(goal.progressText),
                    "status": .string(goal.isReached ? "đã đủ" : goal.isOverdue ? "quá hạn, còn thiếu" : "đang để dành"),
                ]
                let goalIn = moved(.deposit, goal.id), goalOut = moved(.withdrawal, goal.id)
                if goalIn > 0 { item["thisMonthIn"] = ToolMoney.value(goalIn) }
                if goalOut > 0 { item["thisMonthOut"] = ToolMoney.value(goalOut) }
                if let due = goal.dueDate {
                    item["dueDate"] = .string(ToolDates.text(due))
                    if !goal.isReached, !goal.isOverdue {
                        item["perMonthToReach"] = ToolMoney.value(SavingsGoal.monthlySaving(remaining: goal.remaining, until: due))
                    }
                }
                return .object(item)
            }),
        ]
        if goals.isEmpty {
            result["note"] = "Chưa có hũ nào đang mở; tạo ở tab Tài khoản"
        }
        if arguments["include_completed"] == true || arguments["include_completed"]?.string == "true" {
            result["completed"] = .array(store.completedGoals.prefix(10).map { goal in
                [
                    "name": .string(goal.name),
                    "target": ToolMoney.value(goal.target),
                    "closedOn": goal.closedAt.map { .string(ToolDates.text($0)) } ?? .null,
                ]
            })
        }
        return ToolOutput(result: .object(result))
    }
}

// MARK: - Giao dịch định kỳ

/// The recurring transactions: bills, rent, salary, subscriptions, and what they come to a month.
struct GetRecurring: AssistantTool {
    let name = "get_recurring"
    let description = """
        Các giao dịch định kỳ người dùng đã đặt (tiền nhà, điện nước, lương, gói đăng ký…): số tiền, lặp lại \
        thế nào, lần tới ngày nào, tài khoản, đang chạy hay tạm dừng, và tổng chi, thu định kỳ quy ra mỗi tháng. \
        Dùng cho "mỗi tháng phải trả cố định bao nhiêu", "có những khoản định kỳ nào".
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "kind": ["type": "string", "enum": ["expense", "income"], "description": "Bỏ trống là cả hai"],
        ],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        let kind = arguments["kind"]?.string.flatMap(TransactionKind.init(rawValue:))
        let rules = store.recurringRules.filter { kind == nil || $0.kind == kind }
        var perMonth: [TransactionKind: Double] = [:]
        let items = rules.map { rule -> (Date?, JSONValue) in
            let next = rule.isPaused ? nil : store.nextDue(rule)
            let state = rule.isPaused ? "tạm dừng" : next == nil ? "đã kết thúc" : "đang chạy"
            if state == "đang chạy" { perMonth[rule.kind, default: 0] += Self.monthly(rule) }
            var item: [String: JSONValue] = [
                "name": .string(Self.title(rule, in: store)),
                "category": .string(store.categoryName(rule.categoryID)),
                "kind": .string(rule.kind.rawValue),
                "amount": ToolMoney.value(rule.amount),
                "repeats": .string(rule.scheduleDetail()),
                "account": .string(store.account(id: rule.accountID)?.name ?? ""),
                "state": .string(state),
            ]
            // The rule's date as it counts it, in any time zone (audit round 4, 2026-11-16: abroad
            // Milu named the day before).
            if let next { item["next"] = .string(ToolDates.text(RecurringRule.localDate(of: next, hour: 12) ?? next)) }
            if rule.autoRecords { item["autoRecords"] = true }
            return (next, .object(item))
        }
        .sorted { ($0.0 ?? .distantFuture) < ($1.0 ?? .distantFuture) }
        let expense = perMonth[.expense] ?? 0
        let income = perMonth[.income] ?? 0
        var say = rules.isEmpty ? "Bạn chưa đặt giao dịch định kỳ nào." : "Có \(rules.count) giao dịch định kỳ"
        if !rules.isEmpty {
            var parts: [String] = []
            if kind != .income { parts.append("chi cố định khoảng \(expense.rounded().vnd) mỗi tháng") }
            if kind != .expense, income > 0 { parts.append("thu cố định khoảng \(income.rounded().vnd) mỗi tháng") }
            say += parts.isEmpty ? "." : ": " + parts.joined(separator: ", ") + "."
        }
        return ToolOutput(result: [
            "count": .number(Double(rules.count)),
            "monthlyExpense": ToolMoney.value(expense),
            "monthlyIncome": ToolMoney.value(income),
            "say": .string(say),
            "items": .array(items.prefix(20).map(\.1)),
        ])
    }

    /// Its note's first line, else its category's name.
    static func title(_ rule: RecurringRule, in store: FinanceStore) -> String {
        let note = rule.note.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespaces) ?? ""
        return note.isEmpty ? store.categoryName(rule.categoryID) : note
    }

    /// What it comes to in an average month.
    static func monthly(_ rule: RecurringRule) -> Double {
        let perStep: Double = switch rule.frequency {
        case .daily: 365.25 / 12
        case .weekly: 365.25 / 12 / 7
        case .monthly: 1
        case .yearly: 1.0 / 12
        }
        return rule.amount * perStep / Double(max(rule.interval, 1))
    }
}

// MARK: - Sắp đến hạn

/// What falls due in the days ahead, or is already late: recurring days, loans, goals.
struct GetUpcoming: AssistantTool {
    let name = "get_upcoming"
    let description = """
        Những khoản sắp đến hạn hoặc đã quá hạn: ngày giao dịch định kỳ tới (hoá đơn, tiền nhà, lương), hạn trả \
        hay hạn thu các khoản vay, hạn các hũ tiết kiệm. Dùng cho "sắp tới phải trả gì", "tuần này có khoản nào", \
        "có gì quá hạn không".
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "days": ["type": "integer", "description": "Số ngày tới, mặc định 14, tối đa 90"],
        ],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        let days = ToolArgs.int(arguments["days"], default: 14, in: 1...90)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let horizon = calendar.date(byAdding: .day, value: days, to: today) ?? today
        var entries: [(date: Date, item: [String: JSONValue])] = []
        var toPay = 0.0
        var toReceive = 0.0

        // Recurring days left unconfirmed, then those to come, each on the rule's date as it
        // counts it, in any time zone (audit round 4, 2026-11-16: abroad, one day early).
        let ruleDay = { (day: Date) in RecurringRule.localDate(of: day, hour: 12) ?? day }
        // Every time still waiting, not one: three months of rent unconfirmed are three (audit
        // round 4, 2026-11-16: told as one, and left out of what is to pay).
        for occurrence in store.waitingRecurring() where RecurringRule.daysFromToday(occurrence.day) < 0 {
            let rule = occurrence.rule
            let times = occurrence.moreWaiting + 1
            let total = rule.amount * Double(times)
            if rule.kind == .expense { toPay += total } else { toReceive += total }
            entries.append((ruleDay(occurrence.day), [
                "type": "định kỳ chưa xác nhận",
                "name": .string(GetRecurring.title(rule, in: store)),
                "kind": .string(rule.kind.rawValue),
                "amount": ToolMoney.value(rule.amount),
                "times": .number(Double(times)),
                "total": ToolMoney.value(total),
                "late": true,
            ]))
        }
        for occurrence in store.dueRecurring(days: days) {
            let rule = occurrence.rule
            if rule.kind == .expense { toPay += rule.amount } else { toReceive += rule.amount }
            var item: [String: JSONValue] = [
                "type": "định kỳ",
                "name": .string(GetRecurring.title(rule, in: store)),
                "kind": .string(rule.kind.rawValue),
                "amount": ToolMoney.value(rule.amount),
            ]
            if rule.autoRecords { item["autoRecords"] = true }
            entries.append((ruleDay(occurrence.day), item))
        }
        for loan in store.loans where !loan.isSettled {
            guard let due = loan.dueDate, calendar.startOfDay(for: due) <= horizon else { continue }
            let lent = loan.direction == .lent
            if lent { toReceive += loan.outstanding } else { toPay += loan.outstanding }
            entries.append((due, [
                "type": .string(lent ? "hạn thu nợ (người khác trả mình)" : "hạn trả nợ (mình trả người khác)"),
                "name": .string(loan.name),
                "amount": ToolMoney.value(loan.outstanding),
                "late": .bool(calendar.startOfDay(for: due) < today),
            ]))
        }
        for goal in store.activeGoals where !goal.isReached {
            guard let due = goal.dueDate, calendar.startOfDay(for: due) <= horizon else { continue }
            entries.append((due, [
                "type": "hạn hũ tiết kiệm",
                "name": .string(goal.name),
                "missing": ToolMoney.value(goal.remaining),
                "late": .bool(goal.isOverdue),
            ]))
        }
        entries.sort { $0.date < $1.date }
        let shown = entries.prefix(20).map { entry -> JSONValue in
            var item = entry.item
            item["date"] = .string(ToolDates.text(entry.date))
            return .object(item)
        }
        var say = entries.isEmpty
            ? "Không có khoản nào đến hạn trong \(days) ngày tới."
            : "Trong \(days) ngày tới: phải trả khoảng \(toPay.vnd), sẽ nhận khoảng \(toReceive.vnd)."
        // What is already late, said first-hand: the model told a debt due two days ago as coming
        // (eval 2026-11-15).
        let late = entries.filter { $0.item["late"] == true }
        if !late.isEmpty {
            say += " Đã quá hạn: " + late.map { entry in
                let name = entry.item["name"]?.string ?? ""
                let times = entry.item["times"]?.number ?? 1
                let what = times > 1 ? "\(name): \(Int(times)) lần, \((entry.item["total"]?.number ?? 0).vnd)" : name
                return "\(what) (từ \(ToolDates.shortDay(entry.date)))"
            }.joined(separator: ", ") + "."
        }
        return ToolOutput(result: [
            "days": .number(Double(days)),
            "from": .string(ToolDates.text(today)),
            "to": .string(ToolDates.text(horizon)),
            "count": .number(Double(entries.count)),
            "toPay": ToolMoney.value(toPay),
            "toReceive": ToolMoney.value(toReceive),
            "say": .string(say),
            "items": .array(shown),
        ])
    }
}

// MARK: - Các tháng

/// Month against month: money in and out, what was kept, and net worth at each month's end.
struct GetMonthlyTrend: AssistantTool {
    let name = "get_monthly_trend"
    let description = """
        Thu, chi, để dành được (thu trừ chi), tỉ lệ để dành và tài sản ròng cuối tháng của từng tháng gần đây, \
        kèm trung bình mỗi tháng và tháng chi nhiều nhất, ít nhất. Dùng cho so sánh nhiều tháng, xu hướng, \
        "trung bình mỗi tháng tiêu bao nhiêu", "tài sản tăng hay giảm", "tháng nào tiêu nhiều nhất".
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "months": ["type": "integer", "description": "Số tháng gần nhất, tính cả tháng này; mặc định 6, tối đa 24"],
        ],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        let count = ToolArgs.int(arguments["months"], default: 6, in: 2...24)
        // Months before the first transaction are left out: their nothing is no month of spending.
        let first = store.transactions.map(\.date).min().map { DateInterval.month(of: $0).start }
        let points = store.netWorthHistory(months: count).filter { point in first.map { point.month >= $0 } ?? true }
        let thisMonth = DateInterval.month(of: .now).start
        struct Row { let label: String; let income: Double; let expense: Double; let partial: Bool }
        let rows = points.map { point -> Row in
            let items = store.reportableTransactions(in: .month(of: point.month))
            return Row(label: ToolDates.monthName(point.month), income: store.total(.income, of: items),
                       expense: store.total(.expense, of: items), partial: point.month >= thisMonth)
        }
        let months: [JSONValue] = zip(points, rows).map { point, row in
            var item: [String: JSONValue] = [
                "month": .string(row.label),
                "income": ToolMoney.value(row.income),
                "expense": ToolMoney.value(row.expense),
                "kept": ToolMoney.value(row.income - row.expense),
                "netWorthEnd": ToolMoney.value(point.value),
            ]
            if row.income > 0 { item["keptRate"] = .string(((row.income - row.expense) / row.income).percentText) }
            if row.partial { item["note"] = "tháng này, tính đến hôm nay" }
            return .object(item)
        }
        var result: [String: JSONValue] = ["months": .array(months)]
        // Averages and extremes over whole months; this month is not over yet.
        let whole = rows.filter { !$0.partial }
        // Spending averaged over the months that had some, as Báo cáo's "chi trung bình" does: a
        // first month with only a salary pulled it down, and the two disagreed (audit round 4,
        // 2026-11-16).
        let spending = whole.filter { $0.expense > 0 }
        if !whole.isEmpty {
            let averageIncome = whole.reduce(0) { $0 + $1.income } / Double(whole.count)
            let averageExpense = spending.isEmpty ? 0 : spending.reduce(0) { $0 + $1.expense } / Double(spending.count)
            result["averageOfWholeMonths"] = [
                "months": .number(Double(whole.count)),
                "monthsWithSpending": .number(Double(spending.count)),
                "income": ToolMoney.value(averageIncome),
                "expense": ToolMoney.value(averageExpense),
            ]
            // Over how many months, said: "trung bình 6 tháng" was told of two (eval 2026-11-15).
            result["sayAverage"] = .string("""
                Trung bình \(spending.count) tháng trọn gần đây có chi tiêu (không tính tháng này): chi \
                \(averageExpense.rounded().vnd) mỗi tháng; thu trung bình \(averageIncome.rounded().vnd) mỗi tháng \
                qua \(whole.count) tháng.
                """)
            if let most = whole.max(by: { $0.expense < $1.expense }), let least = whole.min(by: { $0.expense < $1.expense }) {
                result["mostSpent"] = ["month": .string(most.label), "expense": ToolMoney.value(most.expense)]
                result["leastSpent"] = ["month": .string(least.label), "expense": ToolMoney.value(least.expense)]
            }
        }
        if let firstPoint = points.first, let last = points.last, points.count > 1 {
            let change = last.value - firstPoint.value
            result["netWorthChange"] = ToolMoney.value(change)
            result["say"] = .string("Tài sản ròng \(change >= 0 ? "tăng" : "giảm") \(abs(change).vnd) từ cuối \(ToolDates.monthName(firstPoint.month)) đến nay (giờ là \(last.value.vnd)).")
        }
        return ToolOutput(result: .object(result))
    }
}

// MARK: - Chuyển tiền

/// Money moved between the user's own accounts (with its fee) and into or out of savings goals.
struct ListTransfers: AssistantTool {
    let name = "list_transfers"
    let description = """
        Các lần chuyển tiền giữa các tài khoản của chính người dùng (kèm phí chuyển) và nạp, rút tiền ở hũ tiết \
        kiệm, trong một khoảng ngày. Đây không phải chi tiêu. Dùng cho "chuyển bao nhiêu từ Vietcombank sang \
        MoMo", "tháng này bỏ vào hũ bao nhiêu", "phí chuyển khoản hết bao nhiêu".
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "from": ["type": "string", "description": "Ngày đầu, YYYY-MM-DD"],
            "to": ["type": "string", "description": "Ngày cuối (tính cả ngày này), YYYY-MM-DD"],
            "type": ["type": "string", "enum": ["account", "goal"], "description": "account: giữa tài khoản; goal: nạp, rút hũ; bỏ trống là cả hai"],
            "account": ["type": "string", "description": "Tên tài khoản hoặc hũ; bỏ trống là tất cả"],
            "limit": ["type": "integer", "description": "Tối đa 20, mặc định 10"],
        ],
        "required": ["from", "to"],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        guard let interval = ToolDates.interval(arguments) else { return .failure("Ngày không hợp lệ, cần YYYY-MM-DD") }
        let type = arguments["type"]?.string
        // The account or goal named, matched as recording matches names (exact first): "ví" is the
        // wallet, not Vietcombank.
        let name = arguments["account"]?.string ?? ""
        // Every account the name may mean, archived too ("Vietcombank" for two of them).
        let accounts = name.isEmpty ? [] : ToolNames.readableAccountIDs(name, in: store)
        let goal = ToolNames.goal(name, in: store)
        if !name.isEmpty, accounts.isEmpty, goal == nil {
            return .failure("Không có tài khoản hay hũ nào tên \(name)")
        }
        func matches(_ accountIDs: Account.ID..., goal goalID: SavingsGoal.ID? = nil) -> Bool {
            guard !name.isEmpty else { return true }
            return accountIDs.contains { accounts.contains($0) } || (goalID != nil && goalID == goal?.id)
        }
        func accountName(_ id: Account.ID) -> String { store.account(id: id)?.name ?? "Tài khoản đã xoá" }

        var entries: [(date: Date, item: JSONValue)] = []
        var moved = 0.0, fees = 0.0, deposited = 0.0, withdrawn = 0.0
        if type != "goal" {
            for transfer in store.accountTransfers where interval.holds(transfer.date) {
                let from = accountName(transfer.fromAccountID), to = accountName(transfer.toAccountID)
                guard matches(transfer.fromAccountID, transfer.toAccountID) else { continue }
                moved += transfer.amount
                fees += transfer.fee
                entries.append((transfer.date, [
                    "date": .string(ToolDates.text(transfer.date)),
                    "type": "chuyển giữa tài khoản",
                    "from": .string(from), "to": .string(to),
                    "amount": ToolMoney.value(transfer.amount),
                    "fee": ToolMoney.value(transfer.fee),
                    "note": .string(transfer.note),
                ]))
            }
        }
        if type != "account" {
            for transfer in store.goalTransfers where interval.holds(transfer.date) {
                guard matches(transfer.accountID, goal: transfer.goalID) else { continue }
                let goalName = store.goal(id: transfer.goalID)?.name ?? "Hũ đã xoá"
                let accountName = accountName(transfer.accountID)
                let deposit = transfer.direction == .deposit
                if deposit { deposited += transfer.amount } else { withdrawn += transfer.amount }
                entries.append((transfer.date, [
                    "date": .string(ToolDates.text(transfer.date)),
                    "type": .string(deposit ? "nạp vào hũ" : "rút từ hũ"),
                    "from": .string(deposit ? accountName : goalName), "to": .string(deposit ? goalName : accountName),
                    "amount": ToolMoney.value(transfer.amount),
                    "note": .string(transfer.note),
                ]))
            }
        }
        entries.sort { $0.date > $1.date }
        let limit = ToolArgs.int(arguments["limit"], default: 10, in: 1...20)
        return ToolOutput(result: [
            "count": .number(Double(entries.count)),
            "betweenAccounts": ToolMoney.value(moved),
            "fees": ToolMoney.value(fees),
            "intoGoals": ToolMoney.value(deposited),
            "outOfGoals": ToolMoney.value(withdrawn),
            "transfers": .array(entries.prefix(limit).map(\.item)),
        ])
    }
}

// MARK: - Helpers

extension ToolNames {
    /// An open savings goal by name: exact first, then one inside the other, without accents.
    static func goal(_ name: String?, in store: FinanceStore) -> SavingsGoal? {
        guard let key = name?.searchKey, !key.isEmpty else { return nil }
        return store.savingsGoals.first { $0.name.searchKey == key }
            ?? store.savingsGoals.first { $0.name.searchKey.contains(key) || key.contains($0.name.searchKey) }
    }
}

extension ToolDates {
    /// "2026-11" (or a whole day in it) → its first day.
    static func month(_ text: String) -> Date? {
        let parts = text.prefix(7).split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2, (1...12).contains(parts[1]) else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: 1))
    }

    /// "10/11", or "10/11/2025" in another year.
    static func shortDay(_ date: Date) -> String {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.day, .month, .year], from: date)
        let sameYear = parts.year == calendar.component(.year, from: .now)
        return "\(parts.day ?? 1)/\(parts.month ?? 1)" + (sameYear ? "" : "/\(parts.year ?? 0)")
    }

    /// "tháng 11", or "tháng 11/2025" in another year.
    static func monthName(_ date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        return year == calendar.component(.year, from: .now) ? "tháng \(month)" : "tháng \(month)/\(year)"
    }
}
