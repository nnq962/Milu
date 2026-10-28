import SwiftUI

/// A savings goal on Tài khoản, two per row: icon, name, the saved amount large, its bar and
/// how far along.
struct GoalTile: View {
    let goal: SavingsGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SolarIcon(goal.icon.rawValue, size: 22)
                .foregroundStyle(Palette.ink)
                .frame(width: 40, height: 40)
                .background(Palette.fill1, in: Circle())
            Text(goal.name)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryText)
                .lineLimit(1)
                .padding(.top, Spacing.m)
            Text(goal.saved.vndCompact)
                .textRole(.amountLarge)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            ProgressBar(value: goal.progress)
                .padding(.top, Spacing.m)
            Text(goal.remaining > 0
                 ? "\(goal.progress.percentText) · còn \(goal.remaining.vndCompact)"
                 : "Đã đủ mục tiêu")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
                .monospacedDigit()
                .lineLimit(1)
                .padding(.top, Spacing.s)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .cardSurface(color: Palette.card, elevated: true)
        .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Sửa hũ tiết kiệm")
    }
}
