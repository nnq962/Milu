import SwiftUI

/// "Hạn mức chi tiêu" (Cài đặt), one page for looking and changing (redone 2026-11-08, user pick
/// "làm lại luồng" after a review: the limit was changed two pages deep, a group's limit hid behind
/// an unlabelled ✎ on its report, and "Phân bổ hạn mức" repeated this page with other numbers).
///
/// - ✎ on the bar changes the month's limit (`MonthBudgetEditor`), the same limit for every month.
/// - The month's card: what is left, the bar, spent of the limit, what can be spent each day.
/// - "Theo nhóm", once a group has a limit: each such group, then "Chưa phân bổ", the part of the
///   month no group holds, which the groups without a limit, fees, interest and any group's
///   overspend spend from; so the parts add up to the month. With no group limited it would only
///   repeat the month's card, so it is left out. Tapping a group opens its limit
///   (`GroupBudgetEditor`), which links to the group's spending.
/// - "Chưa có hạn mức": the other groups, each with "Đặt" to give it one, under one line saying why.
/// - With no month limit yet: what a limit does and "Đặt hạn mức tháng"; no groups until then.
/// Bars turn amber from 80% and red only past the limit. Any past month can be looked at. A group's sheet
/// links to its spending (Báo cáo's page of the group).
struct BudgetView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = SampleData.categoryBudgets

    @State private var month: Date
    @State private var isEditingMonth = false
    /// The group whose limit is open in its sheet.
    @State private var editingGroup: GroupRef?
    /// The group whose spending is pushed from the link in its sheet.
    @State private var reportGroup: GroupRef?

    private struct GroupRef: Identifiable, Hashable {
        let id: String
        let name: String
    }

    /// `month`: the one to show first (Báo cáo opens the month it is showing).
    init(month: Date = .now) {
        _month = State(initialValue: month)
    }

    var body: some View {
        let spentByGroup = Dictionary(uniqueKeysWithValues: store.expensesByCategory(inMonthOf: month)
            .map { ($0.groupID, $0.amount) })
        let allSpent = store.total(.expense, inMonthOf: month)
        let progress = BudgetProgress(limit: monthlyBudget, spent: allSpent)
        let groups = store.groups(.expense)
        let limited = groups.filter { categoryBudgets[$0.id] > 0 }
            .sorted { categoryBudgets[$0.id] > categoryBudgets[$1.id] }
        let others = groups.filter { categoryBudgets[$0.id] == 0 }
            .sorted { (spentByGroup[$0.id] ?? 0) > (spentByGroup[$1.id] ?? 0) }
        // What the groups with a limit spent within it; the rest of the month's spending (groups
        // without one, fees, interest, and any group's overspend) comes out of "Chưa phân bổ".
        let assigned = limited.reduce(0) { $0 + categoryBudgets[$1.id] }
        let withinLimits = limited.reduce(0) { $0 + min(spentByGroup[$1.id] ?? 0, categoryBudgets[$1.id]) }
        let rest = BudgetProgress(limit: max(monthlyBudget - assigned, 0), spent: max(allSpent - withinLimits, 0))
        let overspend = limited.reduce(0) { $0 + max((spentByGroup[$1.id] ?? 0) - categoryBudgets[$1.id], 0) }

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    MonthPickerButton(month: $month)
                    if monthlyBudget > 0 {
                        summary(progress)
                    } else {
                        emptyState
                    }
                }

                // "Nhóm" all through, as the sheets and their notes say it (review 2026-11-08).
                if monthlyBudget > 0, !limited.isEmpty {
                    OutsideHeaderSection(title: "Theo nhóm") {
                        VStack(spacing: 0) {
                            ForEach(Array(limited.enumerated()), id: \.element.id) { index, group in
                                limitedRow(group, progress: BudgetProgress(limit: categoryBudgets[group.id],
                                                                           spent: spentByGroup[group.id] ?? 0))
                                    .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                            }
                            restRow(rest, hasOverspend: overspend > 0, hasUnlimited: !others.isEmpty)
                                .overlay(alignment: .top) { RowDivider() }
                        }
                        .listCard()
                    }
                }
                if monthlyBudget > 0, !others.isEmpty {
                    OutsideHeaderSection(title: "Chưa có hạn mức") {
                        VStack(alignment: .leading, spacing: Spacing.headerGap) {
                            // Why one would, in one line (review 2026-11-08: nothing said it);
                            // "phần chưa phân bổ" only once that row shows.
                            Text(limited.isEmpty
                                 ? "Đặt hạn mức riêng để Milu nhắc khi nhóm sắp chạm mức."
                                 : "Đặt hạn mức riêng để Milu nhắc khi nhóm sắp chạm mức. Nhóm chưa có hạn mức chi từ phần chưa phân bổ.")
                                .textRole(.caption)
                                .foregroundStyle(Palette.secondaryLabel)
                                .fixedSize(horizontal: false, vertical: true)
                            VStack(spacing: 0) {
                                ForEach(Array(others.enumerated()), id: \.element.id) { index, group in
                                    unlimitedRow(group, spent: spentByGroup[group.id] ?? 0)
                                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                                }
                            }
                            .listCard()
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.l)
            .padding(.bottom, Spacing.xxl)
        }
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Hạn mức chi tiêu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if monthlyBudget > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    EditToolbarButton { isEditingMonth = true }
                        .accessibilityLabel("Sửa hạn mức tháng")
                }
            }
        }
        .sheet(isPresented: $isEditingMonth) { MonthBudgetEditor() }
        // The group's spending is a link in its sheet (review 2026-11-08: a long press no screen
        // showed, against the rule of no long-press menus).
        .sheet(item: $editingGroup) { group in
            GroupBudgetEditor(groupID: group.id, name: group.name) { reportGroup = group }
        }
        .navigationDestination(item: $reportGroup) {
            CategoryReportView(groupID: $0.id, period: ReportPeriod(.month, containing: month))
        }
        // A group hidden or deleted since gives its limit back to "Chưa phân bổ".
        .onAppear { categoryBudgets = categoryBudgets.keeping(store.budgetGroupIDs) }
    }

    // MARK: - Tháng

    /// No limit yet: what one does, and the one way to set it (review 2026-11-08: two stacked cards
    /// whose line said nothing of what a limit is for).
    private var emptyState: some View {
        VStack(spacing: Spacing.m) {
            EmptyStateCard(title: "Chưa đặt hạn mức",
                           message: "Đặt mức chi cho mỗi tháng, Milu sẽ cho biết còn tiêu được bao nhiêu và nhắc khi sắp chạm mức.",
                           picture: IconCatalog.emojiName("🎯"))
            TimiButton("Đặt hạn mức tháng", role: .primary, fullWidth: true) { isEditingMonth = true }
        }
    }

    /// What is left in large type, the bar, spent of the limit, and each day's share of what is left.
    private func summary(_ progress: BudgetProgress) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Over, "Đã vượt" and the red amount say it: no "Vượt hạn mức" badge beside them
                // (review 2026-11-08). The badge goes under the words at the accessibility sizes.
                AdaptiveStack(alignment: .center, spacing: Spacing.s, stackedSpacing: Spacing.xs) {
                    Text(leftWords(progress))
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryLabel)
                    if let state = stateWords(progress) {
                        StatusBadge(title: state, tone: .caution)
                    }
                }
                // Over: the amount over in red, no minus after "Đã vượt" (the word says it).
                Text(abs(progress.left).vnd)
                    .textRole(.amountLarge)
                    .foregroundStyle(progress.isOver ? Palette.expense : Palette.label)
                    .shrinksOnlyToFit(0.5)
            }
            ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
            // "Đã chi X trên Y" in one form, both full or both short; stacked at the accessibility
            // sizes (review 2026-11-08: "25.000.000đ / 30tr", and cut words at large text).
            AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s, stackedSpacing: Spacing.xxs) {
                if typeSize.isAccessibilitySize {
                    // One sentence that wraps: in four pieces on one line even the short form ran
                    // past the card, cutting "Đã chi" to "Đ…" (review 2026-11-08).
                    Text("Đã chi \(progress.spent.vnd) trên \(progress.limit.vnd)")
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ViewThatFits(in: .horizontal) {
                        spentLine(progress, compact: false)
                        spentLine(progress, compact: true)
                    }
                }
                if !typeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
                Text(progress.percentText)
                    .monospacedDigit()
            }
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryLabel)

            if let daily = progress.dailyAllowance(in: month) {
                AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s, stackedSpacing: Spacing.xxs) {
                    Text("Mỗi ngày có thể chi")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                    if !typeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text("khoảng")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                        MoneyText(amount: daily)
                    }
                }
                .padding(.top, Spacing.m)
                // A form hairline: from where the words start to the card's edge.
                .overlay(alignment: .top) { FormDivider(hasIcon: false).padding(.horizontal, -RowMetrics.horizontal) }
            }
        }
        .settingsCard()
        // Read as a sentence (review 2026-11-08: "/" and "~" were read as symbols).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summaryLabel(progress))
    }

    private func spentLine(_ progress: BudgetProgress, compact: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Text("Đã chi")
            // At their own width: left loose, a short "0đ" took a share of the row and stood
            // apart from "trên" (Simulator check 2026-11-08). The outer `ViewThatFits` still
            // falls back to the short form when the full one does not fit.
            MoneyText(amount: progress.spent, size: .caption, tone: .muted, compact: compact)
                .fixedSize()
            Text("trên")
            MoneyText(amount: progress.limit, size: .caption, tone: .muted, compact: compact)
                .fixedSize()
        }
    }

    private func summaryLabel(_ progress: BudgetProgress) -> String {
        var parts = [progress.isOver
            ? "Đã vượt hạn mức \(MoneyText.spoken(abs(progress.left)))"
            : "\(leftWords(progress)) \(MoneyText.spoken(max(progress.left, 0)))"]
        // The badge's words too (review 2026-11-08: "Sắp hết" was never read).
        if let state = stateWords(progress) { parts.append(state.lowercased()) }
        parts.append("đã chi \(MoneyText.spoken(progress.spent)) trên \(MoneyText.spoken(progress.limit)), \(progress.percentText)")
        if let daily = progress.dailyAllowance(in: month) {
            parts.append("mỗi ngày có thể chi khoảng \(MoneyText.spoken(daily))")
        }
        return parts.joined(separator: ", ")
    }

    /// The month gone by is done: what it did not spend is "Còn dư", and nothing is "Sắp hết"
    /// any more (review 2026-11-08).
    private var isPastMonth: Bool {
        !Calendar.current.isDate(month, equalTo: .now, toGranularity: .month)
    }

    private func leftWords(_ progress: BudgetProgress) -> String {
        progress.isOver ? "Đã vượt" : isPastMonth ? "Còn dư" : "Còn lại"
    }

    /// "Hết hạn mức" with nothing left, "Sắp hết" from 80% in the month under way; nil when fine
    /// or over (then "Đã vượt" and the red amount say it).
    private func stateWords(_ progress: BudgetProgress) -> String? {
        if progress.isOver { return nil }
        if progress.left <= 0 { return "Hết hạn mức" }
        return progress.isNearing && !isPastMonth ? "Sắp hết" : nil
    }

    // MARK: - Nhóm

    /// A group with a limit: name over its limit, what is left or how much over, the bar. Tapping it
    /// opens the limit, whose sheet links to the group's spending.
    private func limitedRow(_ group: Category, progress: BudgetProgress) -> some View {
        Button { editingGroup = GroupRef(id: group.id, name: group.name) } label: {
            HStack(spacing: RowMetrics.gap) {
                RowIcon(name: group.icon)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s, stackedSpacing: Spacing.xxs) {
                        VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                            Text(group.name)
                                .textRole(.body)
                                .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                            // Wraps at the accessibility sizes rather than "Hạn mức 6.000…".
                            Text("Hạn mức \(progress.limit.vnd)")
                                .textRole(.caption)
                                .foregroundStyle(Palette.secondaryLabel)
                                .monospacedDigit()
                                .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                        }
                        if !typeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
                        leftLabel(progress)
                    }
                    ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
                }
            }
            .formRowFrame()
        }
        .buttonStyle(.row)
        .accessibilityElement(children: .ignore)
        // The share used and the state too, as the bar shows them (review 2026-11-08).
        .accessibilityLabel(["\(group.name), hạn mức \(MoneyText.spoken(progress.limit))",
                             progress.isOver ? "đã vượt \(MoneyText.spoken(-progress.left))" : "còn \(MoneyText.spoken(progress.left))",
                             "đã dùng \(progress.percentText)",
                             stateWords(progress)?.lowercased()].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Sửa hạn mức của nhóm")
    }

    /// The part of the month no group holds, and what has come out of it. Not a button: it changes
    /// as the groups' limits and the month's do.
    private func restRow(_ progress: BudgetProgress, hasOverspend: Bool, hasUnlimited: Bool) -> some View {
        HStack(spacing: RowMetrics.gap) {
            RowIcon(name: "hugeicons-dashboard-square-01")
            VStack(alignment: .leading, spacing: Spacing.s) {
                AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s, stackedSpacing: Spacing.xxs) {
                    VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                        Text("Chưa phân bổ")
                            .textRole(.body)
                        // What actually spends from it (review 2026-11-08: "nhóm chưa có hạn mức"
                        // with every group given one).
                        Text(restCaption(hasOverspend: hasOverspend, hasUnlimited: hasUnlimited))
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !typeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
                    leftLabel(progress)
                }
                if progress.limit > 0 {
                    ProgressBar(value: progress.ratio, color: ProgressBar.budgetColor(progress.ratio))
                } else if progress.spent > 0 {
                    // Nothing left to give, yet something spent from it: a full red bar.
                    ProgressBar(value: 1, color: Palette.negative)
                }
            }
        }
        .formRowFrame()
        .accessibilityElement(children: .ignore)
        // No "0 đồng" (review 2026-11-08): with nothing left to give, "đã phân bổ hết" instead; and
        // what spends from it, as the caption says.
        .accessibilityLabel(["Chưa phân bổ",
                             progress.limit <= 0 ? "hạn mức tháng đã phân bổ hết cho các nhóm"
                                                 : MoneyText.spoken(progress.limit),
                             progress.isOver ? "đã vượt \(MoneyText.spoken(-progress.left))"
                                 : progress.limit > 0 ? "còn \(MoneyText.spoken(progress.left))" : nil,
                             restCaption(hasOverspend: hasOverspend, hasUnlimited: hasUnlimited).lowercased()]
            .compactMap { $0 }.joined(separator: ", "))
    }

    /// Everything that spends from it, fees and interest always among them, in the same words
    /// (review 2026-11-08: "phí, lãi" here, "phí chuyển khoản và lãi vay" there, and none at all
    /// beside the groups without a limit).
    private func restCaption(hasOverspend: Bool, hasUnlimited: Bool) -> String {
        switch (hasUnlimited, hasOverspend) {
        case (true, true): "Dành cho nhóm chưa có hạn mức, phí chuyển khoản, lãi vay và phần vượt của các nhóm"
        case (true, false): "Dành cho nhóm chưa có hạn mức, phí chuyển khoản và lãi vay"
        case (false, true): "Dành cho phí chuyển khoản, lãi vay và phần vượt của các nhóm"
        case (false, false): "Dành cho phí chuyển khoản và lãi vay"
        }
    }

    /// "Còn 1.740.000đ", "Vượt 300.000đ" in red (no minus: the word says it), or "Đã phân bổ hết"
    /// for a part with nothing left to give and nothing spent from it ("Đã chia hết" read as
    /// "divisible", review 2026-11-08); spent from all the same, "Vượt". On one line, except at the
    /// accessibility sizes, where a long amount wraps rather than runs past the card.
    @ViewBuilder
    private func leftLabel(_ progress: BudgetProgress) -> some View {
        if progress.limit <= 0 && progress.spent == 0 {
            Text("Đã phân bổ hết")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(progress.isOver ? "Vượt" : "Còn")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                Text(abs(progress.left).vnd)
                    .textRole(.captionStrong)
                    .monospacedDigit()
                    .foregroundStyle(progress.isOver ? Palette.expense : Palette.label)
            }
            .fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: true)
        }
    }

    /// "Chưa chi tháng này", or the month as the month button names it, with its year when it is
    /// another year's (review 2026-11-08: November 2025 read "Chưa chi tháng 11").
    private var noSpendingWords: String {
        Calendar.current.isDate(month, equalTo: .now, toGranularity: .month)
            ? "Chưa chi tháng này"
            : "Chưa chi " + MonthPickerButton.name(of: month).lowercased()
    }

    /// The same for VoiceOver, which reads "11/2025" as a fraction: "chưa chi tháng 11 năm 2025".
    private var noSpendingSpoken: String {
        let calendar = Calendar.current
        guard isPastMonth, calendar.component(.year, from: month) != calendar.component(.year, from: .now) else {
            return noSpendingWords.lowercased()
        }
        return "chưa chi tháng \(calendar.component(.month, from: month)) năm \(String(calendar.component(.year, from: month)))"
    }

    /// A group with no limit: what it spent, and "+ Đặt hạn mức" to give it one (review 2026-11-08: these rows
    /// opened the group's report, where the limit hid behind an unlabelled ✎).
    private func unlimitedRow(_ group: Category, spent: Double) -> some View {
        Button { editingGroup = GroupRef(id: group.id, name: group.name) } label: {
            HStack(spacing: RowMetrics.gap) {
                RowIcon(name: group.icon)
                // "+ Đặt" under the words at the accessibility sizes, so "Đã chi" keeps its whole
                // amount (review 2026-11-08).
                AdaptiveStack(alignment: .center, spacing: RowMetrics.gap, stackedSpacing: Spacing.xs) {
                    VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                        Text(group.name)
                            .textRole(.body)
                            .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                        Text(spent > 0 ? "Đã chi \(spent.vnd)" : noSpendingWords)
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                            .monospacedDigit()
                            .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // Hugeicons' + as every button in a page's content (SF only on the bars).
                    HStack(spacing: IconSize.glyphGap) {
                        TimiIcon("hugeicons-add-01", size: IconSize.inline)
                        // The verb with what it sets (review 2026-11-08: a lone "Đặt" read cut
                        // short, as "Đủ" did).
                        Text("Đặt hạn mức").textRole(.accessory)
                    }
                    .foregroundStyle(Palette.primary)
                    .fixedSize()
                }
            }
            .formRowFrame()
        }
        .buttonStyle(.row)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(group.name), chưa có hạn mức, " + (spent > 0 ? "đã chi \(MoneyText.spoken(spent))" : noSpendingSpoken))
        .accessibilityHint("Đặt hạn mức cho nhóm")
    }
}
