import Charts
import SwiftUI

/// "Báo cáo" (user choice 2026-10-30), opened from the month card on Tổng quan and the totals on
/// Giao dịch. For a week or a month: spent, received and what is left over against the period
/// before; spending by group in a ring and a list (each opens the group); in and out over the last
/// six periods; and money in and out per account. Counts as every report does (`reportable`).
struct ReportView: View {
    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @State private var period: ReportPeriod
    /// The charts grow with the text, so their labels keep room (strict review 2026-10-31).
    @ScaledMetric(relativeTo: .body) private var ringHeight: CGFloat = 190
    @ScaledMetric(relativeTo: .footnote) private var barsHeight: CGFloat = 180

    init(period: ReportPeriod = ReportPeriod(.month)) {
        _period = State(initialValue: period)
    }


    var body: some View {
        let interval = period.interval
        let previous = period.comparison()
        let spent = store.total(.expense, in: interval)
        let received = store.total(.income, in: interval)
        let groups = store.expensesByCategory(in: interval)
        let before = Dictionary(uniqueKeysWithValues: store.expensesByCategory(in: previous).map { ($0.groupID, $0.amount) })

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                ReportPeriodBar(period: $period)
                totals(spent: spent, received: received,
                       spentBefore: store.total(.expense, in: previous),
                       receivedBefore: store.total(.income, in: previous))
                categories(groups, spent: spent, before: before)
                trend
                accounts
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxl)
        }
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Báo cáo")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Tổng

    private func totals(spent: Double, received: Double, spentBefore: Double, receivedBefore: Double) -> some View {
        let net = received - spent
        return VStack(alignment: .leading, spacing: Spacing.l) {
            // Signed and coloured as the month card on Thu chi (strict review 2026-10-31); under
            // each, how it moved against the period before.
            SplitTotals(items: [
                .init("Đã chi", amount: spent, tone: spent > 0 ? .signedExpense : .neutral),
                .init("Đã thu", amount: received, tone: received > 0 ? .signedIncome : .neutral),
            ]) { item in
                let isSpending = item.title == "Đã chi"
                ChangeLabel(now: item.amount, before: isSpending ? spentBefore : receivedBefore,
                            period: period, risingIsBad: isSpending)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // Money in ink with "+", out in red with "-", as on Thu chi (strict review 2026-10-31).
            HStack(alignment: .firstTextBaseline) {
                // Grey as "Đã chi" / "Đã thu" above it; the amount carries the meaning.
                Text(net >= 0 ? "Dư ra" : "Chi nhiều hơn thu")
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryLabel)
                Spacer(minLength: Spacing.s)
                MoneyText(amount: net, tone: .signedNet)
            }
            .padding(.top, Spacing.m)
            .overlay(alignment: .top) { SplitLine() }
            .accessibilityElement(children: .combine)

            facts(spent: spent)
                .padding(.top, Spacing.m)
                .overlay(alignment: .top) { SplitLine() }

            // A month's limit, as on Tổng quan; it opens Hạn mức chi tiêu (review fix 2026-10-30).
            if period.unit == .month, monthlyBudget > 0 {
                NavigationLink { BudgetView(month: period.start) } label: { budgetRow(spent: spent) }
                    .buttonStyle(.automatic)
                    .padding(.top, Spacing.m)
                    .overlay(alignment: .top) { SplitLine() }
            }
        }
        .card(padding: Spacing.xl)
    }

    /// Per day so far, and the largest single spending of the period (review fix 2026-10-30).
    private func facts(spent: Double) -> some View {
        let calendar = ReportPeriod.calendar
        let end = period.isCurrent() ? calendar.startOfDay(for: .now) : period.interval.end
        let days = max((calendar.dateComponents([.day], from: period.start, to: end).day ?? 0) + (period.isCurrent() ? 1 : 0), 1)
        let largest = store.reportableTransactions(in: period.interval)
            .filter { $0.kind == .expense }
            .max { $0.amount < $1.amount }
        return HStack(alignment: .top, spacing: 0) {
            fact("TB mỗi ngày", amount: spent / Double(days), note: "\(days) ngày")
                .padding(.trailing, Spacing.l)
            fact("Lớn nhất", amount: largest?.amount,
                 note: largest.map { store.title(of: $0) } ?? "Chưa có khoản chi")
                .padding(.leading, Spacing.l)
        }
    }

    /// Money out, so red with "-" as every spending figure (strict review 2026-10-31).
    private func fact(_ title: String, amount: Double?, note: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
            if let amount, amount > 0 {
                MoneyText(amount: amount, tone: .signedExpense)
            } else {
                Text("—")
                    .textRole(.amount)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            Text(note)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// "Hạn mức 30tr", its bar and ›, then where it stands in the app's one look for a limit
    /// (`BudgetStatusLine`, strict review 2026-10-31).
    private func budgetRow(spent: Double) -> some View {
        let progress = BudgetProgress(limit: monthlyBudget, spent: spent)
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Text("Hạn mức \(monthlyBudget.vnd)")
                    .textRole(.captionStrong)
                Spacer(minLength: Spacing.s)
                RowChevron()
            }
            ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
            BudgetStatusLine(level: .init(progress),
                             message: progress.isOver ? "Vượt hạn mức \((-progress.left).vnd)"
                                 : "Đã dùng \(progress.ratio.percentText) hạn mức, còn \(progress.left.vnd)")
        }
        .foregroundStyle(Palette.label)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Mở hạn mức chi tiêu")
    }

    // MARK: - Theo hạng mục

    @ViewBuilder
    private func categories(_ groups: [CategoryTotal], spent: Double, before: [String: Double]) -> some View {
        if groups.isEmpty {
            // Its heading stays, as on the empty trend below (strict review 2026-10-31).
            HeaderCard(title: "Chi theo hạng mục") {
                EmptyStateCard(icon: "hugeicons-pie-chart", title: "Chưa có chi tiêu",
                               message: "Khoản chi trong kỳ sẽ hiện ở đây.")
            }
        } else {
            ReportSection(title: "Chi theo hạng mục") {
                ring(groups, spent: spent)
                    .padding(.vertical, Spacing.xl)
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    NavigationLink {
                        CategoryReportView(groupID: group.groupID, period: period)
                    } label: {
                        BreakdownRowLabel(icon: group.icon, title: group.name,
                                          detail: detail(group, share: group.amount / spent, before: before),
                                          amount: group.amount, tone: .signedExpense, dot: color(at: index),
                                          edgedDot: ChartShades.isRest(at: index))
                    }
                    .buttonStyle(.row)
                    .overlay(alignment: .top) { RowDivider() }
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

    private func ring(_ groups: [CategoryTotal], spent: Double) -> some View {
        let top = Array(groups.prefix(ChartShades.steps.count))
        let rest = groups.dropFirst(ChartShades.steps.count).reduce(0) { $0 + $1.amount }
        let slices = top.enumerated().map { (name: $1.name, amount: $1.amount, color: color(at: $0)) }
            + (rest > 0 ? [(name: "Khác", amount: rest, color: ChartShades.rest)] : [])
        return Chart(slices, id: \.name) { slice in
            SectorMark(angle: .value("Chi", slice.amount), innerRadius: .ratio(0.66), angularInset: 1.5)
                .cornerRadius(4)
                .foregroundStyle(slice.color)
                .accessibilityLabel(slice.name)
                .accessibilityValue(slice.amount.vnd)
        }
        .frame(height: ringHeight)
        .overlay {
            VStack(spacing: Spacing.xxs) {
                Text("Tổng chi")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                MoneyText(amount: spent, size: .heading, tone: .signedExpense)
                    .fixedSize()
            }
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Xu hướng

    @ViewBuilder
    private var trend: some View {
        let periods = period.lastPeriods(6)
        let unit = period.unit.title.lowercased()
        // Nothing in all six: a short line, not an empty chart that looks broken (review 2026-10-30).
        if periods.allSatisfy({ store.reportableTransactions(in: $0.interval).isEmpty }) {
            HeaderCard(title: "Thu chi \(periods.count) \(unit) gần đây") {
                EmptyStateCard(icon: "hugeicons-chart-increase", title: "Chưa có thu chi",
                               message: "Thu chi từng \(unit) sẽ hiện ở đây.")
            }
        } else {
            trendChart(periods)
        }
    }

    private func trendChart(_ periods: [ReportPeriod]) -> some View {
        let rows = periods.flatMap { item in
            [TrendBar(period: item, kind: "Thu", amount: store.total(.income, in: item.interval)),
             TrendBar(period: item, kind: "Chi", amount: store.total(.expense, in: item.interval))]
        }
        // Averaged over the periods that have spending, so months before the app was used do not
        // pull it down.
        let spending = rows.filter { $0.kind == "Chi" && $0.amount > 0 }.map(\.amount)
        let unit = period.unit.title.lowercased()
        // A footer for the computed figure only; that a bar opens its period is said to VoiceOver
        // as a hint (strict review 2026-10-31: no explanatory footers).
        let average = spending.count > 1 ? spending.reduce(0, +) / Double(spending.count) : nil
        return ReportSection(title: "Thu chi \(periods.count) \(unit) gần đây",
                             footer: average.map { "Trung bình chi \($0.vnd) mỗi \(unit) có ghi chép." }) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(spacing: Spacing.l) {
                    legend("Thu", color: Palette.positive)
                    legend("Chi", color: Palette.negative)
                }
                Chart(rows) { row in
                    BarMark(x: .value("Kỳ", row.period.shortTitle), y: .value("Tiền", row.amount), width: .ratio(0.8))
                        .position(by: .value("Loại", row.kind))
                        .clipShape(Capsule())
                        .foregroundStyle(row.kind == "Thu" ? Palette.positive : Palette.negative)
                        .opacity(row.period == period ? 1 : 0.35)
                        .accessibilityLabel("\(row.kind) \(row.period.title)")
                        .accessibilityValue(row.amount.vnd)
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
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(SpatialTapGesture().onEnded { value in
                                guard let plot = proxy.plotFrame else { return }
                                let x = value.location.x - geometry[plot].origin.x
                                guard let title: String = proxy.value(atX: x),
                                      let picked = periods.first(where: { $0.shortTitle == title }) else { return }
                                withAnimation(.snappy) { period = picked }
                            })
                    }
                }
                .frame(height: barsHeight)
                .accessibilityHint("Chạm một cột để xem kỳ đó")
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
    private var accounts: some View {
        let totals = store.totalsByAccount(in: period.interval)
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
                    .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                }
            }
        }
    }
}
