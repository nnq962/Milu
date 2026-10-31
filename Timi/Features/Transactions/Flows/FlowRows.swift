import SwiftUI

/// Day totals beside each date heading: both sides in full, a single side compact.
struct DayTotals: View {
    let items: [FinanceTransaction]

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let counted = items.reportable(excluding: store.lockedAccountIDs)
        let income = counted.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        let expense = counted.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        // In full where they fit, as every figure (`MoneyText` shortens both when they do not).
        HStack(spacing: Spacing.m) {
            if income > 0 {
                MoneyText(amount: income, size: .caption, tone: .signedIncome)
            }
            if expense > 0 {
                // Money out red (user rule 2026-10-30).
                MoneyText(amount: expense, size: .caption, tone: .signedExpense)
            }
        }
        // In words: "Thu 1.200.000 đ, chi 55.000 đ", not "trừ 55k".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([income > 0 ? "Thu \(income.vnd)" : nil, expense > 0 ? "chi \(expense.vnd)" : nil]
            .compactMap { $0 }.joined(separator: ", ").capitalizedFirstLetter)
        .accessibilityHidden(income == 0 && expense == 0)
    }
}

/// Transactions and transfers grouped by day, newest first: the day's title and totals over a
/// card of rows, a card per day (user choice 2026-10-30, back from one long block that read as a
/// wall of rows); tapping one hands it back. Shared by "Giao dịch" and its search.
struct ActivityDayList: View {
    let groups: [(day: Date, items: [AccountDetailView.Activity])]
    /// The account whose history this is (its page): transfers read "Chuyển đến …" / "Nhận từ …".
    var viewedAccount: Account.ID? = nil
    let onOpen: (AccountDetailView.Activity) -> Void

    static func byDay(_ items: [AccountDetailView.Activity]) -> [(day: Date, items: [AccountDetailView.Activity])] {
        let groups = Dictionary(grouping: items) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in (day, groups[day] ?? []) }
    }

    var body: some View {
        ForEach(groups, id: \.day) { group in
            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                dayHeader(group)
                VStack(spacing: 0) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                        ActivityRow(item: item, side: viewedAccount == nil ? .list : .account, viewedAccount: viewedAccount,
                                    detail: .time, onEdit: onOpen)
                            .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .listCard()
            }
        }
    }

    /// The day and its totals, as every heading over a card (`SectionHeader`: inset to the rows,
    /// on one baseline, the totals under the day at the accessibility text sizes). A day of one row
    /// shows no total: it was the row's own amount again, just above it (review 2026-10-31).
    private func dayHeader(_ group: (day: Date, items: [AccountDetailView.Activity])) -> some View {
        SectionHeader(title: group.day.transactionDayTitle) {
            if group.items.count > 1 {
                // The day's spending and income: its transactions. A transfer, fee and all, is a
                // thing of its own (user choice 2026-10-29), so it adds nothing here.
                DayTotals(items: group.items.compactMap {
                    if case .transaction(let transaction) = $0 { transaction } else { nil }
                })
            }
        }
    }
}

