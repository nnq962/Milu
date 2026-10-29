import SwiftUI

/// A savings goal on Tài khoản: a card in a row that scrolls sideways (user choice 2026-10-28,
/// after rows and two-column tiles). Wide enough that nothing is cut off: icon, name, the saved
/// amount in full, "Mục tiêu 40tr · 70%", and the bar.
struct GoalCard: View {
    let goal: SavingsGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RowIcon(name: goal.icon)
            Text(goal.name)
                .textRole(.body)
                .lineLimit(1)
                .padding(.top, Spacing.m)
            MoneyText(amount: goal.saved)
                .padding(.top, Spacing.xs)
            Text(goal.isReached ? "Đã đủ · mục tiêu \(goal.target.vndCompact)"
                                : "Mục tiêu \(goal.target.vndCompact) · \(goal.progressText)")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
                .monospacedDigit()
                .lineLimit(1)
                .padding(.top, Spacing.xxs)
            ProgressBar(value: goal.progress)
                .padding(.top, Spacing.m)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.card)
        .cardSurface(color: Palette.card, elevated: true)
        .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
