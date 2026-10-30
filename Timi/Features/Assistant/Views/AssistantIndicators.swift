import SwiftUI

struct AssistantAvatar: View {
    var body: some View {
        // A plain teal glyph, no circle (user rule: icons without a background).
        TimiIcon("hugeicons-ai-magic", size: 22)
            .foregroundStyle(Palette.primary)
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)
    }
}

struct TypingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AssistantAvatar()
            TimiIcon("hugeicons-more-horizontal", size: 20)
                .foregroundStyle(Palette.secondary)
                .phaseAnimator([false, true]) { content, dimmed in
                    content.opacity(reduceMotion ? 1 : (dimmed ? 0.35 : 1))
                } animation: { _ in
                    .easeInOut(duration: 0.7)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Palette.card, in: UnevenRoundedRectangle(
                    topLeadingRadius: Bubble.tail, bottomLeadingRadius: Bubble.radius,
                    bottomTrailingRadius: Bubble.radius, topTrailingRadius: Bubble.radius, style: .continuous))
            Spacer()
        }
        .accessibilityLabel("Timi đang trả lời")
    }
}
