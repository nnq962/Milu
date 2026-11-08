import SwiftUI

/// The small blocks of Tổng quan, two side by side as the home screen's widgets (user pick "A"
/// 2026-11-04), now in two sections with their headings on the page (user request 2026-11-08):
/// "Chi tiêu" (what is left to spend this month, on the one blue block; what went out today with
/// the last seven days) and "Hũ và khoản vay" (the savings goal nearest full; the loan nearest its
/// deadline). Each says one thing, its picture or graphic on top, and opens what it is about. At
/// accessibility text sizes they stack one under another.
struct SpendingTiles: View {
    let onOpenReport: () -> Void
    let onOpenToday: () -> Void

    var body: some View {
        OutsideHeaderSection(title: "Chi tiêu") {
            Button(action: onOpenReport) { HeaderLink(title: "Báo cáo", opensPage: true) }
                .headerLinkButton()
        } content: {
            TilePair { BudgetTile(action: onOpenReport) } second: { TodayTile(action: onOpenToday) }
        }
    }
}

struct SavingTiles: View {
    let onAddGoal: () -> Void
    let onAddLoan: () -> Void

    var body: some View {
        OutsideHeaderSection(title: "Hũ và khoản vay") {
            TilePair { GoalTile(onAdd: onAddGoal) } second: { LoanTile(onAdd: onAddLoan) }
        }
    }
}

/// Two blocks side by side, as tall as each other; one under the other at accessibility sizes.
private struct TilePair<First: View, Second: View>: View {
    @ViewBuilder var first: First
    @ViewBuilder var second: Second

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: OverviewTileMetrics.gap) { first; second }
        } else {
            Grid(horizontalSpacing: OverviewTileMetrics.gap) {
                GridRow { first; second }
            }
        }
    }
}

/// One block: its graphic on top, a label, one figure, a line under it; on the card's white, on
/// the primary blue for the one that leads, or on the warning's pale ground once the month's
/// limit is passed.
private struct OverviewTile<Graphic: View>: View {
    let label: String
    let value: String
    var valueColor: Color = Palette.label
    let detail: String
    var detailColor: Color = Palette.secondaryLabel
    var ground: TileGround = .plain
    let accessibility: String
    let hint: String
    let action: () -> Void
    @ViewBuilder let graphic: Graphic

    @ScaledMetric(relativeTo: .body) private var scaledGraphic = OverviewTileMetrics.graphic
    /// Grows with the text, no more than 1.6 times (review 2026-11-08: about 150 tall at AX5).
    private var graphicHeight: CGFloat { RowMetrics.capped(scaledGraphic, base: OverviewTileMetrics.graphic) }

    var body: some View {
        let ink = ground.ink
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                graphic
                    .frame(height: graphicHeight, alignment: .bottomLeading)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    // One line, so the figures of two tiles side by side stand level whatever the
                    // label (a long goal name wrapped and pushed its % lower).
                    Text(label)
                        .textRole(.captionStrong)
                        // Shrinks a little before "Tháng này đã…" at the larger text sizes.
                        .shrinksOnlyToFit(0.8)
                        .foregroundStyle(ink ?? Palette.secondaryLabel)
                    Text(value)
                        .textRole(.pageTitle)
                        .monospacedDigit()
                        .foregroundStyle(ink ?? valueColor)
                        .shrinksOnlyToFit(0.7)
                    Text(detail)
                        .textRole(.caption)
                        .foregroundStyle(ink ?? detailColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(OverviewTileMetrics.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .cardSurface(radius: CardCorners.card, color: ground.fill)
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.card, style: .continuous))
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
        .accessibilityHint(hint)
    }
}

/// What a tile stands on, and the ink its words take there.
private enum TileGround {
    case plain, accent, warning

    var fill: Color {
        switch self {
        case .plain: Palette.surface
        case .accent: Palette.accent
        case .warning: Palette.warningSoft
        }
    }

    /// One ink for all the words on a coloured ground; nil keeps each word's own colour.
    var ink: Color? {
        switch self {
        case .plain: nil
        case .accent: Palette.onAccent
        case .warning: Palette.warning
        }
    }
}

