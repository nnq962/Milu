import SwiftUI

extension View {
    /// Solid design color with Apple's continuous corners. Glass belongs to buttons only.
    func cardSurface(radius: CGFloat = CardCorners.large, color: Color = Palette.card, elevated: Bool = false) -> some View {
        // Clip the content (not the shadow) so a pressed row's grey follows the card's corners.
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(color)
                // Shadow only the surface, so text and nested tiles don't acquire their own.
                .softCardShadow(elevated)
        }
    }

    /// The one card shadow of the app, kept gentle (user request 2026-10-30, after a tighter,
    /// darker pair): a barely-there contact line and a wide faint spread, no border.
    func softCardShadow(_ isOn: Bool = true) -> some View {
        shadow(color: .black.opacity(isOn ? 0.025 : 0), radius: 1, x: 0, y: 0.5)
            .shadow(color: .black.opacity(isOn ? 0.04 : 0), radius: 12, x: 0, y: 4)
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
