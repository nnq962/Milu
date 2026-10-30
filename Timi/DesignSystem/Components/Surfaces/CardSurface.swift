import SwiftUI

extension View {
    /// Solid design color with Apple's continuous corners. Glass belongs to buttons only.
    func cardSurface(radius: CGFloat = CardCorners.large, color: Color = Palette.card, elevated: Bool = false) -> some View {
        // Clip the content (not the shadow) so a pressed row's grey follows the card's corners.
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(color)
                // A short shadow close under the card and no border, as in the user's reference
                // (2026-10-30): a tight contact line plus a faint spread. Shadow only the surface,
                // so text and nested tiles don't acquire their own.
                .shadow(color: .black.opacity(elevated ? 0.06 : 0), radius: 1.5, x: 0, y: 1)
                .shadow(color: .black.opacity(elevated ? 0.05 : 0), radius: 6, x: 0, y: 3)
        }
    }
}

extension View {
    /// A white card holding rows (accounts, transactions, settings): no padding, the rows bring
    /// their own. One helper so every list card looks the same.
    func listCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(color: Palette.card, elevated: true)
    }

    /// White Sleek card: p-5, large continuous corners and the soft shadow.
    func sleekCard(padding: CGFloat = Spacing.card, radius: CGFloat = CardCorners.large) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: radius, color: Palette.card, elevated: true)
    }
}
