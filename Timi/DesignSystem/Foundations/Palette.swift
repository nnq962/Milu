import SwiftUI

/// Sleek design tokens shared by every screen; the app intentionally uses light appearance.
enum Palette {
    // Exact sRGB tokens from examples.
    static let background = Color(red: 250/255, green: 250/255, blue: 247/255)
    static let card = Color.white
    static let muted = Color(red: 241/255, green: 241/255, blue: 236/255)
    // CSS bg-muted/60 composited over the white card.
    static let balanceTile = Color(red: 246.6/255, green: 246.6/255, blue: 243.6/255)
    /// Tile behind money coming in (Tiền vào, Đang cho vay): green 10% over white, not lime.
    static let incomeTile = Color(red: 232/255, green: 246/255, blue: 237/255)
    static let ink = Color(red: 17/255, green: 24/255, blue: 39/255)
    /// Solid fills of primary actions (main button, selected chip, switch on): pure black, user request 2026-10-28.
    static let primary = Color.black
    static let secondary = Color(red: 107/255, green: 114/255, blue: 128/255)
    static let secondarySurface = Color(red: 238/255, green: 240/255, blue: 243/255)
    // Chat input field.
    static let input = Color(red: 243/255, green: 243/255, blue: 239/255)
    static let border = Color(red: 229/255, green: 229/255, blue: 224/255)
    // User-requested optical adjustment for small text; keep control tints separate.
    static let secondaryText = Color(red: 89/255, green: 97/255, blue: 113/255)
    /// The one accent, used sparingly: Pro, AI, the current day. Never a default fill or progress colour.
    static let lime = Color(red: 198/255, green: 244/255, blue: 50/255)
    static let red = Color(red: 220/255, green: 38/255, blue: 38/255)
    // chart-3: within-budget progress.
    static let green = Color(red: 22/255, green: 163/255, blue: 74/255)
    /// Amber (web --warning, amber-500): a limit getting close.
    static let warning = Color(red: 245/255, green: 158/255, blue: 11/255)

    // Ink laid thin, like iOS systemFill (web --fill-1/2/3): one grey that suits page, card and sheet.
    /// Text fields, neutral icon tiles, a row under the finger.
    static let fill1 = ink.opacity(0.04)
    /// Grey buttons, tracks.
    static let fill2 = ink.opacity(0.06)
    /// Pressed grey, a switch turned off.
    static let fill3 = ink.opacity(0.10)
    /// A list row under the finger: lime at 18% on white (#F3FCD6). The accent only flashes here, so
    /// it stays rare (user choice 2026-10-28, tried iOS grey and went back).
    static let rowPressed = lime.opacity(0.18)
}
