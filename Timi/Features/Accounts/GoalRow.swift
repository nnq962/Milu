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
/// scrolling sideways): a tall rounded jar in `surfaceMuted`, lime water rising from the bottom to
/// the share saved, its surface rocking gently like water in a bottle, a stronger slosh as the jar
/// comes on screen that settles (user request 2026-11-03); still at Reduce Motion. The goal's 3D
/// picture at the top and the percent at the bottom; under the jar its name and what is saved of
/// the target. Full once the goal is reached or closed, with "Đủ" for the percent and a still
/// surface; pale coral with the percent in red once past its date. Three to a row, as wide as the
/// grid makes them.
struct GoalJarTile: View {
    /// The jar's height at the default text size; it grows with the text.
    static let jarHeight: CGFloat = 128
    /// What a goal with anything saved shows at least, so the water is there to see.
    static let minimumLevel = 0.04
    /// The water's line at rest, and the extra of the slosh as it comes on screen.
    static let ripple: CGFloat = 2.5
    static let slosh: CGFloat = 6

    let goal: SavingsGoal

    @ScaledMetric(relativeTo: .body) private var jarHeight = GoalJarTile.jarHeight
    // The one size of a 3D picture on a card (`RowMetrics.picture`).
    @ScaledMetric(relativeTo: .body) private var picture = RowMetrics.picture
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    /// When the jar came on screen: the slosh dies down from there.
    @State private var shownAt = Date.now
    /// Only on screen does the water move: running on while its tab was hidden, it left the glass
    /// of the bars stuck in the old look after a change of the system's appearance (Simulator
    /// check 2026-11-03), and it spent the battery for nothing.
    @State private var isOnScreen = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous)
        let isFull = goal.isClosed || goal.isReached
        let level = isFull ? 1 : goal.progress > 0 ? max(goal.progress, Self.minimumLevel) : 0
        // The percent sits in the jar's lowest quarter, the water's line rocking a little over
        // it: in ink on the lime once the lime is clear above it.
        let onFill = level >= 0.3
        let still = reduceMotion || isFull || level == 0 || !isOnScreen
        VStack(spacing: Spacing.s) {
            ZStack {
                shape.fill(Palette.surfaceMuted)
                TimelineView(.animation(minimumInterval: 1 / 30, paused: still)) { context in
                    water(level: level, time: context.date.timeIntervalSince(shownAt), still: still)
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
        .onAppear {
            shownAt = .now
            isOnScreen = true
        }
        .onDisappear { isOnScreen = false }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([goal.name, "đã để dành \(goal.saved.vnd) trên \(goal.target.vnd)",
                             goal.isReached ? "đã đủ mục tiêu" : goal.isOverdue ? "quá hạn" : goal.progressText]
            .joined(separator: ", "))
        .accessibilityHint("Xem hũ")
    }

    /// Two waves, a paler one behind out of step with the front, so the surface reads as water
    /// moving rather than a line sliding sideways.
    private func water(level: Double, time: TimeInterval, still: Bool) -> some View {
        let color = goal.isOverdue ? Palette.expenseSoft : Palette.accent
        let height = level >= 1 ? 0 : still ? Self.ripple : Self.ripple + Self.slosh * CGFloat(exp(-time / 1.4))
        // Each jar out of step with the next, so a row of them does not rock as one.
        let offset = Double(goal.name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 628) / 100
        let phase = still ? offset : time + offset
        return ZStack {
            // Paler by day; at night half the lime over the dark jar read as moss (Simulator
            // check 2026-11-03), so it stays near the lime.
            WaterSurface(level: level, height: height * 0.8, phase: phase * 1.7 + .pi * 0.6)
                .fill(color.opacity(colorScheme == .dark ? 0.8 : 0.5))
            WaterSurface(level: level, height: height, phase: phase * 2.3)
                .fill(color)
        }
    }
}

/// Water up to `level` of the rect, its top a gentle wave `height` high moving with `phase`.
private struct WaterSurface: Shape {
    let level: Double
    let height: CGFloat
    let phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard level > 0 else { return path }
        let top = rect.maxY - rect.height * level
        // About one crest and trough across the jar.
        let length = rect.width * 1.1
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for x in stride(from: rect.minX, through: rect.maxX, by: 2) {
            let angle = Double(x / length) * 2 * .pi + phase
            path.addLine(to: CGPoint(x: x, y: top + height * CGFloat(sin(angle))))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: top + height * CGFloat(sin(Double(rect.width / length) * 2 * .pi + phase))))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
