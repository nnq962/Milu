import Foundation

/// Thống kê: tổng thu chi, chi theo hạng mục và theo tài khoản, cho một tháng hay bất kỳ kỳ nào
/// (tuần, tháng, năm của Báo cáo).
extension FinanceStore {
    func monthlyTransactions(for date: Date = .now) -> [FinanceTransaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }
    }

    /// What a month's totals, charts and the assistant count: its transactions that are reported,
    /// and the fees of its transfers (spending, though they have no row).
    func reportableTransactions(inMonthOf date: Date = .now) -> [FinanceTransaction] {
        reportableTransactions(in: .month(of: date))
    }

    /// The same for any stretch of time: transactions, transfer fees and loan interest, reported.
    func reportableTransactions(in interval: DateInterval) -> [FinanceTransaction] {
        (transactions.filter { interval.holds($0.date) } + feeExpenses(in: interval) + interestTransactions(in: interval))
            .reportable(excluding: lockedAccountIDs)
    }

    func total(_ kind: TransactionKind, inMonthOf date: Date = .now) -> Double {
        total(kind, in: .month(of: date))
    }

    func total(_ kind: TransactionKind, in interval: DateInterval) -> Double {
        reportableTransactions(in: interval)
            .filter { $0.kind == kind }
            .reduce(0) { $0 + $1.amount }
    }

    /// Chi tiêu trong tháng gộp theo nhóm hạng mục ("Ăn sáng" và "Ăn trưa" vào "Ăn uống"), lớn nhất
    /// lên đầu.
    func expensesByCategory(inMonthOf date: Date = .now) -> [CategoryTotal] {
        expensesByCategory(in: .month(of: date))
    }

    func expensesByCategory(in interval: DateInterval) -> [CategoryTotal] {
        let expenses = reportableTransactions(in: interval).filter { $0.kind == .expense }
        return totals(of: expenses) { groupID(of: $0.categoryID) }
    }

    /// One group's spending split by its items ("Ăn sáng", "Ăn trưa"…), largest first. An old
    /// transaction filed under the group itself stays a line of its own, named after the group.
    func expensesByItem(inGroup groupID: String, in interval: DateInterval) -> [CategoryTotal] {
        totals(of: expenses(inGroup: groupID, in: interval)) { $0.categoryID }
    }

    /// One group's reported spending in a stretch of time, newest first.
    func expenses(inGroup groupID: String, in interval: DateInterval) -> [FinanceTransaction] {
        reportableTransactions(in: interval)
            .filter { $0.kind == .expense && self.groupID(of: $0.categoryID) == groupID }
            .sorted { $0.date > $1.date }
    }

    /// Money in and out per account (and per hũ), most spending first; accounts with neither are left
    /// out.
    func totalsByAccount(in interval: DateInterval) -> [AccountTotal] {
        Dictionary(grouping: reportableTransactions(in: interval)) { $0.accountID }
            .map { id, items in
                AccountTotal(id: id,
                             name: account(id: id)?.name ?? goal(id: id)?.name ?? "Tài khoản đã xoá",
                             icon: account(id: id)?.iconName ?? goal(id: id)?.icon ?? "hugeicons-wallet-01",
                             income: items.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount },
                             expense: items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount })
            }
            .sorted { ($0.expense, $0.income) > ($1.expense, $1.income) }
    }

    /// The groups a spending limit can be set on: the expense groups in use. Not a system category
    /// ("Phí chuyển khoản", "Lãi vay"), which the user never files anything under.
    var budgetGroupIDs: Set<String> { Set(groups(.expense).map(\.id)) }

    /// The limit note for a spending being written: `amount` in `categoryID` on `date`; `replacing`
    /// is the transaction being edited, whose old amount is taken out first. Nil when it would not
    /// count (excluded, locked account) or no limit applies.
    func budgetNotice(amount: Double, categoryID: String, accountID: Account.ID?, date: Date,
                      isExcluded: Bool, replacing old: FinanceTransaction?,
                      monthLimit: Double, groupLimits: CategoryBudgets) -> BudgetNotice? {
        guard amount > 0, !isExcluded, !categoryID.isEmpty,
              let accountID, !lockedAccountIDs.contains(accountID) else { return nil }
        let month = DateInterval.month(of: date)
        let group = groupID(of: categoryID)
        // The edited one as it was, if it counted in this month: not spent twice.
        let counted = old.flatMap { old -> FinanceTransaction? in
            old.kind == .expense && isReportable(old) && month.holds(old.date) ? old : nil
        }
        let groupNotice: BudgetNotice? = {
            let limit = budgetGroupIDs.contains(group) ? groupLimits[group] : 0
            guard limit > 0 else { return nil }
            let spent = expenses(inGroup: group, in: month).reduce(0) { $0 + $1.amount }
                - (counted.map { self.groupID(of: $0.categoryID) == group ? $0.amount : 0 } ?? 0)
            return BudgetNotice(name: categoryName(group), limit: limit, spent: spent, amount: amount)
        }()
        let monthNotice: BudgetNotice? = monthLimit > 0
            ? BudgetNotice(name: "Hạn mức tháng", limit: monthLimit,
                           spent: total(.expense, in: month) - (counted?.amount ?? 0), amount: amount)
            : nil
        return BudgetNotice.pick(group: groupNotice, month: monthNotice)
    }

    private func totals(of expenses: [FinanceTransaction], by key: (FinanceTransaction) -> String) -> [CategoryTotal] {
        Dictionary(grouping: expenses, by: key)
            .map { id, items in
                CategoryTotal(groupID: id, name: categoryName(id), icon: categoryIcon(id),
                              amount: items.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.amount > $1.amount }
    }
}

struct CategoryTotal: Identifiable {
    /// A group of "Hạng mục", or a system category ("Phí chuyển khoản"); for `expensesByItem`, an item.
    let groupID: String
    let name: String
    let icon: String
    let amount: Double

    var id: String { groupID }
}

struct AccountTotal: Identifiable {
    let id: Account.ID
    let name: String
    let icon: String
    let income: Double
    let expense: Double
}

extension DateInterval {
    /// The calendar month `date` falls in.
    static func month(of date: Date) -> DateInterval {
        Calendar.current.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 0)
    }

    /// Whether `date` is inside, the end left out (so midnight on the 1st is next month's).
    func holds(_ date: Date) -> Bool { start <= date && date < end }
}
