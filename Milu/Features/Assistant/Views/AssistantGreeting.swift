import SwiftUI

/// A new chat (user design 2026-11-15, Figma "12 · Milu · Trợ lý AI"): "Chào Minh!", what Milu
/// does and three questions to start with, in the middle of the page, no ✨ above (as ChatGPT); what
/// is left of the week's questions just over the field. Scrolls when the text is large.
///
/// The words come in softly and the questions rise one after another, each time a new chat opens.
struct AssistantGreeting: View {
    let title: String
    /// "Còn 18 lượt hỏi tuần này · …", or nil with Milu Pro.
    let quotaLine: String?
    /// The chat it greets: a new one plays the greeting's coming in again.
    let chatID: Conversation.ID?
    /// A question tapped: asked at once.
    let ask: (String) -> Void
    /// A request tapped that would change the records (recording): put in the field to send, so
    /// nothing is recorded on a tap made to see what it does.
    let fill: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    private struct Suggestion: Identifiable {
        let emoji: String
        let words: String
        /// Recorded on sending: put in the field, not sent.
        var records = false
        var id: String { words }
    }

    private static let suggestions = [
        Suggestion(emoji: "📊", words: "Tháng này mình chi bao nhiêu?"),
        Suggestion(emoji: "☕", words: "Ghi cà phê 35k", records: true),
        Suggestion(emoji: "🤝", words: "Mình còn nợ ai?"),
    ]

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: Spacing.xl)
                    VStack(spacing: Spacing.s) {
                        Text(title)
                            .textRole(.display)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text("Hỏi mình về chi tiêu, khoản vay, hoặc nhờ mình ghi hay xoá giao dịch.")
                            .textRole(.body)
                            .foregroundStyle(Palette.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 320)
                    }
                    .modifier(ComesIn(shown: shown, delay: 0))
                    VStack(spacing: Spacing.s + 2) {
                        ForEach(Array(Self.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                            chip(suggestion)
                                .modifier(ComesIn(shown: shown, delay: 0.12 + 0.06 * Double(index)))
                        }
                    }
                    .padding(.top, Spacing.section)
                    Spacer(minLength: Spacing.xl)
                    if let quotaLine {
                        // What is left this week, and that recording costs none (user choice 2026-11-12).
                        Text(quotaLine)
                            .textRole(.caption)
                            .foregroundStyle(Palette.tertiaryLabel)
                            .multilineTextAlignment(.center)
                            .monospacedDigit()
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, Spacing.m)
                            .modifier(ComesIn(shown: shown, delay: 0.3))
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .task(id: chatID) {
            guard !reduceMotion else {
                shown = true
                return
            }
            shown = false
            // A frame hidden, then the coming in.
            try? await Task.sleep(for: .milliseconds(30))
            shown = true
        }
    }

    private func chip(_ suggestion: Suggestion) -> some View {
        Button {
            Haptics.selection()
            if suggestion.records { fill(suggestion.words) } else { ask(suggestion.words) }
        } label: {
            HStack(spacing: Spacing.s + 2) {
                Image(IconCatalog.emojiName(suggestion.emoji))
                    .resizable()
                    .scaledToFit()
                    .frame(width: IconSize.rowGlyph, height: IconSize.rowGlyph)
                    .accessibilityHidden(true)
                Text(suggestion.words)
                    .textRole(.body)
                    .foregroundStyle(Palette.label)
                    .multilineTextAlignment(.leading)
            }
            .padding(.leading, Spacing.m)
            .padding(.trailing, Spacing.l)
            .padding(.vertical, Spacing.s + 2)
            .frame(minHeight: ControlHeight.regular)
            .background(Palette.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.separator, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityHint(suggestion.records ? "Đưa vào ô hỏi" : "Hỏi Milu")
    }
}

/// Coming in: clear and a little low, then in place, on a soft spring after `delay`.
private struct ComesIn: ViewModifier {
    let shown: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 10)
            .animation(shown ? Motion.gentle(.spring(duration: 0.5, bounce: 0.15).delay(delay)) : nil, value: shown)
    }
}
