import SwiftUI

/// Day totals beside each date heading: both sides in full, a single side compact.
struct DayTotals: View {
    let items: [FinanceTransaction]

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let counted = items.reportable(excluding: store.lockedAccountIDs)
        let income = counted.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        let expense = counted.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        HStack(spacing: Spacing.m) {
            if income > 0 && expense > 0 {
                Text("+\(income.formatted(.number.locale(.vietnam)))")
                // The same grey as a day of spending alone, so 55k reads the same on every day.
                Text("-\(expense.formatted(.number.locale(.vietnam)))").foregroundStyle(Palette.secondaryText)
            } else if income > 0 {
                Text("+\(income.vndCompact)")
            } else if expense > 0 {
                Text("-\(expense.vndCompact)").foregroundStyle(Palette.secondaryText)
            }
        }
        .textRole(.captionStrong)
        .monospacedDigit()
        // In words: "Thu 1.200.000 đ, chi 55.000 đ", not "trừ 55k".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([income > 0 ? "Thu \(income.vnd)" : nil, expense > 0 ? "chi \(expense.vnd)" : nil]
            .compactMap { $0 }.joined(separator: ", ").capitalizedFirstLetter)
        .accessibilityHidden(income == 0 && expense == 0)
    }
}

/// Transactions and transfers grouped by day, newest first: the day's title and totals over a
/// card of rows; tapping one hands it back. Shared by "Giao dịch" and its search.
struct ActivityDayList: View {
    let groups: [(day: Date, items: [AccountDetailView.Activity])]
    let onOpen: (AccountDetailView.Activity) -> Void

    static func byDay(_ items: [AccountDetailView.Activity]) -> [(day: Date, items: [AccountDetailView.Activity])] {
        let groups = Dictionary(grouping: items) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in (day, groups[day] ?? []) }
    }

    var body: some View {
        ForEach(groups, id: \.day) { group in
            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                SectionHeader(title: group.day.transactionDayTitle) {
                    // The day's spending and income: its transactions. A transfer, fee and all,
                    // is a thing of its own (user choice 2026-10-29), so it adds nothing here.
                    DayTotals(items: group.items.compactMap {
                        if case .transaction(let transaction) = $0 { transaction } else { nil }
                    })
                }
                VStack(spacing: 0) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                        ActivityRow(item: item, side: .account, detail: .time, onEdit: onOpen)
                            .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .listCard()
            }
        }
    }
}

