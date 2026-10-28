import SwiftUI

/// 44pt circle holding an icon.
struct IconCircle: View {
    let icon: String
    var iconSize: CGFloat = 20
    var background: Color = Palette.muted

    var body: some View {
        TimiIcon(icon, size: iconSize)
            .foregroundStyle(Palette.ink)
            .frame(width: 44, height: 44)
            .background(background, in: Circle())
    }
}

/// 44pt circle with a person's initial, standing in for profile photos.
struct InitialsAvatar: View {
    let name: String

    var body: some View {
        Text(String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased())
            .textRole(.title)
            .foregroundStyle(Palette.ink)
            .frame(width: 44, height: 44)
            .background(Palette.muted, in: Circle())
            .accessibilityHidden(true)
    }
}
