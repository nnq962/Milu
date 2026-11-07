import SwiftUI

/// The head of a tab's page: a dog's sky running on behind the navigation bar, its role small
/// over the page's large title, the dog on the right resting on the edge. Tài khoản (Nâu, Figma
/// 79:1333), Giao dịch (Than, Figma 317:6594) and Tổng quan (the three dogs' hill, Figma 272:727)
/// share it, so all are the same height with the words in the same place (user request
/// 2026-11-07). The words set the height; the sky and the dog stay anchored to the lower edge,
/// the 240 of the 402-wide drawing.
struct SkyHeader: View {
    let overline: String
    /// The large title; nil on Tổng quan, where the dogs stand in its place (Figma 272:727). Its
    /// room is kept, so the head stays as tall as the other tabs' at every text size.
    var title: String?
    /// The dog's picture in `MiluArt` ("cun-nau-mac-dinh"); nil when the sky is a scene that
    /// already has its dogs (`Sky.hill`).
    var mascot: String?
    var placement: MascotPlacement = .nauAtRest
    var sky: Sky = .nau
    /// The 🐾 before the role; Tổng quan's family line has none (Figma 272:727).
    var showsPaw = true

    /// Whose sky: its picture (anchored by its foot, as wide as the screen), the colour it runs on
    /// in above, and the colour of the role over the title.
    struct Sky {
        let image: String
        /// The picture's height at 402 wide.
        let height: CGFloat
        let top: Color
        let ink: Color

        /// Nâu's: sun or moon and a horizon of clouds (402 × 240).
        static let nau = Sky(image: "milu-hero-sky", height: 240, top: Palette.skyTop, ink: Palette.nauInk)
        /// Than's: clouds and a paper plane (402 × 256, its top under the bar).
        static let than = Sky(image: "than-hero-sky", height: 256, top: Palette.thanSkyTop, ink: Palette.deep)
        /// Tổng quan's: the hill with Vàng, Than and Nâu peeking over it (402 × 352, the dogs
        /// drawn in, its top under the bar).
        static let hill = Sky(image: "overview-hero-scene", height: 352, top: Palette.hillSkyTop, ink: Palette.deep)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Bounds of the exported dog artwork within the 402 × 240 reference composition.
    struct MascotPlacement {
        let left: CGFloat
        let top: CGFloat
        let width: CGFloat

        /// "Nâu giữ ví" on a Sổ ví with wallets (Figma 79:1361).
        static let nauAtRest = MascotPlacement(left: 247, top: 158, width: 166.3)
        /// The curious and happy Figma instances have an inset around the same SVG viewport.
        static let nauGreeting = MascotPlacement(left: 250.2, top: 159.7, width: 162)
        /// Than with its tongue out on Giao dịch (Figma 320:3768, "Than ghi chép · Hero đồng bộ"),
        /// in "cun-than-dau-trang", whose mountain runs on past the edge.
        static let thanAtRest = MascotPlacement(left: 231.6, top: 158, width: 196.7)
    }

    private static let referenceWidth: CGFloat = 402
    private static let referenceEdge: CGFloat = 240
    /// How far the sky's colour runs on above the head, under the bars and a pull-down.
    private static let overscroll: CGFloat = 800
    /// The title's room on the left of the dog's peaks.
    private static let titleShare: CGFloat = 0.64
    /// Figma's paw line: the paw 5 before the words, 11 Heavy spaced 1.6.
    private static let overlineGap: CGFloat = 5
    private static let overlineSize: CGFloat = 11
    private static let overlineTracking: CGFloat = 1.6
    /// Room under the title down to the sky's edge (Figma: the title's foot 200, the edge 240).
    private static let bottomRoom: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Self.overlineGap) {
                if showsPaw {
                    Image(systemName: "pawprint.fill")
                        .font(Typography.font(.caption2, size: Self.overlineSize, weight: .bold))
                        .accessibilityHidden(true)
                }
                // 11, not Milu's 10: the smallest size the HIG reads as legible (review 2026-11-05).
                Text(overline)
                    .textRole(.overline)
                    .font(Typography.font(.caption2, size: Self.overlineSize, weight: .heavy))
                    .tracking(Self.overlineTracking)
            }
            .foregroundStyle(sky.ink)
            if let title {
                Text(title)
                    .textRole(.hero)
                    .foregroundStyle(Palette.label)
                    .fixedSize(horizontal: false, vertical: true)
                    .containerRelativeFrame(.horizontal, alignment: .leading) { width, _ in
                        max(width * Self.titleShare, 0)
                    }
                    .accessibilityAddTraits(.isHeader)
            } else {
                // One line of the title's room, unseen: the same height as the other tabs' heads.
                Text(" ")
                    .textRole(.hero)
                    .hidden()
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Spacing.page)
        // Figma: the paw line 130 down, the title's foot at 200, the edge at 240. The bar ends near
        // 106 on a 402 screen, so 24 above and 40 below put each where it is drawn.
        .padding(.top, Spacing.xxl)
        .padding(.bottom, Self.bottomRoom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottom) { art }
        .accessibilityElement(children: .combine)
    }

    /// In: grows from the feet as it fades in. Out: gone in a blink, so the two dogs barely overlap.
    /// With Reduce Motion, a fade only.
    private var mascotSwap: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.82, anchor: .bottom)),
            removal: .opacity.animation(.easeOut(duration: 0.12)))
    }

    /// Sky, sun and clouds, and the dog, behind the words. Above, the sky runs on under the bars;
    /// below, a straight edge meets the page, as Milu draws it (user 2026-11-05: no blur; the soft
    /// bands tried on 2026-11-04 and -05 read rough).
    private var art: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let edge = proxy.size.height
            let scale = width / Self.referenceWidth
            let skyHeight = sky.height * scale
            ZStack(alignment: .topLeading) {
                sky.top
                    .frame(width: width, height: Self.overscroll + edge)
                    .offset(y: -Self.overscroll)
                Image(sky.image)
                    .resizable()
                    .frame(width: width, height: skyHeight)
                    .offset(y: edge - skyHeight)
                // A new mood hops in from the dog's feet while the old one fades out quickly
                // (user 2026-11-05: a plain cross-fade looked rough — halfway, both pictures were
                // half see-through and the sky showed through the dog). The spring is set here, so
                // the change looks the same whichever action changed the mood.
                ZStack {
                    if let mascot {
                        Image(mascot)
                            .resizable()
                            .scaledToFit()
                            .id(mascot)
                            .transition(mascotSwap)
                    }
                }
                .frame(width: placement.width * scale)
                .offset(x: placement.left * scale,
                        y: edge - (Self.referenceEdge - placement.top) * scale)
                .animation(reduceMotion ? .easeInOut(duration: 0.25) : .spring(duration: 0.5, bounce: 0.35),
                           value: mascot)
            }
            .frame(width: width, height: edge, alignment: .topLeading)
            // Nothing past the edge: the dog's foot ends where the page begins.
            .mask(alignment: .bottom) { Rectangle().frame(height: 4000) }
        }
        .accessibilityHidden(true)
    }
}
