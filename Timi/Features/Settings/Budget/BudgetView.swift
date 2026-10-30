import SwiftUI

/// "Hạn mức chi tiêu" (Cài đặt), built 2026-10-30 from the user's choices: the month's limit with
/// what is left and what can be spent each day until the month ends, then a limit per group of
/// "Hạng mục" for those that have one, and the other groups to give one. Bars turn orange from 80%
/// and red when over. Any past month can be looked at; the limits are the same for every month.
///
/// Look first, then change (user choice 2026-10-30): the month's card opens Phân bổ hạn mức and a
/// group opens its detail; the limits are changed there with ✎. Only a month with no limit yet
/// offers "Đặt hạn mức tháng" here.
struct BudgetView: View {
    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = SampleData.categoryBudgets

    @State private var month: Date
    @State private var isSettingMonth = false

    /// `month`: the one to show first (Báo cáo opens the month it is showing).
    init(month: Date = .now) {
        _month = State(initialValue: month)
    }

    var body: some View {
        let progress = BudgetProgress(limit: monthlyBudget, spent: store.total(.expense, inMonthOf: month))
        let spentByGroup = Dictionary(uniqueKeysWithValues: store.expensesByCategory(inMonthOf: month)
            .map { ($0.groupID, $0) })
        let groups = store.groups(.expense)
        let limited = groups.filter { categoryBudgets[$0.id] > 0 }
        let others = groups.filter { categoryBudgets[$0.id] == 0 }
            .sorted { (spentByGroup[$0.id]?.amount ?? 0) > (spentByGroup[$1.id]?.amount ?? 0) }
        let monthPeriod = ReportPeriod(.month, containing: month)

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    MonthMenu(month: $month)
                    if monthlyBudget > 0 {
                        // The card opens how the limit is split among the groups (user choice 2026-10-30).
                        NavigationLink {
                            BudgetAllocationView(month: month)
                        } label: {
                            summary(progress)
                                .foregroundStyle(Palette.ink)
                        }
                        .buttonStyle(.automatic)
                        .accessibilityHint("Xem phân bổ hạn mức")
                    } else {
                        EmptyStateCard(icon: "hugeicons-chart-increase", title: "Chưa đặt hạn mức",
                                       message: "Đặt hạn mức để theo dõi chi tiêu mỗi tháng.")
                        FormGroup {
                            FormNavigationRow(title: "Đặt hạn mức tháng", icon: "hugeicons-chart-increase") {
                                isSettingMonth = true
                            }
                        }
                    }
                }

                if !limited.isEmpty {
                    FormGroup(title: "Theo hạng mục") {
                        ForEach(Array(limited.enumerated()), id: \.element.id) { index, group in
                            if index > 0 { FormDivider() }
                            groupRow(group, progress: BudgetProgress(limit: categoryBudgets[group.id],
                                                                     spent: spentByGroup[group.id]?.amount ?? 0))
                        }
                    }
                }

                if !others.isEmpty {
                    FormGroup(title: "Chưa có hạn mức") {
                        ForEach(Array(others.enumerated()), id: \.element.id) { index, group in
                            if index > 0 { FormDivider() }
                            let spent = spentByGroup[group.id]?.amount ?? 0
                            NavigationLink {
                                CategoryReportView(groupID: group.id, period: monthPeriod)
                            } label: {
                                // What it spent, on the right like any value: one line per group.
                                NavigationRowLabel(title: group.name, icon: group.icon,
                                                   value: spent > 0 ? spent.vndCompact : nil)
                            }
                            .buttonStyle(.row)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Hạn mức chi tiêu")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isSettingMonth) { MonthBudgetEditor() }
        // A group hidden or deleted since gives its limit back to "Chưa phân bổ".
        .onAppear { categoryBudgets = categoryBudgets.keeping(store.budgetGroupIDs) }
    }

    /// What is left in large type, the bar, spent of the limit, and each day's share of what is left.
    private func summary(_ progress: BudgetProgress) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(progress.isOver ? "Đã vượt" : "Còn lại")
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryText)
                    if progress.isOver {
                        StatusBadge(text: "Vượt", tone: .warning)
                    } else if progress.isNearing {
                        StatusBadge(text: "Sắp hết", tone: .caution)
                    }
                    Spacer(minLength: Spacing.s)
                    // › alone says the card opens the split.
                    TimiIcon("hugeicons-arrow-right-01", size: 16)
                        .foregroundStyle(Palette.secondary)
                }
                Text(abs(progress.left).vnd)
                    .textRole(.amountLarge)
                    .foregroundStyle(progress.isOver ? Palette.red : Palette.ink)
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                    .frame(minHeight: 32)
            }
            ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
            HStack {
                Text("Đã chi \(progress.spent.vndCompact) / \(progress.limit.vndCompact)")
                Spacer(minLength: Spacing.s)
                Text(progress.ratio.percentText)
            }
            .textRole(.caption)
            .monospacedDigit()
            .foregroundStyle(Palette.secondaryText)

            if let daily = progress.dailyAllowance(in: month) {
                HStack {
                    Text("Mỗi ngày")
                        .textRole(.captionStrong)
                    Spacer(minLength: Spacing.s)
                    Text("~\(daily.vndCompact)")
                        .textRole(.bodyStrong)
                        .monospacedDigit()
                }
                .padding(.top, Spacing.m)
                .overlay(alignment: .top) { Palette.border.frame(height: 1) }
                .accessibilityElement(children: .combine)
            }
        }
        .sleekCard(padding: Spacing.xl)
        .accessibilityElement(children: .combine)
    }

    /// A group with a limit: name, what is left or how much over, and the bar; it opens the group's
    /// detail.
    private func groupRow(_ group: Category, progress: BudgetProgress) -> some View {
        // Opens the group: its items, its transactions, and "Hạn mức" to change the limit.
        NavigationLink {
            CategoryReportView(groupID: group.id, period: ReportPeriod(.month, containing: month))
        } label: {
            HStack(spacing: RowMetrics.gap) {
                RowIcon(name: group.icon)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack {
                        Text(group.name)
                            .textRole(.body)
                            .lineLimit(1)
                        Spacer(minLength: Spacing.s)
                        Text(progress.isOver ? "vượt \((-progress.left).vndCompact)" : "còn \(progress.left.vndCompact)")
                            .textRole(.captionStrong)
                            .foregroundStyle(progress.isOver ? Palette.red : Palette.secondaryText)
                            .monospacedDigit()
                    }
                    ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
                }
            }
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, Spacing.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.row)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(group.name), đã chi \(progress.spent.vnd) trên \(progress.limit.vnd), "
            + (progress.isOver ? "vượt \((-progress.left).vnd)" : "còn \(progress.left.vnd)"))
        .accessibilityHint("Xem chi tiết")
    }
}
