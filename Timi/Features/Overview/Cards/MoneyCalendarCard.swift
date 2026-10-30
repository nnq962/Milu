import SwiftUI

/// "Lịch thu chi": a month grid straight on the page, no card (user request 2026-10-30: fewer
/// cards). Each day shows only its number, shaded by how much went out and with a green dot if
/// money came in; tapping a day hands its date to `onSelectDay`, where the figures are.
struct MoneyCalendarCard: View {
    let onSelectDay: (Date) -> Void

    @Environment(FinanceStore.self) private var store
    @State private var displayedMonth = Date.now
    /// Every day the same height: the day and a dot for money in (user choice 2026-10-30: the
    /// figures in each day read as clutter; tap a day for them).
    @ScaledMetric(relativeTo: .caption) private var dayHeight = 44

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
                // The "Chọn tháng" sheet of Giao dịch, behind the quiet compact button (user request 2026-10-30).
                // Its 44pt reaches above and below the title rather than pushing the grid down.
                MonthMenu(month: $displayedMonth, compact: true)
                    .padding(.vertical, -10)
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
            legend
        }
    }

    /// What the shades and the dot mean, small and quiet under the grid.
    private var legend: some View {
        HStack(spacing: Spacing.l) {
            HStack(spacing: Spacing.xs) {
                ForEach([0.08, 0.14, 0.20], id: \.self) { strength in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Palette.red.opacity(strength))
                        .frame(width: 12, height: 12)
                }
                Text("Chi càng nhiều càng đậm")
            }
            HStack(spacing: Spacing.xs) {
                Circle().fill(Palette.income).frame(width: 6, height: 6)
                Text("Có tiền vào")
            }
        }
        .textRole(.footnote)
        .foregroundStyle(Palette.secondaryText)
        .accessibilityHidden(true)
    }

    private func day(_ date: Date, income: Double, expense: Double) -> some View {
        let calendar = Calendar.current
        let today = calendar.isDateInToday(date)
        // Days still ahead: faint and not tappable, nothing can be on them yet.
        let isAhead = date > calendar.startOfDay(for: .now) && !today
        // Shaded by how much went out, deeper the more (user choice 2026-10-30): money in does not
        // colour a day. Today is ringed in moss on top of its shade (UI review 2026-10-30: a solid
        // fill on today hid how much went out on it).
        let strength = expense >= 3_000_000 ? 0.20 : expense >= 1_000_000 ? 0.14 : 0.08
        // Today without spending keeps a clear cell: a moss wash on the cream read as grey
        // (UI review 2026-10-30); its ring and moss number mark it.
        let fill = expense > 0 ? Palette.red.opacity(strength) : .clear
        return Button { onSelectDay(date) } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: date))")
                    .textRole(today ? .captionStrong : .caption)
                    .monospacedDigit()
                    .foregroundStyle(today ? Palette.primary : Palette.ink)
                Circle()
                    .fill(Palette.income)
                    .frame(width: 5, height: 5)
                    .opacity(income > 0 ? 1 : 0)
            }
            .padding(.top, 5)
            .frame(maxWidth: .infinity, minHeight: dayHeight, maxHeight: dayHeight)
            .background(fill, in: RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous))
            .overlay {
                if today {
                    RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous)
                        .strokeBorder(Palette.primary, lineWidth: 1.5)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous))
        }
        // Calendar cells are flat data tiles in the design; only the month control uses glass.
        .buttonStyle(.card)
        .disabled(isAhead)
        .opacity(isAhead ? 0.4 : 1)
        .accessibilityLabel("\(today ? "Hôm nay, " : "")\(date.formatted(.dateTime.weekday(.wide).day().month().year().locale(.vietnam))), thu \(income.vnd), chi \(expense.vnd)")
        .accessibilityHint("Xem giao dịch trong ngày")
    }
}
