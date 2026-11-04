import SwiftUI

/// "Lịch thu chi": a month grid and its legend; the page puts them on a card under the
/// section heading that holds the month menu (2026-10-31). Each day shows its number and, under
/// it, what went out in coral and what came in in green, both short ("757k", "2,5tr"):
/// at a glance which days cost what (user pick "B" 2026-11-04, after shades alone read pale).
/// Every day gone by is a pale tile, today a lime one, days ahead a faint number on nothing (user
/// pick "A" 2026-11-04: figures floating on the card read as untidy). At accessibility text sizes
/// the figures give way to a dot of each colour. Tapping a day hands its date to `onSelectDay`,
/// where the full figures are.
struct MoneyCalendarCard: View {
    /// The month shown; the page owns it, since the month menu sits on the section heading
    /// above the card (2026-10-31).
    @Binding var displayedMonth: Date
    let onSelectDay: (Date) -> Void

    @Environment(FinanceStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Every day the same height, room for its number and two short figures (out and in) at
    /// their own size, so the rows line up whatever each day holds.
    @ScaledMetric(relativeTo: .caption) private var figuresDayHeight: CGFloat = 56
    /// At accessibility sizes a day holds its number and the dots only: kept to that, the tiles
    /// stood near three times as tall as wide (Simulator check 2026-11-04).
    @ScaledMetric(relativeTo: .caption) private var dotsDayHeight: CGFloat = 32
    private var dayHeight: CGFloat { typeSize.isAccessibilitySize ? dotsDayHeight : figuresDayHeight }
    /// The figures may shrink this far before a long one ("125,5tr") would be cut.
    private static let figureMinimumScale: CGFloat = 0.7
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

    /// What the two colours mean, small and quiet under the grid.
    private var legend: some View {
        HStack(spacing: Spacing.l) {
            HStack(spacing: Spacing.xs) {
                LegendDot(color: Palette.expense)
                Text("Chi")
            }
            HStack(spacing: Spacing.xs) {
                LegendDot(color: Palette.income)
                Text("Thu")
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
        // Days still ahead: a faint number on nothing, not tappable, nothing can be on them yet.
        let isAhead = date > calendar.startOfDay(for: .now) && !today
        let shape = RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous)
        let tile = isAhead ? Color.clear : today ? Palette.accent : Palette.surfaceMuted
        return Button { onSelectDay(date) } label: {
            VStack(spacing: 0) {
                Text("\(calendar.component(.day, from: date))")
                    .textRole(today ? .captionStrong : .caption)
                    .monospacedDigit()
                    .foregroundStyle(isAhead ? Palette.tertiaryLabel : today ? Palette.onAccent : Palette.label)
                figures(income: income, expense: expense, onLime: today)
                Spacer(minLength: 0)
            }
            .padding(.top, Spacing.xs + 2)
            .frame(maxWidth: .infinity, minHeight: dayHeight, maxHeight: dayHeight)
            .background(tile, in: shape)
            .contentShape(shape)
        }
        // Calendar cells are flat data tiles in the design; only the month control uses glass.
        .buttonStyle(.card)
        .disabled(isAhead)
        .accessibilityLabel(dayLabel(date, today: today, income: income, expense: expense))
        .accessibilityHint("Xem giao dịch trong ngày")
    }

    /// Out over in, each only when there is some. Short ("757k", "1,3tr", "2,1tỷ"), one line,
    /// shrinking a little before a long one would be cut. At accessibility sizes, where no figure
    /// fits a seventh of the card, a dot of each colour instead. On today's lime both are in ink:
    /// coral and green on it fell under 4:1, at night near 1.5:1; out stays above in, as on every day.
    @ViewBuilder
    private func figures(income: Double, expense: Double, onLime: Bool) -> some View {
        let out = onLime ? Palette.onAccent : Palette.expense
        let into = onLime ? Palette.onAccent : Palette.income
        if typeSize.isAccessibilitySize {
            HStack(spacing: Spacing.xxs) {
                if expense > 0 { LegendDot(color: out) }
                if income > 0 { LegendDot(color: into) }
            }
            .padding(.top, Spacing.xxs)
        } else {
            VStack(spacing: 0) {
                if expense > 0 {
                    Text(Self.short(expense))
                        .foregroundStyle(out)
                }
                if income > 0 {
                    Text(Self.short(income))
                        .foregroundStyle(into)
                }
            }
            .textRole(.footnote)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(Self.figureMinimumScale)
            .padding(.horizontal, Spacing.xxs)
        }
    }

    /// A figure in at most five characters, to fit a seventh of the card at one size: as
    /// `vndCompact`, but whole from 100 of a unit up ("126tr", not "125,5tr", which had to shrink
    /// beside its neighbours, Simulator check 2026-11-04).
    private static func short(_ amount: Double) -> String {
        let value = abs(amount)
        let whole = FloatingPointFormatStyle<Double>(locale: .vietnam).precision(.fractionLength(0))
        switch value {
        case 99_950_000_000...: return (value / 1_000_000_000).formatted(whole) + "tỷ"
        case 999_950_000...: return value.vndCompact
        case 99_950_000...: return (value / 1_000_000).formatted(whole) + "tr"
        default: return value.vndCompact
        }
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
