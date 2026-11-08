import Foundation
import Testing
@testable import Timi

/// The money rules: balances, transfers and their fees, loans and repayments, locked and archived
/// accounts. Each test builds an in-memory store (no database) with only the accounts it needs.
@MainActor
struct FinanceStoreTests {
    private let wallet = Account(name: "Ví", type: .cash, balance: 1_000_000)
    private let bank = Account(name: "Ngân hàng", type: .bank, balance: 5_000_000)

    private func makeStore(_ accounts: [Account]? = nil, loans: [Loan] = []) -> FinanceStore {
        FinanceStore(accounts: accounts ?? [wallet, bank], transactions: [], loans: loans,
                     paymentReminders: [], savingsGoals: [])
    }

    private func balance(_ store: FinanceStore, _ account: Account) -> Double {
        store.account(id: account.id)?.balance ?? .nan
    }

    private func expense(_ amount: Double, on account: Account, date: Date = .now) -> FinanceTransaction {
        FinanceTransaction(amount: amount, category: .food, accountID: account.id, date: date)
    }

    // MARK: - Giao dịch

    @Test func addingAnExpenseTakesItFromTheAccount() {
        let store = makeStore()
        store.add(expense(200_000, on: wallet))
        #expect(balance(store, wallet) == 800_000)
        #expect(store.total(.expense) == 200_000)
    }

    @Test func deletingATransactionGivesTheMoneyBack() {
        let store = makeStore()
        let lunch = expense(200_000, on: wallet)
        store.add(lunch)
        store.delete(lunch)
        #expect(balance(store, wallet) == 1_000_000)
        #expect(store.transactions.isEmpty)
    }

    @Test func movingATransactionToAnotherAccountMovesTheMoney() {
        let store = makeStore()
        var lunch = expense(200_000, on: wallet)
        store.add(lunch)
        lunch.accountID = bank.id
        lunch.amount = 300_000
        store.update(lunch)
        #expect(balance(store, wallet) == 1_000_000)
        #expect(balance(store, bank) == 4_700_000)
    }

    @Test func excludedTransactionsStayOutOfTotals() {
        let store = makeStore()
        var gift = expense(500_000, on: wallet)
        gift.isExcluded = true
        store.add(gift)
        #expect(balance(store, wallet) == 500_000)
        #expect(store.total(.expense) == 0)
    }

    // MARK: - Chuyển khoản

    @Test func aTransferWithAFeeMovesBothBalancesAndCountsTheFee() {
        let store = makeStore()
        store.add(AccountTransfer(fromAccountID: bank.id, toAccountID: wallet.id, amount: 1_000_000, fee: 5_000, date: .now))
        #expect(balance(store, bank) == 3_995_000)
        #expect(balance(store, wallet) == 2_000_000)
        // The transfer itself is neither income nor spending; its fee is spending.
        #expect(store.total(.expense) == 5_000)
        #expect(store.total(.income) == 0)
        #expect(store.netWorth == 5_995_000)
    }

    @Test func deletingATransferUndoesIt() {
        let store = makeStore()
        let transfer = AccountTransfer(fromAccountID: bank.id, toAccountID: wallet.id, amount: 1_000_000, fee: 5_000, date: .now)
        store.add(transfer)
        store.delete(transfer)
        #expect(balance(store, bank) == 5_000_000)
        #expect(balance(store, wallet) == 1_000_000)
    }

    // MARK: - Vay nợ

    @Test func lendingTakesTheMoneyAndRepaymentsBringItBack() {
        let store = makeStore()
        let loan = Loan(name: "Minh", direction: .lent, principal: 2_000_000, outstanding: 2_000_000,
                        dueDate: nil, accountID: bank.id, monthlyInterestRate: 1.5)
        store.save(loan)
        #expect(balance(store, bank) == 3_000_000)
        // Lent money is still the user's: net worth does not change.
        #expect(store.netWorth == 6_000_000)

        store.save(LoanPayment(loanID: loan.id, principal: 500_000, interest: 30_000, accountID: wallet.id, date: .now))
        #expect(store.loan(id: loan.id)?.outstanding == 1_500_000)
        #expect(balance(store, wallet) == 1_530_000)
        // The interest is income; the principal is not.
        #expect(store.total(.income) == 30_000)
    }

