import SwiftUI

/// A part of a main page in Milu: its heading on the page in Section title ("Ví & ngân hàng"),
/// and under it, 12 down, its card or tiles (the grey "Số dư", "Tiến độ" on the right went,
/// user request 2026-11-07). The heading is not numbered and sits outside the card (Milu Sổ ví).
struct PageSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            // The heading alone: the column names "Số dư" and "Tiến độ" beside it are gone (user
            // request 2026-11-07: the rows show what their figures are).
            Text(title)
                .textRole(.heading)
                .foregroundStyle(Palette.label)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// An empty card by its emoji ("👝"): `EmptyStateCard`, the one look of the app's empty cards.
struct EmptyNoteCard: View {
    /// The picture's emoji, drawn from `MiluEmoji2D`.
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        EmptyStateCard(title: title, message: message, picture: IconCatalog.emojiName(emoji))
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
