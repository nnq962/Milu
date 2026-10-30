import SwiftUI

/// The lead card of Tổng quan: solid teal with a neutral shadow, like every other card (UI
/// review 2026-10-30: the teal-tinted glow read as a smear under the card).
struct HeroBackground: View {
    var radius: CGFloat = CardCorners.large

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Palette.heroCard)
            .shadow(color: .black.opacity(0.10), radius: 12, y: 8)
    }
}
