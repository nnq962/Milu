import SwiftUI

extension View {
    /// A solid surface with Apple's continuous corners and, unless `outlined` is false (a tile
    /// inside a card), the app's one card edge: a soft shadow with a white rim (user choice
    /// 2026-10-31, after a hairline: the Iconly look, a card lifted a little off the near-white
    /// page, the white rim keeping its edge crisp where the shadow meets it).
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
    /// button): the soft shadow and the white rim.
    func cardEdge<S: InsettableShape>(_ shape: S) -> some View {
        overlay { shape.strokeBorder(Palette.surface, lineWidth: 1) }
            .cardShadow()
    }

    /// The one shadow of the app (user choice 2026-10-31): a faint contact line and a wide soft
    /// spread, so a card sits just above the page without a dark edge.
    func cardShadow() -> some View {
        shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 6)
    }
}

extension View {
    /// A white card holding rows (accounts, transactions, settings): no padding, the rows bring
    /// their own. One helper so every list card looks the same.
    /// Corners 24, as form groups: concentric with the rows' 16 inset and their ~9 icon corners
    /// (user report 2026-10-30: at 28 the corners crowded the first and last rows' icons).
    func listCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: CardCorners.inset)
    }

    /// The app's card: white, 20 inside, large continuous corners and the card edge.
    func card(padding: CGFloat = Spacing.card, radius: CGFloat = CardCorners.large) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: radius)
    }
}
