import SwiftUI

/// Sleek design tokens shared by every screen; the app intentionally uses light appearance.
enum Palette {
    // Exact sRGB tokens from examples.
    static let background = Color(red: 250/255, green: 250/255, blue: 247/255)
    static let card = Color.white
    static let muted = Color(red: 241/255, green: 241/255, blue: 236/255)
    // CSS bg-muted/60 composited over the white card.
    static let balanceTile = Color(red: 246.6/255, green: 246.6/255, blue: 243.6/255)
    static let incomeTile = Color(red: 237.9/255, green: 251.7/255, blue: 188.1/255)
    static let ink = Color(red: 17/255, green: 24/255, blue: 39/255)
    static let secondary = Color(red: 107/255, green: 114/255, blue: 128/255)
    static let secondarySurface = Color(red: 238/255, green: 240/255, blue: 243/255)
    static let border = Color(red: 229/255, green: 229/255, blue: 224/255)
    // User-requested optical adjustment for small text; keep control tints separate.
    static let secondaryText = Color(red: 89/255, green: 97/255, blue: 113/255)
    static let lime = Color(red: 198/255, green: 244/255, blue: 50/255)
    static let red = Color(red: 220/255, green: 38/255, blue: 38/255)
}
