import SwiftUI

/// Timi's ✦ on the bar of every tab, opening Trợ lý AI: the 3D sparkles of "Hỏi Timi một câu" in
/// the bar's glass circle, twinkling now and then (user pick "A" 2026-11-04: livelier, a 3D
/// icon). The one coloured picture among the bar's line icons, so the AI stands apart.
///
/// The twinkle: every `pause` seconds the sparkles grow a little and turn one way then the other,
/// in about half a second, then stand still. Only while on screen (`.task` ends as the tab goes
/// away: a hidden tab that kept moving held its bar's glass in the old look after a change of
/// appearance, Simulator check 2026-11-03) and never with Reduce Motion.
struct AssistantBarButton: View {
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Counts the twinkles; each new count plays one.
    @State private var twinkles = 0

    private static let pause: Duration = .seconds(5)

    private struct Pose {
        var scale: CGFloat = 1
        var angle: Double = 0
    }

    var body: some View {
        Button(action: action) {
            // In colour: the bar draws an image in the tint unless told to keep its own.
            Image("fluent-sparkles")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
                .keyframeAnimator(initialValue: Pose(), trigger: twinkles) { picture, pose in
                    picture
                        .scaleEffect(pose.scale)
                        .rotationEffect(.degrees(pose.angle))
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        SpringKeyframe(1.15, duration: 0.22, spring: .snappy)
                        SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                    }
                    KeyframeTrack(\.angle) {
                        CubicKeyframe(-12, duration: 0.15)
                        CubicKeyframe(8, duration: 0.2)
                        CubicKeyframe(0, duration: 0.25)
                    }
                }
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Hỏi Timi")
        .accessibilityHint("Mở trợ lý AI")
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.pause)
                guard !Task.isCancelled else { return }
                twinkles += 1
            }
        }
    }
}
