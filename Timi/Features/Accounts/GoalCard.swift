import SwiftUI

/// A savings goal on Tài khoản: a card in a row that scrolls sideways (user choice 2026-10-28,
/// after rows and two-column tiles). Wide enough that nothing is cut off: icon, name, the saved
/// amount in full, "Mục tiêu 40tr · 70%", and the bar.
struct GoalCard: View {
    let goal: SavingsGoal

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RowIcon(name: goal.icon)
            Text(goal.name)
                .textRole(.body)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .padding(.top, Spacing.m)
            MoneyText(amount: goal.saved)
                .padding(.top, Spacing.xs)
            Text(goal.isReached ? "Đã đủ · mục tiêu \(goal.target.vndCompact)"
                 : goal.isOverdue ? "Quá hạn · mục tiêu \(goal.target.vndCompact)"
                 : "Mục tiêu \(goal.target.vndCompact) · \(goal.progressText)")
                .textRole(.caption)
                .foregroundStyle(goal.isOverdue ? Palette.red : Palette.secondaryText)
                .monospacedDigit()
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                .padding(.top, Spacing.xxs)
            ProgressBar(value: goal.progress)
                .padding(.top, Spacing.m)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.card)
        .cardSurface(color: Palette.card, elevated: true)
        .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        // In words: "Mua xe, đã để dành 10.000.000 đ trên 40.000.000 đ, 25%".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([goal.name, "đã để dành \(goal.saved.vnd) trên \(goal.target.vnd)",
                             goal.isReached ? "đã đủ mục tiêu" : goal.isOverdue ? "quá hạn" : goal.progressText]
            .joined(separator: ", "))
        .accessibilityHint("Xem hũ")
    }
}
