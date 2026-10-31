import SwiftUI

extension View {
    /// A solid surface with Apple's continuous corners and, unless `outlined` is false (a tile
    /// inside a card), the app's one card edge: a white rim and a faint shadow (user choice
    /// 2026-10-31, from the soft-UI mock-ups: an off-white card lit at its edge on a pale grey page).
    func cardSurface(radius: CGFloat = CardCorners.large, color: Color = Palette.surface, outlined: Bool = true) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        // Clip the content (not the edge) so a pressed row's wash follows the card's corners.
        return clipShape(shape)
            .background {
                if outlined {
                    shape.fill(color).cardEdge(shape)
                } else {
                    shape.fill(color)
                }
            }
    }

    /// The card edge alone, put on a filled shape (a chat bubble, the circle behind a round
    /// button): by day the soft shadow and a white rim; at night a hairline in `separator`, since
    /// a shadow shows nothing on black and the lighter card already lifts off the page.
    func cardEdge<S: InsettableShape>(_ shape: S) -> some View {
        modifier(CardEdge(shape: shape))
    }
}

/// The one shadow of the app (user choice 2026-10-31): a faint contact line and a wide soft
/// spread, so a card sits just above the page without a dark edge. None in dark mode.
///
/// The soft look of the mock-ups (2026-10-31) is the rim: white on an off-white card, brightest
/// at the top as if lit from above, 1.5 so it reads on a 3x screen. A pure white card
/// showed nothing.
private struct CardEdge<S: InsettableShape>: ViewModifier {
    let shape: S

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        content
            .overlay {
                shape.strokeBorder(
                    LinearGradient(colors: [Palette.rim, Palette.rim.opacity(isDark ? 1 : 0.7)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: isDark ? 1 : 1.5)
            }
            // Lighter than first tried (0.03 r1 y1 + 0.07 r20 y8): the cards stood apart from the
            // page (user 2026-10-31); the rim now does most of the lifting.
            .shadow(color: .black.opacity(isDark ? 0 : 0.02), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 14, x: 0, y: 5)
    }
}

extension View {
    /// A card holding rows (accounts, transactions, settings): no padding, the rows bring
    /// their own. One helper so every list card looks the same.
    /// Corners 24, as form groups: concentric with the rows' 16 inset and their ~9 icon corners
    /// (user report 2026-10-30: at 28 the corners crowded the first and last rows' icons).
    func listCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: CardCorners.inset)
    }

    /// The app's card: 20 inside, large continuous corners and the card edge.
    func card(padding: CGFloat = Spacing.card, radius: CGFloat = CardCorners.large) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: radius)
    }
}
