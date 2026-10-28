import SwiftUI

extension View {
    /// Solid design color with Apple's continuous corners. Glass belongs to buttons only.
    func cardSurface(radius: CGFloat = CardCorners.large, color: Color = .white, elevated: Bool = false) -> some View {
        background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(color)
                // Sleek: 0 2px 16px rgba(28,36,48,.05). Shadow only the surface,
                // so text and nested tiles don't acquire their own shadows.
                .shadow(color: Color(red: 28/255, green: 36/255, blue: 48/255).opacity(elevated ? 0.05 : 0),
                        radius: 8, x: 0, y: 2)
        }
    }
}

extension View {
    /// White Sleek card: p-5, large continuous corners and the soft shadow.
    func sleekCard(padding: CGFloat = 20, radius: CGFloat = CardCorners.large) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: radius, color: Palette.card, elevated: true)
    }
}
