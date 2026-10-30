import SwiftUI

/// "Lịch thu chi": a month grid with each day's income and spending, shaded by how busy it was.
/// Tapping a day hands its date to `onSelectDay`.
struct MoneyCalendarCard: View {
    let onSelectDay: (Date) -> Void

    @Environment(FinanceStore.self) private var store
    @State private var displayedMonth = Date.now
    @ScaledMetric(relativeTo: .caption2) private var dayHeight = 52

    var body: some View {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let dayCount = calendar.range(of: .day, in: .month, for: start)!.count
        let offset = (calendar.component(.weekday, from: start) + 5) % 7
        let cellCount = ((offset + dayCount + 6) / 7) * 7
        // Reported ones only, transfer fees included (already filtered, so `reportable` below is a no-op).
        let transactionsByDay = Dictionary(grouping: store.reportableTransactions(inMonthOf: start)) {
            calendar.startOfDay(for: $0.date)
        }
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Lịch thu chi")
                    .textRole(.title)
                    .frame(minHeight: 24)
                Spacer(minLength: 4)
                // The same month button and "Chọn tháng" sheet as Giao dịch (user request 2026-10-29).
                MonthMenu(month: $displayedMonth)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 4), count: 7), spacing: 4) {
                ForEach(["T2", "T3", "T4", "T5", "T6", "T7", "CN"], id: \.self) { title in
                    Text(title)
                        .textRole(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 15)
                        .padding(.vertical, 4)
                        .accessibilityHidden(true)
                }
                ForEach(0..<cellCount, id: \.self) { index in
                    if index < offset || index >= offset + dayCount {
                        Color.clear.frame(height: dayHeight).accessibilityHidden(true)
                    } else {
                        let date = calendar.date(byAdding: .day, value: index - offset, to: start)!
                        let items = transactionsByDay[calendar.startOfDay(for: date)] ?? []
                        let income = items.reportable(excluding: store.lockedAccountIDs).filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
                        let expense = items.reportable(excluding: store.lockedAccountIDs).filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
                        day(date, income: income, expense: expense)
                    }
                }
            }
        }
        .overviewCard()
    }

    private func day(_ date: Date, income: Double, expense: Double) -> some View {
        let calendar = Calendar.current
        let today = calendar.isDateInToday(date)
        // Days still ahead: faint and not tappable, nothing can be on them yet.
        let isAhead = date > calendar.startOfDay(for: .now) && !today
        // Green where more came in than went out, red where more went out, deeper the bigger the
        // gap (user choice 2026-10-29, after the greys); today stays lime.
        let net = income - expense
        let strength = abs(net) >= 3_000_000 ? 0.24 : abs(net) >= 1_000_000 ? 0.15 : 0.08
        let fill = today ? Palette.lime
            : net > 0 ? Palette.green.opacity(strength)
            : net < 0 ? Palette.red.opacity(strength)
            : Palette.fill1
        return Button { onSelectDay(date) } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .textRole(.captionStrong)
                    .foregroundStyle(today ? Palette.onLime : Palette.secondaryText)
                    .frame(minHeight: 16.5, alignment: .topLeading)
                VStack(alignment: .leading, spacing: 0) {
                    if income > 0 {
                        amount("+\(income.vndCompact)", color: today ? Palette.onLime : Palette.ink)
                    }
                    if expense > 0 {
                        amount("-\(expense.vndCompact)", color: Palette.red)
                    }
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity, minHeight: dayHeight, alignment: .topLeading)
            .background(fill, in: RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous))
        }
        // Calendar cells are flat data tiles in the design; only the month control uses glass.
        .buttonStyle(.card)
        .disabled(isAhead)
        .opacity(isAhead ? 0.4 : 1)
        .accessibilityLabel("\(today ? "Hôm nay, " : "")\(date.formatted(.dateTime.weekday(.wide).day().month().year().locale(.vietnam))), thu \(income.vnd), chi \(expense.vnd)")
        .accessibilityHint("Xem giao dịch trong ngày")
    }

    private func amount(_ text: String, color: Color) -> some View {
        // One size for every day: 13pt only fit short figures, so "-85k" and "-430k" came out at
        // different sizes. Shrinks only for a rare long one ("-12,5tr").
        Text(text)
            .font(Typography.font(.caption2, size: 10, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1).minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func changeMonth(_ delta: Int) {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        displayedMonth = calendar.date(byAdding: .month, value: delta, to: start) ?? start
    }
}
