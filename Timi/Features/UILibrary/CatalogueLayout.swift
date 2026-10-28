import SwiftUI

/// One part: title, when to use it, then sample cards.
struct PartSection<Content: View>: View {
    let part: DesignSystemView.Part
    @ViewBuilder var content: Content

    var body: some View {
        // Spacing: heading → note 4, header → first sample 16, samples 16 apart, parts 32 apart.
        VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(part.title)
                    .textRole(.heading)
                Text(part.note)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
            .padding(.horizontal, Spacing.xs)
            content
        }
        .id(part)
    }
}

/// A white card naming the sample inside it in small capitals.
struct SampleCard<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(label)
                .textRole(.overline)
                .foregroundStyle(Palette.secondaryText)
            content
        }
        .sleekCard()
    }
}
