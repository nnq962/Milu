import SwiftUI

/// A part of a main page in Milu: its heading on the page in Section title ("Ví & ngân hàng"),
/// what its numbers are on the right in small grey words ("Số dư", "Tiến độ"), and under it, 12
/// down, its card or tiles. The heading is not numbered and sits outside the card (Milu Sổ ví).
struct PageSection<Content: View>: View {
    let title: String
    /// A column's name for what the rows show at their right ("Số dư").
    var note: String? = nil
    @ViewBuilder var content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                Text(title)
                    .textRole(.heading)
                    .foregroundStyle(Palette.label)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.s)
                // Not at the accessibility sizes: beside the heading it broke "Hũ tiết kiệm" over
                // two lines (review 2026-11-06), and the rows say what their figures are anyway.
                if let note, !dynamicTypeSize.isAccessibilitySize {
                    Text(note)
                        .textRole(.footnote)
                        .foregroundStyle(Palette.secondaryLabel)
                        // Read with the rows, which say what each figure is.
                        .accessibilityHidden(true)
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// What a part of a page shows before it has anything: its Fluent Flat picture, a title and a line
/// on what it is for, centred (Milu "Tài khoản / Nội dung trống · Căn giữa", Figma 120:1650,
/// 2026-11-05). Static: neither the card nor its parts take a tap; the + on the bar adds.
struct EmptyNoteCard: View {
    /// The picture's emoji, drawn from `MiluEmoji2D` ("👝").
    let emoji: String
    let title: String
    let message: String

    @ScaledMetric(relativeTo: .body) private var picture: CGFloat = 52

    var body: some View {
        VStack(spacing: 9) {
            Image(IconCatalog.emojiName(emoji))
                .resizable()
                .scaledToFit()
                .frame(width: RowMetrics.capped(picture, base: 52), height: RowMetrics.capped(picture, base: 52))
                .accessibilityHidden(true)
            VStack(spacing: 3) {
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
        .padding(.top, Spacing.xl)
        .padding(.bottom, 21)
        .frame(maxWidth: .infinity, minHeight: 150)
        .cardSurface(radius: CardCorners.card)
        .accessibilityElement(children: .combine)
    }
}

extension AnyTransition {
    /// A part's empty card giving way to what it is waiting for, and back (the first wallet in,
    /// the last one out): the leaving one gone at once, so its words never show through the part
    /// below sliding up or down, the coming one fading in as the page settles (Simulator check
    /// 2026-11-05: "Chưa có tài khoản" faded in place over "Hũ tiết kiệm").
    static var emptySwap: AnyTransition {
        .asymmetric(insertion: .opacity.animation(.easeIn(duration: 0.25).delay(0.1)),
                    removal: .opacity.animation(.easeOut(duration: 0.08)))
    }
}
