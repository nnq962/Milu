import SwiftUI
import UIKit

/// Design tokens shared by every screen, named by what they do (as iOS's own `label`,
/// `separator`, `systemFill`), not by their hue, so a change of colours changes no names. Every
/// token here has a caller; one was pruned as soon as it had none (user 2026-10-31: too many).
///
/// Two sets of values, light and dark, picked by the system (dark mode 2026-10-31, as the HIG
/// expects; the app no longer locks itself to light). Both keep the monochrome idea chosen
/// 2026-10-31: words and actions in one near-black (light) or near-white (dark) on a plain page,
/// grey only as a faint block, a hairline and secondary words; colour kept for money out
/// (`negative`), a limit getting close (`warning`), good signs (`positive`, small marks only) and
/// the hues that tell data apart (`chart`). The PRO badge and crown use `primary`. Each dark value
/// reads at least 4.5:1 on the dark card for words and 3:1 for marks, as the light ones do.
///
/// The one copy outside this file is `AccentColor` in Assets (system alerts), light and dark, set
/// to `primary`.
enum Palette {
    // MARK: Surfaces

    /// The page: a step whiter than iOS's grouped grey (user request 2026-10-31); black at night.
    static let background = dynamic((250, 250, 250), dark: (0, 0, 0))
    /// Cards, list blocks, chips at rest.
    static let surface = dynamic((255, 255, 255), dark: (28, 28, 30))
    /// A quiet block on a card or page: the track of a progress bar, an avatar's disc, the chat field.
    static let surfaceMuted = dynamic((243, 243, 244), dark: (44, 44, 46))
    /// Hairlines between rows, the edge of a chip or a logo tile; the edge of a card at night.
    static let separator = dynamic((232, 232, 234), dark: (56, 56, 58))

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
    /// A list row under the finger: a faint wash of the primary colour.
    static let rowPressed = primary.opacity(0.10)
    /// A tile in the primary colour, thin: the avatar in Cài đặt, the empty part of a progress ring.
    static let primaryTint = primary.opacity(0.10)
    /// A dashed outline in the primary colour (a "new" tile).
    static let primaryDash = primary.opacity(0.35)
    /// Ink laid thin, like iOS systemFill: grey buttons and the neutral badge, on page and card alike.
    static let fill = label.opacity(0.06)

    // MARK: Meaning

    /// Money out, over a limit, delete. Coral deepened so text on white reaches 4.5:1; lighter at night.
    static let negative = dynamic((181, 84, 63), dark: (240, 130, 110))
    /// Text and glyphs on `negative` (a destructive button).
    static let onNegative = dynamic((255, 255, 255), dark: (17, 17, 17))
    /// Good signs: growth, a limit well within, a loan settled, a day with more in than out.
    /// Small marks only (a dot, an arrow, a 13pt line), never a fill (user rule 2026-10-31: no
    /// grey, and no colour but small vivid marks). 5:1 on white, so the 13pt line reads.
    static let positive = dynamic((21, 128, 61), dark: (74, 222, 128))
    /// A limit getting close (from 80%): bars and dots, 3.2:1 on white as a graphic that carries
    /// meaning must be (review 2026-10-31: #E8890C was 2.6:1); words take `warningLabel`.
    static let warning = dynamic((217, 119, 6), dark: (245, 158, 11))
    /// Words in the warning colour, deep enough to read on white and on `warning` 16%.
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
    /// The groups after the fourth, as one ("Khác"): iOS's own grey, 3:1 on white and on the dark card.
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
