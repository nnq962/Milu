import SwiftUI

/// A bank or wallet logo in its own colours: a rounded tile on white with a hairline edge, so
/// logos of any shape and colour sit evenly in a list (Wallet-style). The mark sits 14% in from
/// the edge: many logos are drawn edge to edge (Vietcombank), and would otherwise touch the border.
struct InstitutionLogo: View {
    let image: String
    var size: CGFloat = RowMetrics.iconColumn

    var body: some View {
        Image(image)
            .resizable()
            .scaledToFit()
            .padding(size * 0.14)
            .frame(width: size, height: size)
            .background(Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .strokeBorder(Palette.border, lineWidth: 0.5)
            }
            .accessibilityHidden(true)
    }
}

/// The icon of an account, category or goal, never on a tile: a glyph in ink, or, for names
/// under `Institutions/`, the bank or wallet logo. Both fill the same square, `size` (24 in a row,
/// the icon column), so a logo is never bigger than a plain icon: the logo tile takes the whole
/// square and the glyph its usual 20/24 of it (Hugeicons glyphs carry their own inner margin).
struct RowIcon: View {
    let name: String
    var size: CGFloat = RowMetrics.iconColumn
    /// Colour of a glyph (logos keep their own).
    var tint: Color = Palette.ink
    /// A glyph on the same white tile as the logos, so a list mixing cash and banks lines up
    /// (lists of accounts, `AccountRow`).
    var tiled = false

    var body: some View {
        Group {
            if name.hasPrefix("Institutions/") {
                InstitutionLogo(image: name, size: size)
            } else if tiled {
                TimiIcon(name, size: size * 0.5)
                    .foregroundStyle(tint)
                    .frame(width: size, height: size)
                    .background(Palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                            .strokeBorder(Palette.border, lineWidth: 0.5)
                    }
                    .accessibilityHidden(true)
            } else {
                TimiIcon(name, size: size * RowMetrics.iconGlyph / RowMetrics.iconColumn)
                    .foregroundStyle(tint)
            }
        }
        .frame(width: size, height: size)
    }
}
