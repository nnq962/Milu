import SwiftUI

/// Design tokens shared by every screen. One light theme since 2026-10-30 (user request: dark
/// mode removed, the app is locked to light by `UIUserInterfaceStyle`).
///
/// Palette from the user's "TổngQuan" theme (2026-10-30): moss green (#3E5B3F) for primary
/// actions, deep green (#1E5A48) for money in, coral red for money out, warm gold as the one
/// accent, on a warm off-white page (#FAF7F2).
///
/// To change the look, change the few base colours at the top; everything below them follows.
/// The one copy outside this file is `AccentColor` in Assets (system alerts), set to `primary`.
enum Palette {
    // MARK: Base colours

    /// Warm off-white (#FAF7F2) unless another combo is being tried (`AccentTrial`).
    static var background: Color { AccentTrial.shared.choice.background }
    static let card = rgb(255, 255, 255)
    static let ink = rgb(31, 42, 34)
    /// Solid fills of primary actions (main button, selected chip, switch on, chosen tab), the
    /// header icons. Moss (#3E5B3F) unless another is being tried (`AccentTrial`).
    static var primary: Color { AccentTrial.shared.choice.color }
    /// Good signs (growth, a limit well within, settled) and the tiles behind money lent.
    static let green = rgb(30, 90, 72)
    /// Money out, over a limit, delete. Coral like the theme, deepened so text on white reaches
    /// 4.5:1 (the theme's #D9725B is 3.2:1).
    static let red = rgb(181, 84, 63)
    /// The one accent, used sparingly: the PRO badge and crown, the onboarding reward, the Pro
    /// card's edge. Gold (was lime; the name stays so every use follows).
    static let lime = rgb(224, 168, 64)
    /// The second hue: money lent, people, info tiles.
    static let sky = rgb(95, 184, 154)
    /// Orange: a limit getting close (apart from the gold accent).
    static let warning = rgb(232, 137, 12)
    /// Deep orange text on a warning badge.
    static let warningText = rgb(138, 75, 8)
    /// Charts: the fourth group, then "Khác" (the first three are `primary`, `sky`, `lime`).
    static let chartCoral = rgb(232, 145, 122)
    static let chartRest = rgb(169, 185, 160)

    // Warm neutrals.
    static var muted: Color { AccentTrial.shared.choice.muted }
    // Chat input field.
    static var input: Color { AccentTrial.shared.choice.input }
    static var border: Color { AccentTrial.shared.choice.border }
    /// Chevrons and faint glyphs.
    static let secondary = rgb(150, 142, 130)
    /// The theme's #7A7266, one step darker so it stays 4.5:1 on the page.
    static let secondaryText = rgb(111, 103, 91)

    // MARK: Derived: follow the base colours

    /// Money in: ink, with its "+" (user choice 2026-10-30, as Wallet and Cake do). The deep
    /// green read too close to the moss of buttons and tabs; only money out keeps a colour.
    /// `green` stays for good signs: growth, a limit well within, a loan settled.
    static let income = ink
    /// Text and glyphs on `primary`: white, or ink on a light one being tried.
    static var onPrimary: Color { AccentTrial.shared.choice.isLight ? ink : .white }
    /// Text and glyphs on the accent: the dark ink.
    static let onLime = ink
    /// Switches turned on and the chosen day in a calendar.
    static var controlTint: Color { primary }
    /// Tile behind money coming in (Đang cho vay): the money-in colour, thin.
    static let incomeTile = green.opacity(0.12)

    // Ink laid thin, like iOS systemFill: one tint that suits page, card and sheet.
    /// Text fields, neutral icon tiles, a row under the finger.
    static let fill1 = ink.opacity(0.04)
    /// Grey buttons, tracks.
    static let fill2 = ink.opacity(0.06)
    /// Pressed grey, a switch turned off.
    static let fill3 = ink.opacity(0.10)
    /// A list row under the finger: a faint wash of the primary colour.
    static var rowPressed: Color { primary.opacity(0.10) }

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}
