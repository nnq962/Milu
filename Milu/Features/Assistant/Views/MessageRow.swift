import SwiftUI

/// One message of the chat: the user's in a bubble at the right, Milu's under its name, with the
/// card of a transaction it recorded or is asked to delete.
struct MessageRow: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.onBubbleFrame) private var onBubbleFrame
    let message: ChatMessage
    let onAction: (CardAction, ChatMessage) -> Void

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 0)
                // As wide as its words, which are never wider than the field's (`QuestionWords`).
                UserBubble(text: message.text)
                    .modifier(ReportsBubbleFrame(report: onBubbleFrame))
            }
        case .assistant:
            // Milu's name over a bubble that may run the page's width, no avatar column beside it
            // (user requests 2026-10-31: text close to both margins, yet still a chat).
            VStack(alignment: .leading, spacing: Spacing.s) {
                AssistantSender()
                answer
                cardButtons
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
        .modifier(ReportsBubbleFrame(report: onBubbleFrame))
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
                    MiluIcon(icon, size: RowMetrics.inlineGlyph)
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

    /// Hiển thị **in đậm** và _in nghiêng_ theo cú pháp Markdown, giữ nguyên xuống dòng. Read
    /// once per answer and kept: an answer's text never changes.
    private var formattedText: AttributedString { Self.formatted(message.text) }

    static func formatted(_ markdown: String) -> AttributedString {
        if let cached = formatted[markdown] { return cached }
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let text = (try? AttributedString(markdown: markdown, options: options)) ?? AttributedString(markdown)
        if formatted.count > 200 { formatted.removeAll() }
        formatted[markdown] = text
        return text
    }

    /// The words "Sao chép" puts on the clipboard: the question as typed, the answer without the
    /// markdown's stars.
    static func copiedText(of message: ChatMessage) -> String {
        switch message.role {
        case .user: message.text
        case .assistant: String(formatted(message.text).characters)
        }
    }

    private static var formatted: [String: AttributedString] = [:]
}

/// Transaction summary inside an assistant bubble: the same row as every list of transactions
/// (`TransactionListRow`: plain icon, `MoneyText` with its sign and colour) on a muted tile
/// (strict review 2026-10-31: a white icon disc and a hand-made amount).
private struct TransactionCard: View {
    let transaction: FinanceTransaction

    var body: some View {
        TransactionListRow(transaction: transaction, detail: .day)
            .cardSurface(radius: CardCorners.card, color: Palette.surfaceMuted, outlined: false)
            .accessibilityElement(children: .combine)
    }
}

/// The user's words in their blue bubble: the chat's row, and the bubble that flies up from the
/// field as a question is sent (`ChatViewController.fly`), so the two are one drawing.
struct UserBubble: View {
    let text: String

    var body: some View {
        // Set as the field sets its words, so its lines break where they did as it was typed.
        QuestionWords(text: text)
            .accessibilityLabel(text)
            .padding(.horizontal, Bubble.userInset.leading)
            .padding(.vertical, Bubble.userInset.top)
            .background(Palette.primary, in: Bubble.userShape)
    }
}

/// Tells the chat where a message's bubble is in its row, so holding it lifts just the bubble
/// (`ChatViewController`'s hold menu). The menu is the list's, not SwiftUI's `.contextMenu`: inside
/// a UIKit list's row that one warns "_UIReparentingView … not supported" (user report 2026-11-11).
private struct ReportsBubbleFrame: ViewModifier {
    let report: ((CGRect) -> Void)?

    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ChatRow.space)) } action: {
            report?($0)
        }
    }
}

enum ChatRow {
    /// The coordinate space of a chat row's content, inside the row's margins.
    static let space = "chatRow"
}

extension EnvironmentValues {
    /// Where the row's bubble is, in `ChatRow.space`.
    @Entry var onBubbleFrame: ((CGRect) -> Void)? = nil
}

enum Bubble {
    /// A bubble rounds like a list card, with a small tail corner (re-review 2026-10-31:
    /// written as 24 and 8; a `CardCorners.bubbleTail` token would be the clean home for the 8).
    static let radius = CardCorners.card
    static let tail = CardCorners.small
    /// The user's bubble around its words, and its shape.
    static let userInset = EdgeInsets(top: Spacing.m, leading: Spacing.l, bottom: Spacing.m, trailing: Spacing.l)
    static let userShape = UnevenRoundedRectangle(
        topLeadingRadius: radius, bottomLeadingRadius: radius,
        bottomTrailingRadius: radius, topTrailingRadius: tail, style: .continuous)

    /// Milu's bubble's outline: its tail corner under the name.
    static let assistantOutline = UnevenRoundedRectangle(
        topLeadingRadius: tail, bottomLeadingRadius: radius,
        bottomTrailingRadius: radius, topTrailingRadius: radius, style: .continuous)

    /// Milu's bubble, in the card colour with the cards' edge, its tail corner under the name.
    static var assistantShape: some View {
        assistantOutline
            .fill(Palette.surface)
            .cardShadow()
    }
}
