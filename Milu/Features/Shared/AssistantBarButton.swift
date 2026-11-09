import SwiftUI

/// "✨ Hỏi Milu" on the bar of every tab, opening the assistant: a pill in the bar's glass, the
/// sparkle and the words in Milu's deep blue (Milu "Hỏi Milu · Trợ lý", Figma 79:1372).
///
/// The sparkle twinkles now and then (user pick "A" 2026-11-04: livelier): every `pause` seconds
/// it grows a little and turns one way then the other, in about half a second, then stands still.
/// Only while on screen (`.task` ends as the tab goes away: a hidden tab that kept moving held its
/// bar's glass in the old look after a change of appearance, Simulator check 2026-11-03) and
/// never with Reduce Motion.
struct AssistantBarButton: View {
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The ✨ grows with the words beside it (HIG review 2026-11-05), no further than 1.6 times.
    @ScaledMetric(relativeTo: .subheadline) private var scaledSparkle: CGFloat = 20
    private var sparkle: CGFloat { RowMetrics.capped(scaledSparkle, base: 20) }
    /// Counts the twinkles; each new count plays one.
    @State private var twinkles = 0

    private static let pause: Duration = .seconds(5)
    /// The pill's width at the default text size, for `HiddenTitleBar`.
    static let width: CGFloat = 112

    private struct Pose {
        var scale: CGFloat = 1
        var angle: Double = 0
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Fluent Flat's ✨ in its own colours (user request 2026-11-05): the bar tints an
                // image unless told to keep its own.
                Image(IconCatalog.emojiName("✨"))
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: sparkle, height: sparkle)
                    .keyframeAnimator(initialValue: Pose(), trigger: twinkles) { sparkle, pose in
                        sparkle
                            .scaleEffect(pose.scale)
                            .rotationEffect(.degrees(pose.angle))
                    } keyframes: { _ in
                        KeyframeTrack(\.scale) {
                            SpringKeyframe(1.2, duration: 0.22, spring: .snappy)
                            SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                        }
                        KeyframeTrack(\.angle) {
                            CubicKeyframe(-12, duration: 0.15)
                            CubicKeyframe(8, duration: 0.2)
                            CubicKeyframe(0, duration: 0.25)
                        }
                    }
                // Nunito SemiBold 15 (user pick 2026-11-05: Regular 13 read faint on the glass).
                Text("Hỏi Milu")
                    .font(Typography.font(.subheadline, size: 15, weight: .semibold))
            }
            .foregroundStyle(Palette.deep)
            .legacyBarPill()
        }
        .tint(Palette.deep)
        .accessibilityLabel("Hỏi Milu")
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
