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

/// A goal in Tài khoản as a jar filling up (user pick "C" 2026-11-03, in place of the tiles
/// scrolling sideways): a tall rounded jar in `surfaceMuted`, lime rising from the bottom to the
/// share saved, the goal's 3D picture at the top and the percent at the bottom; under the jar its
/// name and what is saved of the target. Full once the goal is reached or closed, with "Đủ" for
/// the percent; pale coral with the percent in red once past its date. Three to a row, as wide as
/// the grid makes them.
struct GoalJarTile: View {
    let goal: SavingsGoal

    @ScaledMetric(relativeTo: .body) private var jarHeight: CGFloat = 128
    @ScaledMetric(relativeTo: .body) private var picture: CGFloat = 44

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous)
        let isFull = goal.isClosed || goal.isReached
        // A sliver shows as soon as anything is in the jar.
        let level = isFull ? 1 : goal.progress > 0 ? max(goal.progress, 0.04) : 0
        // The percent sits in the jar's lowest quarter: in ink on the lime once the lime reaches it.
        let onFill = level >= 0.25
        VStack(spacing: Spacing.s) {
            ZStack {
                shape.fill(Palette.surfaceMuted)
                GeometryReader { proxy in
                    (goal.isOverdue ? Palette.expenseSoft : Palette.accent)
                        .frame(height: proxy.size.height * level)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                VStack {
                    Image(Picture3D.name(for: goal.icon))
                        .resizable()
                        .scaledToFit()
                        .frame(width: picture, height: picture)
                    Spacer(minLength: Spacing.s)
                    Text(isFull ? "Đủ" : goal.progressText)
                        .textRole(.title)
                        .monospacedDigit()
                        .foregroundStyle(goal.isOverdue ? Palette.negative
                                         : onFill ? Palette.onAccent : Palette.label)
                }
                .padding(.vertical, Spacing.m)
            }
            .frame(height: jarHeight)
            .clipShape(shape)
            VStack(spacing: Spacing.xxs) {
                Text(goal.name)
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.label)
                // Both short ("28tr / 40tr"), as they fit under a third of the card.
                Text("\(goal.saved.vndCompact) / \(goal.target.vndCompact)")
                    .textRole(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.secondaryLabel)
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(shape)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([goal.name, "đã để dành \(goal.saved.vnd) trên \(goal.target.vnd)",
                             goal.isReached ? "đã đủ mục tiêu" : goal.isOverdue ? "quá hạn" : goal.progressText]
            .joined(separator: ", "))
        .accessibilityHint("Xem hũ")
    }
}
