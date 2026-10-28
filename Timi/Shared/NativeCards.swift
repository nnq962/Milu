import SwiftUI

/// Optical mapping of Sleek's CSS squircle tokens to Apple's continuous curves.
/// Values are native points, not the CSS radius multiplied by 2.5.
enum CardCorners {
    static let large: CGFloat = 32
    /// Sleek rounded-3xl (32px CSS × 2.5 squircle); same optical ratio as `large` for rounded-2xl.
    static let extraLarge: CGFloat = 40
    static let inset: CGFloat = 28
    /// Short income/expense tiles: fitted to the supplied @2x reference silhouette.
    static let flow: CGFloat = 18
    /// Text fields and inline pickers, 44pt tall (web: 12px on a 44px field).
    static let field: CGFloat = 14
    static let icon: CGFloat = 12
    static let calendarDay: CGFloat = 8
    /// Top corners of a sheet (web: 28–32px).
    static let sheet: CGFloat = 32
}

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
