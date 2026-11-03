import SwiftUI

/// A savings goal as a row in Tài khoản's list, like the accounts above it (HIG review
/// 2026-10-30: two big tiles read as a second layout on the page and went uneven with an odd
/// count). A small ring of how far along with the goal's icon in it, the name and when it is due,
/// what is saved of the target and the percent. The ring turns red when the goal is overdue.
struct GoalRow: View {
    let goal: SavingsGoal

    var body: some View {
        ListRow(title: goal.name, subtitle: subtitle,
                subtitleColor: goal.isOverdue ? Palette.negative : Palette.secondaryLabel) {
            // As wide as an account's logo, so the hairline between rows is `RowDivider(column: .logo)`.
            GoalRing(goal: goal, size: RowMetrics.listLogo)
        } trailing: {
            ListRowTrailing(note: goal.isReached ? "Đủ" : goal.progressText,
                            noteColor: goal.isOverdue ? Palette.negative : Palette.secondaryLabel) {
                // In the weight of every amount in a list (strict review 2026-10-31).
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    MoneyText(amount: goal.saved)
                    Text(" / ").textRole(.amount)
                    MoneyText(amount: goal.target)
                }
            }
        }
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
}

/// A goal's ring with its icon in it: the share saved, red once past the deadline, full once the
/// goal is closed (it met its target; the money has since left it). The glyph is half the ring,
/// as the glyph on an account's tile (`RowIcon(tiled:)`), at any size. `size` is the size at the
/// default text size; the ring grows with the text on its own, as `RowIcon` does.
struct GoalRing: View {
    let goal: SavingsGoal

    @ScaledMetric private var size: CGFloat

    init(goal: SavingsGoal, size: CGFloat) {
        self.goal = goal
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        // Red when overdue, lime once full or closed (`progressDone`), ink on the way.
        ProgressRing(progress: goal.isClosed ? 1 : goal.progress,
                     color: goal.isOverdue ? Palette.negative
                         : goal.isClosed || goal.isReached ? Palette.progressDone : Palette.progress)
            .overlay {
                // The goal's 3D picture in the ring (2026-11-03), as on its tile.
                Image(Picture3D.name(for: goal.icon))
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.55, height: size * 0.55)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Kiểu B of Tài khoản: a goal as a tile in a row scrolling sideways, like the shelves in Photos
/// and Fitness (redone 2026-11-03 with the page's 3D pictures): the goal's 3D picture with no tile
/// behind it, standing on the card, its name on one line, a thin bar of how far along (lime once full, red when overdue) and
/// what is saved of the target. Same size whatever the name, so the row stays even.
struct GoalCarouselTile: View {
    /// A goal's width: two goals and the edge of the next fit across the card.
    static let width: CGFloat = 132
    /// The dashed edge of "+ Hũ mới" (re-review 2026-10-31: named instead of written in place).
    static let dash = StrokeStyle(lineWidth: 1.5, dash: [5, 4])

    let goal: SavingsGoal

    @ScaledMetric(relativeTo: .body) private var width = GoalCarouselTile.width
    @ScaledMetric(relativeTo: .body) private var picture = RowMetrics.picture

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Image(Picture3D.name(for: goal.icon))
                .resizable()
                .scaledToFit()
                .frame(width: picture, height: picture)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(goal.name)
                    .textRole(.body)
                    .lineLimit(1)
                ProgressBar(value: goal.isClosed ? 1 : goal.progress,
                            color: goal.isOverdue ? Palette.negative
                                : goal.isClosed || goal.isReached ? Palette.progressDone : Palette.progress)
                // Both short ("28tr / 40tr"): left to fit on their own, one shortened and the
                // other did not (Simulator check 2026-11-03).
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(goal.saved.vndCompact)
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.label)
                    Text(" / \(goal.target.vndCompact)")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                }
                .monospacedDigit()
                .lineLimit(1)
            }
        }
        .padding(.vertical, Spacing.s)
        .frame(width: width, alignment: .leading)
        // No tile of its own, the card's white around it: goals stand apart by the gap between
        // them (user reports 2026-11-03: the grey tile, then a hairline, read busy).
        .contentShape(RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous))
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
        let shape = RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous)
        VStack(spacing: Spacing.s) {
            TimiIcon("hugeicons-add-01", size: RowMetrics.iconGlyph)
            Text("Hũ mới")
                .textRole(.body)
        }
        .foregroundStyle(Palette.primary)
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .overlay { shape.strokeBorder(Palette.primaryDash, style: GoalCarouselTile.dash) }
        .contentShape(shape)
    }
}
