import SwiftUI

/// "Lịch thu chi": a month grid and its legend; the page puts them on a card under the
/// section heading that holds the month menu (2026-10-31). Each day shows its number and, under
/// it, what went out in red and what came in in green, both short ("757k", "2,5tr"):
/// at a glance which days cost what (user pick "B" 2026-11-04, after shades alone read pale).
/// Every day gone by is a pale tile, today a blue one, days ahead a faint number on nothing (user
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
    @ScaledMetric(relativeTo: .caption) private var figuresDayHeight = CalendarDayCell.figuresHeight
    @ScaledMetric(relativeTo: .caption) private var dotsDayHeight = CalendarDayCell.dotsHeight
    private var dayHeight: CGFloat { typeSize.isAccessibilitySize ? dotsDayHeight : figuresDayHeight }
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
                        .shrinksOnlyToFit(0.5, alignment: .center)
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
                        CalendarDayCell(date: date, items: items) { onSelectDay(date) }
                    }
                }
            }
            CalendarLegend()
                .padding(.top, Spacing.s)
        }
    }
}

/// What the calendar's two colours mean, small and quiet under its days.
struct CalendarLegend: View {
    var body: some View {
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
}

/// One day of "Lịch thu chi", and of "Tuần này" on Tổng quan: its number and, under it, what went
/// out over what came in. A day gone by is a pale tile, today a blue one, a day ahead a faint
/// number on nothing, not tappable.
struct CalendarDayCell: View {
    let date: Date
    let income: Double
    let expense: Double
    let action: () -> Void

    /// Room for the number and two short figures at their own size, so the rows line up whatever
    /// each day holds; at accessibility sizes the number and the dots only (kept at the figures'
    /// height, the tiles stood near three times as tall as wide, Simulator check 2026-11-04).
    static let figuresHeight: CGFloat = 56
    static let dotsHeight: CGFloat = 32
    /// The figures may shrink this far before a long one would be cut.
    private static let figureMinimumScale: CGFloat = 0.7

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .caption) private var figuresHeight = CalendarDayCell.figuresHeight
    @ScaledMetric(relativeTo: .caption) private var dotsHeight = CalendarDayCell.dotsHeight

    /// The day's figures from its reported transactions (`reportableTransactions`, as Day's sheet).
    init(date: Date, items: [FinanceTransaction], action: @escaping () -> Void) {
        self.date = date
        income = items.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        expense = items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        self.action = action
    }

    var body: some View {
        let calendar = Calendar.current
        let today = calendar.isDateInToday(date)
        let isAhead = date > calendar.startOfDay(for: .now) && !today
        let shape = RoundedRectangle(cornerRadius: CardCorners.small, style: .continuous)
        let tile = isAhead ? Color.clear : today ? Palette.accent : Palette.surfaceMuted
        let height = typeSize.isAccessibilitySize ? dotsHeight : figuresHeight
        Button(action: action) {
            // At their own height, no cap: capped, a day with both figures squeezed them smaller
            // than a day with one, and its number sat higher (user report 2026-11-08). Every day
            // keeps the same three lines, so all the tiles of a row stand alike.
            VStack(spacing: 0) {
                Text("\(calendar.component(.day, from: date))")
                    .textRole(today ? .captionStrong : .caption)
                    .monospacedDigit()
                    // Shrinks rather than "…" at the accessibility sizes, where a seventh of the
                    // card is narrower than "28" (review 2026-11-08).
                    .shrinksOnlyToFit(0.5, alignment: .center)
                    .foregroundStyle(isAhead ? Palette.tertiaryLabel : today ? Palette.onAccent : Palette.label)
                figures(onAccent: today)
            }
            .padding(.vertical, Spacing.xs + 2)
            .frame(maxWidth: .infinity, minHeight: height, alignment: .top)
            .background(tile, in: shape)
            .contentShape(shape)
        }
        // Calendar cells are flat data tiles in the design; only the month control uses glass.
        .buttonStyle(.card)
        .disabled(isAhead)
        .accessibilityLabel(label(today: today))
        // A day ahead cannot be opened: no hint promising it.
        .accessibilityHint(isAhead ? "" : "Xem giao dịch trong ngày")
    }

