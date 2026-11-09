import SwiftUI

/// A savings goal as a row, in Tài sản ròng and the UI library (Tài khoản shows its goals as
/// jars, `GoalJar`, since 2026-11-05). A small ring of how far along with the goal's icon in it, the name and when it is due,
/// what is saved of the target and the percent. The ring turns red when the goal is overdue.
struct GoalRow: View {
    let goal: SavingsGoal

    var body: some View {
        ListRow(title: goal.name, subtitle: subtitle,
                subtitleColor: goal.isOverdue ? Palette.negative : Palette.secondaryLabel,
                hasTrailingNote: true) {
            // As wide as an account's logo, so the hairline between rows is `RowDivider(column: .logo)`.
            GoalRing(goal: goal, size: RowMetrics.listLogo)
        } trailing: {
            ListRowTrailing(note: goal.isReached ? "Đã đủ" : goal.progressText,
                            noteColor: goal.isOverdue ? Palette.negative : Palette.secondaryLabel) {
                // In the weight of every amount in a list (strict review 2026-10-31). Both figures
                // short, always: each choosing on its own wrote "10.000.000đ / 40tr" (user report
                // 2026-11-08), and the full pair, taking the row first, left the name "Mua…".
                figures
            }
        }
        // In words: "Mua xe, hạn 5 tháng 1, 2028, đã để dành 10.000.000 đồng trên 40.000.000 đồng,
        // 25%" (review 2026-11-08: "đ" was read as a letter and the deadline left out).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([goal.name, subtitle.map { FormDateRow.spokenDays(in: $0.lowercased()) },
                             "đã để dành \(MoneyText.spoken(goal.saved)) trên \(MoneyText.spoken(goal.target))",
                             // "Quá hạn …" is already in the subtitle read above: once.
                             goal.isReached ? "đã đủ mục tiêu" : goal.progressText]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Xem hũ")
    }

    private var figures: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            MoneyText(amount: goal.saved, compact: true)
            Text(" / ").textRole(.amount)
            MoneyText(amount: goal.target, compact: true)
        }
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

    private let base: CGFloat
    @ScaledMetric private var scaled: CGFloat

    init(goal: SavingsGoal, size: CGFloat) {
        self.goal = goal
        base = size
        _scaled = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        // As every row's leading, no bigger than `RowMetrics.leadingMaxScale` times its size.
        let size = RowMetrics.capped(scaled, base: base)
        // Red when overdue, green once full or closed (`progressDone`), the progress colour on the way.
        ProgressRing(progress: goal.isClosed ? 1 : goal.progress,
                     color: goal.isOverdue ? Palette.negative
                         : goal.isClosed || goal.isReached ? Palette.progressDone : Palette.progress)
            .overlay {
                // Use the same artwork in the ring and on the tile.
                Image(GoalArtwork.name(for: goal.icon))
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.55, height: size * 0.55)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
