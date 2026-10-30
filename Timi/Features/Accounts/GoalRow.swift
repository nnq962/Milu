import SwiftUI

/// A savings goal as a row in Tài khoản's white list, like the accounts above it (HIG review
/// 2026-10-30: two big tiles read as a second layout on the page and went uneven with an odd
/// count). A small ring of how far along with the goal's icon in it, the name and when it is due,
/// what is saved of the target and the percent. The ring turns red when the goal is overdue.
struct GoalRow: View {
    let goal: SavingsGoal

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The ring, as wide as an account's logo, growing with the text.
    @ScaledMetric(relativeTo: .body) private var ringSize: CGFloat = 36

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.m))
        HStack(spacing: Spacing.m) {
            ring
            layout {
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text(goal.name)
                        .textRole(.label)
                    if let subtitle {
                        Text(subtitle)
                            .textRole(.caption)
                            .foregroundStyle(goal.isOverdue ? Palette.red : Palette.secondaryText)
                    }
                }
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
                VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: RowMetrics.lineGap) {
                    Text("\(goal.saved.vndCompact) / \(goal.target.vndCompact)")
                        .textRole(.label)
                        .monospacedDigit()
                    Text(goal.isReached ? "Đủ" : goal.progressText)
                        .textRole(.caption)
                        .monospacedDigit()
                        .foregroundStyle(goal.isOverdue ? Palette.red : Palette.secondaryText)
                }
            }
            // Stacked, the words take the row's width so every row starts at the same edge.
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
            TimiIcon("hugeicons-arrow-right-01", size: 14)
                .foregroundStyle(Palette.secondary)
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, Spacing.s)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        // In words: "Mua xe, đã để dành 10.000.000 đ trên 40.000.000 đ, 25%".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([goal.name, "đã để dành \(goal.saved.vnd) trên \(goal.target.vnd)",
                             goal.isReached ? "đã đủ mục tiêu" : goal.isOverdue ? "quá hạn" : goal.progressText]
            .joined(separator: ", "))
        .accessibilityHint("Xem hũ")
    }

    /// The due date, red once past it; nothing when the goal has none.
    private var subtitle: String? {
        guard let due = goal.dueDate else { return nil }
        return goal.isOverdue ? "Quá hạn \(due.formatted(.dateTime.day().month(.defaultDigits).locale(.vietnam)))"
            : "Hạn \(due.formatted(.dateTime.day().month(.defaultDigits).year().locale(.vietnam)))"
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(Palette.primary.opacity(0.12), lineWidth: 3)
            Circle().trim(from: 0, to: min(goal.progress, 1))
                .stroke(goal.isOverdue ? Palette.red : Palette.primary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            TimiIcon(goal.icon, size: ringSize * 0.45)
                .foregroundStyle(Palette.ink)
        }
        .frame(width: ringSize, height: ringSize)
    }
}

/// Kiểu B of Tài khoản: a goal as a tile in a row scrolling sideways, like the shelves in Photos
/// and Fitness. A ring of how far along with the icon in it, the name, what is saved of the
/// target; red when overdue. Same size whatever the name, so the row stays even.
struct GoalCarouselTile: View {
    let goal: SavingsGoal

    @ScaledMetric(relativeTo: .body) private var ringSize: CGFloat = 56
    @ScaledMetric(relativeTo: .body) private var width: CGFloat = 132

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous)
        VStack(alignment: .leading, spacing: Spacing.m) {
            ZStack {
                Circle().stroke(Palette.primary.opacity(0.12), lineWidth: 4)
                Circle().trim(from: 0, to: min(goal.progress, 1))
                    .stroke(goal.isOverdue ? Palette.red : Palette.primary,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                TimiIcon(goal.icon, size: ringSize * 0.4)
                    .foregroundStyle(Palette.ink)
            }
            .frame(width: ringSize, height: ringSize)
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(goal.name)
                    .textRole(.label)
                    .lineLimit(2, reservesSpace: true)
                Text("\(goal.saved.vndCompact) / \(goal.target.vndCompact)")
                    .textRole(.caption)
                    .monospacedDigit()
                    .foregroundStyle(goal.isOverdue ? Palette.red : Palette.secondaryText)
            }
        }
        .padding(Spacing.l)
        .frame(width: width, alignment: .leading)
        .background(Palette.card, in: shape)
        .softCardShadow()
        .contentShape(shape)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([goal.name, "đã để dành \(goal.saved.vnd) trên \(goal.target.vnd)",
                             goal.isReached ? "đã đủ mục tiêu" : goal.isOverdue ? "quá hạn" : goal.progressText]
            .joined(separator: ", "))
        .accessibilityHint("Xem hũ")
    }
}

/// The last tile of Kiểu B's row: "+ Hũ mới", the same size as a goal, a dashed edge on the page.
struct NewGoalTile: View {
    @ScaledMetric(relativeTo: .body) private var width: CGFloat = 132

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous)
        VStack(spacing: Spacing.s) {
            TimiIcon("hugeicons-add-01", size: 22)
            Text("Hũ mới")
                .textRole(.label)
        }
        .foregroundStyle(Palette.primary)
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .overlay { shape.strokeBorder(Palette.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])) }
        .contentShape(shape)
    }
}
