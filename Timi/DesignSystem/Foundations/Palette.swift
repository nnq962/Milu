import SwiftUI
import UIKit

/// Design tokens shared by every screen, named by what they do (as iOS's own `label`,
/// `separator`, `systemFill`), not by their hue, so a change of colours changes no names. Every
/// token here has a caller.
///
/// The Milu palette, "Một bầu trời, hai giao diện" (design system 2026-11-04,
/// `docs/design/milu/milu-design-system/milu.tokens.json`): a pale sky-blue page with white cards
/// by day, blue-black at night; ink words, a deep blue for actions, and sky, honey and apricot for
/// the brand's art. Each token below names the Milu token it takes, light and dark as given there.
///
/// The one copy outside this file is `AccentColor` in Assets (system alerts), set to `primary`.
enum Palette {
    // MARK: Surfaces

    /// Surface/Canvas: the page and every scrolling area.
    static let background = dynamic(0xF4F9FB, dark: 0x101D25)
    /// Surface/Card: cards, fields and whole sheets.
    static let surface = dynamic(0xFFFFFF, dark: 0x192B35)
    /// Brand/Mist: a quiet block on a card or page (an icon's tile, a light hint, a secondary
    /// button).
    static let surfaceMuted = dynamic(0xE8F5FB, dark: 0x1E3947)
    /// Border/Quiet: hairlines between rows, the outline of a card, a progress bar's track.
    static let separator = dynamic(0xD8E5EB, dark: 0x344C58)
    /// Border/Control: the outline of a control.
    static let controlBorder = dynamic(0x778C95, dark: 0x8198A6)

    // MARK: Words

    /// Content/Primary: titles, balances and the main words.
    static let label = dynamic(0x142E43, dark: 0xF0F6F9)
    /// Content/Secondary: providers, descriptions and dates.
    static let secondaryLabel = dynamic(0x4C687A, dark: 0xB8CAD3)
    /// Content/Tertiary: minor labels, sources and times, chevrons.
    static let tertiaryLabel = dynamic(0x536C79, dark: 0xA4BBC7)
    /// Content/Icon: an icon that carries meaning.
    static let icon = dynamic(0x294D60, dark: 0xC4DCE7)

    // MARK: Actions

    /// Action/Primary: the main button, links and the chosen item.
    static let primary = dynamic(0x145577, dark: 0x9DD9F0)
    /// Action/Pressed: the main action under the finger.
    static let primaryPressed = dynamic(0x0D405B, dark: 0x85C5E1)
    /// Action/OnPrimary: words and glyphs on `primary`.
    static let onPrimary = dynamic(0xFFFFFF, dark: 0x112A39)
    /// Action/Focus: the outline of the field being typed in.
    static let focus = dynamic(0x187398, dark: 0x7ACDEB)
    /// The fill of a main control (button, chosen chip, switch on): Milu fills them in the
    /// action blue.
    static let accent = primary
    /// Words and glyphs on `accent`.
    static let onAccent = onPrimary
    static let switchOn = accent
    /// A list row under the finger: a faint wash of the primary colour.
    static let rowPressed = primary.opacity(0.10)
    /// A tile in the primary colour, thin: the avatar in Cài đặt, the empty part of a progress ring.
    static let primaryTint = primary.opacity(0.10)
    /// A faint label-coloured fill for secondary buttons and neutral badges.
    static let fill = label.opacity(0.06)
    /// Action/DisabledSurface and Action/DisabledInk: a control that cannot be used.
    static let disabledFill = dynamic(0xE5EBED, dark: 0x2B3942)
    static let disabledLabel = dynamic(0x586A74, dark: 0xA3B0B7)

    // MARK: Brand

    /// Brand/Sky: the sky behind the art at a page's head.
    static let sky = dynamic(0xBEE8FB, dark: 0x23485B)
    /// Brand/Deep: the brand's ink on the sky (the wordmark, the profile's initial), the part of
    /// a goal saved so far.
    static let deep = dynamic(0x134767, dark: 0xBEE8FB)
    /// Brand/Honey: behind AI turns and a savings milestone.
    static let honey = dynamic(0xFFF0CE, dark: 0x473B29)
    /// Brand/Apricot: details of the art, never words.
    static let apricot = dynamic(0xF49B76, dark: 0xF1A389)

    /// The top edge of the light and dark sky illustration, extended during a pull-down.
    static let skyTop = dynamic(0x9ED8F2, dark: 0x142B47)
    /// The small letters Nâu signs the Sổ ví with ("NÂU GIỮ VÍ"): the brown of Nâu's ink.
    static let nauInk = dynamic(0x63482B, dark: 0xE7C79A)
    /// The top edge of Than's sky on Giao dịch (Milu `than/skyTop`, Figma 239:6884), run on
    /// above the head during a pull-down.
    static let thanSkyTop = dynamic(0xCBE6F3, dark: 0x152C44)
    /// The top edge of the three dogs' hill on Tổng quan (Figma 272:727 / 272:728, the scene's own
    /// gradient start), run on above the head during a pull-down.
    static let hillSkyTop = dynamic(0xCDEFEA, dark: 0x142E38)
    /// The top edges of Milu's meadow and lake skies (Figma "Nền / Đồi hoa", "Nền / Bờ hồ", their
    /// gradients' start). Drawn by day only: at night the whole sky takes `nightShade`, so the
    /// same colour stays under it.
    static let meadowSkyTop = dynamic(0xCDEFEA, dark: 0xCDEFEA)
    static let lakeSkyTop = dynamic(0xDBEFEB, dark: 0xDBEFEB)
    /// Laid over a day-only sky at night (`hillSkyTop`'s night colour), clear by day.
    static let nightShade = dynamic(0x142E38, dark: 0x142E38)

