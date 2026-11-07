import SwiftUI

/// A card whose heading sits inside it, at the top, with the heading's control on its right
/// ("Lịch thu chi · Tháng 11 ⌄", "Ví & ngân hàng · Lưu trữ ›"); nothing of a section is left on
/// the page (user request 2026-11-02, after the reference with headings inside the cards).
///
/// The content is what used to sit under a `SectionHeader`: rows with `listCard()`, a padded
/// `card()`, an `EmptyStateCard` or tiles. Inside here those draw no card of their own
/// (`isInHeaderCard`), so call sites keep them as they were.
struct HeaderCard<Trailing: View, Content: View>: View {
    let title: String
    /// Where the heading starts: the rows' 16 by default; the padding of a padded `card()` inside
    /// (`Spacing.card`), so the heading stands on the same edge as what is under it.
    var inset: CGFloat = RowMetrics.horizontal
    var radius: CGFloat = CardCorners.card
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: title) { trailing }
                // `SectionHeader` brings the rows' 16; a padded card's content starts further in.
                .padding(.horizontal, inset - RowMetrics.horizontal)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xs)
            content
                .environment(\.isInHeaderCard, true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: radius)
    }
}

extension HeaderCard where Trailing == EmptyView {
    init(title: String, inset: CGFloat = RowMetrics.horizontal, radius: CGFloat = CardCorners.card,
         @ViewBuilder content: () -> Content) {
        self.init(title: title, inset: inset, radius: radius, trailing: { EmptyView() }, content: content)
    }
}

/// A heading on the page over its card, at the card's edge, 8 above it: the days of Giao dịch and
/// of an account's history, the "Lịch sử" of an account or a goal (user requests 2026-11-07). The
/// same words and size as a `HeaderCard`'s heading, only outside the card.
struct OutsideHeaderSection<Trailing: View, Content: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: title) { trailing }
                // At the card's edge, not the rows' 16 in: as "Ví & ngân hàng".
                .padding(.horizontal, -RowMetrics.horizontal)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension OutsideHeaderSection where Trailing == EmptyView {
    init(title: String, @ViewBuilder content: () -> Content) {
        self.init(title: title, trailing: { EmptyView() }, content: content)
    }
}
