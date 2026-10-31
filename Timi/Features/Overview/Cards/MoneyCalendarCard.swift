import SwiftUI

/// "Lịch thu chi": a month grid and its legend; the page puts them on a card under the
/// section heading that holds the month menu (2026-10-31). Each day shows only its number, shaded by how much went out and with a dot in ink if
/// money came in; tapping a day hands its date to `onSelectDay`, where the figures are.
struct MoneyCalendarCard: View {
    /// The month shown; the page owns it, since the month menu sits on the section heading
    /// above the card (2026-10-31).
    @Binding var displayedMonth: Date
    let onSelectDay: (Date) -> Void

    @Environment(FinanceStore.self) private var store
    /// Every day the same height: the day and a dot for money in (user choice 2026-10-30: the
    /// figures in each day read as clutter; tap a day for them).
    @ScaledMetric(relativeTo: .caption) private var dayHeight = ControlHeight.regular
    /// A shade swatch in the legend: a day cell in small, so it rounds like one.
    private static let swatchSize: CGFloat = 12
    /// Its corner: a named radius, not the spacing token `xxs` it borrowed (re-review 2026-10-31).
    private static let swatchRadius: CGFloat = 2
    /// The ring round today.
    private static let todayRing: CGFloat = 1.5
    /// How deep a day is shaded by what went out: under 1tr, under 3tr, more. Far enough apart to
    /// tell at a glance; 8 / 14 / 20% read as one pale red, the first near invisible (review
    /// 2026-10-31).
    private static let shades = [0.12, 0.24, 0.40]
    /// Between the day cells, across and down.
    private static let cellGap = Spacing.xs

    var body: some View {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let dayCount = calendar.range(of: .day, in: .month, for: start)!.count
        let offset = (calendar.component(.weekday, from: start) + 5) % 7
        let cellCount = ((offset + dayCount + 6) / 7) * 7
        // Reported ones only, transfer fees and loan interest included: the list Day's sheet shows.
        let transactionsByDay = Dictionary(grouping: store.reportableTransactions(inMonthOf: start)) {
            calendar.startOfDay(for: $0.date)
        }
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: Self.cellGap), count: 7),
                      spacing: Self.cellGap) {
                ForEach(["T2", "T3", "T4", "T5", "T6", "T7", "CN"], id: \.self) { title in
                    Text(title)
                        .textRole(.footnote)
                        .foregroundStyle(Palette.secondaryLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                        .accessibilityHidden(true)
                }
                ForEach(0..<cellCount, id: \.self) { index in
                    if index < offset || index >= offset + dayCount {
                        Color.clear.frame(height: dayHeight).accessibilityHidden(true)
                    } else {
                        let date = calendar.date(byAdding: .day, value: index - offset, to: start)!
                        // The same list Day's sheet shows (`reportableTransactions`).
                        let items = transactionsByDay[calendar.startOfDay(for: date)] ?? []
                        let income = items.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
                        let expense = items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
                        day(date, income: income, expense: expense)
                    }
                }
            }
            legend
                .padding(.top, Spacing.s)
        }
    }

    /// What the shades and the dot mean, small and quiet under the grid.
    private var legend: some View {
        HStack(spacing: Spacing.l) {
            HStack(spacing: Spacing.xs) {
                ForEach(Self.shades, id: \.self) { strength in
                    // The day cell's own shape, small.
                    RoundedRectangle(cornerRadius: Self.swatchRadius, style: .continuous)
                        .fill(Palette.negative.opacity(strength))
                        .frame(width: Self.swatchSize, height: Self.swatchSize)
                }
                Text("Chi càng nhiều càng đậm")
            }
            HStack(spacing: Spacing.xs) {
                // The shared legend dot, as in each day (re-review 2026-10-31: drawn at 5).
                LegendDot(color: Palette.label)
                Text("Có tiền vào")
            }
        }
        // A chart's legend, as `LegendRow` under the bars: caption (footnote is for axes).
        .textRole(.caption)
        .foregroundStyle(Palette.secondaryLabel)
        .accessibilityHidden(true)
    }

    private func day(_ date: Date, income: Double, expense: Double) -> some View {
        let calendar = Calendar.current
        let today = calendar.isDateInToday(date)
        // Days still ahead: faint and not tappable, nothing can be on them yet.
        let isAhead = date > calendar.startOfDay(for: .now) && !today
        // Shaded by how much went out, deeper the more (user choice 2026-10-30): money in does not
        // colour a day. Today is ringed in the primary colour on top of its shade (UI review 2026-10-30: a solid
        // fill on today hid how much went out on it).
        let strength = expense >= 3_000_000 ? Self.shades[2] : expense >= 1_000_000 ? Self.shades[1] : Self.shades[0]
        // Today keeps a clear cell when nothing went out (a wash read as grey, UI review
        // 2026-10-30); its ring and number in the primary colour mark it over any shade.
        let fill = expense > 0 ? Palette.negative.opacity(strength) : .clear
        return Button { onSelectDay(date) } label: {
            VStack(spacing: Spacing.xxs) {
                Text("\(calendar.component(.day, from: date))")
                    .textRole(today ? .captionStrong : .caption)
                    .monospacedDigit()
                    .foregroundStyle(today ? Palette.primary : Palette.label)
                LegendDot(color: Palette.label)
                    .opacity(income > 0 ? 1 : 0)
            }
            .padding(.top, Spacing.xs)
            .frame(maxWidth: .infinity, minHeight: dayHeight, maxHeight: dayHeight)
            .background(fill, in: RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous))
            .overlay {
                if today {
                    RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous)
                        .strokeBorder(Palette.primary, lineWidth: Self.todayRing)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous))
        }
        // Calendar cells are flat data tiles in the design; only the month control uses glass.
        .buttonStyle(.card)
        .disabled(isAhead)
        .opacity(isAhead ? 0.4 : 1)
        .accessibilityLabel(dayLabel(date, today: today, income: income, expense: expense))
        .accessibilityHint("Xem giao dịch trong ngày")
    }

    /// Only the figures there are; an empty day says so (re-review 2026-10-31: "thu 0đ, chi 0đ").
    private func dayLabel(_ date: Date, today: Bool, income: Double, expense: Double) -> String {
        let name = (today ? "Hôm nay, " : "") + date.formatted(.dateTime.weekday(.wide).day().month().year().locale(.vietnam))
        var figures: [String] = []
        if income > 0 { figures.append("thu \(income.vnd)") }
        if expense > 0 { figures.append("chi \(expense.vnd)") }
        return name + ", " + (figures.isEmpty ? "không có thu chi" : figures.joined(separator: ", "))
    }
}