    // MARK: Money and meaning
    //
    // One colour per meaning across the app. Words in these colours reach 4.5:1 on the card and the
    // page; each has a pale `…Soft` background for badges (Milu's State/…Surface).

    /// Money/Income, State/SuccessInk: money in, with its "+".
    static let positive = dynamic(0x176649, dark: 0x91D7AF)
    static let income = positive
    /// State/SuccessSurface.
    static let incomeSoft = dynamic(0xE2F4E9, dark: 0x1E392D)

    /// Money/Expense, State/ErrorInk: money out with its "−", a negative balance, an error, delete.
    static let negative = dynamic(0xA3303B, dark: 0xFFA9AB)
    static let expense = negative
    /// State/ErrorSurface.
    static let expenseSoft = dynamic(0xFCE8E8, dark: 0x452B32)
    /// Words and glyphs on `negative` (a destructive button).
    static let onNegative = onPrimary

    /// Money that only moves between the user's own accounts: neither in nor out.
    static let transfer = secondaryLabel

    /// State/WarningInk: due soon, worth a look; bars and words alike.
    static let warning = dynamic(0x795116, dark: 0xFFD58B)
    static let warningLabel = warning
    /// State/WarningSurface.
    static let warningSoft = dynamic(0xFFF0CD, dark: 0x3C3221)

    /// Action/SelectedSurface: behind a filter or choice that is on.
    static let accentSoft = dynamic(0xDBEFF7, dark: 0x294B5B)

    // MARK: Progress

    /// Brand/Deep: the part of a goal or a limit done so far. It turns `warning` and `negative`
    /// as a limit runs out.
    static let progress = deep
    /// State/SuccessInk: a goal reached, a loan settled, the steps done.
    static let progressDone = positive
    /// Border/Quiet: the empty part of every bar and ring.
    static let progressTrack = separator

    // MARK: Savings jars

    /// The water in the glass jars of Sổ ví, in turn: mint, sky and honey (Milu "Hũ thủy tinh",
    /// Figma 129:542, 2026-11-05: "Các sắc mật ong, xanh trời và bạc hà dùng để phân biệt hũ"). By
    /// day as drawn; at night the same hues deepened, so the white emoji in the water still shows.
    static let jarWater = [
        dynamic(0x9ECDAD, dark: 0x4C7F5D),
        dynamic(0x8BCBE7, dark: 0x3C7F9E),
        dynamic(0xEBC074, dark: 0x9A7433),
    ]
    /// The water of the goal at `index` among the goals being saved for, the order of Sổ ví.
    static func jarWater(at index: Int) -> Color { jarWater[index % jarWater.count] }

    /// The jar's glass inside its outline, and the outline and lid: the page, the muted words and
    /// the quiet border, as drawn.
    static let jarGlass = background
    static let jarOutline = secondaryLabel
    static let jarLid = separator

    // MARK: Data

    /// The chart's shades, largest group first: deep blue, iris, sky, pink, bronze. No green and no
    /// red, so a group never reads as money in or out. Small marks that tell data apart, never
    /// words; each at least 3:1 on the card by day and at night.
    static let chart = [
        dynamic(0x134767, dark: 0xBEE8FB),
        dynamic(0x6D72F0, dark: 0xA5A8FF),
        dynamic(0x2B8CC4, dark: 0x6CC2F0),
        dynamic(0xD0458A, dark: 0xF07AB4),
        dynamic(0xB7851A, dark: 0xE3B54A),
    ]
    /// The groups after the fifth, as one ("Khác").
    static let chartRest = dynamic(0x8198A6, dark: 0x8198A6)

    // MARK: UIKit

    /// The same colours for the few UIKit appearances (`Typography.configureNativeAppearance`),
    /// dynamic like the rest.
    static let uiLabel = dynamicUI(0x142E43, dark: 0xF0F6F9)
    static let uiSecondaryLabel = dynamicUI(0x4C687A, dark: 0xB8CAD3)
    /// A segmented control's track and its chosen segment: `fill` and the card.
    static let uiFill = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0xF0 / 255, green: 0xF6 / 255, blue: 0xF9 / 255, alpha: 0.06)
            : UIColor(red: 0x14 / 255, green: 0x2E / 255, blue: 0x43 / 255, alpha: 0.06)
    }
    static let uiSurface = dynamicUI(0xFFFFFF, dark: 0x192B35)

    private static func dynamic(_ light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: dynamicUI(light, dark: dark))
    }

    private static func dynamicUI(_ light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255,
                           alpha: 1)
        }
    }
}
