import Charts
import SwiftUI

/// Spending per day of a month, drawn with Swift Charts: one bar per day, today in lime, days still
/// ahead faint. Press (or press and drag) across the bars to read a day's total under the chart; the selected bar
/// turns black and the phone ticks. The pick stays after the finger lifts; tapping it again clears
/// it. VoiceOver reads every day through Charts' own audio graph.
struct DailySpendingChart: View {
    let month: Date
    /// Day of the month → amount spent.
    let totals: [Int: Double]

    @State private var selectedDay: String?
    /// What Charts reports while a finger is down; nil again once it lifts.
    @State private var touchedDay: String?

    private struct Day: Identifiable {
        let number: Int
        let amount: Double
        let isToday: Bool
        let isFuture: Bool
        var id: Int { number }
        var label: String { String(number) }
    }

    private var calendar: Calendar { .current }
    private var start: Date { calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month }
    private var monthNumber: Int { calendar.component(.month, from: start) }

    private var days: [Day] {
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let today = calendar.startOfDay(for: .now)
        return (1...count).map { number in
            let date = calendar.date(byAdding: .day, value: number - 1, to: start) ?? start
            return Day(number: number, amount: totals[number, default: 0],
                       isToday: calendar.isDate(date, inSameDayAs: today), isFuture: date > today)
        }
    }

    var body: some View {
        let days = days
        let peak = max(days.map(\.amount).max() ?? 0, 1)
        let selected = days.first { $0.label == selectedDay }

        VStack(spacing: Spacing.s) {
            Chart(days) { day in
                // Empty and future days keep a stub so the month still reads as 30 slots.
                BarMark(
                    x: .value("Ngày", day.label),
                    y: .value("Chi", day.isFuture ? peak * 0.06 : max(day.amount, peak * 0.04)),
                    width: .ratio(0.7)
                )
                .clipShape(Capsule())
                .foregroundStyle(color(for: day, selected: selected))
                .accessibilityLabel("Ngày \(day.number)/\(monthNumber)")
                .accessibilityValue(day.amount.vnd)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: 0...peak)
            .chartXSelection(value: $touchedDay)
            .onChange(of: touchedDay) { old, new in
                guard let new else { return }
                // A new touch that lands on the day already picked clears it.
                selectedDay = (old == nil && new == selectedDay) ? nil : new
            }
            .frame(height: 64)
            .sensoryFeedback(.selection, trigger: selectedDay)

            HStack {
                Text("1/\(monthNumber)")
                Spacer()
                if let selected {
                    Text("Ngày \(selected.number)/\(monthNumber) · \(selected.amount.vnd)")
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText())
                    Spacer()
                }
                Text("\(days.count)/\(monthNumber)")
            }
            .textRole(.footnote)
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
            // Room for the selected day's line, so the card doesn't jump when it appears.
            .frame(minHeight: 18)
        }
        .animation(.snappy(duration: 0.2), value: selectedDay)
    }

    private func color(for day: Day, selected: Day?) -> Color {
        if let selected { return day.id == selected.id ? Palette.primary : Palette.secondary.opacity(0.2) }
        if day.isToday { return Palette.lime }
        return day.isFuture ? Palette.muted : Palette.secondary.opacity(0.3)
    }
}
