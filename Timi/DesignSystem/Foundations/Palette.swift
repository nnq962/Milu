import SwiftUI
import UIKit

/// Sleek design tokens shared by every screen. Each one has a light and a dark value and follows
/// the appearance the app runs in (user request 2026-10-29: dark mode, by the phone or chosen in
/// Cài đặt → Giao diện). Dark values follow iOS's own dark greys; the accent stays lime.
enum Palette {
    // Exact sRGB tokens from examples (light); iOS system greys (dark).
    static let background = Color(light: rgb(250, 250, 247), dark: rgb(0, 0, 0))
    static let card = Color(light: rgb(255, 255, 255), dark: rgb(28, 28, 30))
    static let muted = Color(light: rgb(241, 241, 236), dark: rgb(44, 44, 46))
    // CSS bg-muted/60 composited over the white card.
    static let balanceTile = Color(light: rgb(246.6, 246.6, 243.6), dark: rgb(36, 36, 38))
    /// Tile behind money coming in (Tiền vào, Đang cho vay): green 10% over the card, not lime.
    static let incomeTile = Color(light: rgb(232, 246, 237), dark: rgb(22, 48, 32))
    static let ink = Color(light: rgb(17, 24, 39), dark: rgb(242, 242, 247))
    /// Solid fills of primary actions (main button, selected chip, switch on): black, white in
    /// dark (user requests 2026-10-28, 2026-10-29).
    static let primary = Color(light: rgb(0, 0, 0), dark: rgb(255, 255, 255))
    /// Text and glyphs on `primary`: white on black, black on white.
    static let onPrimary = Color(light: rgb(255, 255, 255), dark: rgb(0, 0, 0))
    /// Switches turned on and the chosen day in a calendar: black in light; iOS green in dark,
    /// where white would hide the switch knob and the day's white number.
    static let controlTint = Color(light: rgb(0, 0, 0), dark: rgb(48, 209, 88))
    static let secondary = Color(light: rgb(107, 114, 128), dark: rgb(142, 142, 147))
    static let secondarySurface = Color(light: rgb(238, 240, 243), dark: rgb(44, 44, 46))
    // Chat input field.
    static let input = Color(light: rgb(243, 243, 239), dark: rgb(44, 44, 46))
    static let border = Color(light: rgb(229, 229, 224), dark: rgb(56, 56, 58))
    // User-requested optical adjustment for small text; keep control tints separate.
    static let secondaryText = Color(light: rgb(89, 97, 113), dark: rgb(161, 161, 170))
    /// The one accent, used sparingly: Pro, AI, the current day. Never a default fill or progress colour.
    static let lime = Color(red: 198/255, green: 244/255, blue: 50/255)
    /// Text and glyphs on lime: always the dark ink, in dark mode too (light ink on lime is unreadable).
    static let onLime = Color(red: 17/255, green: 24/255, blue: 39/255)
    static let red = Color(light: rgb(220, 38, 38), dark: rgb(255, 69, 58))
    // chart-3: within-budget progress.
    static let green = Color(light: rgb(22, 163, 74), dark: rgb(48, 209, 88))
    /// Amber (web --warning, amber-500): a limit getting close.
    static let warning = Color(light: rgb(245, 158, 11), dark: rgb(255, 176, 32))
    /// Deep amber text on an amber badge (light), light amber (dark).
    static let warningText = Color(light: rgb(146, 64, 14), dark: rgb(251, 191, 36))
    /// The dark Pro card: ink in light, a raised grey in dark so it still stands apart.
    static let proCard = Color(light: rgb(17, 24, 39), dark: rgb(44, 44, 46))

    // Ink laid thin, like iOS systemFill (web --fill-1/2/3): one grey that suits page, card and sheet.
    /// Text fields, neutral icon tiles, a row under the finger.
    static let fill1 = ink.opacity(0.04)
    /// Grey buttons, tracks.
    static let fill2 = ink.opacity(0.06)
    /// Pressed grey, a switch turned off.
    static let fill3 = ink.opacity(0.10)
    /// A list row under the finger: lime at 18% on the card (#F3FCD6 on white). The accent only
    /// flashes here, so it stays rare (user choice 2026-10-28, tried iOS grey and went back).
    static let rowPressed = lime.opacity(0.18)

    fileprivate static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> UIColor {
        UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}

extension Color {
    /// A colour that follows the appearance: `light` in light mode, `dark` in dark mode.
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}
