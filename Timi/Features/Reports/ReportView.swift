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
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Báo cáo")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Tổng

    private func totals(spent: Double, received: Double, spentBefore: Double, receivedBefore: Double) -> some View {
        let net = received - spent
        return VStack(alignment: .leading, spacing: Spacing.l) {
            HStack(alignment: .top, spacing: 0) {
                total("Đã chi", amount: spent, before: spentBefore, risingIsBad: true)
                    .padding(.trailing, Spacing.l)
                    .overlay(alignment: .trailing) { Palette.border.frame(width: 1) }
                total("Đã thu", amount: received, before: receivedBefore, risingIsBad: false)
                    .padding(.leading, Spacing.l)
            }
            HStack {
                Text(net >= 0 ? "Dư ra" : "Chi nhiều hơn thu")
                    .textRole(.captionStrong)
                Spacer(minLength: Spacing.s)
                Text((net >= 0 ? "+" : "-") + abs(net).vnd)
                    .textRole(.bodyStrong)
                    .monospacedDigit()
                    .foregroundStyle(net >= 0 ? Palette.green : Palette.red)
            }
            .padding(.top, Spacing.m)
            .overlay(alignment: .top) { Palette.border.frame(height: 1) }
            .accessibilityElement(children: .combine)

            facts(spent: spent)
                .padding(.top, Spacing.m)
                .overlay(alignment: .top) { Palette.border.frame(height: 1) }

            // A month's limit, as on Tổng quan; it opens Hạn mức chi tiêu (review fix 2026-10-30).
            if period.unit == .month, monthlyBudget > 0 {
                NavigationLink { BudgetView(month: period.start) } label: { budgetRow(spent: spent) }
                    .buttonStyle(.automatic)
                    .padding(.top, Spacing.m)
                    .overlay(alignment: .top) { Palette.border.frame(height: 1) }
            }
        }
        .sleekCard(padding: Spacing.xl)
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
            fact("TB mỗi ngày", value: (spent / Double(days)).vndCompact, note: "\(days) ngày")
                .padding(.trailing, Spacing.l)
            fact("Lớn nhất", value: largest?.amount.vndCompact ?? "—",
                 note: largest.map { store.title(of: $0) } ?? "Chưa có khoản chi")
                .padding(.leading, Spacing.l)
        }
    }

    private func fact(_ title: String, value: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
            Text(value)
                .textRole(.bodyStrong)
                .monospacedDigit()
            Text(note)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// "Hạn mức 30tr · 60%" with its bar and ›.
    private func budgetRow(spent: Double) -> some View {
        let progress = BudgetProgress(limit: monthlyBudget, spent: spent)
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.xs) {
                Text("Hạn mức \(monthlyBudget.vndCompact)")
                    .textRole(.captionStrong)
                Spacer(minLength: Spacing.s)
                Text(progress.isOver ? "vượt \((-progress.left).vndCompact)" : "đã dùng \(progress.ratio.percentText)")
                    .textRole(.captionStrong)
                    .foregroundStyle(progress.isOver ? Palette.red : Palette.secondaryText)
                    .monospacedDigit()
                TimiIcon("hugeicons-arrow-right-01", size: 14)
                    .foregroundStyle(Palette.secondary)
            }
            ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
        }
        .foregroundStyle(Palette.ink)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Mở hạn mức chi tiêu")
    }

    private func total(_ title: String, amount: Double, before: Double, risingIsBad: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryText)
            Text(amount.vnd)
                .textRole(.amountLarge)
                .foregroundStyle(risingIsBad ? Palette.red : Palette.green)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                .frame(minHeight: 32)
            ChangeLabel(now: amount, before: before, period: period, risingIsBad: risingIsBad)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Theo hạng mục

    @ViewBuilder
    private func categories(_ groups: [CategoryTotal], spent: Double, before: [String: Double]) -> some View {
        if groups.isEmpty {
            EmptyStateCard(icon: "hugeicons-pie-chart", title: "Chưa có chi tiêu",
                           message: "Kỳ này chưa ghi khoản chi nào.")
        } else {
            FormGroup(title: "Chi theo hạng mục") {
                ring(groups, spent: spent)
                    .padding(.vertical, Spacing.xl)
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    FormDivider()
                    NavigationLink {
                        CategoryReportView(groupID: group.groupID, period: period)
                    } label: {
                        BreakdownRowLabel(icon: group.icon, title: group.name,
                                          detail: detail(group, share: group.amount / spent, before: before),
                                          amount: group.amount.vndCompact, dot: color(at: index),
                                          edgedDot: ChartShades.isRest(at: index))
                    }
                    .buttonStyle(.row)
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
        .frame(height: 190)
        .overlay {
            VStack(spacing: 2) {
                Text("Tổng chi")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                Text(spent.vndCompact)
                    .textRole(.heading)
                    .monospacedDigit()
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
            FormGroup(title: "Thu chi \(periods.count) \(unit) gần đây") {
                Text("Chưa có thu chi trong \(periods.count) \(unit) này.")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(RowMetrics.horizontal)
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
        let footer = spending.count > 1
            ? "Trung bình chi \((spending.reduce(0, +) / Double(spending.count)).vndCompact) mỗi \(unit) có ghi chép. Chạm một cột để xem kỳ đó."
            : "Chạm một cột để xem kỳ đó."
        return FormGroup(title: "Thu chi \(periods.count) \(unit) gần đây", footer: footer) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(spacing: Spacing.l) {
                    legend("Thu", color: Palette.green)
                    legend("Chi", color: Palette.red)
                }
                Chart(rows) { row in
                    BarMark(x: .value("Kỳ", row.period.shortTitle), y: .value("Tiền", row.amount), width: .ratio(0.8))
                        .position(by: .value("Loại", row.kind))
                        .clipShape(Capsule())
                        .foregroundStyle(row.kind == "Thu" ? Palette.green : Palette.red)
                        .opacity(row.period == period ? 1 : 0.35)
                        .accessibilityLabel("\(row.kind) \(row.period.title)")
                        .accessibilityValue(row.amount.vnd)
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine().foregroundStyle(Palette.border)
                        AxisValueLabel {
                            Text((value.as(Double.self) ?? 0).vndCompact)
                                .textRole(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(Typography.font(.caption2, size: 11, weight: .medium))
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
                .frame(height: 180)
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
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
    }

    // MARK: - Theo tài khoản

    @ViewBuilder
    private var accounts: some View {
        let totals = store.totalsByAccount(in: period.interval)
        if !totals.isEmpty {
            FormGroup(title: "Theo tài khoản") {
                ForEach(Array(totals.enumerated()), id: \.element.id) { index, account in
                    if index > 0 { FormDivider() }
                    // Opens the account or hũ, like a group opens its detail (review fix 2026-10-30).
                    NavigationLink {
                        if store.goal(id: account.id) != nil {
                            GoalDetailView(goalID: account.id)
                        } else {
                            AccountDetailView(accountID: account.id)
                        }
                    } label: {
                        BreakdownRowLabel(icon: account.icon, title: account.name,
                                          detail: account.income > 0 ? "Thu +\(account.income.vndCompact)" : "Không có khoản thu",
                                          amount: "-\(account.expense.vndCompact)")
                    }
                    .buttonStyle(.row)
                }
            }
        }
    }
}
