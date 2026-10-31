import SwiftUI
import UIKit

/// Design tokens shared by every screen, named by what they do (as iOS's own `label`,
/// `separator`, `systemFill`), not by their hue, so a change of colours changes no names. Every
/// token here has a caller; one was pruned as soon as it had none (user 2026-10-31: too many).
///
/// Light mode keeps the monochrome palette; dark mode uses darker monochrome surfaces (2026-10-31).
/// Near-white words and actions sit on neutral backgrounds, with brighter surfaces
/// distinguishing cards and inset content. Semantic and chart colours keep their meanings.
///
/// The one copy outside this file is `AccentColor` in Assets (system alerts), light and dark, set
/// to `primary`.
enum Palette {
    // MARK: Surfaces

    /// Pale grey in light mode, pure black in dark mode.
    static let background = dynamic((243, 243, 244), dark: (0, 0, 0))
    /// Cards, list blocks, chips at rest: off-white by day, #18181A at night.
    static let surface = dynamic((249, 249, 250), dark: (24, 24, 26))
    /// A quiet block on a card or page: the track of a progress bar, an avatar's disc, the chat field.
    static let surfaceMuted = dynamic((236, 236, 238), dark: (38, 38, 40))
    /// Hairlines between rows and outlines of chips or logo tiles.
    static let separator = dynamic((232, 232, 234), dark: (46, 46, 48))

    // MARK: Words

    /// Words, figures, row icons.
    static let label = dynamic((17, 17, 17), dark: (242, 242, 247))
    /// Secondary words: subtitles, captions, labels above figures. 4.5:1 on the page and the card.
    static let secondaryLabel = dynamic((110, 110, 115), dark: (161, 161, 166))
    /// Chevrons, faint glyphs, disabled words.
    static let tertiaryLabel = dynamic((174, 174, 178), dark: (99, 99, 102))

    // MARK: Actions

    /// Solid fills of primary actions (main button, selected chip, switch on, chosen tab), links
    /// in words, the header icons: the words' colour.
    static let primary = dynamic((17, 17, 17), dark: (242, 242, 247))
    /// Text and glyphs on `primary`.
    static let onPrimary = dynamic((255, 255, 255), dark: (17, 17, 17))
    /// Native switches keep a white thumb in both appearances; their on-track needs its own tint.
    // Light tint sampled from the reference image in sRGB; dark tint is slightly brighter.
    static let switchOn = dynamic((72, 126, 198), dark: (88, 143, 216))
    /// A list row under the finger: a faint wash of the primary colour.
    static let rowPressed = primary.opacity(0.10)
    /// A tile in the primary colour, thin: the avatar in Cài đặt, the empty part of a progress ring.
    static let primaryTint = primary.opacity(0.10)
    /// A dashed outline in the primary colour (a "new" tile).
    static let primaryDash = primary.opacity(0.35)
    /// A faint label-coloured fill for secondary buttons and neutral badges.
    static let fill = label.opacity(0.06)

    // MARK: Meaning

    /// Money out, over a limit, delete. Coral deepened so text on the card reaches 4.5:1; lighter at night.
    static let negative = dynamic((181, 84, 63), dark: (240, 130, 110))
    /// Text and glyphs on `negative` (a destructive button).
    static let onNegative = dynamic((255, 255, 255), dark: (17, 17, 17))
    /// Good signs: growth, a limit well within, a loan settled, a day with more in than out.
    /// Small marks only (a dot, an arrow, a 13pt line), never a fill (user rule 2026-10-31: no
    /// grey, and no colour but small vivid marks). 5:1 on the card, so the 13pt line reads.
    static let positive = dynamic((21, 128, 61), dark: (74, 222, 128))
    /// A limit getting close (from 80%): bars and dots, 3.2:1 on the card as a graphic that carries
    /// meaning must be (review 2026-10-31: #E8890C was 2.6:1); words take `warningLabel`.
    static let warning = dynamic((217, 119, 6), dark: (245, 158, 11))
    /// Words in the warning colour, deep enough to read on the card and on `warning` 16%.
    static let warningLabel = dynamic((138, 75, 8), dark: (251, 191, 36))

    // MARK: Data

    /// The chart's shades, largest group first: blue, orange, coral, violet, as the storage bar of
    /// the mock-ups; small vivid marks that tell data apart, never words. Each at least 3:1 on
    /// its surface (HIG: graphics that carry meaning), which is why the orange is deeper than the
    /// mock-up's in the light set.
    static let chart = [
        dynamic((47, 124, 246), dark: (90, 155, 255)),
        dynamic((217, 119, 6), dark: (245, 166, 35)),
        dynamic((245, 85, 93), dark: (255, 107, 114)),
        dynamic((124, 77, 255), dark: (156, 123, 255)),
    ]
    /// The groups after the fourth, as one ("Khác"): iOS's own grey, 3:1 on the light and the dark card.
    static let chartRest = dynamic((142, 142, 147), dark: (142, 142, 147))

    // MARK: UIKit

    /// The same colours for the few UIKit appearances (`Typography.configureNativeAppearance`),
    /// dynamic like the rest.
    static let uiLabel = dynamicUI((17, 17, 17), dark: (242, 242, 247))
    static let uiSecondaryLabel = dynamicUI((110, 110, 115), dark: (161, 161, 166))

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
