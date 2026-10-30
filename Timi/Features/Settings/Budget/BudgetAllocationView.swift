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
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                overview(parts: parts, assigned: assigned, unassigned: unassigned)

                FormGroup(title: "Phân bổ") {
                    ForEach(parts) { part in
                        NavigationLink {
                            CategoryReportView(groupID: part.id, period: monthPeriod)
                        } label: {
                            BreakdownRowLabel(icon: part.icon, title: part.name,
                                              detail: detail(limit: part.limit, spent: part.spent),
                                              amount: part.limit.vndCompact, dot: part.color, edgedDot: part.isRest)
                        }
                        .buttonStyle(.row)
                        FormDivider()
                    }
                    BreakdownRowLabel(icon: "hugeicons-dashboard-square-01", title: "Chưa phân bổ",
                                      detail: detail(limit: unassigned, spent: restSpent),
                                      amount: unassigned.vndCompact, hollowDot: true, opensMore: false)
                }

                if !restGroups.isEmpty {
                    FormGroup(title: "Chi từ phần chưa phân bổ") {
                        ForEach(Array(restGroups.enumerated()), id: \.element.id) { index, group in
                            if index > 0 { FormDivider() }
                            NavigationLink {
                                CategoryReportView(groupID: group.groupID, period: monthPeriod)
                            } label: {
                                BreakdownRowLabel(icon: group.icon, title: group.name,
                                                  detail: restSpent > 0 ? (group.amount / restSpent).percentText : "",
                                                  amount: group.amount.vndCompact)
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
                Text(monthlyBudget.vnd)
                    .textRole(.amountLarge)
                    .monospacedDigit()
            }
            GeometryReader { proxy in
                HStack(spacing: 2) {
                    ForEach(parts) { part in
                        part.color.frame(width: max(proxy.size.width * part.limit / whole - 2, 2))
                    }
                    // The empty track, like any progress bar: what is not split yet.
                    if unassigned > 0 {
                        Palette.muted
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: 12)
            .accessibilityHidden(true)
            HStack {
                Text("Đã phân bổ \(assigned.vndCompact)")
                Spacer(minLength: Spacing.s)
                Text("Chưa phân bổ \(unassigned.vndCompact)")
            }
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
        }
        .sleekCard(padding: Spacing.l, radius: CardCorners.extraLarge)
        .accessibilityElement(children: .combine)
    }
}
