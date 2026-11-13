import SwiftUI

/// One group of "Hạng mục" in a period (user request 2026-10-30): what it spent against the period
/// before and its share of all spending, its monthly limit when looking at a month, each item inside
/// it ("Ăn sáng", "Cà phê"…) with its share, and the transactions. Opened from Báo cáo and from
/// "Xem chi tiêu của nhóm" in a group's limit sheet on Hạn mức chi tiêu; ✎ in the toolbar sets the group's limit (it must fit in the
/// month's, `BudgetRules`).
struct CategoryReportView: View {
    let groupID: String

    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = CategoryBudgets()
    @State private var period: ReportPeriod
    @State private var isEditingLimit = false
    /// The item opened, pushed from the page rather than by a link in its row, so the row leaving
    /// (a deletion left one item, and the part hid) does not close the open page (review 2026-11-08).
    @State private var openItem: String?
    /// The icon grows with the text beside it, as in `ListRow`.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Told when the period changes here, so the page this came from shows the same one on the
    /// way back (review 2026-11-08: Tháng 10 here, Tháng 11 again on Báo cáo).
    var onPeriodChange: ((ReportPeriod) -> Void)? = nil

    init(groupID: String, period: ReportPeriod, onPeriodChange: ((ReportPeriod) -> Void)? = nil) {
        self.groupID = groupID
        self.onPeriodChange = onPeriodChange
        _period = State(initialValue: period)
    }

    /// An expense group in use can have a limit; a system one ("Phí chuyển khoản", "Lãi vay") or a
    /// hidden one cannot.
    private var canHaveLimit: Bool { store.budgetGroupIDs.contains(groupID) }

    var body: some View {
        let interval = period.interval
        // The period read once; the group's spending, the page's total, the items and the list
        // all come from it (reviews 2026-11-08 and -09: five reads, then three).
        let all = store.reportableTransactions(in: interval)
        let transactions = all
            .filter { $0.kind == .expense && store.groupID(of: $0.categoryID) == groupID }
            .sorted { $0.date > $1.date }
        let spent = transactions.reduce(0) { $0 + $1.amount }
        let items = store.expensesByItem(of: transactions)

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                ReportPeriodBar(period: $period)
                summary(spent: spent, allSpent: store.total(.expense, of: all),
                        before: store.expenses(inGroup: groupID, in: period.comparison()).reduce(0) { $0 + $1.amount })

                if items.count > 1 {
                    ReportSection(title: "Hạng mục nhỏ") {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            // An item opens its own transactions (user request 2026-10-30).
                            Button { openItem = item.groupID } label: {
                                itemRow(item, share: item.amount / spent)
                            }
                            .buttonStyle(.row)
                            .separatorAbove(index > 0, order: index) { RowDivider() }
                        }
                    }
                }

                if transactions.isEmpty {
                    // Worded as on Báo cáo for the same case (strict review 2026-10-31).
                    // A picture, as the empty cards of Báo cáo (review 2026-11-08).
                    EmptyStateCard(title: "Chưa có chi tiêu", message: "Khoản chi trong kỳ sẽ hiện ở đây.",
                                   picture: IconCatalog.emojiName("🧾"))
                } else {
                    ReportTransactionList(title: store.categoryName(groupID), transactions: transactions)
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxl)
        }
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle(store.categoryName(groupID))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: period) { _, new in onPeriodChange?(new) }
        .navigationDestination(item: $openItem) { itemID in
            ItemTransactionsView(groupID: groupID, itemID: itemID, period: period)
        }
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
        // In ink with no sign, as "Đã chi" on Báo cáo (user report 2026-11-08: the red lead
        // figure and the extra lines read as clutter).
        return SummaryCard(title: "Đã chi", amount: spent, icon: store.categoryIcon(groupID), tone: .neutral) {
            let showsLimit = period.unit == .month && limit > 0
            // Only with something to show under the figure: a group with nothing spent in the
            // period or the one before left a blank band (review 2026-11-09).
            if (allSpent > 0 && spent > 0) || before > 0 || showsLimit {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    // Share of all spending, and under it the move since last period when there
                    // is one: on one line they squeezed each other at larger text (review 2026-11-08).
                    if (allSpent > 0 && spent > 0) || before > 0 {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            // Not "0% tổng chi" for a group with nothing in the period.
                            if allSpent > 0 && spent > 0 {
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
                    // The limit is a month's, so it is shown on a month only: the bar and one
                    // line under it, as on Báo cáo (no heading over the bar, no line above it).
                    if showsLimit {
                        let progress = BudgetProgress(limit: limit, spent: spent)
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
                            BudgetStatusLine(level: .init(progress),
                                             message: progress.isOver ? "Vượt hạn mức \((-progress.left).vnd)"
                                                 : "Đã dùng \(progress.percentText) hạn mức \(limit.vnd)")
                        }
                        .padding(.top, Spacing.xs)
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
            RowIcon(name: item.icon)
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
                    // "−" in ink, as the transactions under it (review 2026-11-08).
                    MoneyText(amount: item.amount, tone: .outflow)
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
        // "trừ … đồng", as every amount is read (review 2026-11-09).
        .accessibilityLabel("\(item.name), trừ \(MoneyText.spoken(item.amount)), \(share.percentText)")
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
                SummaryCard(title: period.unit == .week ? "Đã chi tuần \(period.title)" : "Đã chi \(period.title.lowercased())",
                            amount: total, icon: store.categoryIcon(itemID),
                            // In ink with no sign, as the group's page (review 2026-11-08).
                            tone: .neutral)

                if transactions.isEmpty {
                    // Worded as on Báo cáo for the same case (strict review 2026-10-31).
                    EmptyStateCard(title: "Chưa có chi tiêu", message: "Khoản chi trong kỳ sẽ hiện ở đây.",
                                   picture: IconCatalog.emojiName("🧾"))
                } else {
                    ReportTransactionList(title: store.categoryName(itemID), transactions: transactions)
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.s)
            .padding(.bottom, Spacing.xxl)
        }
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle(store.categoryName(itemID))
        .navigationBarTitleDisplayMode(.inline)
    }
}
