import SwiftUI

/// Named text roles: one scale for the whole app, built around a 16pt body (user choice 2026-10-28,
/// after trying 17 and 14). Manrope is wide, so 16 reads close to SF Pro's 17 Body. Each step is
/// 1–4pt from the next so the hierarchy stays clear: 34 · 24 · 20 · 17 · 16 · 14 · 13 · 12 · 11.
/// Buttons take their own roles, one weight over the words around them (`button`, `buttonCompact`).
/// Use `.textRole(_:)` instead of raw sizes. Manrope at the weight named (see Typography).
enum TextRole: CaseIterable, Identifiable {
    /// The screen's lead figure (Tài sản ròng). 34
    case display
    /// The amount being typed in a form: 52, shrinking to 38 and 28 as the figure grows
    /// (`amountEntrySize(for:)`).
    case amountEntry
    /// Big figures inside a card (Đã chi / Đã thu). 24
    case amountLarge
    /// Screen titles in the toolbar. 24
    case pageTitle
    /// Headings of a screen's parts (catalogue sections). 20
    case heading
    /// A main screen's section headings (`SectionHeader` `.section`), titles inside a card, a
    /// sheet or a dialog. Sentence case. 17 SemiBold
    case title
    /// Everything read in a row: row titles, values, body text, typed text, button labels. 16
    case body
    /// Rare emphasis inside body text. 16 SemiBold
    case bodyStrong
    /// The words on a button (`TimiButton`): body's size, one weight over it, so a button reads as
    /// one at a glance (user request 2026-11-03). 16 SemiBold
    case button
    /// Amounts at the end of a row: the title's size and weight, tabular (user 2026-10-31: no
    /// heavier than the name beside it). 16
    case amount
    /// A control beside a section heading (the month of Lịch thu chi): clearly under the 17 title
    /// it sits by, its colour marks it (user choice 2026-10-30: 16 read as large as the title). 14
    case accessory
    /// Row subtitles, notes, errors and descriptions. 13
    case caption
    /// Chips, badges, small labels above figures. 13 SemiBold
    case captionStrong
    /// The words on a compact button (`TimiButton(size: .compact)`): one weight over
    /// `captionStrong`, as `button` is over `body`. 13 Bold
    case buttonCompact
    /// Chart axes and tiny meta. 11
    case footnote
    /// Small capitals naming a group of rows in a sheet or form (`SectionHeader` `.group`).
    /// 12 Bold
    case overline

    var id: Self { self }

    var size: CGFloat {
        switch self {
        case .display: 34
        case .amountEntry: 52
        case .amountLarge, .pageTitle: 24
        case .heading: 20
        case .title: 17
        case .body, .bodyStrong, .button, .amount: 16
        case .accessory: 14
        case .caption, .captionStrong, .buttonCompact: 13
        case .overline: 12
        case .footnote: 11
        }
    }

    var weight: Font.Weight {
        switch self {
        // Titles and figures Bold; the words of the content Medium, one step under the SemiBold
        // they had, which read heavy on the Pro card (user request 2026-10-31); Regular read as
        // faded (2026-10-30). `captionStrong` keeps SemiBold, so it is stronger than `caption`.
        // Buttons one step over the words they sit among (2026-11-03).
        case .display, .amountEntry, .amountLarge, .pageTitle, .heading, .title, .bodyStrong, .overline,
             .buttonCompact: .bold
        case .captionStrong, .button: .semibold
        case .body, .accessory, .caption, .footnote, .amount: .medium
        }
    }

    /// Design line box; nil keeps the font's own metrics. The two big figures keep their box while
    /// they shrink to fit, so a card does not change height with the amount.
    var lineHeight: CGFloat? {
        switch self {
        case .amountEntry: nil
        case .display: 42
        case .amountLarge: 32
        case .pageTitle: 32
        case .heading: 26
        case .title: 24
        case .body, .bodyStrong, .button, .amount: 22
        case .accessory: 20
        case .caption, .captionStrong, .buttonCompact: 18
        case .overline: 16
        case .footnote: 14
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .display, .amountEntry: .largeTitle
        case .amountLarge, .pageTitle: .title2
        case .heading: .title3
        case .title: .headline
        case .body, .bodyStrong, .button, .amount: .body
        case .accessory: .subheadline
        case .caption, .captionStrong, .buttonCompact, .overline: .caption
        case .footnote: .caption2
        }
    }

    var isNumeric: Bool { [.display, .amountEntry, .amountLarge, .amount].contains(self) }

    /// The amount being typed shrinks as it grows: 52 up to seven characters with their dots
    /// ("500.000"), 40 to ten, 32 to thirteen, 26 beyond (user request 2026-10-30: larger than
    /// before, the amount is what the form is for). One step sooner than at first, so the figure
    /// keeps clear of the ⓧ at the row's end (user request 2026-11-01).
    static func amountEntrySize(for count: Int) -> CGFloat {
        switch count {
        case ..<8: 52
        case ..<11: 40
        case ..<14: 32
        default: 26
        }
    }
    var tracking: CGFloat { self == .overline ? 0.6 : 0 }

    var font: Font { Typography.font(textStyle, size: size, weight: weight) }

    /// Vietnamese name shown in the design system screen.
    var name: String {
        switch self {
        case .display: "Số dẫn đầu"
        case .amountEntry: "Số tiền đang nhập"
        case .amountLarge: "Số lớn trong thẻ"
        case .pageTitle: "Tên màn"
        case .heading: "Tiêu đề phần"
        case .title: "Tiêu đề phần · thẻ · sheet"
        case .body: "Nội dung · tên dòng"
        case .bodyStrong: "Nhấn mạnh"
        case .button: "Chữ trên nút"
        case .amount: "Số tiền dòng"
        case .accessory: "Nút cạnh tiêu đề"
        case .caption: "Phụ đề · chú thích"
        case .captionStrong: "Chip · badge"
        case .buttonCompact: "Chữ trên nút gọn"
        case .footnote: "Chữ rất nhỏ"
        case .overline: "Nhãn nhóm trong sheet"
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
