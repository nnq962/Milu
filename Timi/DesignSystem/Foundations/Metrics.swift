import SwiftUI

/// Multiples of 4 (web: same scale). Page margin and section gap keep the Sleek iOS values.
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32

    /// Left/right margin of every screen.
    static let page: CGFloat = 20
    /// Between the parts of a screen.
    static let section: CGFloat = 20
    /// Inside a regular card.
    static let card: CGFloat = 20

    static let scale: [(name: String, value: CGFloat)] = [
        ("xxs", xxs), ("xs", xs), ("s", s), ("m", m), ("l", l), ("xl", xl), ("xxl", xxl), ("xxxl", xxxl),
    ]
}

/// Every row on a white card (form, list, option sheet) shares these, so rows line up everywhere:
/// 16 side margin, at least 10 above and below, 14 between icon and text. Every one-line row is
/// exactly 52 whatever sits on the right (text, 30pt pill, the 31pt native switch); a row with a
/// 12pt subtitle is ~58. Apply the min height after the padding, or it never takes effect.
enum RowMetrics {
    static let horizontal: CGFloat = 16
    static let vertical: CGFloat = 10
    static let gap: CGFloat = 14
    static let minHeight: CGFloat = 52
    /// Icon without a tile: glyph and the column it sits in.
    static let iconGlyph: CGFloat = 20
    static let iconColumn: CGFloat = 24
    /// Title to subtitle.
    static let lineGap: CGFloat = 2
    /// Where a divider starts when rows have icons: margin + icon column + gap.
    static let dividerInset: CGFloat = horizontal + iconColumn + gap
}

/// Heights of tappable things; nothing smaller than 44 unless it is a chip inside content.
enum ControlHeight {
    static let large: CGFloat = 56
    static let regular: CGFloat = 44
    static let small: CGFloat = 36
    static let field: CGFloat = 44
    static let row: CGFloat = 52
    static let floating: CGFloat = 56
}

/// Corner radii, closer to Apple's own apps than the web's (user request 2026-10-28): cards 22,
/// like a widget; smaller things round less, so every corner looks in proportion.
enum CardCorners {
    /// Cards and lists on a page, savings goal tiles, overview cards.
    static let large: CGFloat = 22
    /// The page's lead card (Tổng số dư, the month summary on Giao dịch).
    static let extraLarge: CGFloat = 26
    /// A form group or the card in a short sheet.
    static let inset: CGFloat = 22
    /// Tiles inside a card (Số dư / Cho vay / Nợ, Tiền vào / Tiền ra), chat cards.
    static let flow: CGFloat = 16
    /// Text fields and inline pickers, 44pt tall.
    static let field: CGFloat = 12
    static let icon: CGFloat = 10
    static let calendarDay: CGFloat = 8
    /// Top corners of a custom sheet; system sheets keep Apple's own.
    static let sheet: CGFloat = 32
}
