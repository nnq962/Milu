import SwiftUI

/// A circle with a person's initial, standing in for profile photos: 44 on its own (a sheet's
/// header), `RowMetrics.listLogo` in a list, like an account's logo. The letter scales with the
/// circle, so it never spills out at large text.
struct InitialsAvatar: View {
    let name: String
    var size: CGFloat = RowMetrics.featureIcon

    var body: some View {
        Text(String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased())
            // The circle already scales; scaling the letter again spilled it out at the largest sizes.
            .font(Typography.fixedFont(size: size * 0.42, weight: .semibold))
            .foregroundStyle(Palette.label)
            .frame(width: size, height: size)
            .background(Palette.surfaceMuted, in: Circle())
            .accessibilityHidden(true)
    }
}
