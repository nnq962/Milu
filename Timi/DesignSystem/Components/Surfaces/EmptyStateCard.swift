import SwiftUI

/// Empty list placeholder: an icon, a title and one line saying what
/// will appear here. No button: adding goes through the page's own + (user choice 2026-10-28).
/// With `picture`, a 3D picture (`Picture3D`) stands in for the line icon, as on the cards of the
/// main tabs (2026-11-03).
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    var picture: String? = nil

    @ScaledMetric(relativeTo: .body) private var pictureSize = RowMetrics.picture

    var body: some View {
        VStack(spacing: 0) {
            if let picture {
                Image(picture)
                    .resizable()
                    .scaledToFit()
                    .frame(width: pictureSize, height: pictureSize)
                    .accessibilityHidden(true)
            } else {
                // Plain glyph in ink, no tile, drawn like the logo atop an account so the two match
                // in size (user choice 2026-10-28).
                RowIcon(name: icon, size: RowMetrics.featureIcon)
            }
            Text(title)
                .textRole(.title)
                .padding(.top, Spacing.m)
            Text(message)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .card(padding: Spacing.leadCard)
        .accessibilityElement(children: .combine)
    }
}
