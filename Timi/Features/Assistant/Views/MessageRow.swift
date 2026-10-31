import SwiftUI

struct MessageRow: View {
    @Environment(FinanceStore.self) private var store
    let message: ChatMessage
    let onSuggestion: (String) -> Void
    let onAction: (CardAction, ChatMessage) -> Void

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 0)
                Text(message.text)
                    // The body role's own line box; no extra `lineSpacing` (re-review 2026-10-31).
                    .textRole(.body)
                    .foregroundStyle(Palette.onPrimary)
                    .padding(.horizontal, Spacing.l)
                    .padding(.vertical, Spacing.m)
                    .background(Palette.primary, in: UnevenRoundedRectangle(
                        topLeadingRadius: Bubble.radius, bottomLeadingRadius: Bubble.radius,
                        bottomTrailingRadius: Bubble.radius, topTrailingRadius: Bubble.tail, style: .continuous))
                    .containerRelativeFrame(.horizontal, alignment: .trailing) { width, _ in width * Bubble.maxWidth }
            }
        case .assistant:
            // Timi's name over a bubble that may run the page's width, no avatar column beside it
            // (user requests 2026-10-31: text close to both margins, yet still a chat).
            VStack(alignment: .leading, spacing: Spacing.s) {
                AssistantSender()
                answer
                cardButtons
                if message.showsSuggestions {
                    FlowLayout(spacing: Spacing.s) {
                        // Flat capsules 44 tall: no glass in a scrolling page, and a question
                        // may wrap, which a 36 `TagChip` would cut (re-review 2026-10-31).
                        ForEach(MockAssistant.suggestions, id: \.self) { suggestion in
                            Button { onSuggestion(suggestion) } label: {
                                Text(suggestion)
                                    .textRole(.captionStrong)
                                    .foregroundStyle(Palette.label)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, Spacing.l)
                                    .padding(.vertical, Spacing.s)
                                    .frame(minHeight: ControlHeight.regular)
                            }
                            .flatCapsuleButton()
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var answer: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(formattedText)
                .textRole(.body)
                .fixedSize(horizontal: false, vertical: true)
            if let transaction = cardTransaction {
                TransactionCard(transaction: transaction)
            }
            if let status = cardStatus {
                Text(status)
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryLabel)
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background { Bubble.assistantShape }
    }

    /// Shows the live transaction (after edits) while it exists, else the snapshot.
    private var cardTransaction: FinanceTransaction? {
        switch message.card {
        case .recorded(let snapshot, _), .confirmDelete(let snapshot, _):
            store.transaction(id: snapshot.id) ?? snapshot
        case nil: nil
        }
    }

    private var cardStatus: String? {
        switch message.card {
        // Short, like every status line (re-review 2026-10-31).
        case .recorded(_, removed: true), .confirmDelete(_, .deleted): "Đã xoá khoản này."
        case .confirmDelete(_, .cancelled): "Đã giữ lại khoản này."
        default: nil
        }
    }

    @ViewBuilder
    private var cardButtons: some View {
        switch message.card {
        case .recorded(let snapshot, removed: false) where store.transaction(id: snapshot.id) != nil:
            HStack(spacing: Spacing.s) {
                // "Xem": it opens the transaction's sheet, where it is edited (strict review
                // 2026-10-31: "Sửa" promised an editor and showed the detail).
                cardButton("Xem", icon: "hugeicons-eye", color: Palette.label) { onAction(.view, message) }
                cardButton("Xoá", icon: "hugeicons-delete-02", color: Palette.negative) { onAction(.remove, message) }
            }
        case .confirmDelete(let snapshot, .pending) where store.transaction(id: snapshot.id) != nil:
            HStack(spacing: Spacing.s) {
                cardButton("Huỷ", color: Palette.label) { onAction(.cancel, message) }
                cardButton("Xoá khoản này", color: Palette.onNegative, fill: Palette.negative, role: .destructive) {
                    onAction(.confirm, message)
                }
            }
        default:
            EmptyView()
        }
    }

    /// A flat capsule at least 44 tall: no Liquid Glass inside the chat, which scrolls (re-review
    /// 2026-10-31: glass, and ~34 tall).
    private func cardButton(_ title: String, icon: String? = nil, color: Color, fill: Color = Palette.fill,
                            role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            HStack(spacing: Spacing.xs) {
                if let icon {
                    TimiIcon(icon, size: RowMetrics.inlineGlyph)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
            .textRole(.captionStrong)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.l)
            .frame(maxWidth: .infinity, minHeight: ControlHeight.regular)
        }
        .flatCapsuleButton(fill: fill)
    }

    /// Hiển thị **in đậm** và _in nghiêng_ theo cú pháp Markdown, giữ nguyên xuống dòng.
    private var formattedText: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: message.text, options: options)) ?? AttributedString(message.text)
    }
}

/// Transaction summary inside an assistant bubble: the same row as every list of transactions
/// (`TransactionListRow`: plain icon, `MoneyText` with its sign and colour) on a muted tile
/// (strict review 2026-10-31: a white icon disc and a hand-made amount).
private struct TransactionCard: View {
    let transaction: FinanceTransaction

    var body: some View {
        TransactionListRow(transaction: transaction, detail: .day)
            .cardSurface(radius: CardCorners.flow, color: Palette.surfaceMuted, shadowed: false)
            .accessibilityElement(children: .combine)
    }
}

enum Bubble {
    /// A bubble rounds like a list card, with a small tail corner (re-review 2026-10-31:
    /// written as 24 and 8; a `CardCorners.bubbleTail` token would be the clean home for the 8).
    static let radius = CardCorners.inset
    static let tail = CardCorners.calendarDay
    /// Wide enough that a question fills most of the row (user request 2026-10-31: close to the
    /// margins), short enough that it still reads as the user's side.
    static let maxWidth: CGFloat = 0.85

    /// Timi's bubble, in the card colour with the cards' edge, its tail corner under the name.
    static var assistantShape: some View {
        UnevenRoundedRectangle(topLeadingRadius: tail, bottomLeadingRadius: radius,
                               bottomTrailingRadius: radius, topTrailingRadius: radius, style: .continuous)
            .fill(Palette.surface)
            .cardShadow()
    }
}
