import SwiftUI

/// A tappable row: the row takes a faint wash of the primary colour while pressed and fades back on
/// release, like a cell in an iOS list. The card around the rows clips it to its corners (see
/// `cardSurface`).
struct RowButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Palette.rowPressed : .clear)
            // Instant on press, a short fade on release.
            .animation(configuration.isPressed || reduceMotion ? nil : .easeOut(duration: 0.3), value: configuration.isPressed)
    }
}

/// A whole tappable card or tile (a loan, a savings goal, a shortcut, a calendar day): it dims
/// while pressed as the system's plain buttons do, nothing more (design-system pass 2026-10-31:
/// it shrank and sprang back, against the rule to keep Apple's own press effects).
struct CardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == RowButtonStyle {
    static var row: RowButtonStyle { RowButtonStyle() }
}

extension ButtonStyle where Self == CardButtonStyle {
    static var card: CardButtonStyle { CardButtonStyle() }
}
