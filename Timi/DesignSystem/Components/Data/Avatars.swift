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
            .foregroundStyle(Palette.ink)
            .frame(width: size, height: size)
            .background(Palette.muted, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Progress as a ring round an icon (a goal, the onboarding steps): one track and line for all.
struct ProgressRing: View {
    let progress: Double
    var color: Color = Palette.primary
    /// The empty part: thin primary by default, a grey for a ring in another colour.
    var track: Color = Palette.primaryTrack
    var lineWidth: CGFloat = RowMetrics.ringStroke

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
    }
}
