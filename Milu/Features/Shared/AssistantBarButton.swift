import SwiftUI

/// "✨" on the bar of every tab, opening the assistant: the sparkle alone in the bar's glass
/// circle, as the other bar buttons (user request 2026-11-16: no "Hỏi Milu" beside it; it was a
/// pill, Milu "Hỏi Milu · Trợ lý", Figma 79:1372). VoiceOver still calls it "Hỏi Milu".
///
/// The sparkle twinkles now and then (user pick "A" 2026-11-04: livelier): every `pause` it grows a
/// little and turns one way then the other, quickly, then stands still (user request 2026-11-16:
/// more often and quicker than every 5 seconds). Only while on screen (`.task` ends as the tab goes
/// away: a hidden tab that kept moving held its bar's glass in the old look after a change of
/// appearance, Simulator check 2026-11-03) and never with Reduce Motion.
struct AssistantBarButton: View {
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Counts the twinkles; each new count plays one.
    @State private var twinkles = 0

    private static let pause: Duration = .seconds(2.5)
    /// The sparkle in the circle: a little larger than a bar glyph (`IconSize.bar`), as a coloured
    /// picture reads smaller than a line.
    private static let sparkle: CGFloat = 22

    private struct Pose {
        var scale: CGFloat = 1
        var angle: Double = 0
    }

    var body: some View {
        Button(action: action) {
            // Fluent Flat's ✨ in its own colours (user request 2026-11-05): the bar tints an image
            // unless told to keep its own.
            Image(IconCatalog.emojiName("✨"))
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: Self.sparkle, height: Self.sparkle)
                .keyframeAnimator(initialValue: Pose(), trigger: twinkles) { sparkle, pose in
                    sparkle
                        .scaleEffect(pose.scale)
                        .rotationEffect(.degrees(pose.angle))
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        SpringKeyframe(1.25, duration: 0.15, spring: .snappy)
                        SpringKeyframe(1, duration: 0.3, spring: .bouncy)
                    }
                    KeyframeTrack(\.angle) {
                        CubicKeyframe(-14, duration: 0.1)
                        CubicKeyframe(10, duration: 0.14)
                        CubicKeyframe(0, duration: 0.18)
                    }
                }
                // The frame every bar glyph has, so the glass circle is the same as the others'.
                .frame(width: IconSize.barFrame, height: IconSize.barFrame)
                .legacyBarCircle()
        }
        .buttonBorderShape(.circle)
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
