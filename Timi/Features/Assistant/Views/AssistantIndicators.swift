import SwiftUI

/// Timi's mark: ✦ on a disc of the primary colour, as on the strip of Tổng quan, so the chat reads
/// as talking to someone (user request 2026-10-31: plain text read like a document).
struct AssistantAvatar: View {
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = RowMetrics.iconColumn + Spacing.xs

    var body: some View {
        TimiIcon("hugeicons-ai-magic", size: RowMetrics.inlineGlyph)
            .foregroundStyle(Palette.onPrimary)
            .frame(width: size, height: size)
            .background(Palette.primary, in: Circle())
            .accessibilityHidden(true)
    }
}

/// The avatar and the name over each of Timi's messages: who speaks, without an avatar column
/// that would take the bubble's width.
struct AssistantSender: View {
    var body: some View {
        HStack(spacing: Spacing.s) {
            AssistantAvatar()
            Text("Timi")
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryLabel)
        }
        .accessibilityHidden(true)
    }
}

/// Timi writing: three dots rising in turn inside the answer's own bubble, so nothing jumps when
/// the answer comes.
struct TypingIndicator: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            AssistantSender()
            TypingDots()
                .frame(height: ControlHeight.small / 2 + Spacing.xs)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background { Bubble.assistantShape }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement()
        .accessibilityLabel("Timi đang trả lời")
    }
}

/// The three dots rising in turn, alone, as the chat's typing bubble draws them.
struct TypingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var dot: CGFloat = 7

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Palette.secondaryLabel)
                    .frame(width: dot, height: dot)
                    .phaseAnimator([false, true]) { content, up in
                        content
                            .offset(y: reduceMotion ? 0 : (up ? -dot / 2 : dot / 4))
                            .opacity(up ? 1 : 0.4)
                    } animation: { _ in
                        .easeInOut(duration: 0.45).delay(Double(index) * 0.15)
                    }
            }
        }
    }
}
