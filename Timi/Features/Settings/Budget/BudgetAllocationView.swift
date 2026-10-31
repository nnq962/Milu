import SwiftUI

/// "Phân bổ hạn mức" (user choice 2026-10-30), opened from the month's card on Hạn mức chi tiêu:
/// how the month's limit splits into the groups' limits and what is left unassigned ("Chưa phân
/// bổ"), each part with what it has spent. Groups without a limit spend from "Chưa phân bổ"; they
/// are listed under it. Every group opens its detail; ✎ changes the month's limit, which never drops
/// below what the groups hold (`BudgetRules`).
struct BudgetAllocationView: View {
    let month: Date

    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = SampleData.categoryBudgets
    @State private var isEditing = false
    @Environment(\.dismiss) private var dismiss

    /// One part of the month's limit: a group's, or the rest.
    private struct Part: Identifiable {
        let id: String
        let name: String
        let icon: String
        let limit: Double
        let spent: Double
        let color: Color
        var isRest = false
    }

    var body: some View {
        let spentByGroup = Dictionary(uniqueKeysWithValues: store.expensesByCategory(inMonthOf: month).map { ($0.groupID, $0) })
        let limited = store.groups(.expense).filter { categoryBudgets[$0.id] > 0 }
            .sorted { categoryBudgets[$0.id] > categoryBudgets[$1.id] }
        let parts = limited.enumerated().map { index, group in
            Part(id: group.id, name: group.name, icon: group.icon, limit: categoryBudgets[group.id],
                 spent: spentByGroup[group.id]?.amount ?? 0,
                 color: ChartShades.color(at: index), isRest: ChartShades.isRest(at: index))
        }
        let assigned = parts.reduce(0) { $0 + $1.limit }
        let unassigned = max(monthlyBudget - assigned, 0)
        let allSpent = store.total(.expense, inMonthOf: month)
        let restSpent = max(allSpent - parts.reduce(0) { $0 + $1.spent }, 0)
        let restGroups = store.expensesByCategory(inMonthOf: month).filter { categoryBudgets[$0.groupID] == 0 }
        let monthPeriod = ReportPeriod(.month, containing: month)

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                overview(parts: parts, assigned: assigned, unassigned: unassigned)

                // Headings and list cards as on Báo cáo, which these rows open into (re-review
                // 2026-10-31: small-caps form groups on a page of figures).
                VStack(alignment: .leading, spacing: Spacing.headerGap) {
                    SectionHeader(title: "Phân bổ")
                    VStack(spacing: 0) {
                        ForEach(Array(parts.enumerated()), id: \.element.id) { index, part in
                            NavigationLink {
                                CategoryReportView(groupID: part.id, period: monthPeriod)
                            } label: {
                                BreakdownRowLabel(icon: part.icon, title: part.name,
                                                  detail: detail(limit: part.limit, spent: part.spent),
                                                  amount: part.limit, dot: part.color, edgedDot: part.isRest)
                            }
                            .buttonStyle(.row)
                            .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                        }
                        BreakdownRowLabel(icon: "hugeicons-dashboard-square-01", title: "Chưa phân bổ",
                                          detail: detail(limit: unassigned, spent: restSpent),
                                          amount: unassigned, hollowDot: true, opensMore: false)
                            .overlay(alignment: .top) { if !parts.isEmpty { RowDivider() } }
                    }
                    .listCard()
                }

                if !restGroups.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Chi từ phần chưa phân bổ")
                        VStack(spacing: 0) {
                            ForEach(Array(restGroups.enumerated()), id: \.element.id) { index, group in
                                NavigationLink {
                                    CategoryReportView(groupID: group.groupID, period: monthPeriod)
                                } label: {
                                    // The same row as these groups under "Chưa có hạn mức" on Hạn mức.
                                    BreakdownRowLabel(icon: group.icon, title: group.name,
                                                      detail: restSpent > 0 ? (group.amount / restSpent).percentText : "Chưa chi",
                                                      amount: group.amount)
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
        .foregroundStyle(Palette.ink)
        .navigationTitle("Phân bổ hạn mức")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditToolbarButton { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) { MonthBudgetEditor() }
        // With no month limit there is nothing to split: back to Hạn mức chi tiêu.
        .onChange(of: monthlyBudget) { _, value in if value == 0 { dismiss() } }
    }

    /// "Còn 170k" or "Vượt 1,1tr".
    private func detail(limit: Double, spent: Double) -> String {
        let progress = BudgetProgress(limit: limit, spent: spent)
        return progress.isOver ? "Vượt \((-progress.left).vndCompact)" : "Còn \(progress.left.vndCompact)"
    }

    /// The month's limit and one bar split into the parts, "Chưa phân bổ" in grey at the end.
    private func overview(parts: [Part], assigned: Double, unassigned: Double) -> some View {
        // Over-assigned groups fill the bar by their own total.
        let whole = max(monthlyBudget, assigned, 1)
        return VStack(alignment: .leading, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Hạn mức tháng")
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryText)
                MoneyText(amount: monthlyBudget, size: .large)
            }
            GeometryReader { proxy in
                HStack(spacing: Spacing.xxs) {
                    ForEach(parts) { part in
                        part.color.frame(width: max(proxy.size.width * part.limit / whole - Spacing.xxs, Spacing.xxs))
                    }
                    // The empty track, like any progress bar: what is not split yet.
                    if unassigned > 0 {
                        Palette.muted
                    }
                }
                .clipShape(Capsule())
            }
            // One bar height in the app (strict review 2026-10-31: this one was 12).
            .frame(height: ProgressBar.height)
            .accessibilityHidden(true)
            // Amounts as MoneyText, grey like the words (re-review 2026-10-31).
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("Đã phân bổ")
                MoneyText(amount: assigned, size: .caption, tone: .muted, compact: true)
                Spacer(minLength: Spacing.s)
                Text("Chưa phân bổ")
                MoneyText(amount: unassigned, size: .caption, tone: .muted, compact: true)
            }
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
        }
        .settingsCard()
        .accessibilityElement(children: .combine)
    }
}
