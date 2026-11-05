import SwiftUI

/// Multiples of 4.
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24

    /// Left/right margin of every screen.
    static let page: CGFloat = 20
    /// Between the parts of a screen.
    static let section: CGFloat = 28
    /// From a section heading to the card under it, on every screen and in forms.
    static let headerGap: CGFloat = 8
    /// Inside a regular card.
    static let card: CGFloat = 20
    /// Inside a card that leads a page or stands alone (an empty state).
    static let leadCard: CGFloat = 24

    static let scale: [(name: String, value: CGFloat)] = [
        ("xxs", xxs), ("xs", xs), ("s", s), ("m", m), ("l", l), ("xl", xl), ("xxl", xxl),
    ]
}

/// The app's icon sizes, one per role, used everywhere (user request 2026-11-05: "đừng mỗi chỗ một
/// size"). Which family goes where: Fluent Flat emoji for the user's things (categories,
/// wallets, goals, loans, empty states), Hugeicons line glyphs for functions and labels
/// (Settings, form rows, in-page buttons), SF Symbols for bar buttons, chevrons and system marks.
enum IconSize {
    /// An SF Symbol in a bar's glass button (+, search, bell, pencil, history) and the selection
    /// tick: Regular (the tick Semibold), as iOS's own.
    static let bar: CGFloat = 17
    /// The frame it sits in, so every glass circle is the same.
    static let barFrame: CGFloat = 28
    /// A row's picture (emoji, bank logo, avatar, goal picture) and the column every row's icon
    /// sits in: lists, sheets and forms alike.
    static let rowArtwork: CGFloat = 32
    /// A row's line glyph (Settings, form labels), centred in that 32 column.
    static let rowGlyph: CGFloat = 22
    /// A picture on a card, an empty state or a detail page's header.
    static let cardArtwork: CGFloat = 52
    /// A picture beside a row's value, on the right ("💼 Đồng nghiệp", "🏦 Techcombank"): the
    /// line of words it sits in, not the row's column.
    static let valueArtwork: CGFloat = 24
    /// A glyph inside a control beside or instead of words (a button's icon, send, mic, the
    /// search field's lens, filter): a step under the row glyph, as iOS's own buttons.
    static let control: CGFloat = 20
    /// A glyph inside a line of text (↑, a lock, a warning).
    static let inline: CGFloat = 14
    /// The › at a row's end: SF, Semibold, tertiary.
    static let chevron: CGFloat = 13
}

/// Every row on a card (form, list, option sheet) shares these, so rows line up everywhere:
/// 16 side margin, at least 10 above and below, the 32 icon column, 14 between icon and text. Every one-line row is
/// exactly 52 whatever sits on the right (text, 30pt pill, the 31pt native switch); a row with a
/// 13pt subtitle is ~62. Apply the min height after the padding, or it never takes effect.
enum RowMetrics {
    static let horizontal: CGFloat = 16
    static let vertical: CGFloat = 10
    static let gap: CGFloat = 14
    static let minHeight: CGFloat = 52
    /// Icon without a tile: glyph and the column it sits in (`IconSize`).
    static let iconGlyph: CGFloat = IconSize.rowGlyph
    static let iconColumn: CGFloat = IconSize.rowArtwork
    /// Title to subtitle.
    static let lineGap: CGFloat = 2
    /// An icon or logo standing alone, the same everywhere: a screen's header (account, credit card)
    /// and an empty state.
    static let featureIcon: CGFloat = IconSize.cardArtwork
    /// A choice in the full icon sheet (the form's quick row uses `featureIcon`).
    static let iconChoice: CGFloat = 52
    /// A Fluent Emoji Flat picture and its pale tile, one size on every card of Tổng quan: an
    /// insight, the first step, Timi Pro (user request 2026-11-02: one size for all).
    static let picture: CGFloat = IconSize.cardArtwork
    /// A glyph in a toolbar's glass circle (+ on Tài khoản, the edit pencil), and the frame it sits in.
    static let toolbarGlyph: CGFloat = IconSize.bar
    static let toolbarGlyphFrame: CGFloat = IconSize.barFrame
    /// The › at the end of a row (`RowChevron`), on every list and form.
    static let chevron: CGFloat = 16
    /// The › or ⌄ after a link in words ("Lưu trữ (2) ›", "Tháng 10 ⌄", "Tìm hiểu thêm ›"), and
    /// the × of a chip.
    static let linkChevron: CGFloat = 12
    /// A glyph before a line of text: an ↑, a lock, the warning before a limit line.
    static let inlineGlyph: CGFloat = IconSize.inline
    /// A bank or wallet logo in a list of accounts.
    static let listLogo: CGFloat = IconSize.rowArtwork
    /// How far a row's icon, logo or avatar grows with the text: at most this many times its size.
    /// Growing freely, a 32 avatar reached ~90 at the largest sizes and took a third of the row,
    /// so names broke a word to a line (review 2026-11-03).
    static let leadingMaxScale: CGFloat = 1.6

    /// A row's leading size grown with the text, but no further than `leadingMaxScale`.
    static func capped(_ scaled: CGFloat, base: CGFloat) -> CGFloat {
        min(scaled, base * leadingMaxScale)
    }
    /// The line of a progress ring (`ProgressRing`).
    static let ringStroke: CGFloat = 3
    /// A legend dot beside a chart or a split bar (`LegendDot`).
    static let legendDot: CGFloat = 8
}

/// Heights of tappable things; nothing smaller than 44 unless it is a chip inside content.
enum ControlHeight {
    static let large: CGFloat = 56
    static let regular: CGFloat = 44
    static let small: CGFloat = 36
}

/// Corner radii. Every card one radius, 28 (UI review 2026-10-30: cards were 22, 26 and 32 side
/// by side); tiles inside a card round less (20), so the inner corner never bulges past the outer.
enum CardCorners {
    /// Cards on a page with 20 inside (overview cards, totals).
    static let large: CGFloat = 28
    /// A form group, a list of rows (`listCard`), or the card in a short sheet.
    static let inset: CGFloat = 24
    /// Tiles inside a card (Số dư / Cho vay / Nợ, Tiền vào / Tiền ra), chat cards.
    static let flow: CGFloat = 20
    /// Text fields and inline pickers, 44pt tall.
    static let field: CGFloat = 12
    static let calendarDay: CGFloat = 8
}