    /// Out on the first line, in always on the second, each shown only when there is some: a day
    /// with money in only keeps the first line empty, so in sits in the same place on every day
    /// (user request 2026-11-08). Short ("757k", "1,3tr", "2,1tỷ"), one line, shrinking a little
    /// only when one is too wide for its tile. At accessibility sizes, where no figure
    /// fits a seventh of the card, a dot of each colour instead, out on the left and in on the
    /// right, each in its place even when the other is missing. On today's blue both are in its
    /// ink (red and green on it fell under 4:1): out a filled dot, in a ring, so the two still
    /// differ there (review 2026-11-08).
    @ViewBuilder
    private func figures(onAccent: Bool) -> some View {
        let out = onAccent ? Palette.onAccent : Palette.expense
        let into = onAccent ? Palette.onAccent : Palette.income
        if typeSize.isAccessibilitySize {
            HStack(spacing: Spacing.xxs) {
                LegendDot(color: out)
                    .opacity(expense > 0 ? 1 : 0)
                Group {
                    if onAccent {
                        Circle().strokeBorder(into, lineWidth: 1.5)
                            .frame(width: RowMetrics.legendDot, height: RowMetrics.legendDot)
                    } else {
                        LegendDot(color: into)
                    }
                }
                .opacity(income > 0 ? 1 : 0)
                .accessibilityHidden(true)
            }
            .padding(.top, Spacing.xxs)
        } else {
            VStack(spacing: 0) {
                figure(expense, color: out)
                figure(income, color: into)
            }
            .textRole(.footnote)
            .monospacedDigit()
            .lineLimit(1)
            .padding(.horizontal, Spacing.xxs)
        }
    }

    /// One line of figures; with nothing, the line is kept, unseen.
    /// At its own width when it fits, centred under the day's number; shrunk only when too wide
    /// for its tile, and centred then too (Simulator check 2026-11-08).
    private func figure(_ amount: Double, color: Color) -> some View {
        Text(amount > 0 ? Self.short(amount) : "0")
            .shrinksOnlyToFit(Self.figureMinimumScale, alignment: .center)
            .foregroundStyle(color)
            .opacity(amount > 0 ? 1 : 0)
            .accessibilityHidden(true)
    }

    /// A figure in at most five characters, to fit a seventh of the card at one size: as
    /// `vndCompact`, but whole from 100 of a unit up ("126tr", not "125,5tr", which had to shrink
    /// beside its neighbours, Simulator check 2026-11-04).
    static func short(_ amount: Double) -> String {
        let value = abs(amount)
        let whole = FloatingPointFormatStyle<Double>(locale: .vietnam).precision(.fractionLength(0))
        switch value {
        case 99_950_000_000...: return (value / 1_000_000_000).formatted(whole) + "tỷ"
        case 999_950_000...: return value.vndCompact
        case 99_950_000...: return (value / 1_000_000).formatted(whole) + "tr"
        default: return value.vndCompact
        }
    }

    /// Only the figures there are; an empty day says so (re-review 2026-10-31: "thu 0đ, chi 0đ"); a
    /// day ahead only its name. The day in full words, the year only in another year: `.month()`
    /// was read "3 thg 11, 2026" on every tile (review 2026-11-08).
    private func label(today: Bool) -> String {
        let style = Date.FormatStyle.dateTime.weekday(.wide).day().month(.wide).locale(.vietnam)
        let sameYear = Calendar.current.isDate(date, equalTo: .now, toGranularity: .year)
        let name = (today ? "Hôm nay, " : "") + date.formatted(sameYear ? style : style.year())
        if date > Calendar.current.startOfDay(for: .now), !today { return name }
        var figures: [String] = []
        // Out before in, as the tile shows them (review 2026-11-08).
        if expense > 0 { figures.append("chi \(MoneyText.spoken(expense))") }
        if income > 0 { figures.append("thu \(MoneyText.spoken(income))") }
        return name + ", " + (figures.isEmpty ? "không có thu chi" : figures.joined(separator: ", "))
    }
}
