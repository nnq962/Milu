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
                                .foregroundStyle(Palette.label)
                        }
                        // Pressed like every other card that opens something (strict review 2026-10-31).
                        .buttonStyle(.card)
                        .accessibilityHint("Xem phân bổ hạn mức")
                    } else {
                        EmptyStateCard(icon: "hugeicons-chart-increase", title: "Chưa đặt hạn mức",
                                       message: "Phần còn lại mỗi tháng sẽ hiện ở đây.")
                        FormGroup {
                            FormNavigationRow(title: "Đặt hạn mức tháng", icon: "hugeicons-chart-increase") {
                                isSettingMonth = true
                            }
                        }
                    }
                }

                // Headings and list cards as on Báo cáo, which these rows open into: this is a page
                // of figures, not a form (re-review 2026-10-31: small-caps form groups).
                if !limited.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Theo hạng mục")
                        VStack(spacing: 0) {
                            ForEach(Array(limited.enumerated()), id: \.element.id) { index, group in
                                groupRow(group, progress: BudgetProgress(limit: categoryBudgets[group.id],
                                                                         spent: spentByGroup[group.id]?.amount ?? 0))
                                    .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                            }
                        }
                        .listCard()
                    }
                }

                if !others.isEmpty {
                    let othersSpent = others.reduce(0) { $0 + (spentByGroup[$1.id]?.amount ?? 0) }
                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Chưa có hạn mức")
                        VStack(spacing: 0) {
                            ForEach(Array(others.enumerated()), id: \.element.id) { index, group in
                                let spent = spentByGroup[group.id]?.amount ?? 0
                                NavigationLink {
                                    CategoryReportView(groupID: group.id, period: monthPeriod)
                                } label: {
                                    // The same row as these groups on Phân bổ hạn mức: what each
                                    // spent and its share of what they spent together (re-review
                                    // 2026-10-31: grey words here, MoneyText there).
                                    BreakdownRowLabel(icon: group.icon, title: group.name,
                                                      detail: spent > 0 && othersSpent > 0
                                                          ? (spent / othersSpent).percentText : "Chưa chi",
                                                      amount: spent)
                                }
                                .buttonStyle(.row)
                                .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                            }
                        }
                        .listCard()
                    }
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.l)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.label)
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
                        .foregroundStyle(Palette.secondaryLabel)
                    if progress.isOver {
                        StatusBadge(text: "Vượt hạn mức", tone: .warning)
                    } else if progress.isNearing {
                        StatusBadge(text: "Sắp hết", tone: .caution)
                    }
                    Spacer(minLength: Spacing.s)
                    // › alone says the card opens the split.
                    RowChevron()
                }
                // Over the limit: the amount over, red.
                MoneyText(amount: progress.isOver ? -abs(progress.left) : progress.left,
                          size: .large, tone: .negativeRed)
            }
            ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
            // The amounts as MoneyText, grey like the words around them (re-review 2026-10-31).
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("Đã chi")
                MoneyText(amount: progress.spent, size: .caption, tone: .muted, compact: true)
                Text("/")
                MoneyText(amount: progress.limit, size: .caption, tone: .muted, compact: true)
                Spacer(minLength: Spacing.s)
                Text(progress.ratio.percentText)
            }
            .textRole(.caption)
            .monospacedDigit()
            .foregroundStyle(Palette.secondaryLabel)

            if let daily = progress.dailyAllowance(in: month) {
                HStack {
                    Text("Mỗi ngày")
                        .textRole(.captionStrong)
                    Spacer(minLength: Spacing.s)
                    HStack(spacing: 0) {
                        Text("~").textRole(.amount)
                        MoneyText(amount: daily, compact: true)
                    }
                }
                .padding(.top, Spacing.m)
                // A form hairline: from where the words start to the card's edge.
                .overlay(alignment: .top) { FormDivider(hasIcon: false).padding(.horizontal, -RowMetrics.horizontal) }
                .accessibilityElement(children: .combine)
            }
        }
        // A card at 24 like the form groups under it, its words 16 in like their rows.
        .settingsCard()
        .accessibilityElement(children: .combine)
    }

    /// A group with a limit: name, what is left or how much over, and the bar; it opens the group's
    /// detail.
    private func groupRow(_ group: Category, progress: BudgetProgress) -> some View {
        // "Còn" / "Vượt" in sentence case as on Phân bổ hạn mức, the amount a MoneyText, red with
        // "-" once over as on the month's card (re-review 2026-10-31).
        // Opens the group: its items, its transactions, and "Hạn mức" to change the limit.
        NavigationLink {
            CategoryReportView(groupID: group.id, period: ReportPeriod(.month, containing: month))
        } label: {
            HStack(spacing: RowMetrics.gap) {
                // Grows with the text, as on Báo cáo (re-review 2026-10-31: a fixed 24).
                RowIcon(name: group.icon)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack {
                        Text(group.name)
                            .textRole(.body)
                            .lineLimit(1)
                        Spacer(minLength: Spacing.s)
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            Text(progress.isOver ? "Vượt" : "Còn")
                                .textRole(.caption)
                                .foregroundStyle(Palette.secondaryLabel)
                            MoneyText(amount: progress.isOver ? -abs(progress.left) : progress.left,
                                      size: .caption, tone: .negativeRed, compact: true)
                        }
                        .fixedSize()
                    }
                    ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
                }
                // Opens the group, as the rows of "Chưa có hạn mức" do (strict review 2026-10-31).
                RowChevron()
            }
            .formRowFrame()
        }
        .buttonStyle(.row)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(group.name), đã chi \(progress.spent.vnd) trên \(progress.limit.vnd), "
            + (progress.isOver ? "Vượt \((-progress.left).vnd)" : "Còn \(progress.left.vnd)"))
        .accessibilityHint("Xem chi tiết")
    }
}
