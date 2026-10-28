import SwiftUI

/// Named text roles: one scale for the whole app, built around a 16pt body (user choice 2026-10-28,
/// after trying 17 and 14). Manrope is wide, so 16 reads close to SF Pro's 17 Body. Each step is
/// 1–4pt from the next so the hierarchy stays clear: 34 · 24 · 20 · 17 · 16 · 13 · 12 · 11.
/// Use `.textRole(_:)` instead of raw sizes. Manrope renders one weight heavier (see Typography).
enum TextRole: CaseIterable, Identifiable {
    /// The screen's lead figure (Tổng tài sản). 34
    case display
    /// The amount being typed in a form. 40
    case hero
    /// Big figures inside a card (Đã chi / Đã thu). 24
    case amountLarge
    /// Screen titles in the toolbar. 24
    case pageTitle
    /// Headings of a screen's parts (catalogue sections). 20
    case heading
    /// Card, section, sheet and dialog titles. 17 SemiBold
    case title
    /// Everything read in a row: row titles, values, body text, typed text, button labels. 16
    case body
    /// Field labels above a field. 16 Medium
    case label
    /// Rare emphasis inside body text. 16 SemiBold
    case bodyStrong
    /// Amounts at the end of a row: same size as the title, a touch heavier, tabular. 16 Medium
    case amount
    /// Row subtitles, notes, errors and descriptions. 13
    case caption
    /// Chips, badges, small labels above figures. 13 Medium
    case captionStrong
    /// Chart axes and tiny meta. 11
    case footnote
    /// Small capitals naming a group of rows. 12 Medium
    case overline
    /// Text typed into a field: 16, same as the body it sits beside.
    case input

    var id: Self { self }

    var size: CGFloat {
        switch self {
        case .display: 34
        case .hero: 40
        case .amountLarge, .pageTitle: 24
        case .heading: 20
        case .title: 17
        case .body, .label, .bodyStrong, .amount, .input: 16
        case .caption, .captionStrong: 13
        case .overline: 12
        case .footnote: 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display, .amountLarge: .heavy
        case .hero: .bold
        case .pageTitle, .heading, .title, .bodyStrong: .semibold
        case .label, .amount, .captionStrong, .overline: .medium
        case .body, .caption, .footnote, .input: .regular
        }
    }

    /// Design line box; nil keeps the font's own metrics (figures that may shrink to fit).
    var lineHeight: CGFloat? {
        switch self {
        case .display, .hero, .amountLarge, .input: nil
        case .pageTitle: 32
        case .heading: 26
        case .title: 24
        case .body, .label, .bodyStrong, .amount: 22
        case .caption, .captionStrong: 18
        case .overline: 16
        case .footnote: 14
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .display, .hero: .largeTitle
        case .amountLarge, .pageTitle: .title2
        case .heading: .title3
        case .title: .headline
        case .body, .label, .bodyStrong, .amount, .input: .body
        case .caption, .captionStrong, .overline: .caption
        case .footnote: .caption2
        }
    }

    var isNumeric: Bool { [.display, .hero, .amountLarge, .amount].contains(self) }
    var tracking: CGFloat { self == .overline ? 0.6 : 0 }

    var font: Font { Typography.font(textStyle, size: size, weight: weight) }

    /// Vietnamese name shown in the design system screen.
    var name: String {
        switch self {
        case .display: "Số dẫn đầu"
        case .hero: "Số tiền đang nhập"
        case .amountLarge: "Số lớn trong thẻ"
        case .pageTitle: "Tên màn"
        case .heading: "Tiêu đề phần"
        case .title: "Tiêu đề thẻ · nút"
        case .body: "Nội dung · tên dòng"
        case .label: "Nhãn ô nhập"
        case .bodyStrong: "Nhấn mạnh"
        case .amount: "Số tiền dòng"
        case .caption: "Phụ đề · chú thích"
        case .captionStrong: "Chip · badge"
        case .footnote: "Chữ rất nhỏ"
        case .overline: "Nhãn nhóm"
        case .input: "Chữ trong ô"
        }
    }
}

extension View {
    /// Applies a named text role: Manrope at the role's size and weight, its line box and tracking.
    @ViewBuilder
    func textRole(_ role: TextRole) -> some View {
        let styled = self
            .font(role.font)
            .tracking(role.tracking)
            .textCase(role == .overline ? .uppercase : nil)
            .modifier(MonospacedDigitsIf(enabled: role.isNumeric))
        if let lineHeight = role.lineHeight {
            styled.designLineHeight(lineHeight, relativeTo: role.textStyle)
        } else {
            styled
        }
    }
}

private struct MonospacedDigitsIf: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled { content.monospacedDigit() } else { content }
    }
}

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
