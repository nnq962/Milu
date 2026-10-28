import SwiftUI

/// Empty list placeholder from the Sleek component sheet: an icon, a title and one line saying what
/// will appear here. No button: adding goes through the page's own + (user choice 2026-10-28).
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            // Plain glyph in ink, no tile, drawn like the logo atop an account so the two match in
            // size (user choice 2026-10-28).
            RowIcon(name: icon, size: RowMetrics.featureIcon)
            Text(title)
                .textRole(.title)
                .padding(.top, Spacing.m)
            Text(message)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .sleekCard(padding: 24, radius: CardCorners.extraLarge)
        .accessibilityElement(children: .combine)
    }
}
