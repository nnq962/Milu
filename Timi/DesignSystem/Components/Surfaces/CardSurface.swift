import SwiftUI

extension View {
    /// A borderless solid surface with continuous corners and an optional light-mode shadow.
    func cardSurface(radius: CGFloat = CardCorners.large, color: Color = Palette.surface, shadowed: Bool = true) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return clipShape(shape)
            .background {
                if shadowed {
                    shape.fill(color).cardShadow()
                } else {
                    shape.fill(color)
                }
            }
    }

    /// Shared light-mode shadow for cards, chat bubbles and round action backgrounds.
    func cardShadow() -> some View {
        modifier(CardShadow())
    }
}

/// No borders in either appearance; dark surfaces separate through their fill alone.
private struct CardShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        content
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

    /// The app's card: 20 inside, large continuous corners and the light-mode shadow.
    func card(padding: CGFloat = Spacing.card, radius: CGFloat = CardCorners.large) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: radius)
    }
}
