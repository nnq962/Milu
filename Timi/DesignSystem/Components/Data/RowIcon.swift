import SwiftUI

/// A bank or wallet logo in its own colours: a rounded tile on white with a hairline edge, so
/// logos of any shape and colour sit evenly in a list (Wallet-style). The mark sits 14% in from
/// the edge: many logos are drawn edge to edge (Vietcombank), and would otherwise touch the border.
struct InstitutionLogo: View {
    let image: String
    var size: CGFloat = 28

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

/// The icon at the start of a row: a Solar glyph in ink, or, for names under `Institutions/`, the
/// bank or wallet logo. The logo is 28 wide but keeps the 24pt icon column, so text and dividers
/// line up with every other row.
struct RowIcon: View {
    let name: String
    var glyphSize: CGFloat = RowMetrics.iconGlyph

    var body: some View {
        Group {
            if name.hasPrefix("Institutions/") {
                InstitutionLogo(image: name)
            } else {
                SolarIcon(name, size: glyphSize)
                    .foregroundStyle(Palette.ink)
            }
        }
        .frame(width: RowMetrics.iconColumn)
    }
}
