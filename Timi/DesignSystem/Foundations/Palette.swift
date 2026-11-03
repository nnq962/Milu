import SwiftUI
import UIKit

/// Design tokens shared by every screen, named by what they do (as iOS's own `label`,
/// `separator`, `systemFill`), not by their hue, so a change of colours changes no names. Every
/// token here has a caller; one was pruned as soon as it had none (user 2026-10-31: too many).
///
/// Light palette (user 2026-11-02): a near-white page with pure white cards and faint shadows by
/// day, charcoal at night, slate words, and one lime accent for a few fills. Semantic and chart colours keep
/// their meanings.
///
/// The one copy outside this file is `AccentColor` in Assets (system alerts), light and dark, set
/// to `primary`: alerts tint words, and lime words don't read on a light page.
enum Palette {
    // MARK: Surfaces

    /// The faintest beige by day (#F6F4F0, user 2026-11-03: "be cực nhẹ nhàng", after cream
    /// #F5F1E8 read too yellow and a cool grey and a lime wash were tried). Still a step under
    /// the white card so the card stands off it (at #FAFAF7 the cards sank into the page, user
    /// pick "D" 2026-11-02). A warm charcoal at night, a breath of the day's beige.
    static let background = dynamic((246, 244, 240), dark: (20, 19, 17))
    /// Cards, list blocks, chips at rest: pure white by day (lifts off the page without an
    /// outline), #1F1D1A at night.
    static let surface = dynamic((255, 255, 255), dark: (31, 29, 26))
    /// A quiet block on a card or page: the track of a progress bar, an avatar's disc, the chat field.
    static let surfaceMuted = dynamic((240, 238, 233), dark: (42, 40, 37))
    /// Hairlines between rows and outlines of chips or logo tiles.
    static let separator = dynamic((237, 235, 230), dark: (51, 48, 45))

    // MARK: Words

    /// Words, figures, row icons: slate ink by day (softer than black, as the reference), off-white at night.
    static let label = dynamic((17, 24, 39), dark: (242, 241, 238))
    /// Secondary words: subtitles, captions, labels above figures. 4.5:1 on the page and the card.
    static let secondaryLabel = dynamic((107, 114, 128), dark: (161, 159, 155))
    /// Chevrons, faint glyphs, disabled words.
    static let tertiaryLabel = dynamic((163, 168, 176), dark: (101, 99, 95))

    // MARK: Actions

    /// Links in words, the header icons, the chosen tab, and the fills that stay ink (the user's
    /// chat bubble, the Pro card): the words' colour.
    static let primary = label
    /// Text and glyphs on `primary`.
    static let onPrimary = dynamic((255, 255, 255), dark: (17, 24, 39))
    /// The one accent, lime, as a fill only (main button, selected chip, chosen tile, progress,
    /// switch on): about 1.2:1 on the page, so never words or thin glyphs on a light surface.
    /// Deeper and calmer at night, not brighter: on the dark page the day's lime glared, most of all
    /// as a switch's track (user report 2026-11-02). Still 9.6:1 on the night card, ink on it 10:1.
    static let accent = dynamic((200, 240, 75), dark: (176, 208, 64))
    /// Text and glyphs on `accent`: brown-black in both appearances.
    static let onAccent = dynamic((17, 24, 39), dark: (17, 24, 39))
    /// Native switches keep a white thumb in both appearances; their on-track is the accent.
    static let switchOn = accent
    /// A list row under the finger: a faint wash of the primary colour.
    static let rowPressed = primary.opacity(0.10)
    /// A tile in the primary colour, thin: the avatar in Cài đặt, the empty part of a progress ring.
    static let primaryTint = primary.opacity(0.10)
    /// A faint label-coloured fill for secondary buttons and neutral badges (kept after trying
    /// white outlined buttons, user choice 2026-11-03).
    static let fill = label.opacity(0.06)

    // MARK: Money and meaning
    //
    // One colour per meaning across the app (user request 2026-11-02, "a palette for money out,
    // money in, progress… instead of one kind per chart"). Lime is the brand only: never money,
    // never a chart. Words in these colours reach 4.5:1 on the white card; each has a pale `…Soft`
    // background for badges, and an `on…` for a solid fill where one exists.

