import SwiftUI

/// Named text roles: one scale for the whole app, built around a 16pt body (user choice 2026-10-28,
/// after trying 17 and 14). Manrope is wide, so 16 reads close to SF Pro's 17 Body. Each step is
/// 1–4pt from the next so the hierarchy stays clear: 34 · 24 · 20 · 17 · 16 · 14 · 13 · 12 · 11.
/// The amount being typed (`TimiAmountField`) is the one figure outside it, 52 shrinking as it grows.
/// Use `.textRole(_:)` instead of raw sizes. Manrope at the weight named (see Typography).
enum TextRole: CaseIterable, Identifiable {
    /// The screen's lead figure (Tài sản ròng). 34
    case display
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
    /// Field labels above a field. 16 SemiBold
    case label
    /// Rare emphasis inside body text. 16 SemiBold
    case bodyStrong
    /// Amounts at the end of a row: same size as the title, a touch heavier, tabular. 16 Bold
    case amount
    /// A control beside a section heading (the month of Lịch thu chi): clearly under the 17 title
    /// it sits by, its colour marks it (user choice 2026-10-30: 16 read as large as the title). 14
    case accessory
    /// Row subtitles, notes, errors and descriptions. 13
    case caption
    /// Chips, badges, small labels above figures. 13 SemiBold
    case captionStrong
    /// Chart axes and tiny meta. 11
    case footnote
    /// Small capitals naming a group of rows in a sheet or form (`SectionHeader` `.group`).
    /// 12 Bold
    case overline

    var id: Self { self }

    var size: CGFloat {
        switch self {
        case .display: 34
        case .amountLarge, .pageTitle: 24
        case .heading: 20
        case .title: 17
        case .body, .label, .bodyStrong, .amount: 16
        case .accessory: 14
        case .caption, .captionStrong: 13
        case .overline: 12
        case .footnote: 11
        }
    }

    var weight: Font.Weight {
        switch self {
        // Titles and figures Bold, every other text SemiBold: one step under the Sleek examples'
        // ExtraBold and Bold, which read too heavy (user request 2026-10-30); Regular read as faded.
        case .display, .amountLarge, .pageTitle, .heading, .title, .bodyStrong, .amount, .overline: .bold
        case .body, .label, .accessory, .caption, .captionStrong, .footnote: .semibold
        }
    }

    /// Design line box; nil keeps the font's own metrics (figures that may shrink to fit).
    var lineHeight: CGFloat? {
        switch self {
        case .display, .amountLarge: nil
        case .pageTitle: 32
        case .heading: 26
        case .title: 24
        case .body, .label, .bodyStrong, .amount: 22
        case .accessory: 20
        case .caption, .captionStrong: 18
        case .overline: 16
        case .footnote: 14
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .display: .largeTitle
        case .amountLarge, .pageTitle: .title2
        case .heading: .title3
        case .title: .headline
        case .body, .label, .bodyStrong, .amount: .body
        case .accessory: .subheadline
        case .caption, .captionStrong, .overline: .caption
        case .footnote: .caption2
        }
    }

    var isNumeric: Bool { [.display, .amountLarge, .amount].contains(self) }
    var tracking: CGFloat { self == .overline ? 0.6 : 0 }

    var font: Font { Typography.font(textStyle, size: size, weight: weight) }

    /// Vietnamese name shown in the design system screen.
    var name: String {
        switch self {
        case .display: "Số dẫn đầu"
        case .amountLarge: "Số lớn trong thẻ"
        case .pageTitle: "Tên màn"
        case .heading: "Tiêu đề phần"
        case .title: "Tiêu đề phần · thẻ · sheet"
        case .body: "Nội dung · tên dòng"
        case .label: "Nhãn ô nhập"
        case .bodyStrong: "Nhấn mạnh"
        case .amount: "Số tiền dòng"
        case .accessory: "Nút cạnh tiêu đề"
        case .caption: "Phụ đề · chú thích"
        case .captionStrong: "Chip · badge"
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
