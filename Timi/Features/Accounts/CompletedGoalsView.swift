import SwiftUI

/// "Hũ đã hoàn thành": every closed goal (spent or taken out after reaching its target), the most
/// recent first, as rows: icon, name, how and when it ended, and the target it met. Tapping one
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
                               message: "Hũ đã dùng tiền hoặc rút hết sau khi đủ mục tiêu sẽ nằm ở đây.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                        NavigationLink(value: GoalRoute(id: goal.id)) {
                            ListRow(icon: goal.icon, title: goal.name,
                                    subtitle: completedText(goal),
                                    amount: goal.target, amountTone: .plain)
                        }
                        .buttonStyle(.row)
                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .listCard()
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Hũ đã hoàn thành")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// "Đã dùng: Mua xe · 29/10": how it ended and the day it closed.
    private func completedText(_ goal: SavingsGoal) -> String {
        let day = goal.closedAt.map(TransactionListRow.dayMonth)
        return [goal.closingNote.isEmpty ? "Đã hoàn thành" : goal.closingNote, day]
            .compactMap { $0 }.joined(separator: " · ")
    }
}
