import SwiftUI

struct AssistantAvatar: View {
    var body: some View {
        // A plain teal glyph, no circle (user rule: icons without a background).
        // A glyph in content, not a toolbar's (re-review 2026-10-31).
        TimiIcon("hugeicons-ai-magic", size: RowMetrics.iconGlyph)
            .foregroundStyle(Palette.primary)
            .frame(width: RowMetrics.listLogo, height: RowMetrics.listLogo)
            .accessibilityHidden(true)
    }
}

struct TypingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            AssistantAvatar()
            TimiIcon("hugeicons-more-horizontal", size: RowMetrics.iconGlyph)
                .foregroundStyle(Palette.secondary)
                .phaseAnimator([false, true]) { content, dimmed in
                    content.opacity(reduceMotion ? 1 : (dimmed ? 0.35 : 1))
                } animation: { _ in
                    .easeInOut(duration: 0.7)
                }
                // The real bubble's padding and shadow, so it does not jump when the answer comes.
                .padding(Spacing.l)
                .background { Bubble.assistantShape }
            Spacer()
        }
        .accessibilityLabel("Timi đang trả lời")
    }
}
