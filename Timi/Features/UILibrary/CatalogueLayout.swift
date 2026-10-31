import SwiftUI

/// One part: its heading as on every page of the app (`SectionHeader`, 16 in like the rows in the
/// cards), a line on when to use it, then the sample cards (strict review 2026-10-31: the heading
/// was 20 and 4 in, so it did not line up with anything in the app).
struct PartSection<Content: View>: View {
    let part: DesignSystemView.Part
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SectionHeader(title: part.title)
                Text(part.note)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .padding(.horizontal, RowMetrics.horizontal)
            }
            VStack(alignment: .leading, spacing: Spacing.l) {
                content
            }
        }
        .id(part)
    }
}

/// A card naming the sample inside it in small capitals.
struct SampleCard<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(label)
                .textRole(.overline)
                .foregroundStyle(Palette.secondaryLabel)
            content
        }
        .card()
    }
}

/// The name of a sample over a list card (`listCard`), the way the app heads its lists.
struct SampleList<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: label, style: .group)
            VStack(spacing: 0) { content }
                .listCard()
        }
    }
}
