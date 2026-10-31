import SwiftUI

extension View {
    /// A solid surface with Apple's continuous corners and, when `outlined`, the app's one card
    /// edge: a hairline in `separator`, no shadow (user choice 2026-10-31, design-system pass: on
    /// the near-white page a white card tells itself apart by its edge, as the Iconly mock-ups and
    /// iOS's own grouped lists do; the soft shadow used before let the cards melt into the page).
    func cardSurface(radius: CGFloat = CardCorners.large, color: Color = Palette.surface, outlined: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        // Clip the content (not the edge) so a pressed row's wash follows the card's corners.
        return clipShape(shape)
            .background(color, in: shape)
            .overlay { if outlined { shape.strokeBorder(Palette.separator, lineWidth: 1) } }
    }

    /// The card edge alone, for a surface drawn in another shape (a chat bubble, a round button).
    func cardOutline<S: InsettableShape>(_ shape: S) -> some View {
        overlay { shape.strokeBorder(Palette.separator, lineWidth: 1) }
    }
}

extension View {
    /// A white card holding rows (accounts, transactions, settings): no padding, the rows bring
    /// their own. One helper so every list card looks the same.
    /// Corners 24, as form groups: concentric with the rows' 16 inset and their ~9 icon corners
    /// (user report 2026-10-30: at 28 the corners crowded the first and last rows' icons).
    func listCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: CardCorners.inset, outlined: true)
    }

    /// The app's card: white, 20 inside, large continuous corners and the hairline edge.
    func card(padding: CGFloat = Spacing.card, radius: CGFloat = CardCorners.large) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: radius, outlined: true)
    }
}
