import SwiftUI

/// Design tokens shared by every screen, named by what they do (as iOS's own `label`,
/// `separator`, `systemFill`), not by their hue, so a change of colours changes no names. Every
/// token here has a caller; one was pruned as soon as it had none (user 2026-10-31: too many).
///
/// One light theme, the monochrome set chosen 2026-10-31 (the moss theme of 2026-10-30 is kept
/// in `docs/design-history.md`): near-black words and actions on a near-white page, grey only as a
/// faint block, a hairline and secondary words; colour kept for money out (`negative`), a limit
/// getting close (`warning`), good signs (`positive`, small marks only) and the hues that tell
/// data apart (`chart`). The PRO badge and crown use `primary`: a black pill with white words.
/// Plain constants, so a token costs nothing to read.
///
/// The one copy outside this file is `AccentColor` in Assets (system alerts), set to `primary`.
enum Palette {
    // MARK: Surfaces

    /// The page, a step whiter than iOS's grouped grey (user request 2026-10-31).
    static let background = rgb(250, 250, 250)
    /// Cards, list blocks, chips at rest.
    static let surface = rgb(255, 255, 255)
    /// A quiet block on a card or page: the track of a progress bar, an avatar's disc.
    static let surfaceMuted = rgb(243, 243, 244)
    /// Hairlines between rows, the edge of a chip or a logo tile.
    static let separator = rgb(232, 232, 234)

    // MARK: Words

    /// Words, figures, row icons.
    static let label = rgb(17, 17, 17)
    /// Secondary words: subtitles, captions, labels above figures. 4.5:1 on the page.
    static let secondaryLabel = rgb(110, 110, 115)
    /// Chevrons, faint glyphs, disabled words.
    static let tertiaryLabel = rgb(174, 174, 178)

    // MARK: Actions

    /// Solid fills of primary actions (main button, selected chip, switch on, chosen tab), links
    /// in words, the header icons: ink.
    static let primary = rgb(17, 17, 17)
    /// Text and glyphs on `primary`.
    static let onPrimary = Color.white
    /// A list row under the finger: a faint wash of the primary colour.
    static let rowPressed = primary.opacity(0.10)
    /// A tile in the primary colour, thin: the avatar in Cài đặt, the empty part of a progress ring.
    static let primaryTint = primary.opacity(0.10)
    /// A dashed outline in the primary colour (a "new" tile).
    static let primaryDash = primary.opacity(0.35)
    /// Ink laid thin, like iOS systemFill: grey buttons and the neutral badge, on page and card alike.
    static let fill = label.opacity(0.06)

    // MARK: Meaning

    /// Money out, over a limit, delete. Coral deepened so text on white reaches 4.5:1.
    static let negative = rgb(181, 84, 63)
    /// Text and glyphs on `negative` (a destructive button).
    static let onNegative = Color.white
    /// Good signs: growth, a limit well within, a loan settled, a day with more in than out.
    /// Small marks only (a dot, an arrow, a 13pt line), never a fill (user rule 2026-10-31: no
    /// grey, and no colour but small vivid marks). 5:1 on white, so the 13pt line reads.
    static let positive = rgb(21, 128, 61)
    /// A limit getting close (from 80%): bars and dots, 3.2:1 on white as a graphic that carries
    /// meaning must be (review 2026-10-31: #E8890C was 2.6:1); words take `warningLabel`.
    static let warning = rgb(217, 119, 6)
    /// Words in the warning colour, deep enough to read on white and on `warning` 16%.
    static let warningLabel = rgb(138, 75, 8)

    // MARK: Data

    /// The chart's shades, largest group first: blue, orange, coral, violet, as the storage bar of
    /// the mock-ups; small vivid marks that tell data apart, never words. Each at least 3:1 on
    /// white (HIG: graphics that carry meaning), which is why the orange is deeper than the mock-up's.
    static let chart = [rgb(47, 124, 246), rgb(217, 119, 6), rgb(245, 85, 93), rgb(124, 77, 255)]
    /// The groups after the fourth, as one ("Khác"): iOS's own grey, 3:1 on white.
    static let chartRest = rgb(142, 142, 147)

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}
