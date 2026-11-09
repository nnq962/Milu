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

/// A whole tappable card or tile (a loan, a savings goal, a calendar day): `LivelyPress`.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(LivelyPress(isPressed: configuration.isPressed))
    }
}

/// The press of every card and flat button (user request 2026-10-31: a flash of the fill read
/// flat): it sinks a little under the finger, dims a touch and gives a light tap, then springs
/// back with a small bounce as it is let go. With Reduce Motion it only dims. Rows keep iOS's own
/// wash (`RowButtonStyle`), as a list does.
struct LivelyPress: ViewModifier {
    let isPressed: Bool

    /// How far it sinks: a little more for a small control than for a card.
    var scale: CGFloat = 0.97

    /// The shortest time it stays down. A quick tap inside a scroll view is pressed and let go in
    /// the same moment (iOS waits to see whether the touch scrolls), so following `isPressed` alone
    /// showed nothing but the haptic (user report 2026-10-31).
    private static let minimumDown: Duration = .milliseconds(60)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// What is drawn: down from the touch, up again no sooner than `minimumDown` after it.
    @State private var isDown = false
    @State private var pressedAt = ContinuousClock.now

    func body(content: Content) -> some View {
        content
            .scaleEffect(isDown && !reduceMotion ? scale : 1)
            .opacity(isDown ? 0.85 : 1)
            .onChange(of: isPressed) { _, pressed in
                if pressed {
                    pressedAt = .now
                    withAnimation(reduceMotion ? .easeOut(duration: 0.08) : .spring(duration: 0.1)) { isDown = true }
                } else {
                    let wait = Self.minimumDown - (ContinuousClock.now - pressedAt)
                    Task { @MainActor in
                        if wait > .zero { try? await Task.sleep(for: wait) }
                        withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .spring(duration: 0.28, bounce: 0.35)) {
                            isDown = false
                        }
                    }
                }
            }
            .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: isPressed) { _, new in new }
    }
}

extension ButtonStyle where Self == RowButtonStyle {
    static var row: RowButtonStyle { RowButtonStyle() }
}

extension ButtonStyle where Self == CardButtonStyle {
    static var card: CardButtonStyle { CardButtonStyle() }
}
