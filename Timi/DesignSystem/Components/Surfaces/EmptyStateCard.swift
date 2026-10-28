import SwiftUI

/// Empty list placeholder from the Sleek component sheet.
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            SolarIcon(icon, size: 26)
                .foregroundStyle(Palette.secondary)
                .frame(width: 56, height: 56)
                .background(Palette.muted, in: Circle())
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
