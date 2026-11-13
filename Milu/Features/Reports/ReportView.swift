import Charts
import SwiftUI

/// "Báo cáo" (user choice 2026-10-30), opened from the month card on Tổng quan and the totals on
/// Giao dịch. For a week or a month: spent against the period before, the limit, received and what
/// is left; where the money came from and went (Dòng tiền); spending by group (each opens the
/// group); in and out over the latest six periods; and money in and out per account. A part with
/// nothing in the period is left out; a period with nothing at all says so once, under the totals
/// (review 2026-11-08: parts came and went by different rules). Counts as every report does.
struct ReportView: View {
    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = 0.0
    @State private var period: ReportPeriod
    /// The group opened from the list: pushed by value from the page, not by a link in its row,
    /// so a row that leaves the list (the group page moved to a period with none of it) does not
    /// take the open page with it (review 2026-11-08).
    @State private var openGroup: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The charts grow with the text, so their labels keep room (strict review 2026-10-31).
    @ScaledMetric(relativeTo: .footnote) private var barsHeight: CGFloat = 180

    init(period: ReportPeriod = ReportPeriod(.month)) {
        _period = State(initialValue: period)
    }


    var body: some View {
        // Each period read once and every figure taken from it (review 2026-11-08: some 25 reads
        // of every transaction per redraw).
        let items = store.reportableTransactions(in: period.interval)
        let earlier = store.reportableTransactions(in: period.comparison())
        let spent = store.total(.expense, of: items)
        let received = store.total(.income, of: items)
        let groups = store.expensesByCategory(of: items)
        let before = Dictionary(uniqueKeysWithValues: store.expensesByCategory(of: earlier).map { ($0.groupID, $0.amount) })

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                ReportPeriodBar(period: $period)
                totals(spent: spent, received: received, spentBefore: store.total(.expense, of: earlier))
                if spent == 0 && received == 0 {
                    // "kỳ này", not "tháng này": a past month is not this month (review 2026-11-08).
                    EmptyStateCard(title: "Chưa có thu chi",
                                   message: "Khoản thu, chi trong kỳ này sẽ hiện ở đây.",
                                   picture: IconCatalog.emojiName("📊"))
                }
                // Dòng tiền only with both: income alone drew one band into "Còn dư", spending
                // alone one grey bar fanning out, neither saying more than the totals and the
                // list (review 2026-11-08).
                if spent > 0 && received > 0 {
                    cashFlow(groups, incomes: store.incomesByCategory(of: items), received: received, spent: spent)
                }
                if spent > 0 {
                    categories(groups, spent: spent, before: before)
                }
                trend
                accounts(items)
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxl)
        }
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Báo cáo")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $openGroup) { groupID in
            CategoryReportView(groupID: groupID, period: period) { period = $0 }
        }
    }

    // MARK: - Tổng

    /// One lead figure, then everything else at one smaller size (user report 2026-11-08: five
    /// amounts at three sizes, four of them red, read as clutter). What was spent and how it
    /// moved; the month's limit; then what came in and what is left, side by side.
    private func totals(spent: Double, received: Double, spentBefore: Double) -> some View {
        let net = received - spent
        return VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Đã chi")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                // In ink, as "Hôm nay đã chi" on Tổng quan: the word says it is money out, and
                // the one red left on the card is a month spent past what came in.
                MoneyText(amount: spent, size: .display, tone: .neutral)
                ChangeLabel(now: spent, before: spentBefore, period: period, risingIsBad: true)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            if period.unit == .month { budget(spent: spent) }

            footer(received: received, net: net)
                .padding(.top, Spacing.m)
                .overlay(alignment: .top) { SplitLine() }
        }
        .card(padding: Spacing.xl)
    }

    /// "Đã thu" and "Còn dư" (or "Chi vượt thu", red with no "-": the words say it, review
    /// 2026-11-08), the names Dòng tiền gives them too. Side by side; one under the other at the
    /// accessibility sizes, where each half was too narrow for its words.
    @ViewBuilder
    private func footer(received: Double, net: Double) -> some View {
        let income = stat("Đã thu", amount: received, tone: received > 0 ? .signedIncome : .neutral)
        if received == 0 {
            // Nothing came in: "Chi vượt thu" would only repeat "Đã chi" in red, every period, for
            // someone who records spending alone (review 2026-11-08).
            income
        } else {
            footerPair(income: income, net: net)
        }
    }

    @ViewBuilder
    private func footerPair(income: some View, net: Double) -> some View {
        let rest = net >= 0
            ? stat("Còn dư", amount: net, tone: net > 0 ? .signedIncome : .neutral)
            : stat("Chi vượt thu", amount: -net, tone: .expense)
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.m) {
                income
                rest
                    .padding(.top, Spacing.m)
                    .overlay(alignment: .top) { SplitLine() }
            }
        } else {
            HStack(alignment: .top, spacing: 0) {
                income
                    .padding(.trailing, Spacing.l)
                    .overlay(alignment: .trailing) { VerticalDivider() }
                rest
                    .padding(.leading, Spacing.l)
            }
        }
    }

    /// A small figure under its name, both sides of the card's foot alike.
    private func stat(_ title: String, amount: Double, tone: MoneyText.Tone) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            MoneyText(amount: amount, tone: tone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// A month's limit, as on Tổng quan, opening Hạn mức chi tiêu (review fix 2026-10-30); with
    /// none set, the way to set one, where people look for it (review 2026-11-08).
    @ViewBuilder
    private func budget(spent: Double) -> some View {
        if monthlyBudget > 0 {
            NavigationLink { BudgetView(month: period.start) } label: { budgetRow(spent: spent) }
                .buttonStyle(.automatic)
        } else {
            NavigationLink { BudgetView(month: period.start) } label: {
                // The link under the words at the accessibility sizes, where side by side the
                // words were cut to "Hạn…" (review 2026-11-08).
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Text("Hạn mức tháng")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                            .fixedSize()
                        Spacer(minLength: Spacing.s)
                        HeaderLink(title: "Đặt hạn mức", opensPage: true)
                    }
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Hạn mức tháng")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                        HeaderLink(title: "Đặt hạn mức", opensPage: true)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    /// The bar, then where it stands in the app's one look for a limit (`BudgetStatusLine`,
    /// strict review 2026-10-31) with ›: one line under the bar, no heading over it (user report
    /// 2026-11-08: the card had too many lines of words).
    private func budgetRow(spent: Double) -> some View {
        let progress = BudgetProgress(limit: monthlyBudget, spent: spent)
        return VStack(alignment: .leading, spacing: Spacing.s) {
            ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                BudgetStatusLine(level: .init(progress),
                                 message: progress.isOver ? "Vượt hạn mức \((-progress.left).vnd)"
                                     : "Đã dùng \(progress.percentText) hạn mức \(monthlyBudget.vnd)")
                Spacer(minLength: Spacing.s)
                RowChevron()
            }
        }
        .foregroundStyle(Palette.label)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Mở hạn mức chi tiêu")
    }

    // MARK: - Theo hạng mục

    @ViewBuilder
    private func categories(_ groups: [CategoryTotal], spent: Double, before: [String: Double]) -> some View {
        // Shown only with spending (see `body`).
        if !groups.isEmpty {
            ReportSection(title: "Chi theo hạng mục") {
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    Button { openGroup = group.groupID } label: {
                        // "−" in ink as every list of money out (B+, 2026-11-03), as the
                        // transactions on the group's page (review 2026-11-08: all red here).
                        BreakdownRowLabel(icon: group.icon, title: group.name,
                                          detail: detail(group, share: group.amount / spent, before: before),
                                          amount: group.amount, tone: .outflow, dot: color(at: index),
                                          edgedDot: ChartShades.isRest(at: index))
                    }
                    .buttonStyle(.row)
                    .separatorAbove(index > 0, order: index) { RowDivider() }
                }
            }
        }
    }

    /// "32% · ↑ 15%", the share of all spending and the move since the period before ("mới" for a
    /// group not spent on then); the share alone when nothing was recorded before.
    private func detail(_ group: CategoryTotal, share: Double, before: [String: Double]) -> String {
        guard !before.isEmpty else { return share.percentText }
        guard let move = Change.text(group.amount, from: before[group.groupID] ?? 0) else { return "\(share.percentText) · mới" }
        return "\(share.percentText) · \(move)"
    }

    private func color(at index: Int) -> Color {
        ChartShades.color(at: index)
    }

    // MARK: - Dòng tiền

    /// Where the money came from and went (user request 2026-11-08), in place of the ring: the
    /// first three sources of income ("Thu khác" for the rest) and "Chi vượt thu" when more went
    /// out than came in (not "Lấy từ số dư": it may have gone on a card or a loan, review
    /// 2026-11-08); the five largest groups in the list's colours, "Khác" and "Còn dư", the names
    /// the totals card uses.
    @ViewBuilder
    private func cashFlow(_ groups: [CategoryTotal], incomes: [CategoryTotal], received: Double, spent: Double) -> some View {
            let shownIncomes = 3, shownGroups = ChartShades.steps.count
            let otherIncome = incomes.dropFirst(shownIncomes).reduce(0) { $0 + $1.amount }
            let otherSpending = groups.dropFirst(shownGroups).reduce(0) { $0 + $1.amount }
            let sources = incomes.prefix(shownIncomes).map {
                CashFlowChart.Node(id: "in-\($0.groupID)", name: $0.name, amount: $0.amount, color: Palette.income, kind: .income)
            }
                + (otherIncome > 0 ? [.init(id: "in-other", name: "Thu khác", amount: otherIncome, color: Palette.income, kind: .income)] : [])
                + (spent > received ? [.init(id: "over", name: "Chi vượt thu", amount: spent - received,
                                             color: ChartShades.rest, kind: .over)] : [])
            let sinks = groups.prefix(shownGroups).enumerated().map { index, group in
                CashFlowChart.Node(id: "out-\(group.groupID)", name: group.name, amount: group.amount,
                                   color: color(at: index), kind: .spending)
            }
                + (otherSpending > 0 ? [.init(id: "out-other", name: "Khác", amount: otherSpending, color: ChartShades.rest, kind: .spending)] : [])
                + (received > spent ? [.init(id: "kept", name: "Còn dư", amount: received - spent, color: Palette.income, kind: .kept)] : [])
            OutsideHeaderSection(title: "Dòng tiền") {
                CashFlowChart(sources: sources, sinks: sinks, resetKey: period)
                    .card()
                    // Drawn at once on a new period: the page's ‹ › animate, and the labels slid
                    // while the canvas, which cannot, jumped (review 2026-11-08).
                    .transaction { $0.animation = nil }
            }
    }

    // MARK: - Xu hướng

    @ViewBuilder
    private var trend: some View {
        // Always the six up to now, whichever one is being looked at (user report 2026-11-08:
        // picking October showed May to October, no longer "gần đây"); the one looked at is lit.
        let periods = ReportPeriod(period.unit).lastPeriods(6)
        let unit = period.unit.title.lowercased()
        // The six read at once, then split (review 2026-11-08: twelve reads plus six more).
        let span = DateInterval(start: periods[0].start, end: periods[periods.count - 1].interval.end)
        let all = store.reportableTransactions(in: span)
        let byPeriod = periods.map { item in all.filter { item.interval.holds($0.date) } }
        // Nothing in all six: a short line, not an empty chart that looks broken (review 2026-10-30).
        if byPeriod.allSatisfy(\.isEmpty) {
            OutsideHeaderSection(title: "Thu chi \(periods.count) \(unit) gần đây") {
                EmptyStateCard(title: "Chưa có thu chi",
                               message: "Thu chi từng \(unit) sẽ hiện ở đây.",
                               picture: IconCatalog.emojiName("📈"))
            }
        } else {
            trendChart(periods, byPeriod)
        }
    }

    private func trendChart(_ periods: [ReportPeriod], _ byPeriod: [[FinanceTransaction]]) -> some View {
        let rows = zip(periods, byPeriod).flatMap { item, items in
            [TrendBar(period: item, kind: "Thu", amount: store.total(.income, of: items)),
             TrendBar(period: item, kind: "Chi", amount: store.total(.expense, of: items))]
        }
        // Averaged over the past periods that have spending: months before the app was used, and
        // the one still running, would pull it down (review 2026-11-08).
        let spending = rows.filter { $0.kind == "Chi" && $0.amount > 0 && !$0.period.isCurrent() }.map(\.amount)
        let unit = period.unit.title.lowercased()
        // A footer for the computed figure only (strict review 2026-10-31: no explanatory footers).
        // The bars are to look at: a period is picked with the title's ⌄ at the top, where the
        // page changes in view (review 2026-11-08: tapping a bar down here changed the page
        // above, out of sight, and VoiceOver could not do it).
        let average = spending.count > 1 ? spending.reduce(0, +) / Double(spending.count) : nil
        return ReportSection(title: "Thu chi \(periods.count) \(unit) gần đây",
                             footer: average.map { "Các \(unit) trước chi trung bình \($0.vnd) mỗi \(unit)." }) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(spacing: Spacing.l) {
                    legend("Thu", color: Palette.positive)
                    legend("Chi", color: Palette.negative)
                }
                // A bar with money in it at least a short pill: a few points tall, shorter than it
                // is wide, its round ends flattened into a square (user report 2026-11-08: T11's
                // 850k beside 30tr). The real figure stays in VoiceOver.
                let least = (rows.map(\.amount).max() ?? 0) * 0.06
                Chart(rows) { row in
                    BarMark(x: .value("Kỳ", row.period.shortTitle),
                            y: .value("Tiền", row.amount > 0 ? max(row.amount, least) : 0), width: .ratio(0.8))
                        .position(by: .value("Loại", row.kind))
                        .clipShape(Capsule())
                        .foregroundStyle(row.kind == "Thu" ? Palette.positive : Palette.negative)
                        // Lit: the one looked at; all alike when it is older than the six.
                        .opacity(row.period == period || !periods.contains(period) ? 1 : 0.35)
                        .accessibilityLabel("\(row.kind) \(row.period.title)")
                        // The real figure in words, as every amount (the bar may be drawn taller).
                        .accessibilityValue(MoneyText.spoken(row.amount))
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine().foregroundStyle(Palette.separator)
                        AxisValueLabel {
                            // The axis is too narrow for the full figure: the one place that keeps "4,3tr".
                            Text((value.as(Double.self) ?? 0).vndCompact)
                                .textRole(.footnote)
                                .foregroundStyle(Palette.secondaryLabel)
                        }
                    }
                }
                .chartXAxis {
                    // The same type as the amounts on the other axis.
                    AxisMarks { value in
                        AxisValueLabel {
                            Text(value.as(String.self) ?? "")
                                .textRole(.footnote)
                                .foregroundStyle(Palette.secondaryLabel)
                        }
                    }
                }
                .frame(height: barsHeight)
            }
            .padding(RowMetrics.horizontal)
        }
    }

    private struct TrendBar: Identifiable {
        let period: ReportPeriod
        let kind: String
        let amount: Double
        var id: String { "\(period.start.timeIntervalSince1970)-\(kind)" }
    }

    private func legend(_ title: String, color: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            LegendDot(color: color)
            Text(title)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
        }
    }

    // MARK: - Theo tài khoản

    @ViewBuilder
    private func accounts(_ items: [FinanceTransaction]) -> some View {
        let totals = store.totalsByAccount(of: items)
        if !totals.isEmpty {
            ReportSection(title: "Theo tài khoản") {
                ForEach(Array(totals.enumerated()), id: \.element.id) { index, account in
                    // Opens the account or hũ, like a group opens its detail (review fix 2026-10-30).
                    let label = BreakdownRowLabel(icon: account.icon, title: account.name,
                                                  detail: account.income > 0 ? "Thu +\(account.income.vnd)" : "Không có khoản thu",
                                                  amount: account.expense,
                                                  tone: account.expense > 0 ? .signedExpense : .neutral,
                                                  isAccount: true)
                    // A hũ or an account in a sheet, as from every list (user choices 2026-11-01).
                    Group {
                        if store.goal(id: account.id) != nil {
                            GoalSheetLink(goalID: account.id) { label }
                        } else {
                            AccountSheetLink(accountID: account.id) { label }
                        }
                    }
                    .buttonStyle(.row)
                    // Accounts as drawn everywhere: a tile in the logo column (user report 2026-10-31).
                    .separatorAbove(index > 0, order: index) { RowDivider(column: .logo) }
                }
            }
        }
    }
}
