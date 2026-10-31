import SwiftUI

/// A bank or wallet logo in its own colours: a rounded tile in the card colour with a hairline edge, so
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
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .strokeBorder(Palette.separator, lineWidth: 0.5)
            }
            .accessibilityHidden(true)
    }
}

/// The icon of an account, category or goal, never on a tile: a glyph in ink, or, for names
/// under `Institutions/`, the bank or wallet logo. Both fill the same square, `size` (24 in a row,
/// the icon column), so a logo is never bigger than a plain icon: the logo tile takes the whole
/// square and the glyph its usual 20/24 of it (Hugeicons glyphs carry their own inner margin).
/// `size` is the size at the default text size; the icon grows with the text on its own, so no
/// caller has to remember to (review 2026-10-31: fifteen did, the forms did not).
struct RowIcon: View {
    let name: String
    /// Colour of a glyph (logos keep their own).
    var tint: Color = Palette.label
    /// A glyph on the same tile as the logos, so a list mixing cash and banks lines up
    /// (lists of accounts, `AccountRow`).
    var tiled = false

    @ScaledMetric private var size: CGFloat

    init(name: String, size: CGFloat = RowMetrics.iconColumn, tint: Color = Palette.label, tiled: Bool = false) {
        self.name = name
        self.tint = tint
        self.tiled = tiled
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        Group {
            if name.hasPrefix("Institutions/") {
                InstitutionLogo(image: name, size: size)
            } else if tiled {
                TimiIcon(name, size: size * 0.5)
                    .foregroundStyle(tint)
                    .frame(width: size, height: size)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                            .strokeBorder(Palette.separator, lineWidth: 0.5)
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
