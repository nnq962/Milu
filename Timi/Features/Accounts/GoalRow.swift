import SwiftUI

/// A savings goal as a row in Tài khoản's white list, like the accounts above it (HIG review
/// 2026-10-30: two big tiles read as a second layout on the page and went uneven with an odd
/// count). A small ring of how far along with the goal's icon in it, the name and when it is due,
/// what is saved of the target and the percent. The ring turns red when the goal is overdue.
struct GoalRow: View {
    let goal: SavingsGoal

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The ring, as wide as an account's logo, growing with the text; the hairline between goal
    /// rows is then `RowDivider(column: .logo)`'s.
    @ScaledMetric(relativeTo: .body) private var ringSize = RowMetrics.listLogo

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.s))
        // The app's row metrics, as `ListRow` and `AccountRow` (strict review 2026-10-31: 12 here
        // put the names off the column of every other list).
        HStack(spacing: RowMetrics.gap) {
            ring
            layout {
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    // One line, as an account's name, so the two lists stand at one row height
                    // (re-review 2026-10-31).
                    Text(goal.name)
                        .textRole(.body)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    if let subtitle {
                        Text(subtitle)
                            .textRole(.caption)
                            .foregroundStyle(goal.isOverdue ? Palette.negative : Palette.secondaryLabel)
                    }
                }
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
                VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: RowMetrics.lineGap) {
                    // In the weight of every amount in a list (strict review 2026-10-31: SemiBold
                    // here read lighter than the balances above).
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        MoneyText(amount: goal.saved, compact: true)
                        Text(" / ").textRole(.amount)
                        MoneyText(amount: goal.target, compact: true)
                    }
                    .fixedSize()
                    Text(goal.isReached ? "Đủ" : goal.progressText)
                        .textRole(.caption)
                        .monospacedDigit()
                        .foregroundStyle(goal.isOverdue ? Palette.negative : Palette.secondaryLabel)
                }
            }
            // Stacked, the words take the row's width so every row starts at the same edge.
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
            RowChevron()
        }
        .padding(.horizontal, RowMetrics.horizontal)
        // The app's row: 10 above and below, at least 52, as every list (user report 2026-10-30:
        // 64 here stood taller than the rows of Hạng mục).
        .padding(.vertical, RowMetrics.vertical)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(Rectangle())
        // In words: "Mua xe, đã để dành 10.000.000 đ trên 40.000.000 đ, 25%".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([goal.name, "đã để dành \(goal.saved.vnd) trên \(goal.target.vnd)",
                             goal.isReached ? "đã đủ mục tiêu" : goal.isOverdue ? "quá hạn" : goal.progressText]
            .joined(separator: ", "))
        .accessibilityHint("Xem hũ")
    }

    /// The due date, red once past it; nothing when the goal has none. The app's one short date
    /// ("6/11", the year only in another year; re-review 2026-10-31: one form with the year, one
    /// without).
    private var subtitle: String? {
        guard let due = goal.dueDate else { return nil }
        return goal.isOverdue ? "Quá hạn \(due.shortDay)" : "Hạn \(due.shortDay)"
    }

    private var ring: some View {
        GoalRing(goal: goal, size: ringSize)
    }
}

/// A goal's ring with its icon in it: the share saved, red once past the deadline, full once the
/// goal is closed (it met its target; the money has since left it). The glyph is half the ring,
/// as the glyph on an account's tile (`RowIcon(tiled:)`), at any size.
struct GoalRing: View {
    let goal: SavingsGoal
    let size: CGFloat

    var body: some View {
        ProgressRing(progress: goal.isClosed ? 1 : goal.progress,
                     color: goal.isOverdue ? Palette.negative : Palette.primary)
            .overlay {
                TimiIcon(goal.icon, size: size / 2)
                    .foregroundStyle(Palette.label)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Kiểu B of Tài khoản: a goal as a tile in a row scrolling sideways, like the shelves in Photos
/// and Fitness. A ring of how far along with the icon in it, the name, what is saved of the
/// target; red when overdue. Same size whatever the name, so the row stays even.
struct GoalCarouselTile: View {
    /// The tile's width and its ring: two names of two lines fit beside the next tile's edge.
    static let width: CGFloat = 140
    static let ring: CGFloat = 56
    /// The dashed edge of "+ Hũ mới" (re-review 2026-10-31: named instead of written in place).
    static let dash = StrokeStyle(lineWidth: 1.5, dash: [5, 4])

    let goal: SavingsGoal

    @ScaledMetric(relativeTo: .body) private var ringSize = GoalCarouselTile.ring
    @ScaledMetric(relativeTo: .body) private var width = GoalCarouselTile.width

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            GoalRing(goal: goal, size: ringSize)
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(goal.name)
                    .textRole(.label)
                    .lineLimit(2, reservesSpace: true)
                // Every amount a `MoneyText`, the target the small grey one (re-review 2026-10-31:
                // a hand-made " / 50tr" that shrank to fit).
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    MoneyText(amount: goal.saved, compact: true)
                    Text(" / ")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                    MoneyText(amount: goal.target, size: .caption, tone: .muted, compact: true)
                }
                .lineLimit(1)
            }
        }
        // 16 at the sides, as the rows and headings of the page, so the ring stands on their
        // edge (re-review 2026-10-31: 20 put it 4pt in from the logos); 20 above and below.
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, Spacing.card)
        .frame(width: width, alignment: .leading)
        // The goal tile's corners and the one card surface (strict review 2026-10-31: 20 and a
        // shadow put on by hand).
        .cardSurface(radius: CardCorners.large, elevated: true)
        .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([goal.name, "đã để dành \(goal.saved.vnd) trên \(goal.target.vnd)",
                             goal.isReached ? "đã đủ mục tiêu" : goal.isOverdue ? "quá hạn" : goal.progressText]
            .joined(separator: ", "))
        .accessibilityHint("Xem hũ")
    }
}

/// The last tile of Kiểu B's row: "+ Hũ mới", the same size as a goal, a dashed edge on the page.
struct NewGoalTile: View {
    @ScaledMetric(relativeTo: .body) private var width = GoalCarouselTile.width

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
        VStack(spacing: Spacing.s) {
            TimiIcon("hugeicons-add-01", size: RowMetrics.iconGlyph)
            Text("Hũ mới")
                .textRole(.label)
        }
        .foregroundStyle(Palette.primary)
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .overlay { shape.strokeBorder(Palette.primaryDash, style: GoalCarouselTile.dash) }
        .contentShape(shape)
    }
}
