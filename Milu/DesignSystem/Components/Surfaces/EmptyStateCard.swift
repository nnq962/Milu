import SwiftUI

/// What a part shows before it has anything, or when what was opened is gone: a picture, a title
/// and one line on what will appear here, centred. No button: adding goes through the page's own
/// + (user choice 2026-10-28). One look for every empty card of the app (review 2026-11-07: the
/// Sổ ví card and this one had their own sizes and gaps), Milu's (Figma 120:1650): a Fluent Flat
/// picture 52, no more than 1.6 times, title and line centred.
///
/// `picture` is the emoji's asset (`IconCatalog.emojiName`); `icon`, a line glyph, drawn only
/// where there is no picture (some Cài đặt pages); with a picture it can be left out. Inside a `HeaderCard` it draws no card of its own (`listCard`).
struct EmptyStateCard: View {
    var icon: String? = nil
    let title: String
    let message: String
    var picture: String? = nil

    @ScaledMetric(relativeTo: .body) private var pictureSize = RowMetrics.picture

    var body: some View {
        VStack(spacing: Spacing.s) {
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
            VStack(spacing: Spacing.xxs) {
                Text(title)
                    .textRole(.title)
                    .foregroundStyle(Palette.label)
                Text(message)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.vertical, Spacing.xl)
        .frame(maxWidth: .infinity, minHeight: 150)
        .listCard()
        .accessibilityElement(children: .combine)
    }
}
