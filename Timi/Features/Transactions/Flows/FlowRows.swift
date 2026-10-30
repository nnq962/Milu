import SwiftUI

/// Day totals beside each date heading: both sides in full, a single side compact.
struct DayTotals: View {
    let items: [FinanceTransaction]

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let counted = items.reportable(excluding: store.lockedAccountIDs)
        let income = counted.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        let expense = counted.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        // Always the short form, one side or both, so the column reads the same on every day (HIG
        // review 2026-10-30: both sides in full beside one side short read as two kinds of number).
        HStack(spacing: Spacing.m) {
            if income > 0 {
                Text("+\(income.vndCompact)").foregroundStyle(Palette.income)
            }
            if expense > 0 {
                // Money out red (user rule 2026-10-30).
                Text("-\(expense.vndCompact)").foregroundStyle(Palette.red)
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
/// card of rows, a card per day (user choice 2026-10-30, back from one long block that read as a
/// wall of rows); tapping one hands it back. Shared by "Giao dịch" and its search.
struct ActivityDayList: View {
    let groups: [(day: Date, items: [AccountDetailView.Activity])]
    let onOpen: (AccountDetailView.Activity) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                        ActivityRow(item: item, side: .account, detail: .time, onEdit: onOpen)
                            .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .listCard()
            }
        }
    }

    /// The day and its totals, starting where the rows inside the card start (`SectionHeader`).
    /// At the accessibility text sizes the totals go under the day, which one line cut short.
    private func dayHeader(_ group: (day: Date, items: [AccountDetailView.Activity])) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Spacing.s))
        return layout {
            Text(group.day.transactionDayTitle)
                .textRole(.title)
                .accessibilityAddTraits(.isHeader)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
            // The day's spending and income: its transactions. A transfer, fee and all, is a
            // thing of its own (user choice 2026-10-29), so it adds nothing here.
            DayTotals(items: group.items.compactMap {
                if case .transaction(let transaction) = $0 { transaction } else { nil }
            })
        }
        .padding(.horizontal, RowMetrics.horizontal)
    }
}

