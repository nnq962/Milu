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
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                ReportPeriodBar(period: $period)
                summary(spent: spent, allSpent: store.total(.expense, in: interval),
                        before: store.expenses(inGroup: groupID, in: period.comparison()).reduce(0) { $0 + $1.amount })

                if items.count > 1 {
                    FormGroup(title: "Hạng mục nhỏ") {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            if index > 0 { FormDivider() }
                            // An item opens its own transactions (user request 2026-10-30).
                            NavigationLink {
                                ItemTransactionsView(groupID: groupID, itemID: item.groupID, period: period)
                            } label: {
                                itemRow(item, share: item.amount / spent)
                            }
                            .buttonStyle(.row)
                        }
                    }
                }

                if transactions.isEmpty {
                    EmptyStateCard(icon: "hugeicons-inbox", title: "Chưa có giao dịch",
                                   message: "Kỳ này chưa có khoản chi.")
                } else {
                    ReportTransactionList(title: store.categoryName(groupID), transactions: transactions)
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
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

    /// Spent, against the period before, its share of all spending, and the month's limit.
    private func summary(spent: Double, allSpent: Double, before: Double) -> some View {
        let limit = canHaveLimit ? categoryBudgets[groupID] : 0
        return VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.m) {
                RowIcon(name: store.categoryIcon(groupID), size: 28)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Đã chi")
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryText)
                    Text(spent.vnd)
                        .textRole(.amountLarge)
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                }
            }
            // One line: share of all spending, and the move since last period when there is one.
            HStack(spacing: Spacing.s) {
                if allSpent > 0 {
                    Text("\((spent / allSpent).percentText) tổng chi")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .monospacedDigit()
                }
                if before > 0 {
                    ChangeLabel(now: spent, before: before, period: period)
                }
            }
            // The limit is a month's, so it is shown on a month only.
            if period.unit == .month, limit > 0 {
                let progress = BudgetProgress(limit: limit, spent: spent)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack {
                        Text("Hạn mức \(limit.vndCompact)")
                            .textRole(.captionStrong)
                        Spacer(minLength: Spacing.s)
                        Text(progress.isOver ? "vượt \((-progress.left).vndCompact)" : "còn \(progress.left.vndCompact)")
                            .textRole(.captionStrong)
                            .foregroundStyle(progress.isOver ? Palette.red : Palette.secondaryText)
                            .monospacedDigit()
                    }
                    ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
                }
                .padding(.top, Spacing.m)
                .overlay(alignment: .top) { Palette.border.frame(height: 1) }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sleekCard(padding: Spacing.l, radius: CardCorners.extraLarge)
    }

    /// An item: name, share and amount, ›, and a bar of its share of the group.
    private func itemRow(_ item: CategoryTotal, share: Double) -> some View {
        HStack(spacing: RowMetrics.gap) {
            RowIcon(name: item.icon)
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack {
                    Text(item.name)
                        .textRole(.body)
                        .lineLimit(1)
                    Spacer(minLength: Spacing.s)
                    Text("\(share.percentText) · \(item.amount.vndCompact)")
                        .textRole(.body)
                        .monospacedDigit()
                    TimiIcon("hugeicons-arrow-right-01", size: 16)
                        .foregroundStyle(Palette.secondary)
                }
                ProgressBar(value: share)
            }
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, Spacing.m)
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
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                HStack(spacing: Spacing.m) {
                    RowIcon(name: store.categoryIcon(itemID), size: 28)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(period.unit == .week ? "Đã chi tuần \(period.title)" : "Đã chi \(period.title.lowercased())")
                            .textRole(.captionStrong)
                            .foregroundStyle(Palette.secondaryText)
                        Text(total.vnd)
                            .textRole(.amountLarge)
                            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .sleekCard(padding: Spacing.l, radius: CardCorners.extraLarge)
                .accessibilityElement(children: .combine)

                if transactions.isEmpty {
                    EmptyStateCard(icon: "hugeicons-inbox", title: "Chưa có giao dịch",
                                   message: "Kỳ này chưa có khoản chi.")
                } else {
                    ReportTransactionList(title: store.categoryName(itemID), transactions: transactions)
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle(store.categoryName(itemID))
        .navigationBarTitleDisplayMode(.inline)
    }
}
