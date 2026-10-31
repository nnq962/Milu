import SwiftUI

/// One group of "Hạng mục" in a period (user request 2026-10-30): what it spent against the period
/// before and its share of all spending, its monthly limit when looking at a month, each item inside
/// it ("Ăn sáng", "Cà phê"…) with its share, and the transactions. Opened from Báo cáo and from a
/// group's row on Hạn mức chi tiêu; ✎ in the toolbar sets the group's limit (it must fit in the
/// month's, `BudgetRules`).
struct CategoryReportView: View {
    let groupID: String

    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = SampleData.categoryBudgets
    @State private var period: ReportPeriod
    @State private var isEditingLimit = false
    /// The icon grows with the text beside it, as in `ListRow`.
    @ScaledMetric(relativeTo: .body) private var iconSize = RowMetrics.iconColumn
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(groupID: String, period: ReportPeriod) {
        self.groupID = groupID
        _period = State(initialValue: period)
    }

    /// An expense group in use can have a limit; a system one ("Phí chuyển khoản", "Lãi vay") or a
    /// hidden one cannot.
    private var canHaveLimit: Bool { store.budgetGroupIDs.contains(groupID) }

    var body: some View {
        let interval = period.interval
        let spent = store.expenses(inGroup: groupID, in: interval).reduce(0) { $0 + $1.amount }
        let items = store.expensesByItem(inGroup: groupID, in: interval)
        let transactions = store.expenses(inGroup: groupID, in: interval)

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                ReportPeriodBar(period: $period)
                summary(spent: spent, allSpent: store.total(.expense, in: interval),
                        before: store.expenses(inGroup: groupID, in: period.comparison()).reduce(0) { $0 + $1.amount })

                if items.count > 1 {
                    ReportSection(title: "Hạng mục nhỏ") {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            // An item opens its own transactions (user request 2026-10-30).
                            NavigationLink {
                                ItemTransactionsView(groupID: groupID, itemID: item.groupID, period: period)
                            } label: {
                                itemRow(item, share: item.amount / spent)
                            }
                            .buttonStyle(.row)
                            .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                        }
                    }
                }

                if transactions.isEmpty {
                    // Worded as on Báo cáo for the same case (strict review 2026-10-31).
                    EmptyStateCard(icon: "hugeicons-inbox", title: "Chưa có chi tiêu",
                                   message: "Khoản chi trong kỳ sẽ hiện ở đây.")
                } else {
                    ReportTransactionList(title: store.categoryName(groupID), transactions: transactions)
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.label)
        .navigationTitle(store.categoryName(groupID))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canHaveLimit {
                ToolbarItem(placement: .topBarTrailing) {
                    EditToolbarButton { isEditingLimit = true }
                        .accessibilityLabel("Sửa hạn mức")
                }
            }
        }
        .sheet(isPresented: $isEditingLimit) {
            GroupBudgetEditor(groupID: groupID, name: store.categoryName(groupID))
        }
    }

    /// Spent, against the period before, its share of all spending, and the month's limit, in the
    /// app's one summary card (strict review 2026-10-31: a hand-made one put a toolbar-sized icon on
    /// the left).
    private func summary(spent: Double, allSpent: Double, before: Double) -> some View {
        let limit = canHaveLimit ? categoryBudgets[groupID] : 0
        // Red with "-", as "Đã chi" on Báo cáo and Thu chi (strict review 2026-10-31).
        return SummaryCard(label: "Đã chi", amount: spent, icon: store.categoryIcon(groupID),
                           tone: spent > 0 ? .signedExpense : .plain) {
            let showsLimit = period.unit == .month && limit > 0
            if allSpent > 0 || before > 0 || showsLimit {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    // One line: share of all spending, and the move since last period when there is one.
                    if allSpent > 0 || before > 0 {
                        HStack(spacing: Spacing.s) {
                            if allSpent > 0 {
                                Text("\((spent / allSpent).percentText) tổng chi")
                                    .textRole(.caption)
                                    .foregroundStyle(Palette.secondaryLabel)
                                    .monospacedDigit()
                            }
                            if before > 0 {
                                ChangeLabel(now: spent, before: before, period: period)
                            }
                        }
                    }
                    // The limit is a month's, so it is shown on a month only.
                    if showsLimit {
                        let progress = BudgetProgress(limit: limit, spent: spent)
                        // The app's one look for a limit (`BudgetStatusLine`), as on Báo cáo.
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            Text("Hạn mức \(limit.vndCompact)")
                                .textRole(.captionStrong)
                            ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
                            BudgetStatusLine(level: .init(progress),
                                             text: progress.isOver ? "Vượt hạn mức \((-progress.left).vndCompact)"
                                                 : "Đã dùng \(progress.ratio.percentText) hạn mức, còn \(progress.left.vndCompact)")
                        }
                        .padding(.top, Spacing.m)
                        .overlay(alignment: .top) { SplitLine() }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.top, Spacing.m)
            }
        }
    }

    /// An item: name, share and amount, a bar of its share of the group under them, and › on the
    /// row's own edge, so the bar stops at the amount (strict review 2026-10-31).
    private func itemRow(_ item: CategoryTotal, share: Double) -> some View {
        HStack(spacing: RowMetrics.gap) {
            RowIcon(name: item.icon, size: iconSize)
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    Text(item.name)
                        .textRole(.body)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(share.percentText)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .monospacedDigit()
                        .fixedSize()
                    MoneyText(amount: item.amount, tone: .signedExpense, compact: true)
                        .fixedSize()
                }
                ProgressBar(value: share)
            }
            RowChevron()
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), \(item.amount.vnd), \(share.percentText)")
    }
}

/// One item of a group ("Cà phê" in Ăn uống) in the period picked on the group's page: its total
/// and its transactions, newest first. No Tuần / Tháng here: the group's page already chose it
/// (user note 2026-10-30).
struct ItemTransactionsView: View {
    let groupID: String
    let itemID: String
    let period: ReportPeriod

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let transactions = store.expenses(inGroup: groupID, in: period.interval).filter { $0.categoryID == itemID }
        let total = transactions.reduce(0) { $0 + $1.amount }

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                SummaryCard(label: period.unit == .week ? "Đã chi tuần \(period.title)" : "Đã chi \(period.title.lowercased())",
                            amount: total, icon: store.categoryIcon(itemID),
                            tone: total > 0 ? .signedExpense : .plain)

                if transactions.isEmpty {
                    // Worded as on Báo cáo for the same case (strict review 2026-10-31).
                    EmptyStateCard(icon: "hugeicons-inbox", title: "Chưa có chi tiêu",
                                   message: "Khoản chi trong kỳ sẽ hiện ở đây.")
                } else {
                    ReportTransactionList(title: store.categoryName(itemID), transactions: transactions)
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.label)
        .navigationTitle(store.categoryName(itemID))
        .navigationBarTitleDisplayMode(.inline)
    }
}
