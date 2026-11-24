import SwiftUI

/// Named text roles: the Milu type scale (design system 2026-11-04, `milu.tokens.json`), round a
/// 16pt body, in SF Pro Rounded since 2026-11-24 (Nunito before). Each role is one of Milu's text styles: Display, Heading, Section title,
/// Body, Control label, Supporting, Caption, Overline and the three money styles.
/// Use `.textRole(_:)` instead of raw sizes, at the weight named (see Typography).
enum TextRole: CaseIterable, Identifiable {
    /// A page's big title in its sky ("Sổ ví của bạn"). Milu / Display, 34 Black
    case hero
    /// The screen's lead figure (Tài sản ròng). Milu / Money display, 32 ExtraBold
    case display
    /// The amount being typed in a form: 52, shrinking to 38 and 28 as the figure grows
    /// (`amountEntrySize(for:)`).
    case amountEntry
    /// Big figures inside a card (Đã chi / Đã thu). 24 ExtraBold
    case amountLarge
    /// Screen titles. Milu / Heading, 26 Black
    case pageTitle
    /// A main screen's section headings ("Ví & ngân hàng"). Milu / Section title, 21 Black
    case heading
    /// Titles inside a card, a sheet or a dialog ("Chưa có tài khoản"). 17 ExtraBold
    case title
    /// Words read in a row or a paragraph, typed text. Milu / Body, 16 Medium
    case body
    /// A row's name ("Ví tiền mặt"). 16 ExtraBold
    case bodyStrong
    /// The words on a button (`MiluButton`). Milu / Control label, 15 ExtraBold
    case button
    /// Amounts at the end of a row. Milu / Money row, 16 ExtraBold, tabular
    case amount
    /// A control beside a section heading (the month of Lịch thu chi). 14 SemiBold
    case accessory
    /// The name under a tile, on two lines of 17 (a jar's "Du lịch Đà Nẵng"). 14 ExtraBold
    case tileName
    /// Notes, errors and descriptions. Milu / Supporting, 13 SemiBold
    case caption
    /// Chips, badges, small figures. Milu / Money small, 13 Bold
    case captionStrong
    /// The words on a compact button (`MiluButton(size: .compact)`). 13 ExtraBold
    case buttonCompact
    /// Row subtitles, a column's label, chart axes. Milu / Caption, 12 SemiBold
    case footnote
    /// Small capitals naming a group ("NÂU GIỮ VÍ", a group of rows in a sheet). Milu / Overline,
    /// 11 ExtraBold (Milu 10; 11 is the HIG's smallest), spaced
    case overline

    var id: Self { self }

    var size: CGFloat {
        switch self {
        case .hero: 34
        case .display: 32
        case .amountEntry: 52
        case .pageTitle: 26
        case .amountLarge: 24
        case .heading: 21
        case .title: 17
        case .body, .bodyStrong, .amount: 16
        case .button: 15
        case .accessory, .tileName: 14
        case .caption, .captionStrong, .buttonCompact: 13
        case .footnote: 12
        // 11, the smallest the HIG reads as legible (review 2026-11-07: 10 under every form group).
        case .overline: 11
        }
    }

    /// Two steps lighter than Nunito's (Black titles, ExtraBold names and amounts): SF Pro Rounded
    /// at those weights is heavier and wider, and "Thêm tài khoản của bạn" broke onto two lines
    /// (Simulator 2026-11-24); one step lighter still, as the user found the words "hơi đậm" on
    /// the iPhone (2026-11-24).
    var weight: Font.Weight {
        switch self {
        case .hero, .pageTitle, .heading: .bold
        case .display, .amountEntry, .amountLarge, .title, .bodyStrong, .button, .amount,
             .buttonCompact, .overline, .tileName: .semibold
        case .captionStrong: .medium
        case .accessory, .caption, .footnote: .medium
        case .body: .regular
        }
    }

    /// Design line box; nil keeps the font's own metrics. The big figures keep their box while
    /// they shrink to fit, so a card does not change height with the amount.
    var lineHeight: CGFloat? {
        switch self {
        case .amountEntry: nil
        case .hero: 44
        case .display: 42
        case .pageTitle: 34
        case .amountLarge: 32
        case .heading: 28
        case .title, .amount: 23
        case .body: 24
        case .bodyStrong, .button: 21
        case .accessory: 20
        case .tileName: 17
        case .caption, .captionStrong, .buttonCompact: 19
        case .footnote: 17
        case .overline: 16
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .hero, .display, .amountEntry: .largeTitle
        case .pageTitle: .title
        case .amountLarge: .title2
        case .heading: .title3
        case .title, .button: .headline
        case .body, .bodyStrong, .amount: .body
        case .accessory, .caption, .tileName: .subheadline
        case .captionStrong, .buttonCompact, .footnote: .footnote
        case .overline: .caption2
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
    /// Milu's letter spacing: tighter for the big black titles, open for the overline.
    var tracking: CGFloat {
        switch self {
        case .hero: -0.8
        case .display: -0.6
        case .pageTitle: -0.5
        case .heading: -0.4
        case .overline: 1.2
        default: 0
        }
    }

    /// The role's font at `typeSize`; a view takes it from its own text size with `miluFont(_:)`.
    func font(at typeSize: DynamicTypeSize) -> Font { Typography.font(textStyle, size: size, weight: weight, at: typeSize) }

    /// Vietnamese name shown in the design system screen.
    var name: String {
        switch self {
        case .hero: "Tiêu đề trên bầu trời"
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
        case .tileName: "Tên dưới ô"
        case .caption: "Phụ đề · chú thích"
        case .captionStrong: "Chip · badge"
        case .buttonCompact: "Chữ trên nút gọn"
        case .footnote: "Chữ rất nhỏ"
        case .overline: "Nhãn nhóm trong sheet"
        }
    }
}

extension View {
    /// The rounded system font at `size`, scaled with the text size the view is shown at.
    func miluFont(_ style: Font.TextStyle, size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(MiluFont(style: style, size: size, weight: weight))
    }

    /// A role's font alone, without its line box or tracking (the default font of a whole page).
    func miluFont(_ role: TextRole) -> some View {
        miluFont(role.textStyle, size: role.size, weight: role.weight)
    }

    /// Applies a named text role: the role's size and weight, its line box and tracking.
    @ViewBuilder
    func textRole(_ role: TextRole) -> some View {
        let styled = self
            .miluFont(role)
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

/// The font set for the text size in the view's environment, so it follows Dynamic Type and a
/// smaller size set on the view (`shrinksOnlyToFit`), as `Font.custom(_:size:relativeTo:)` did.
private struct MiluFont: ViewModifier {
    let style: Font.TextStyle
    let size: CGFloat
    let weight: Font.Weight
    @Environment(\.dynamicTypeSize) private var typeSize

    func body(content: Content) -> some View {
        content.font(Typography.font(style, size: size, weight: weight, at: typeSize))
    }
}

private struct MonospacedDigitsIf: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled { content.monospacedDigit() } else { content }
    }
}