    /// Money in: "+18.200.000đ", a loan collected, a day with more in than out. Emerald, leaning to
    /// blue so it never reads as the lime beside it (5.5:1 on the card).
    static let positive = dynamic((4, 120, 87), dark: (52, 211, 153))
    static let income = positive
    static let incomeSoft = dynamic((231, 244, 238), dark: (19, 52, 42))

    /// Money out, over a limit, delete. Coral deepened so text on the card reaches 4.5:1; lighter at night.
    static let negative = dynamic((181, 84, 63), dark: (240, 130, 110))
    static let expense = negative
    static let expenseSoft = dynamic((251, 237, 234), dark: (60, 34, 30))
    /// Text and glyphs on `negative` (a destructive button).
    static let onNegative = dynamic((255, 255, 255), dark: (17, 17, 17))

    /// Money that only moves between the user's own accounts: neither in nor out.
    static let transfer = secondaryLabel

    /// A limit getting close (from 80%), a loan due soon: bars and dots, 3.2:1 on the card as a
    /// graphic that carries meaning must be (review 2026-10-31); words take `warningLabel`.
    static let warning = dynamic((217, 119, 6), dark: (245, 158, 11))
    /// Words in the warning colour, 5:1 on the card and on `warningSoft`.
    static let warningLabel = dynamic((180, 83, 9), dark: (251, 191, 36))
    static let warningSoft = dynamic((253, 243, 226), dark: (58, 44, 18))

    /// A pale wash of the lime, behind something the brand marks.
    static let accentSoft = dynamic((241, 249, 214), dark: (44, 54, 22))

    // MARK: Progress

    /// A bar or ring on its way (a goal filling, a limit used, AI lượt): ink, which reads on the
    /// white card where lime (1.2:1) would not. It turns `warning` and `negative` as a limit runs out.
    /// At night a warm off-white, the words' own, not a bluish one.
    static let progress = dynamic((31, 41, 55), dark: (232, 230, 226))
    /// A goal reached, a loan settled, the steps done: the one place progress takes the lime.
    static let progressDone = accent
    /// The empty part of every bar and ring: a shade under `surfaceMuted`, so a ring still shows its
    /// track on a grey goal tile (Simulator check 2026-11-02: one shade read as no track at all).
    static let progressTrack = dynamic((229, 227, 221), dark: (56, 54, 51))

    // MARK: Data

    /// The chart's shades, largest group first: ink, iris, sky, pink, bronze (user's palette
    /// 2026-11-02, in place of blue, orange, coral, violet). No green and no red, so a group never
    /// reads as money in or out, and no lime, the brand's. Small marks that tell data apart, never
    /// words; each at least 3:1 on the white card and on the night card (HIG: graphics that carry
    /// meaning).
    static let chart = [
        dynamic((30, 41, 59), dark: (203, 213, 225)),
        dynamic((109, 114, 240), dark: (165, 168, 255)),
        dynamic((43, 140, 196), dark: (108, 194, 240)),
        dynamic((208, 69, 138), dark: (240, 122, 180)),
        dynamic((183, 133, 26), dark: (227, 181, 74)),
    ]
    /// The groups after the fifth, as one ("Khác"): a grey 3.1:1 on the light card, 5.4:1 at night.
    static let chartRest = dynamic((142, 146, 154), dark: (142, 146, 154))

    // MARK: UIKit

    /// The same colours for the few UIKit appearances (`Typography.configureNativeAppearance`),
    /// dynamic like the rest.
    static let uiLabel = dynamicUI((17, 24, 39), dark: (242, 241, 238))
    static let uiSecondaryLabel = dynamicUI((107, 114, 128), dark: (161, 159, 155))
    /// A segmented control's track and its chosen segment: `fill` (the words' colour at 6%) and
    /// the card's white, so it sits in the page's warm tone, not iOS's cool grey (user report
    /// 2026-11-03).
    static let uiFill = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 242 / 255, green: 241 / 255, blue: 238 / 255, alpha: 0.06)
            : UIColor(red: 17 / 255, green: 24 / 255, blue: 39 / 255, alpha: 0.06)
    }
    static let uiSurface = dynamicUI((255, 255, 255), dark: (31, 29, 26))

    private typealias RGB = (Double, Double, Double)

    private static func dynamic(_ light: RGB, dark: RGB) -> Color {
        Color(uiColor: dynamicUI(light, dark: dark))
    }

    private static func dynamicUI(_ light: RGB, dark: RGB) -> UIColor {
        UIColor { traits in
            let (r, g, b) = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
        }
    }
}
