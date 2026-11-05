import SwiftUI

/// The Accounts sky extends behind the navigation bar. The text determines the header's
/// height, while the sky and mascot stay anchored to its lower edge (Figma 79:1333, 2026-11-05:
/// the 402 × 240 "Nền trời Milu" with its sun or moon and a horizon of clouds, its edge at 240).
struct SkyHeader: View {
    let overline: String
    let title: String
    /// The dog's picture in `MiluArt` ("cun-nau-mac-dinh").
    let mascot: String
    var placement: MascotPlacement = .nauAtRest

    /// Bounds of the exported dog artwork within the 402 × 240 reference composition.
    struct MascotPlacement {
        let left: CGFloat
        let top: CGFloat
        let width: CGFloat

        /// "Nâu giữ ví" on a Sổ ví with wallets (Figma 79:1361).
        static let nauAtRest = MascotPlacement(left: 247, top: 158, width: 166.3)
        /// The curious and happy Figma instances have an inset around the same SVG viewport.
        static let nauGreeting = MascotPlacement(left: 250.2, top: 159.7, width: 162)
    }

    private static let referenceWidth: CGFloat = 402
    private static let referenceEdge: CGFloat = 240
    /// How far the sky's colour runs on above the head, under the bars and a pull-down.
    private static let overscroll: CGFloat = 800
    /// The title's room on the left of the dog's peaks.
    private static let titleShare: CGFloat = 0.64

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: 5) {
                Image(systemName: "pawprint.fill")
                    .font(Typography.font(.caption2, size: 11, weight: .bold))
                    .accessibilityHidden(true)
                // 11, not Milu's 10: the smallest size the HIG reads as legible (review 2026-11-05).
                Text(overline)
                    .textRole(.overline)
                    .font(Typography.font(.caption2, size: 11, weight: .heavy))
                    .tracking(1.6)
            }
            .foregroundStyle(Palette.nauInk)
            Text(title)
                .textRole(.hero)
                .foregroundStyle(Palette.label)
                .fixedSize(horizontal: false, vertical: true)
                .containerRelativeFrame(.horizontal, alignment: .leading) { width, _ in
                    max(width * Self.titleShare, 0)
                }
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, Spacing.page)
        // Figma: the paw line 130 down, the title's foot at 200, the edge at 240. The bar ends near
        // 106 on a 402 screen, so 24 above and 40 below put each where it is drawn.
        .padding(.top, Spacing.xxl)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottom) { art }
        .accessibilityElement(children: .combine)
    }

    /// Sky, sun and clouds, and the dog, behind the words. Above, the sky runs on under the bars;
    /// below, a straight edge meets the page, as Milu draws it (user 2026-11-05: no blur; the soft
    /// bands tried on 2026-11-04 and -05 read rough).
    private var art: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let edge = proxy.size.height
            let scale = width / Self.referenceWidth
            let skyHeight = Self.referenceEdge * scale
            ZStack(alignment: .topLeading) {
                Palette.skyTop
                    .frame(width: width, height: Self.overscroll + edge)
                    .offset(y: -Self.overscroll)
                Image("milu-hero-sky")
                    .resizable()
                    .frame(width: width, height: skyHeight)
                    .offset(y: edge - skyHeight)
                // A new mood fades over the old one, where the change is animated (the first
                // wallet in, the last one out), instead of the picture swapping in a frame.
                Image(mascot)
                    .resizable()
                    .scaledToFit()
                    .frame(width: placement.width * scale)
                    .offset(x: placement.left * scale,
                            y: edge - (Self.referenceEdge - placement.top) * scale)
                    .id(mascot)
                    .transition(.opacity)
            }
            .frame(width: width, height: edge, alignment: .topLeading)
            // Nothing past the edge: the dog's foot ends where the page begins.
            .mask(alignment: .bottom) { Rectangle().frame(height: 4000) }
        }
        .accessibilityHidden(true)
    }
}
