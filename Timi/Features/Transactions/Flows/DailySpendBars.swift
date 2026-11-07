import SwiftUI

/// The month's spending day by day (user pick "B+" 2026-11-03; no longer on Giao dịch since its
/// month card, 2026-11-07, kept in the UI library): a thin column per day, as tall as that day's spending against the
/// month's biggest day. Days gone by in ink, today in `accent` and never lower than `todayMinimum`, so
/// it shows on a day with nothing spent yet; a day gone by with nothing spent a low stub in the
/// track colour, days still to come a fainter one (review 2026-11-03: the two read the same). The
/// first and last day of the month under it. Hidden from VoiceOver: the figure above says the
/// month's total, the list each day's.
struct DailySpendBars: View {
    let month: Date
    /// The page's day, which it moves on at midnight (`TransactionsView.followToday`), not the
    /// clock read here: left open overnight, today's colour stayed on yesterday (review 2026-11-03).
    let today: Date

    @Environment(FinanceStore.self) private var store

    private static let height: CGFloat = 40
    /// What a day with nothing, or still to come, shows: enough to see the month's shape.
    private static let stub: CGFloat = 3
    /// Today at least this tall, so its colour is there to see.
    private static let todayMinimum: CGFloat = 8

    var body: some View {
        let calendar = Calendar.current
        let days = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        let spent = spending(calendar)
        let biggest = max(spent.values.max() ?? 0, 1)
        let isThisMonth = calendar.isDate(month, equalTo: today, toGranularity: .month)
        let todayNumber = calendar.component(.day, from: today)
        let number = calendar.component(.month, from: month)
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .bottom, spacing: Spacing.xxs) {
                ForEach(1...days, id: \.self) { day in
                    let amount = spent[day] ?? 0
                    let isToday = isThisMonth && day == todayNumber
                    let isAhead = isThisMonth && day > todayNumber
                    let color = isToday ? Palette.accent
                        : isAhead ? Palette.separator
                        : amount == 0 ? Palette.progressTrack : Palette.progress
                    let barHeight = isAhead ? Self.stub
                        : max(Self.height * amount / biggest, isToday ? Self.todayMinimum : Self.stub)
                    RoundedRectangle(cornerRadius: CardCorners.mark, style: .continuous)
                        .fill(color)
                        .frame(height: barHeight)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: Self.height, alignment: .bottom)
            HStack {
                Text("1/\(number)")
                Spacer()
                Text("\(days)/\(number)")
            }
            .textRole(.footnote)
            .monospacedDigit()
            .foregroundStyle(Palette.secondaryLabel)
        }
        .accessibilityHidden(true)
    }

    /// What went out on each day of the month, by its number: the transactions "Đã chi" adds up.
    private func spending(_ calendar: Calendar) -> [Int: Double] {
        store.reportableTransactions(inMonthOf: month)
            .filter { $0.kind == .expense }
            .reduce(into: [:]) { $0[calendar.component(.day, from: $1.date), default: 0] += $1.amount }
    }
}
