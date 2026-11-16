import Foundation
import Testing
@testable import Milu

/// The tools that read the rest of the user's money (`FinanceTools`): the limits, savings goals,
/// recurring transactions, what falls due, month against month, transfers, and the richer
/// accounts, loans and totals. Each builds a store of its own in memory.
@MainActor
struct FinanceToolsTests {
    private let wallet = Account(name: "Ví", type: .cash, balance: 3_000_000)
    private let bank = Account(name: "Vietcombank", type: .bank, balance: 10_000_000)
    private let calendar = Calendar.current

    private func makeStore(transactions: [FinanceTransaction] = [], loans: [Loan] = [],
                           goals: [SavingsGoal] = []) -> FinanceStore {
        FinanceStore(accounts: [wallet, bank], transactions: transactions, loans: loans, paymentReminders: [],
                     savingsGoals: goals, goalTransfers: [], contacts: [])
    }

    private func spend(_ amount: Double, _ category: String, daysAgo: Int = 0) -> FinanceTransaction {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        return FinanceTransaction(amount: amount, categoryID: category, kind: .expense, accountID: wallet.id, date: date)
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .now)) ?? .now
    }

    // MARK: Every tool

    /// With the sample data, every reading tool answers and fits what the server passes on.
    @Test func everyReadingToolFits() {
        let store = FinanceStore()
        let today = ToolDates.text(.now)
        let monthStart = ToolDates.text(DateInterval.month(of: .now).start)
        let range: JSONValue = ["from": .string(monthStart), "to": .string(today)]
        for tool in AssistantTools.all where ![RecordTransaction().name, DeleteTransaction().name].contains(tool.name) {
            let arguments: JSONValue = switch tool.name {
            case SummarizeTransactions().name: ["from": .string(monthStart), "to": .string(today), "kind": "expense"]
            case ListTransactions().name, ListTransfers().name: range
            case GetAppInfo().name: ["topic": "privacy"]
            default: [:]
            }
            let text = tool.run(arguments, in: store).result.jsonString
            #expect(text.count > 20, "\(tool.name)")
            #expect(text.count < 7_000, "\(tool.name): \(text.count)")
            #expect(!text.contains("\"ok\":false"), "\(tool.name): \(text.prefix(200))")
        }
    }

    // MARK: Hạn mức

    @Test func budgetSaysWhatIsLeftAndWhichGroupIsOver() throws {
        let defaults = try #require(UserDefaults(suiteName: "FinanceToolsTests.\(UUID().uuidString)"))
        defaults.set(2_000_000.0, forKey: StorageKey.monthlyBudget)
        defaults.set(CategoryBudgets(limits: ["food": 400_000]).rawValue, forKey: StorageKey.categoryBudgets)
        let store = makeStore(transactions: [spend(300_000, "food.lunch"), spend(200_000, "food.coffee"),
                                             spend(1_000_000, "shopping")])
        let result = GetBudget(defaults: defaults).run([:], in: store).result
        #expect(result["hasLimit"] == true)
        #expect(result["spent"] == 1_500_000)
        #expect(result["left"] == 500_000)
        #expect(result["used"]?.string == 0.75.percentText)
        #expect(result["allowedPerDayToMonthEnd"] != nil)
        #expect(result["spentPerDaySoFar"] == .number(1_500_000 / Double(Calendar.current.component(.day, from: .now))))
        let food = result["groups"].flatMap { groups -> JSONValue? in
            if case .array(let items) = groups { return items.first } else { return nil }
        }
        #expect(food?["name"]?.string == "Ăn uống")
        #expect(food?["over"] == 100_000)
        #expect(food?["status"]?.string == "đã vượt")
        #expect(result["say"]?.string?.contains("còn tiêu được 500.000đ") == true)
    }

    @Test func budgetWithoutALimitSaysSo() throws {
        let defaults = try #require(UserDefaults(suiteName: "FinanceToolsTests.\(UUID().uuidString)"))
        let result = GetBudget(defaults: defaults).run([:], in: makeStore(transactions: [spend(50_000, "food")])).result
        #expect(result["hasLimit"] == false)
        #expect(result["spent"] == 50_000)
    }

    // MARK: Hũ

    @Test func goalsSayWhatIsMissingAndWhatToPutAside() {
        let trip = SavingsGoal(name: "Du lịch Đà Lạt", icon: "", saved: 2_000_000, target: 5_000_000,
                               dueDate: calendar.date(byAdding: .month, value: 3, to: .now))
        let done = SavingsGoal(name: "Laptop", icon: "", saved: 20_000_000, target: 20_000_000)
        let store = makeStore(goals: [trip, done])
        store.goalTransfers = [GoalTransfer(goalID: trip.id, accountID: bank.id, direction: .deposit, amount: 300_000, date: .now)]
        let result = GetSavingsGoals().run([:], in: store).result
        #expect(result["count"] == 2)
        #expect(result["thisMonthIn"] == 300_000)
        #expect(result["totalSaved"] == 22_000_000)
        guard case .array(let goals)? = result["goals"] else { Issue.record("no goals"); return }
        #expect(goals[0]["missing"] == 3_000_000)
        #expect(goals[0]["perMonthToReach"] == 1_000_000)
        #expect(goals[1]["status"]?.string == "đã đủ")
    }

    // MARK: Định kỳ

    @Test func recurringComesToAMonth() {
        let start = day(3)
        let rent = RecurringRule(kind: .expense, amount: 5_000_000, categoryID: "bills", accountID: bank.id,
                                 note: "Tiền nhà", startDate: start)
        let gym = RecurringRule(kind: .expense, amount: 1_200_000, categoryID: "health", accountID: bank.id,
                                frequency: .yearly, startDate: start)
        let paused = RecurringRule(kind: .expense, amount: 9_000_000, categoryID: "bills", accountID: bank.id,
                                   startDate: start, pausedAt: .now)
        let store = makeStore()
        store.recurringRules = [rent, gym, paused]
        let result = GetRecurring().run([:], in: store).result
        #expect(result["count"] == 3)
        // The paused one does not count.
        #expect(result["monthlyExpense"] == 5_100_000)
        guard case .array(let items)? = result["items"] else { Issue.record("no items"); return }
        #expect(items[0]["name"]?.string == "Tiền nhà")
        #expect(items[0]["next"]?.string == ToolDates.text(start))
        #expect(items.last?["state"]?.string == "tạm dừng")
        #expect(GetRecurring.monthly(RecurringRule(kind: .expense, amount: 100_000, categoryID: "food", accountID: bank.id,
                                                   frequency: .weekly, startDate: .now)).rounded() == 434_821)
    }

    // MARK: Sắp đến hạn

    @Test func upcomingListsBillsAndLoansSoonestFirst() {
        let rent = RecurringRule(kind: .expense, amount: 5_000_000, categoryID: "bills", accountID: bank.id,
                                 note: "Tiền nhà", startDate: day(3))
        let owed = Loan(name: "Anh Tuấn", direction: .borrowed, principal: 2_000_000, outstanding: 2_000_000, dueDate: day(5))
        let late = Loan(name: "Lan", direction: .lent, principal: 1_000_000, outstanding: 600_000, dueDate: day(-2))
        let far = Loan(name: "Minh", direction: .borrowed, principal: 9_000_000, outstanding: 9_000_000, dueDate: day(60))
        let store = makeStore(loans: [owed, late, far])
        store.recurringRules = [rent]
        let result = GetUpcoming().run(["days": 14], in: store).result
        #expect(result["count"] == 3)
        #expect(result["toPay"] == 7_000_000)
        #expect(result["toReceive"] == 600_000)
        guard case .array(let items)? = result["items"] else { Issue.record("no items"); return }
        #expect(items.map { $0["name"]?.string } == ["Lan", "Tiền nhà", "Anh Tuấn"])
        #expect(items[0]["late"] == true)
        #expect(result["say"]?.string?.hasSuffix("Đã quá hạn: Lan (từ \(ToolDates.shortDay(day(-2))))."
            ) == true)
    }

    // MARK: Các tháng

    @Test func monthlyTrendAveragesWholeMonthsOnly() {
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: DateInterval.month(of: .now).start) ?? .now
        let daysAgo = calendar.dateComponents([.day], from: lastMonth, to: .now).day ?? 30
        let salary = FinanceTransaction(amount: 20_000_000, categoryID: "salary", kind: .income, accountID: bank.id,
                                        date: lastMonth.addingTimeInterval(3_600 * 12))
        let store = makeStore(transactions: [salary, spend(8_000_000, "shopping", daysAgo: daysAgo - 1),
                                             spend(1_000_000, "food")])
        let result = GetMonthlyTrend().run(["months": 6], in: store).result
        // From the first transaction's month: last month and this one.
        guard case .array(let months)? = result["months"] else { Issue.record("no months"); return }
        #expect(months.count == 2)
        #expect(months[0]["kept"] == 12_000_000)
        #expect(months[0]["keptRate"]?.string == 0.6.percentText)
        #expect(months[1]["note"] != nil)
        #expect(result["averageOfWholeMonths"]?["expense"] == 8_000_000)
        #expect(result["mostSpent"]?["expense"] == 8_000_000)
        #expect(result["sayAverage"]?.string?.hasPrefix("Trung bình 1 tháng trọn gần đây có chi tiêu") == true)
    }

    // MARK: Chuyển tiền

    @Test func transfersCountMovesFeesAndGoals() {
        let trip = SavingsGoal(name: "Du lịch", icon: "", saved: 1_000_000, target: 5_000_000)
        let store = makeStore(goals: [trip])
        store.accountTransfers = [AccountTransfer(fromAccountID: bank.id, toAccountID: wallet.id, amount: 1_000_000,
                                                  fee: 3_300, date: day(-1))]
        store.goalTransfers = [GoalTransfer(goalID: trip.id, accountID: bank.id, direction: .deposit, amount: 500_000,
                                            date: day(-2))]
        let range: JSONValue = ["from": .string(ToolDates.text(day(-7))), "to": .string(ToolDates.text(.now))]
        let all = ListTransfers().run(range, in: store).result
        #expect(all["count"] == 2)
        #expect(all["betweenAccounts"] == 1_000_000)
        #expect(all["fees"] == 3_300)
        #expect(all["intoGoals"] == 500_000)
        var onlyGoal = range
        if case .object(var fields) = onlyGoal { fields["type"] = "goal"; onlyGoal = .object(fields) }
        #expect(ListTransfers().run(onlyGoal, in: store).result["count"] == 1)
        var walletOnly = range
        if case .object(var fields) = walletOnly { fields["account"] = "ví"; walletOnly = .object(fields) }
        #expect(ListTransfers().run(walletOnly, in: store).result["count"] == 1)
    }

    // MARK: Tài khoản, vay, tổng

    @Test func accountsSplitCardDebtFromLoans() {
        let card = Account(name: "Thẻ Visa", type: .credit, balance: -4_000_000)
        let store = FinanceStore(accounts: [wallet, bank, card], transactions: [],
                                 loans: [Loan(name: "Tuấn", direction: .borrowed, principal: 1_000_000, outstanding: 1_000_000)],
                                 paymentReminders: [], savingsGoals: [], goalTransfers: [], contacts: [])
        let result = GetAccounts().run([:], in: store).result
        #expect(result["creditDebt"] == 4_000_000)
        #expect(result["borrowed"] == 1_000_000)
        #expect(result["moneyOnHand"] == 13_000_000)
        #expect(result["netWorth"] == 8_000_000)
    }

    @Test func loansTellPaidAndLateAndSettledOnAsk() {
        let late = Loan(name: "Lan", direction: .lent, principal: 1_000_000, outstanding: 600_000, dueDate: day(-2))
        let done = Loan(name: "Hùng", direction: .lent, principal: 500_000, outstanding: 0)
        let store = makeStore(loans: [late, done])
        guard case .array(let open)? = GetLoans().run([:], in: store).result["loans"] else { Issue.record("no loans"); return }
        #expect(open.count == 1)
        #expect(open[0]["paid"] == 400_000)
        #expect(open[0]["late"] == true)
        guard case .array(let all)? = GetLoans().run(["include_settled": true], in: store).result["loans"] else {
            Issue.record("no loans"); return
        }
        #expect(all.count == 2)
    }

    /// "Nợ nần ra sao": the loans and the credit card owed, in one sentence.
    @Test func loansTellTheCardOwedToo() {
        let card = Account(name: "Thẻ Visa", type: .credit, balance: -4_000_000)
        let store = FinanceStore(accounts: [wallet, card], transactions: [],
                                 loans: [Loan(name: "Tuấn", direction: .borrowed, principal: 1_000_000, outstanding: 1_000_000),
                                         Loan(name: "Lan", direction: .lent, principal: 600_000, outstanding: 600_000)],
                                 paymentReminders: [], savingsGoals: [], goalTransfers: [], contacts: [])
        let result = GetLoans().run([:], in: store).result
        #expect(result["creditCardDebt"] == 4_000_000)
        #expect(result["say"]?.string == "Bạn còn nợ 5.000.000đ (đi vay 1.000.000đ, thẻ tín dụng 4.000.000đ); người khác còn nợ bạn 600.000đ.")
    }

    @Test func summaryAddsADayAndTheGroupsItems() {
        let store = makeStore(transactions: [spend(300_000, "food.lunch"), spend(200_000, "food.coffee")])
        let from = ToolDates.text(day(-9))
        let result = SummarizeTransactions().run(["from": .string(from), "to": .string(ToolDates.text(.now)),
                                                  "kind": "expense", "categories": ["Ăn uống"]], in: store).result
        #expect(result["perDay"] == 50_000)
        guard case .array(let items)? = result["byItem"] else { Issue.record("no items"); return }
        #expect(items.map { $0["name"]?.string } == ["Ăn trưa", "Cà phê"])
    }

    /// A number too large for an Int, or not a number, from the model: kept in range, no crash
    /// (audit round 3, 2026-11-16: `Int(1e20)` stopped the app).
    @Test func hugeNumbersFromTheModelAreKeptInRange() {
        #expect(ToolArgs.int(.number(1e20), default: 10, in: 1...20) == 20)
        #expect(ToolArgs.int(.number(-1e20), default: 10, in: 1...20) == 1)
        #expect(ToolArgs.int(.number(.nan), default: 10, in: 1...20) == 10)
        #expect(ToolArgs.int(nil, default: 10, in: 1...20) == 10)
        #expect(JSONValue.number(1e20).string == "1e+20")
        // The thinking step's words too, made before the tool runs (audit round 4, 2026-11-16).
        let step = ThinkingStep.tool(GetMonthlyTrend().name, arguments: ["months": .number(1e20)])
        #expect(step.done.contains("24 tháng"))
        _ = ThinkingStep.tool(GetMonthlyTrend().name, arguments: ["months": .number(.infinity)])
        let store = makeStore(transactions: [spend(100_000, "food.lunch")])
        let result = ListTransactions().run(["from": .string(ToolDates.text(day(-9))), "to": .string(ToolDates.text(.now)),
                                             "limit": .number(1e20)], in: store).result
        #expect(result["ok"] != false)
    }

    /// A name meaning two accounts reads both; one meaning none is said, not taken for 0đ (audit
    /// round 2, 2026-11-15: "chi bao nhiêu bằng Vietcombank" with two of them came out 0đ).
    @Test func aNameForSeveralAccountsReadsThemAll() {
        let salary = Account(name: "Vietcombank lương", type: .bank, balance: 0)
        let savings = Account(name: "Vietcombank tiết kiệm", type: .bank, balance: 0)
        let date = calendar.date(byAdding: .day, value: -1, to: .now) ?? .now
        let store = FinanceStore(accounts: [wallet, salary, savings], transactions: [
            FinanceTransaction(amount: 300_000, categoryID: "food.lunch", kind: .expense, accountID: salary.id, date: date),
            FinanceTransaction(amount: 200_000, categoryID: "food.lunch", kind: .expense, accountID: savings.id, date: date),
            FinanceTransaction(amount: 50_000, categoryID: "food.lunch", kind: .expense, accountID: wallet.id, date: date),
        ], loans: [], paymentReminders: [], savingsGoals: [], goalTransfers: [], contacts: [])
        let from = ToolDates.text(day(-9)), to = ToolDates.text(.now)
        let both = SummarizeTransactions().run(["from": .string(from), "to": .string(to), "kind": "expense",
                                                "accounts": ["Vietcombank"]], in: store).result
        #expect(both["total"] == 500_000)
        let none = SummarizeTransactions().run(["from": .string(from), "to": .string(to), "kind": "expense",
                                                "accounts": ["ACB"]], in: store).result
        #expect(none["ok"] == false)
        let listed = ListTransactions().run(["from": .string(from), "to": .string(to), "accounts": ["Vietcombank"]],
                                            in: store).result
        guard case .array(let rows)? = listed["transactions"] else { Issue.record("no rows"); return }
        #expect(rows.count == 2)
    }

    // MARK: Words

    @Test func monthsAreReadAndNamed() {
        let november = ToolDates.month("2026-11")
        #expect(november.map(ToolDates.text) == "2026-11-01")
        #expect(ToolDates.month("2026-13") == nil)
        #expect(ToolDates.month("2025-03-15").map(ToolDates.text) == "2025-03-01")
    }

    @Test func stepsSayWhatTheNewToolsDo() {
        #expect(ThinkingStep.tool("get_budget", arguments: [:]).done == "Đã xem hạn mức chi tiêu")
        #expect(ThinkingStep.tool("get_savings_goals", arguments: [:]).done == "Đã xem các hũ tiết kiệm")
        #expect(ThinkingStep.tool("get_monthly_trend", arguments: ["months": 3]).running == "Đang so sánh 3 tháng gần đây…")
        #expect(ThinkingStep.tool("get_upcoming", arguments: [:]).done == "Đã xem các khoản sắp đến hạn")
    }
}
