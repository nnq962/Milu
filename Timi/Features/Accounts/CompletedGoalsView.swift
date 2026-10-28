import SwiftUI

/// "Hũ đã hoàn thành": every savings goal that reached its target, as rows: icon, name, when it
/// was reached and what it holds (the target is not repeated: it equals the amount). Tapping one opens it (to withdraw or delete).
struct CompletedGoalsView: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let goals = store.completedGoals
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                    NavigationLink(value: GoalRoute(id: goal.id)) {
                        ListRow(icon: goal.icon, title: goal.name,
                                subtitle: completedText(goal),
                                amount: goal.saved, amountTone: .plain)
                    }
                    .buttonStyle(.row)
                    .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                }
            }
            .cardSurface(color: Palette.card, elevated: true)
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.l)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Hũ đã hoàn thành")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if goals.isEmpty {
                ContentUnavailableView("Chưa có hũ nào hoàn thành", image: "hugeicons-piggy-bank")
            }
        }
    }

    /// "Hoàn thành 28/10": the day of the latest deposit, which is when the target was reached.
    private func completedText(_ goal: SavingsGoal) -> String {
        guard let last = store.transfers(of: goal).first(where: { $0.direction == .deposit }) else {
            return "Đã hoàn thành"
        }
        return "Hoàn thành \(TransactionListRow.dayMonth(last.date))"
    }
}
