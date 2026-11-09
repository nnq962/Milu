import SwiftUI

/// The user's initial in a glass circle on the leading side of a tab's bar, opening Cài đặt: on
/// Tổng quan and, since their titles went (user pick "B" 2026-11-04), on Tài khoản. Native: the
/// bar draws its glass, so it takes part in push and pop.
struct ProfileBarButton: View {
    let action: () -> Void

    /// The initial of the name set in Cài đặt; a person glyph until there is one (review
    /// 2026-11-09: every install showed the developer's "Q").
    @AppStorage(StorageKey.profileName) private var name = ""

    var body: some View {
        Button(action: action) {
            // The initial drawn as an image: the bar sets an image in a circle like the bell, but
            // text (even an icon-only label) in a pill. A template, tinted when shown: a colour
            // drawn into it stayed the light one at night, black on the dark glass.
            Group {
                if let initial = ProfileName.initial(of: name) {
                    Image(size: CGSize(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)) { context in
                        // Regular, as the words of iOS's own glass buttons (user request 2026-11-05).
                        context.draw(Text(initial).font(Typography.font(.title3, size: TextRole.heading.size, weight: .regular)),
                                     at: CGPoint(x: RowMetrics.toolbarGlyphFrame / 2, y: RowMetrics.toolbarGlyphFrame / 2))
                    }
                    .renderingMode(.template)
                } else {
                    Image(systemName: "person")
                }
            }
            .foregroundStyle(Palette.deep)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.deep)
        .accessibilityLabel(name.isEmpty ? "Hồ sơ" : "Hồ sơ của \(name)")
        .accessibilityHint("Mở cài đặt")
    }
}

/// The page's title kept for VoiceOver and the back button of a page pushed over it, but not
/// shown in the bar (user pick "B" 2026-11-04): the middle slot holds `leading` pushed to its
/// leading edge. In the middle slot rather than a leading item, as on Tổng quan: a
/// leading item morphed into the back button of a pushed page and showed as a box beside ‹ (user
/// report 2026-11-03).
struct HiddenTitleBar<Leading: View>: ViewModifier {
    let title: String
    /// Circles on the bar's leading and trailing sides, so `leading` starts just after the first.
    let leadingCircles: Int
    let trailingCircles: Int
    /// How wide the trailing items are when they are not all circles ("Hỏi Milu" is a pill);
    /// nil counts `trailingCircles` circles.
    var trailingWidth: CGFloat? = nil
    @ViewBuilder let leading: Leading

    /// The middle slot is centred between the bar's items and as wide as its content. Set to this
    /// width, its leading edge falls 16 after the last leading circle (or at the margin).
    private var width: CGFloat {
        let margin = Spacing.l, circle = ControlHeight.regular, spacer = Spacing.s
        // With nothing on the leading side, the middle slot's room starts at the screen's edge,
        // not the margin (Simulator check 2026-11-04: the tabs sat 8 from the edge).
        let leadingEnd = leadingCircles > 0 ? margin + CGFloat(leadingCircles) * circle : 0
        let trailing = trailingWidth
            ?? CGFloat(trailingCircles) * circle + CGFloat(max(trailingCircles - 1, 0)) * spacer
        let trailingStart = UIScreen.main.bounds.width - margin - trailing
        let start = leadingCircles > 0 ? leadingEnd + Spacing.l : margin
        let centre = (leadingEnd + trailingStart) / 2
        return max(2 * (centre - start), 0)
    }

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .principal) {
                        leading.frame(width: width, alignment: .leading)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .principal) {
                        leading.frame(width: width, alignment: .leading)
                    }
                }
            }
    }
}
