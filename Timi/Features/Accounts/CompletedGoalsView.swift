import SwiftUI

/// "Hũ đã hoàn thành": every closed goal (spent or taken out after reaching its target), the most
/// recent first, as rows: ring, name, how and when it ended, and the target it met. Tapping one
/// opens it (read-only history; the pencil offers "Mở lại hũ" and "Xoá hũ").
struct CompletedGoalsView: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let goals = store.completedGoals
        // Laid out as "Tài khoản đã lưu trữ": one scroll view, the same margins, empty or not.
        ScrollView {
            if goals.isEmpty {
                // Reopening the last goal empties this list while the screen is open.
                EmptyStateCard(icon: "hugeicons-piggy-bank", title: "Chưa có hũ nào hoàn thành",
                               message: "Hũ đã đủ mục tiêu sẽ hiện ở đây.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                        NavigationLink(value: GoalRoute(id: goal.id)) {
                            CompletedGoalRow(goal: goal, subtitle: completedText(goal))
                        }
                        .buttonStyle(.row)
                        .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                    }
                }
                .listCard()
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .background(Palette.background)
        .foregroundStyle(Palette.label)
        .navigationTitle("Hũ đã hoàn thành")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// "Đã dùng: Mua xe · 29/10": how it ended and the day it closed.
    private func completedText(_ goal: SavingsGoal) -> String {
        let day = goal.closedAt?.shortDay
        return [goal.closingNote.isEmpty ? "Đã hoàn thành" : goal.closingNote, day]
            .compactMap { $0 }.joined(separator: " · ")
    }
}

/// A closed goal drawn as a goal on the tab (`GoalRow`), not as a transaction (re-review
/// 2026-10-31: a 24 glyph here, a 32 ring there): its full ring in the logo column, the name and
/// how it ended, the target it met, ›.
private struct CompletedGoalRow: View {
    let goal: SavingsGoal
    let subtitle: String

    var body: some View {
        ListRow(title: goal.name, subtitle: subtitle) {
            GoalRing(goal: goal, size: RowMetrics.listLogo)
        } trailing: {
            ListRowAmount(amount: goal.target, compact: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([goal.name, subtitle, "mục tiêu \(goal.target.vnd)"].joined(separator: ", "))
        .accessibilityHint("Xem hũ")
    }
}