private enum OverviewTileMetrics {
    /// The picture, ring or bars on top of a block.
    static let graphic: CGFloat = IconSize.cardArtwork
    static let padding: CGFloat = Spacing.l
    static let ringLine: CGFloat = 6
    static let gap: CGFloat = Spacing.m
}

// MARK: - Còn tiêu được

/// What the month's limit still allows, on the blue block: a ring of how much is used. Over the limit,
/// by how much; with no limit set, what went out. Opens the month's report.
private struct BudgetTile: View {
    let action: () -> Void

    @Environment(FinanceStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    /// The ring runs up to what is used as the block shows.
    @State private var shown: Double = 0

    var body: some View {
        let spent = store.total(.expense, inMonthOf: .now)
        let used = monthlyBudget > 0 ? spent / monthlyBudget : 0
        let words = words(spent: spent, used: used)
        let over = monthlyBudget > 0 && spent > monthlyBudget
        // Over the limit, the whole block turns to the warning's colours, which read in both
        // modes (review 2026-11-08: an apricot ring all but vanished on the night blue).
        OverviewTile(label: words.label, value: words.value, detail: words.detail,
                     ground: over ? .warning : .accent,
                     accessibility: words.spoken, hint: "Xem báo cáo tháng này", action: action) {
            ring(min(used, 1) * shown, ink: over ? Palette.warning : Palette.onAccent)
        }
        .onAppear {
            guard shown == 0 else { return }
            if reduceMotion { shown = 1 } else {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) { shown = 1 }
            }
        }
    }

    /// A faint track and the part used, from the top, in the block's ink.
    private func ring(_ fraction: Double, ink: Color) -> some View {
        ZStack {
            Circle().stroke(ink.opacity(0.14), lineWidth: OverviewTileMetrics.ringLine)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(ink, style: StrokeStyle(lineWidth: OverviewTileMetrics.ringLine, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(OverviewTileMetrics.ringLine / 2)
        .aspectRatio(1, contentMode: .fit)
    }

    private func words(spent: Double, used: Double) -> (label: String, value: String, detail: String, spoken: String) {
        guard monthlyBudget > 0 else {
            return ("Tháng này đã chi", spent.vndCompact, "Chưa đặt hạn mức",
                    "Tháng này đã chi \(MoneyText.spoken(spent)), chưa đặt hạn mức")
        }
        if spent > monthlyBudget {
            let over = spent - monthlyBudget
            return ("Vượt hạn mức", over.vndCompact, "Đã chi \(spent.vndCompact) / \(monthlyBudget.vndCompact)",
                    "Vượt hạn mức \(MoneyText.spoken(over)), đã chi \(MoneyText.spoken(spent)) trên \(MoneyText.spoken(monthlyBudget))")
        }
        let left = monthlyBudget - spent
        return ("Còn tiêu được", left.vndCompact, "Đã dùng \(used.percentText) hạn mức",
                "Còn tiêu được \(MoneyText.spoken(left)), đã dùng \(used.percentText) hạn mức \(MoneyText.spoken(monthlyBudget))")
    }
}

// MARK: - Hôm nay

/// What went out today, and a column for each of the last seven days, today's in the primary blue, the days before in the grey-blue of the chart's rest. Opens
/// today's transactions.
private struct TodayTile: View {
    let action: () -> Void

    @Environment(FinanceStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var grown: CGFloat = 0

    /// A day with nothing still shows a stub; today at least this tall, so its blue is there to see.
    private static let stub: CGFloat = 0.08
    private static let todayMinimum: CGFloat = 0.18

    var body: some View {
        let days = lastSevenDays()
        let today = days.last?.spent ?? 0
        let week = days.reduce(0) { $0 + $1.spent }
        let biggest = max(days.map(\.spent).max() ?? 0, 1)
        OverviewTile(label: "Hôm nay đã chi", value: today.vndCompact,
                     valueColor: today > 0 ? Palette.expense : Palette.label,
                     detail: "7 ngày qua: \(week.vndCompact)",
                     accessibility: "Hôm nay đã chi \(MoneyText.spoken(today)), 7 ngày qua \(MoneyText.spoken(week))",
                     hint: "Xem giao dịch hôm nay", action: action) {
            HStack(alignment: .bottom, spacing: Spacing.xs) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    let isToday = index == days.count - 1
                    let share = day.spent > 0 ? day.spent / biggest : 0
                    // Today keeps a taller stub only when something went out; with 0đ it is the
                    // same empty stub as any day (review 2026-11-08: a blue bar read as spending).
                    let height = isToday && day.spent > 0 ? max(share, Self.todayMinimum) : max(share, Self.stub)
                    GeometryReader { proxy in
                        VStack {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: CardCorners.mark, style: .continuous)
                                // Today in the primary blue, the days before in the grey-blue of the
                                // chart's rest (3:1 on the card by day and night), empty days a faint
                                // stub: pale sky could not be told from an empty day (review 2026-11-08).
                                .fill(day.spent == 0 ? Palette.progressTrack : isToday ? Palette.accent : Palette.chartRest)
                                .frame(height: proxy.size.height * height * grown)
                        }
                    }
                }
            }
        }
        .onAppear {
            guard grown == 0 else { return }
            if reduceMotion { grown = 1 } else {
                withAnimation(.spring(duration: 0.7, bounce: 0.25).delay(0.25)) { grown = 1 }
            }
        }
    }

    /// The last seven days, oldest first, each with what went out on it (reported ones only, as
    /// the calendar and Day's sheet).
    private func lastSevenDays() -> [(day: Date, spent: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let byDay = Dictionary(grouping: store.reportableTransactions(in: DateInterval(start: start, end: end))
            .filter { $0.kind == .expense }) { calendar.startOfDay(for: $0.date) }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start).map { day in
                (day, byDay[day]?.reduce(0) { $0 + $1.amount } ?? 0)
            }
        }
    }
}

