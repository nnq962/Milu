import SwiftUI

/// The month's spending day by day, under "Đã chi" on Thu chi (user pick "B+" 2026-11-03: the
/// head read as words alone): a thin column per day, as tall as that day's spending against the
/// month's biggest day. Days gone by in ink, today in lime, days still to come and days with
/// nothing spent a low stub in the track colour. The first and last day of the month under it.
/// Hidden from VoiceOver: the figure above says the month's total.
struct DailySpendBars: View {
    let month: Date

    @Environment(FinanceStore.self) private var store

    private static let height: CGFloat = 40
    /// What a day with nothing, or still to come, shows: enough to see the month's shape.
    private static let stub: CGFloat = 3

    var body: some View {
        let calendar = Calendar.current
        let days = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        let spent = spending(calendar)
        let biggest = max(spent.values.max() ?? 0, 1)
        let isThisMonth = calendar.isDate(month, equalTo: .now, toGranularity: .month)
        let today = calendar.component(.day, from: .now)
        let number = calendar.component(.month, from: month)
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .bottom, spacing: Spacing.xxs) {
                ForEach(1...days, id: \.self) { day in
                    let amount = spent[day] ?? 0
                    let isAhead = isThisMonth && day > today
                    let color = isThisMonth && day == today ? Palette.accent
                        : isAhead || amount == 0 ? Palette.progressTrack : Palette.progress
                    let barHeight = isAhead ? Self.stub : max(Self.height * amount / biggest, Self.stub)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
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
