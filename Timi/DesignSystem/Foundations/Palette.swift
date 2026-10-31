import SwiftUI

/// Design tokens shared by every screen. One light theme since 2026-10-30 (user request: dark
/// mode removed, the app is locked to light by `UIUserInterfaceStyle`).
///
/// Palette from the user's "TổngQuan" theme (2026-10-30): moss green (#3E5B3F) for primary
/// actions, deep green (#1E5A48) for money in, coral red for money out, warm gold as the one
/// accent, on a warm off-white page (#FAF7F2).
///
/// To change the look, change the few base colours at the top; everything below them follows.
/// The words and the other hues read from `AccentTrial` too since 2026-10-31, so the monochrome
/// set can swap them all. The one copy outside this file is `AccentColor` in Assets (system
/// alerts), set to the moss `primary`.
enum Palette {
    // MARK: Base colours

    /// Warm off-white (#FAF7F2) unless another combo is being tried (`AccentTrial`).
    static var background: Color { AccentTrial.shared.choice.background }
    static let card = rgb(255, 255, 255)
    /// Words: warm green-black, or plain near-black in the monochrome set (`AccentTrial`).
    static var ink: Color { AccentTrial.shared.choice.neutrals.ink }
    /// Solid fills of primary actions (main button, selected chip, switch on, chosen tab), the
    /// header icons. Moss (#3E5B3F) unless another is being tried (`AccentTrial`).
    static var primary: Color { AccentTrial.shared.choice.color }
    /// Good signs (growth, a limit well within, settled) and the tiles behind money lent.
    static var green: Color { AccentTrial.shared.choice.hues.green }
    /// Money out, over a limit, delete. Coral like the theme, deepened so text on white reaches
    /// 4.5:1 (the theme's #D9725B is 3.2:1).
    static let red = rgb(181, 84, 63)
    /// The one accent, used sparingly: the PRO badge and crown, the onboarding reward. Electric
    /// lime (#C9F26B) since 2026-10-31 (was gold #E0A840).
    static var lime: Color { AccentTrial.shared.choice.hues.lime }
    /// The second hue: money lent, people, info tiles.
    static var sky: Color { AccentTrial.shared.choice.hues.sky }
    /// Orange: a limit getting close (apart from the gold accent).
    static let warning = rgb(232, 137, 12)
    /// Deep orange text on a warning badge.
    static let warningText = rgb(138, 75, 8)
    /// Charts: the fourth group, then "Khác" (the first three are `primary`, `sky`, `lime`).
    static var chartCoral: Color { AccentTrial.shared.choice.hues.chartCoral }
    static var chartRest: Color { AccentTrial.shared.choice.hues.chartRest }

    // Warm neutrals.
    static var muted: Color { AccentTrial.shared.choice.muted }
    // Chat input field.
    static var input: Color { AccentTrial.shared.choice.input }
    static var border: Color { AccentTrial.shared.choice.border }
    /// Chevrons and faint glyphs.
    static var secondary: Color { AccentTrial.shared.choice.neutrals.secondary }
    /// The theme's #7A7266, one step darker so it stays 4.5:1 on the page.
    static var secondaryText: Color { AccentTrial.shared.choice.neutrals.secondaryText }

    // MARK: Derived: follow the base colours

    /// Money in: ink, with its "+" (user choice 2026-10-30, as Wallet and Cake do). The deep
    /// green read too close to the moss of buttons and tabs; only money out keeps a colour.
    /// `green` stays for good signs: growth, a limit well within, a loan settled.
    static var income: Color { ink }
    /// Text and glyphs on `primary`: white, or ink on a light one being tried.
    static var onPrimary: Color { AccentTrial.shared.choice.isLight ? ink : .white }
    /// Text and glyphs on red (a destructive button).
    static let onRed = Color.white
    /// Text and glyphs on the accent: the dark ink.
    static var onLime: Color { AccentTrial.shared.choice.hues.onLime }
    /// Switches turned on and the chosen day in a calendar.
    static var controlTint: Color { primary }
    /// Tile behind money coming in (Đang cho vay): the money-in colour, thin.
    static var incomeTile: Color { green.opacity(0.12) }

    // Ink laid thin, like iOS systemFill: one tint that suits page, card and sheet.
    /// Text fields, neutral icon tiles, a row under the finger.
    static var fill1: Color { ink.opacity(0.04) }
    /// Grey buttons, tracks.
    static var fill2: Color { ink.opacity(0.06) }
    /// Pressed grey, a switch turned off.
    static var fill3: Color { ink.opacity(0.10) }
    /// A list row under the finger: a faint wash of the primary colour.
    static var rowPressed: Color { primary.opacity(0.10) }
    /// A tile in the primary colour, thin (the avatar in Cài đặt).
    static var primaryTint: Color { primary.opacity(0.10) }
    /// The empty part of a progress ring.
    static var primaryTrack: Color { primary.opacity(0.12) }
    /// A dashed outline in the primary colour (a "new" tile).
    static var primaryDash: Color { primary.opacity(0.35) }
    /// A tile in the accent, thin (Pro, a caution badge).
    static var limeTile: Color { lime.opacity(0.16) }

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}
