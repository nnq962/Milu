import SwiftUI

/// The lead card of a screen: a small title, the big amount, an optional icon or logo on the
/// right, then whatever the screen adds below (a line, a bar, buttons). Used by "Tổng số dư", an
/// account's and a goal's screen, so they all read the same (user choice 2026-10-29: left-aligned).
struct SummaryCard<Content: View>: View {
    let title: String
    let amount: Double
    var icon: String? = nil
    var tone: MoneyText.Tone = .balance
    /// A Fluent Flat picture in the icon's place (a goal, 2026-11-03).
    var picture: String? = nil
    @ViewBuilder var content: Content

    @ScaledMetric(relativeTo: .body) private var pictureSize = RowMetrics.picture

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryLabel)
                    MoneyText(amount: amount, size: .display, tone: tone)
                }
                Spacer(minLength: 0)
                if let picture {
                    Image(picture)
                        .resizable()
                        .scaledToFit()
                        .frame(width: RowMetrics.capped(pictureSize, base: RowMetrics.picture),
                               height: RowMetrics.capped(pictureSize, base: RowMetrics.picture))
                        .accessibilityHidden(true)
                } else if let icon {
                    RowIcon(name: icon, size: RowMetrics.featureIcon)
                }
            }
            .accessibilityElement(children: .combine)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

extension SummaryCard where Content == EmptyView {
    init(title: String, amount: Double, icon: String? = nil, tone: MoneyText.Tone = .balance) {
        self.init(title: title, amount: amount, icon: icon, tone: tone) { EmptyView() }
    }
}