    @Test func aRepaymentNeverTakesWhatIsLeftBelowZero() {
        let store = makeStore()
        let loan = Loan(name: "Minh", direction: .lent, principal: 1_000_000, outstanding: 1_000_000,
                        dueDate: nil, accountID: bank.id)
        store.save(loan)
        store.save(LoanPayment(loanID: loan.id, principal: 1_500_000, accountID: bank.id, date: .now))
        #expect(store.loan(id: loan.id)?.outstanding == 0)
        #expect(store.loan(id: loan.id)?.isSettled == true)
    }

    @Test func deletingARepaymentPutsTheDebtBack() {
        let store = makeStore()
        let loan = Loan(name: "Hùng", direction: .borrowed, principal: 3_000_000, outstanding: 3_000_000,
                        dueDate: nil, accountID: bank.id)
        store.save(loan)
        #expect(balance(store, bank) == 8_000_000)
        let payment = LoanPayment(loanID: loan.id, principal: 1_000_000, interest: 50_000, accountID: bank.id, date: .now)
        store.save(payment)
        #expect(balance(store, bank) == 6_950_000)
        #expect(store.total(.expense) == 50_000)
        store.delete(payment)
        #expect(balance(store, bank) == 8_000_000)
        #expect(store.loan(id: loan.id)?.outstanding == 3_000_000)
    }

    @Test func anExistingLoanMovesNoMoney() {
        let store = makeStore()
        store.save(Loan(name: "Lan", direction: .lent, principal: 4_000_000, outstanding: 4_000_000,
                        dueDate: nil, isExisting: true, accountID: bank.id))
        #expect(balance(store, bank) == 5_000_000)
        #expect(store.totalLent == 4_000_000)
    }

    // MARK: - Tài sản ròng theo tháng

    @Test func netWorthHistoryTakesBackLaterIncomeAndSpending() {
        let calendar = Calendar.current
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: .now)!
        let store = makeStore()
        store.add(FinanceTransaction(amount: 3_000_000, category: .salary, accountID: bank.id, date: lastMonth))
        store.add(expense(500_000, on: wallet))
        let history = store.netWorthHistory(months: 3)
        #expect(history.count == 3)
        #expect(history[2].value == 8_500_000)
        // Last month closed before today's 500k went out.
        #expect(history[1].value == 9_000_000)
        // Before the salary came in.
        #expect(history[0].value == 6_000_000)
    }

    @Test func transfersAndExistingLoansDoNotMoveTheHistory() {
        let store = makeStore()
        store.add(AccountTransfer(fromAccountID: bank.id, toAccountID: wallet.id, amount: 1_000_000, date: .now))
        store.save(Loan(name: "Lan", direction: .lent, principal: 2_000_000, outstanding: 2_000_000,
                        dueDate: nil, isExisting: true))
        let history = store.netWorthHistory(months: 2)
        #expect(history[0].value == history[1].value)
    }

    // MARK: - Khoá và lưu trữ

    @Test func lockedAccountsStayOutOfTotalsAndReports() {
        var savings = Account(name: "Tiết kiệm", type: .bank, balance: 10_000_000)
        savings.isLocked = true
        let store = makeStore([wallet, savings])
        store.add(expense(100_000, on: savings))
        #expect(store.netWorth == 1_000_000)
        #expect(store.total(.expense) == 0)
    }

    @Test func nothingNewIsRecordedOnAnArchivedAccount() {
        let store = makeStore()
        store.archive(bank)
        store.add(expense(100_000, on: bank))
        #expect(store.transactions.isEmpty)
        #expect(balance(store, bank) == 5_000_000)
    }
}

/// Trợ lý AI's allowance: 20 a month, then the bonus, each onboarding step paying 5 once.
@MainActor
struct AIQuotaTests {
    private func makeQuota() -> AIQuota {
        AIQuota(defaults: UserDefaults(suiteName: "AIQuotaTests.\(UUID().uuidString)")!)
    }

    @Test func aNewMonthStartsWithTheFreeAllowance() {
        let quota = makeQuota()
        #expect(quota.remaining == AIQuota.monthlyFree)
        #expect(!quota.isEmpty)
    }

