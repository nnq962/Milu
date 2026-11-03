import SwiftUI

/// The ground under the head of Tổng quan: one soft light of lime from the top trailing corner
/// over the page colour, gone by the middle of the screen. One colour only: lime and sky mixed
/// into a muddy green-grey, and the ground on every tab made the app read dirty (user report
/// 2026-11-03); the other tabs keep the plain page colour. It stays put as the page scrolls.
struct TabBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Palette.background
                RadialGradient(colors: [Palette.heroGlow.opacity(0.7), Palette.heroGlow.opacity(0)],
                               center: UnitPoint(x: 0.95, y: 0), startRadius: 0,
                               endRadius: proxy.size.height * 0.5)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