// MARK: - Hũ tiết kiệm

/// The savings goal nearest full that is not full yet, in its Fluent Flat picture. With no goal, a way to
/// make the first.
private struct GoalTile: View {
    let onAdd: () -> Void

    @Environment(FinanceStore.self) private var store
    @State private var openGoal: Opened?

    var body: some View {
        let goals = store.activeGoals
        let goal = goals.filter { !$0.isReached }.max { $0.progress < $1.progress } ?? goals.first
        Group {
            if let goal {
                OverviewTile(label: goal.name, value: goal.isReached ? "100%" : goal.progressText,
                             detail: goal.isReached ? "Đã đủ mục tiêu" : "Còn \(goal.remaining.vndCompact)",
                             // Said as shown: a full goal is "đã đủ mục tiêu", not "còn 0 đồng".
                             accessibility: goal.isReached
                                 ? "Hũ \(goal.name), đã đủ mục tiêu"
                                 : "Hũ \(goal.name), đã để dành \(goal.progressText), còn \(MoneyText.spoken(goal.remaining))",
                             hint: "Xem hũ", action: { openGoal = Opened(id: goal.id) }) {
                    picture(GoalArtwork.name(for: goal.icon))
                }
            } else {
                // "Không còn" once every goal was closed: "Chưa có" told someone with a
                // history of goals that they never had one (review 2026-11-08).
                let hadSome = !store.savingsGoals.isEmpty
                OverviewTile(label: "Hũ tiết kiệm", value: hadSome ? "Không còn" : "Chưa có",
                             detail: hadSome ? "Tạo hũ mới" : "Tạo hũ đầu tiên",
                             accessibility: hadSome ? "Không còn hũ đang để dành" : "Chưa có hũ tiết kiệm",
                             hint: "Tạo hũ", action: onAdd) {
                    picture(IconCatalog.emojiName("🐷"))
                }
            }
        }
        .sheet(item: $openGoal) { GoalDetailSheet(goalID: $0.id) }
    }
}

// MARK: - Khoản vay

/// The open loan nearest its deadline (the longest overdue first), who and how much is left, the
/// deadline in its urgency's colour. With no open loan, a way to note one.
private struct LoanTile: View {
    let onAdd: () -> Void

    @Environment(FinanceStore.self) private var store
    @State private var openLoan: Opened?

