import SwiftUI

/// The head of a tab's page: a sky running on behind the navigation bar, its role small over the
/// page's large title, Milu on the right resting on the edge (`MiluHero`). Tổng quan, Tài khoản
/// and Giao dịch share it, so all are the same height with the words in the same place (user
/// request 2026-11-07); each has its own sky (2026-11-13). The words set the height; the sky and the dog stay anchored to the lower edge,
/// the 240 of the 402-wide drawing.
struct SkyHeader: View {
    let overline: String
    /// The large title; nil on Tổng quan, where the dogs stand in its place (Figma 272:727). Its
    /// room is kept, so the head stays as tall as the other tabs' at every text size.
    var title: String?
    /// Milu's face for how the page is going; nil for none.
    var milu: MiluHero.Look?
    /// What Milu says once when the tab first opens.
    var greeting: String?
    /// Than in Rive in Milu's place, with what the page knows (2026-11-13); the still face stays
    /// for when its file cannot load.
    var rive: (character: MiluRiveCharacter, facts: MiluRiveFacts)?
    var sky: Sky = .garden
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
        /// The three tab skies of 2026-11-13 (output/01-backgrounds, 402 × 352, its top under the
        /// bar), each with its own night picture: Tổng quan's garden with the pink tree, Tài
        /// khoản's lake, Thu chi's paper plane.
        static let garden = Sky(image: "milu-sky-tong-quan", height: 352, top: Palette.gardenSkyTop, ink: Palette.deep)
        static let pond = Sky(image: "milu-sky-tai-khoan", height: 352, top: Palette.pondSkyTop, ink: Palette.deep)
        static let plane = Sky(image: "milu-sky-thu-chi", height: 352, top: Palette.planeSkyTop, ink: Palette.deep)
    }

    /// Bounds of the dog's drawing within the 402 × 240 reference composition.
    struct MascotPlacement {
        let left: CGFloat
        let top: CGFloat
        let width: CGFloat

        /// Milu's 320 × 140 faces (2026-11-13), on the right, its peak clear of the title's 64%,
        /// the head as large and where the 350 × 220 faces had it. Row 135 of 140 sits on the
        /// edge, so the drawing's cut foot goes under it.
        static let milu = MascotPlacement(left: 200, top: 240 - 135 * 245 / 320, width: 245)
        /// The Rive characters' 787 × 400 artboard, its head as large and where the still faces
        /// have it (the nose at 370, 285 of the artboard), its lower edge on the sky's edge.
        static let rive = MascotPlacement(left: 205, top: 240 - 400 * 238 / 786.928, width: 238)
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

    private var usesRive: Bool { rive.map { !$0.character.loadFailed } ?? false }

    /// Sky, sun and clouds, and the dog, behind the words. Above, the sky runs on under the bars;
    /// below, a straight edge meets the page, as Milu draws it (user 2026-11-05: no blur; the soft
    /// bands tried on 2026-11-04 and -05 read rough). Placed by `SkyArtLayout`, not a
    /// `GeometryReader`: reading the reader's size laid the whole page out once more before the
    /// first frame of a tab (Instruments 2026-11-09: about a fifth of opening Giao dịch).
    private var art: some View {
        SkyArtLayout(skyHeight: sky.height, placement: usesRive ? .rive : .milu,
                     referenceWidth: Self.referenceWidth, referenceEdge: Self.referenceEdge,
                     overscroll: Self.overscroll) {
            sky.top
            Image(sky.image)
                .resizable()
            ZStack {
                if usesRive, let rive {
                    MiluRiveHero(facts: rive.facts, character: rive.character)
                } else if let milu {
                    MiluHero(look: milu, greeting: greeting, talks: title == nil)
                }
            }
        }
        // Nothing past the edge: the dog's foot ends where the page begins.
        .mask(alignment: .bottom) { Rectangle().frame(height: 4000) }
        .accessibilityHidden(true)
    }
}

/// The sky's three layers in the head's bounds, scaled from the 402-wide drawing: the sky's colour
/// running on up under the bars, the sky picture standing on the lower edge, and the dog where
/// Figma puts it. Sized by what it is given, so it never asks the page to lay itself out again.
private struct SkyArtLayout: Layout {
    let skyHeight: CGFloat
    let placement: SkyHeader.MascotPlacement
    let referenceWidth: CGFloat
    let referenceEdge: CGFloat
    let overscroll: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 3 else { return }
        let width = bounds.width
        let edge = bounds.height
        let scale = width / referenceWidth
        let sky = skyHeight * scale
        subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.minY - overscroll), anchor: .topLeading,
                          proposal: ProposedViewSize(width: width, height: overscroll + edge))
        subviews[1].place(at: CGPoint(x: bounds.minX, y: bounds.minY + edge - sky), anchor: .topLeading,
                          proposal: ProposedViewSize(width: width, height: sky))
        subviews[2].place(at: CGPoint(x: bounds.minX + placement.left * scale,
                                      y: bounds.minY + edge - (referenceEdge - placement.top) * scale),
                          anchor: .topLeading,
                          proposal: ProposedViewSize(width: placement.width * scale, height: nil))
    }
}
