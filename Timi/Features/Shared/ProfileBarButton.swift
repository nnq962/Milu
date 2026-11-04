import SwiftUI

/// The user's initial in a glass circle on the leading side of a tab's bar, opening Cài đặt: on
/// Tổng quan and, since their titles went (user pick "B" 2026-11-04), on Tài khoản. Native: the
/// bar draws its glass, so it takes part in push and pop.
struct ProfileBarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // The initial drawn as an image: the bar sets an image in a circle like the bell, but
            // text (even an icon-only label) in a pill. A template, tinted when shown: a colour
            // drawn into it stayed the light one at night, black on the dark glass.
            Image(size: CGSize(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)) { context in
                context.draw(Text("Q").font(TextRole.heading.font),
                             at: CGPoint(x: RowMetrics.toolbarGlyphFrame / 2, y: RowMetrics.toolbarGlyphFrame / 2))
            }
            .renderingMode(.template)
            .foregroundStyle(Palette.primary)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Hồ sơ của Quyet")
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
    @ViewBuilder let leading: Leading

    /// The middle slot is centred between the bar's items and as wide as its content. Set to this
    /// width, its leading edge falls 16 after the last leading circle (or at the margin).
    private var width: CGFloat {
        let margin = Spacing.l, circle = ControlHeight.regular, spacer = Spacing.s
        // With nothing on the leading side, the middle slot's room starts at the screen's edge,
        // not the margin (Simulator check 2026-11-04: the tabs sat 8 from the edge).
        let leadingEnd = leadingCircles > 0 ? margin + CGFloat(leadingCircles) * circle : 0
        let trailingStart = UIScreen.main.bounds.width - margin
            - CGFloat(trailingCircles) * circle - CGFloat(max(trailingCircles - 1, 0)) * spacer
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