    var body: some View {
        let loan = store.loans.filter { !$0.isSettled }.min { LoanUrgency($0) < LoanUrgency($1) }
        Group {
            if let loan {
                let urgency = LoanUrgency(loan)
                // Which way the money goes on top, how soon in the line under it: "Quá hạn" in both
                // read twice and hid whether it was lent or owed (review 2026-11-08).
                let label = loan.direction == .lent ? "Cho vay" : "Đang nợ"
                OverviewTile(label: label, value: loan.outstanding.vndCompact,
                             valueColor: loan.direction == .borrowed ? Palette.expense : Palette.label,
                             detail: "\(loan.name) · \(urgency.text)",
                             detailColor: LoanRow.urgencyColor(urgency),
                             accessibility: "\(label), \(loan.name), còn \(MoneyText.spoken(loan.outstanding)), \(urgency.text)",
                             hint: "Xem khoản vay", action: { openLoan = Opened(id: loan.id) }) {
                    // The base size: the avatar grows with the text by itself.
                    InitialsAvatar(name: loan.name, size: OverviewTileMetrics.graphic)
                }
            } else {
                let hadSome = !store.loans.isEmpty
                OverviewTile(label: "Khoản vay", value: hadSome ? "Không còn" : "Chưa có",
                             detail: hadSome ? "Đã tất toán hết" : "Ghi khoản cho vay",
                             accessibility: hadSome ? "Không còn khoản vay nào, đã tất toán hết" : "Chưa có khoản vay",
                             hint: "Ghi khoản vay", action: onAdd) {
                    picture(IconCatalog.emojiName("🤝"))
                }
            }
        }
        .sheet(item: $openLoan) { LoanDetailSheet(loanID: $0.id) }
    }
}

/// What a block's sheet opens on.
private struct Opened: Identifiable {
    let id: UUID
}

/// A block's Fluent Flat picture, at the graphic's height.
private func picture(_ name: String) -> some View {
    Image(name)
        .resizable()
        .scaledToFit()
}

// MARK: - Tuần này

/// This week, Monday to Sunday, as the calendar draws its days; "Lịch ›" opens the whole month.
/// In place of the month on Tổng quan (2026-11-04): most of a month's days were still ahead and
/// filled the page with grey numbers.
struct WeekCard: View {
    let onOpenCalendar: () -> Void
    let onSelectDay: (Date) -> Void

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let back = (calendar.component(.weekday, from: today) + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -back, to: today) ?? today
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
        let end = calendar.date(byAdding: .day, value: 7, to: monday) ?? today
        let byDay = Dictionary(grouping: store.reportableTransactions(in: DateInterval(start: monday, end: end))) {
            calendar.startOfDay(for: $0.date)
        }
        // The heading on the page over the card, as every section of Tổng quan (2026-11-08).
        OutsideHeaderSection(title: "Tuần này") {
            Button(action: onOpenCalendar) { HeaderLink(title: "Lịch", opensPage: true) }
                .headerLinkButton()
        } content: {
            Grid(horizontalSpacing: Spacing.xs, verticalSpacing: Spacing.xs) {
                GridRow {
                    ForEach(["T2", "T3", "T4", "T5", "T6", "T7", "CN"], id: \.self) { title in
                        Text(title)
                            .textRole(.footnote)
                            .foregroundStyle(Palette.secondaryLabel)
                            .shrinksOnlyToFit(0.5, alignment: .center)
                            .frame(maxWidth: .infinity)
                            .accessibilityHidden(true)
                    }
                }
                GridRow {
                    ForEach(days, id: \.self) { day in
                        CalendarDayCell(date: day, items: byDay[day] ?? []) { onSelectDay(day) }
                    }
                }
            }
            .card()
        }
    }
}

// MARK: - Lịch thu chi

/// Pushes the month calendar from "Tuần này".
struct CalendarRoute: Hashable {}

/// "Lịch thu chi" on a page of its own: the month menu, the month's days, tap one for its list.
struct MoneyCalendarPage: View {
    @State private var month = Date.now
    @State private var selectedDay: Day?

    private struct Day: Identifiable {
        let date: Date
        var id: Date { date }
    }

    var body: some View {
        ScrollView {
            // The heading on the page over its card, as on Tổng quan (review 2026-11-08).
            OutsideHeaderSection(title: "Theo ngày") {
                MonthPickerButton(month: $month, compact: true)
            } content: {
                MoneyCalendarCard(displayedMonth: $month) { selectedDay = Day(date: $0) }
                    .card()
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.l)
            .padding(.bottom, Spacing.xxl)
        }
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Lịch thu chi")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDay) { DayTransactionsSheet(date: $0.date) }
    }
}