    @Test func questionsUseTheMonthFirstThenTheBonusThenStop() {
        let quota = makeQuota()
        quota.claim("account")
        #expect(quota.remaining == AIQuota.monthlyFree + AIQuota.stepBonus)
        for _ in 0..<AIQuota.monthlyFree { #expect(quota.spend()) }
        #expect(quota.monthlyLeft == 0)
        #expect(quota.bonus == AIQuota.stepBonus)
        for _ in 0..<AIQuota.stepBonus { #expect(quota.spend()) }
        #expect(quota.isEmpty)
        #expect(!quota.spend())
    }

    @Test func eachStepPaysOnce() {
        let quota = makeQuota()
        quota.claim("loan")
        quota.claim("loan")
        #expect(quota.bonus == AIQuota.stepBonus)
    }

    @Test func theAllowanceIsSaved() {
        let defaults = UserDefaults(suiteName: "AIQuotaTests.\(UUID().uuidString)")!
        let quota = AIQuota(defaults: defaults)
        quota.spend()
        quota.claim("askAI")
        let reopened = AIQuota(defaults: defaults)
        #expect(reopened.usedThisMonth == 1)
        #expect(reopened.bonus == AIQuota.stepBonus)
    }
}

/// Hạn mức chi tiêu: what is left, the 80% warning, each day's share, and the groups' limits.
struct BudgetTests {
    private func day(_ value: Int, of month: Int = 10) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: month, day: value, hour: 12))!
    }

    @Test func warnsFromEightyPercentAndSaysWhenOver() {
        #expect(!BudgetProgress(limit: 1_000_000, spent: 790_000).isNearing)
        #expect(BudgetProgress(limit: 1_000_000, spent: 800_000).isNearing)
        let over = BudgetProgress(limit: 1_000_000, spent: 1_200_000)
        #expect(over.isOver && !over.isNearing)
        #expect(over.left == -200_000)
    }

    @Test func eachDaySharesWhatIsLeftTodayIncluded() {
        // 31 October: one day left, today.
        let progress = BudgetProgress(limit: 10_000_000, spent: 7_000_000)
        #expect(progress.dailyAllowance(in: day(31), today: day(31)) == 3_000_000)
        // 22 October: 10 days left with today.
        #expect(progress.dailyAllowance(in: day(1), today: day(22)) == 300_000)
    }

    @Test func noDailyShareForAnotherMonthOrWhenNothingIsLeft() {
        #expect(BudgetProgress(limit: 1_000_000, spent: 0).dailyAllowance(in: day(5, of: 9), today: day(22)) == nil)
        #expect(BudgetProgress(limit: 1_000_000, spent: 1_000_000).dailyAllowance(in: day(22), today: day(22)) == nil)
    }

    @Test func groupLimitsFitInTheMonth() {
        let groups = CategoryBudgets(limits: ["food": 6_000_000, "shopping": 4_000_000])
        // 30tr a month, 10tr given: food may grow to 26tr, a new group may take 20tr.
        #expect(BudgetRules.room(for: "food", month: 30_000_000, groups: groups) == 26_000_000)
        #expect(BudgetRules.groupError(20_000_000, groupID: "fun", month: 30_000_000, groups: groups) == nil)
        #expect(BudgetRules.groupError(20_000_001, groupID: "fun", month: 30_000_000, groups: groups) != nil)
        // No month limit yet: no group limit, but removing one is always fine.
        #expect(BudgetRules.groupError(1_000, groupID: "fun", month: 0, groups: groups) != nil)
        #expect(BudgetRules.groupError(0, groupID: "food", month: 0, groups: groups) == nil)
    }

    @Test func theMonthNeverDropsBelowTheGroups() {
        let groups = CategoryBudgets(limits: ["food": 6_000_000, "shopping": 4_000_000])
        #expect(BudgetRules.monthError(10_000_000, groups: groups) == nil)
        #expect(BudgetRules.monthError(9_999_999, groups: groups) != nil)
        #expect(BudgetRules.monthError(0, groups: groups) != nil)
        #expect(BudgetRules.monthError(0, groups: CategoryBudgets()) == nil)
    }

    @Test func aHiddenGroupNoLongerHoldsPartOfTheMonth() {
        let groups = CategoryBudgets(limits: ["food": 6_000_000, "fun": 2_000_000])
        let inUse = groups.keeping(["food"])
        #expect(inUse.total == 6_000_000)
        #expect(BudgetRules.room(for: "shopping", month: 30_000_000, groups: inUse) == 24_000_000)
    }

    @Test func theNoticeSaysWhatIsLeftAndPicksTheWorse() {
        let food = BudgetNotice(name: "Ăn uống", limit: 6_000_000, spent: 5_830_000, amount: 200_000)
        #expect(food.level == .over)
        #expect(food.text == "Ăn uống còn 170.000đ → vượt 30.000đ")
        let month = BudgetNotice(name: "Hạn mức tháng", limit: 30_000_000, spent: 18_000_000, amount: 200_000)
        #expect(month.level == .fine)
        #expect(BudgetNotice.pick(group: food, month: month) == food)
        let tight = BudgetNotice(name: "Hạn mức tháng", limit: 1_000_000, spent: 0, amount: 900_000)
        let roomy = BudgetNotice(name: "Mua sắm", limit: 4_000_000, spent: 0, amount: 900_000)
        #expect(BudgetNotice.pick(group: roomy, month: tight) == tight)
    }

    @Test func groupLimitsAreSavedAndZeroRemovesOne() {
        var budgets = CategoryBudgets()
        budgets["food"] = 5_000_000
        budgets["shopping"] = 2_000_000
        budgets["shopping"] = 0
        let reopened = CategoryBudgets(rawValue: budgets.rawValue)
        #expect(reopened?.limits == ["food": 5_000_000])
        #expect(reopened?.total == 5_000_000)
    }
}

