import SwiftUI

/// Design tokens shared by every screen: one light theme, the monochrome set chosen 2026-10-31
/// (after the moss theme of 2026-10-30, kept in `docs/design-history.md`): near-black words and
/// actions on a near-white page, grey only as a faint block and a hairline, colour kept for money
/// out (red), a limit getting close (orange) and the small marks that tell data apart (the
/// chart's four hues). Plain constants, so a token costs nothing to read.
///
/// The one copy outside this file is `AccentColor` in Assets (system alerts), set to `primary`.
enum Palette {
    // MARK: Base colours

    /// The page, a step whiter than iOS's grouped grey (user request 2026-10-31).
    static let background = rgb(250, 250, 250)
    static let card = rgb(255, 255, 255)
    /// Words.
    static let ink = rgb(17, 17, 17)
    /// Solid fills of primary actions (main button, selected chip, switch on, chosen tab), the
    /// header icons: ink.
    static let primary = rgb(17, 17, 17)
    /// Good signs (growth, a limit well within, settled): ink in the monochrome set.
    static let green = rgb(17, 17, 17)
    /// Money out, over a limit, delete. Coral deepened so text on white reaches 4.5:1.
    static let red = rgb(181, 84, 63)
    /// The one accent, used sparingly: the PRO badge and crown, the "+5 AI" reward. A black pill
    /// with white words, as the floating button of the Iconly mock-ups.
    static let lime = rgb(17, 17, 17)
    /// The second hue: money lent, people, info.
    static let sky = rgb(47, 124, 246)
    /// Orange: a limit getting close.
    static let warning = rgb(232, 137, 12)
    /// Deep orange text on a warning badge.
    static let warningText = rgb(138, 75, 8)
    /// The chart's four shades, largest group first: blue, orange, coral, violet, as the storage
    /// bar of the mock-ups; then "Khác".
    static let chart = [rgb(47, 124, 246), rgb(245, 166, 35), rgb(245, 85, 93), rgb(124, 77, 255)]
    static let chartRest = rgb(209, 209, 214)

    // Neutrals: the only greys, for blocks, hairlines and secondary words.
    static let muted = rgb(243, 243, 244)
    /// Chat input field.
    static let input = rgb(245, 245, 246)
    static let border = rgb(232, 232, 234)
    /// Chevrons and faint glyphs.
    static let secondary = rgb(174, 174, 178)
    /// Secondary words, 4.5:1 on the page.
    static let secondaryText = rgb(110, 110, 115)

    // MARK: Derived: follow the base colours

    /// Text and glyphs on `primary`.
    static let onPrimary = Color.white
    /// Text and glyphs on red (a destructive button).
    static let onRed = Color.white
    /// Text and glyphs on the accent.
    static let onLime = Color.white

    // Ink laid thin, like iOS systemFill: one tint that suits page, card and sheet.
    /// Text fields, neutral icon tiles, a row under the finger.
    static let fill1 = ink.opacity(0.04)
    /// Grey buttons, tracks.
    static let fill2 = ink.opacity(0.06)
    /// Pressed grey, a switch turned off.
    static let fill3 = ink.opacity(0.10)
    /// A list row under the finger: a faint wash of the primary colour.
    static let rowPressed = primary.opacity(0.10)
    /// A tile in the primary colour, thin (the avatar in Cài đặt).
    static let primaryTint = primary.opacity(0.10)
    /// The empty part of a progress ring.
    static let primaryTrack = primary.opacity(0.12)
    /// A dashed outline in the primary colour (a "new" tile).
    static let primaryDash = primary.opacity(0.35)

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}
