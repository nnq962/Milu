import SwiftUI

/// A tappable row: the row takes a pale lime wash while pressed and fades back on release, like a
/// cell in an iOS list. The card around the rows clips it to its corners (see `cardSurface`).
struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Palette.rowPressed : .clear)
            // Instant on press, a short fade on release.
            .animation(configuration.isPressed ? nil : .easeOut(duration: 0.3), value: configuration.isPressed)
    }
}

/// A whole tappable card (a loan, a savings goal, a calendar day): it dims and shrinks slightly
/// while pressed, then springs back.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == RowButtonStyle {
    static var row: RowButtonStyle { RowButtonStyle() }
}

extension ButtonStyle where Self == CardButtonStyle {
    static var card: CardButtonStyle { CardButtonStyle() }
}