/// Báo cáo: weeks from Monday, stepping between periods, and totals for any period.
@MainActor
struct ReportTests {
    private let wallet = Account(name: "Ví", type: .cash, balance: 1_000_000)

    private func date(_ day: Int, _ month: Int, _ year: Int = 2026) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func aWeekRunsMondayToSunday() {
        // Thursday 29 October 2026 is in the week of Monday 26 October.
        let week = ReportPeriod(.week, containing: date(29, 10))
        #expect(Calendar.current.isDate(week.start, inSameDayAs: date(26, 10)))
        #expect(week.title == "26/10 – 1/11")
        #expect(week.interval.holds(date(1, 11)))
        #expect(!week.interval.holds(date(2, 11)))
    }

    @Test func stepsGoBackAcrossTheYear() {
        let january = ReportPeriod(.month, containing: date(15, 1))
        #expect(Calendar.current.isDate(january.previous.start, inSameDayAs: date(1, 12, 2025)))
        #expect(january.lastPeriods(6).count == 6)
        #expect(january.lastPeriods(6).last == january)
    }

    @Test func totalsCountOnlyThePeriod() {
        let store = FinanceStore(accounts: [wallet], transactions: [], loans: [], paymentReminders: [], savingsGoals: [])
        store.add(FinanceTransaction(amount: 100_000, category: .food, accountID: wallet.id, date: date(27, 10)))
        store.add(FinanceTransaction(amount: 50_000, category: .food, accountID: wallet.id, date: date(20, 10)))
        let week = ReportPeriod(.week, containing: date(29, 10))
        #expect(store.total(.expense, in: week.interval) == 100_000)
        #expect(store.total(.expense, in: ReportPeriod(.month, containing: date(29, 10)).interval) == 150_000)
        #expect(store.totalsByAccount(in: week.interval).first?.expense == 100_000)
        #expect(store.expensesByItem(inGroup: TransactionCategory.food.rawValue, in: week.interval).first?.amount == 100_000)
    }

    @Test func systemCategoriesCannotHaveALimit() {
        let store = FinanceStore(accounts: [wallet], transactions: [], loans: [], paymentReminders: [], savingsGoals: [])
        #expect(!store.budgetGroupIDs.contains(TransactionCategory.transferFee.rawValue))
        #expect(!store.budgetGroupIDs.contains(TransactionCategory.loanInterestExpense.rawValue))
    }

    @Test func editingDoesNotCountTheOldAmountTwice() {
        let store = FinanceStore(accounts: [wallet], transactions: [], loans: [], paymentReminders: [], savingsGoals: [])
        let lunch = FinanceTransaction(amount: 100_000, category: .food, accountID: wallet.id, date: .now)
        store.add(lunch)
        let notice = store.budgetNotice(amount: 150_000, categoryID: lunch.categoryID, accountID: wallet.id, date: .now,
                                        isExcluded: false, replacing: lunch, monthLimit: 1_000_000,
                                        groupLimits: CategoryBudgets())
        #expect(notice?.spent == 0)
        #expect(notice?.after.left == 850_000)
    }

