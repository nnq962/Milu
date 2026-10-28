import SwiftUI

struct GoalCard: View {
    let goal: SavingsGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // justify-between: icon + text on the left, amount + chevron on the right.
            HStack(spacing: 0) {
                HStack(spacing: RowMetrics.gap) {
                    // Same icon column and type as list rows (design system defaults).
                    SolarIcon(goal.icon.rawValue, size: RowMetrics.iconGlyph)
                        .frame(width: RowMetrics.iconColumn)
                    VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                        Text(goal.name)
                            .textRole(.body)
                            .lineLimit(1)
                        Text("Mục tiêu \(goal.target.vnd)")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .lineLimit(1)
                    }
                }
                // Keep the target readable; the saved amount scales down first.
                .layoutPriority(1)
                Spacer(minLength: 8)
                HStack(spacing: 12) {
                    MoneyText(amount: goal.saved)
                    SolarIcon("solar-alt-arrow-right-linear", size: 16)
                        .foregroundStyle(Palette.secondary)
                }
            }
            ProgressBar(value: goal.progress)
                .padding(.top, Spacing.l)
            HStack {
                Text("Đã đạt \(goal.progress.percentText)")
                Spacer()
                Text(goal.remaining > 0 ? "Còn \(goal.remaining.vnd)" : "Đã đủ mục tiêu")
            }
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
            .padding(.top, Spacing.s)
        }
        // p-5 plus the 1pt border, which CSS adds inside the card's box.
        .padding(21)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
                .strokeBorder(Palette.border, lineWidth: 1)
        }
        .cardSurface(color: Palette.card, elevated: true)
        .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Sửa hũ tiết kiệm")
    }
}