    @Test func aRunningPeriodMeetsTheSameDaysBefore() {
        // 5 November: compared with 1–5 October, not all of it.
        let november = ReportPeriod(.month, containing: date(5, 11))
        let compared = november.comparison(now: date(5, 11))
        #expect(Calendar.current.isDate(compared.start, inSameDayAs: date(1, 10)))
        #expect(compared.holds(date(5, 10)))
        #expect(!compared.holds(date(6, 10)))
        // A finished month meets the whole one before.
        #expect(ReportPeriod(.month, containing: date(5, 9)).comparison(now: date(5, 11)) == ReportPeriod(.month, containing: date(5, 8)).interval)
        // 31 March meets all of February, no further.
        let march = ReportPeriod(.month, containing: date(31, 3))
        #expect(march.comparison(now: date(31, 3)).end == ReportPeriod(.month, containing: date(1, 2)).interval.end)
    }

    @Test func bigMovesAreWrittenAsAmounts() {
        #expect(Change.text(115, from: 100) == "↑ 15%")
        #expect(Change.text(4_800_000, from: 560_000) == "↑ 4.240.000đ")
        #expect(Change.text(100, from: 0) == nil)
    }

    @Test func changeIsNilWithNothingBefore() {
        #expect(Change.ratio(100, from: 0) == nil)
        #expect(Change.ratio(150, from: 100) == 0.5)
    }
}

/// The limit note while writing a spending, case by case: month limit 2tr, Ăn uống 1tr with 500k
/// spent this month.
@MainActor
struct BudgetNoticeScenarioTests {
    private let wallet = Account(name: "Ví", type: .cash, balance: 50_000_000)
    private let limits = CategoryBudgets(limits: [TransactionCategory.food.rawValue: 1_000_000])
    private var lastMonth: Date { Calendar.current.date(byAdding: .month, value: -1, to: .now)! }

    private func makeStore(_ extra: [FinanceTransaction] = []) -> (FinanceStore, FinanceTransaction) {
        let lunch = FinanceTransaction(amount: 500_000, category: .food, accountID: wallet.id, date: .now)
        let store = FinanceStore(accounts: [wallet], transactions: [], loans: [], paymentReminders: [], savingsGoals: [])
        store.add(lunch)
        extra.forEach(store.add)
        return (store, lunch)
    }

    private func notice(_ store: FinanceStore, _ amount: Double, _ category: TransactionCategory,
                        date: Date = .now, excluded: Bool = false, account: Account.ID? = nil,
                        replacing: FinanceTransaction? = nil) -> BudgetNotice? {
        store.budgetNotice(amount: amount, categoryID: category.rawValue, accountID: account ?? wallet.id, date: date,
                           isExcluded: excluded, replacing: replacing, monthLimit: 2_000_000, groupLimits: limits)
    }

    @Test func greyWhileTheGroupHasRoom() {
        let n = notice(makeStore().0, 100_000, .food)
        #expect(n?.level == .fine)
        #expect(n?.text == "Ăn uống còn 500.000đ → còn 400.000đ")
    }

    @Test func amberFromEightyPercent() {
        let n = notice(makeStore().0, 300_000, .food)
        #expect(n?.level == .nearing)
        #expect(n?.text == "Ăn uống còn 500.000đ → còn 200.000đ")
    }

    @Test func redWhenItGoesOver() {
        let n = notice(makeStore().0, 600_000, .food)
        #expect(n?.level == .over)
        #expect(n?.text == "Ăn uống còn 500.000đ → vượt 100.000đ")
    }

    @Test func aGroupWithoutALimitUsesTheMonth() {
        let n = notice(makeStore().0, 100_000, .transport)
        #expect(n?.name == "Hạn mức tháng")
        #expect(n?.text == "Hạn mức tháng còn 1.500.000đ → còn 1.400.000đ")
        #expect(notice(makeStore().0, 1_200_000, .transport)?.level == .nearing)
        #expect(notice(makeStore().0, 1_600_000, .transport)?.level == .over)
    }

    @Test func theMonthWinsWhenItIsTighter() {
        // 1,3tr more spent elsewhere: the month is at 90%, Ăn uống at 60% after 100k.
        let (store, _) = makeStore([FinanceTransaction(amount: 1_300_000, category: .shopping, accountID: wallet.id, date: .now)])
        let n = notice(store, 100_000, .food)
        #expect(n?.name == "Hạn mức tháng")
        #expect(n?.level == .nearing)
    }

    @Test func aSmallAmountIsWrittenInFull() {
        let n = BudgetNotice(name: "Mua sắm", limit: 4_000_000, spent: 2_230_000, amount: 1_000)
        #expect(n.text == "Mua sắm còn 1.770.000đ → còn 1.769.000đ")
    }

    @Test func aDayInAnotherMonthCountsThatMonth() {
        let n = notice(makeStore().0, 600_000, .food, date: lastMonth)
        #expect(n?.level == .fine)
        #expect(n?.text == "Ăn uống còn 1.000.000đ → còn 400.000đ")
    }

    @Test func nothingForExcludedOrLockedOrEmpty() {
        let (store, _) = makeStore()
        #expect(notice(store, 100_000, .food, excluded: true) == nil)
        #expect(notice(store, 0, .food) == nil)
        var locked = Account(name: "Khoá", type: .bank, balance: 1_000_000)
        locked.isLocked = true
        store.add(locked)
        #expect(notice(store, 100_000, .food, account: locked.id) == nil)
    }

    @Test func editingCountsOnlyTheChange() {
        let (store, lunch) = makeStore()
        // 500k → 600k: Ăn uống had 1tr free before this one, 400k after.
        #expect(notice(store, 600_000, .food, replacing: lunch)?.text == "Ăn uống còn 1.000.000đ → còn 400.000đ")
        // Moved to Di chuyển: the month gets its 500k back first.
        #expect(notice(store, 500_000, .transport, replacing: lunch)?.text == "Hạn mức tháng còn 2.000.000đ → còn 1.500.000đ")
    }
}

struct BudgetPercentTests {
    /// Rounded down within the limit and up once over, so "100%" stands only beside nothing left.
    @Test func percentRoundsTheWayTheStateReads() {
        #expect(BudgetProgress(limit: 30_000_000, spent: 29_900_000).percentText == "99%")
        #expect(BudgetProgress(limit: 30_000_000, spent: 30_000_000).percentText == "100%")
        #expect(BudgetProgress(limit: 30_000_000, spent: 30_100_000).percentText == "101%")
        #expect(BudgetProgress(limit: 1_000, spent: 796).percentText == "79%")
        // 0.29 × 100 is 28.999… in floating point: still "29%".
        #expect(BudgetProgress(limit: 100, spent: 29).percentText == "29%")
        // A đồng left or over is never "100%", however large the limit.
        #expect(BudgetProgress(limit: 300_000_000, spent: 299_999_999).percentText == "99%")
        #expect(BudgetProgress(limit: 300_000_000, spent: 300_000_001).percentText == "101%")
    }

    @Test func capIsWhatTheFieldTakes() {
        #expect(String(Int(BudgetRules.cap)).count == 12)
    }
}

struct CategoryOrderTests {
    /// Groups take the new order in the places they held; the items of each stay with their group.
    @Test func reorderingGroupsKeepsTheirItems() {
        let store = FinanceStore(accounts: [], transactions: [], loans: [], paymentReminders: [], savingsGoals: [])
        let groups = store.groups(.expense)
        #expect(groups.count > 2)
        let itemsBefore = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, store.items(of: $0).map(\.id)) })
        let reversed = Array(groups.reversed())
        store.reorder(reversed.map(\.id))
        #expect(store.groups(.expense).map(\.id) == reversed.map(\.id))
        for group in groups {
            #expect(store.items(of: group).map(\.id) == itemsBefore[group.id])
        }
    }

    /// A group's items in use take the new order; a hidden one keeps its place.
    @Test func reorderingItemsLeavesAHiddenOneInPlace() throws {
        let wallet = Account(name: "Ví", type: .cash, balance: 1_000_000)
        let store = FinanceStore(accounts: [wallet], transactions: [], loans: [], paymentReminders: [], savingsGoals: [])
        let group = try #require(store.groups(.expense).first { store.items(of: $0).count > 2 })
        let items = store.items(of: group)
        // Hide the second item (it has no transactions here, so give it one to hide rather than delete).
        let hidden = items[1]
        store.add(FinanceTransaction(amount: 1, categoryID: hidden.id, kind: .expense, accountID: wallet.id, date: .now))
        store.remove(hidden)
        let hiddenSlot = try #require(store.category(id: hidden.id)).sortOrder
        let visible = store.items(of: group)
        #expect(!visible.contains { $0.id == hidden.id })
        let reversed = Array(visible.reversed())
        #expect(store.reorder(reversed.map(\.id)))
        #expect(store.items(of: group).map(\.id) == reversed.map(\.id))
        #expect(store.category(id: hidden.id)?.sortOrder == hiddenSlot)
        #expect(store.reorder(["missing"]) == false)
    }
}
