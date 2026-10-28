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
                    .font(Typography.font(.subheadline, size: 14))
                    .lineSpacing(5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Palette.ink, in: UnevenRoundedRectangle(
                        topLeadingRadius: Bubble.radius, bottomLeadingRadius: Bubble.radius,
                        bottomTrailingRadius: Bubble.radius, topTrailingRadius: Bubble.tail, style: .continuous))
                    .containerRelativeFrame(.horizontal, alignment: .trailing) { width, _ in width * Bubble.maxWidth }
            }
        case .assistant:
            HStack(alignment: .top, spacing: 12) {
                AssistantAvatar()
                VStack(alignment: .leading, spacing: 8) {
                    bubble
                    cardButtons
                    if message.showsSuggestions {
                        FlowLayout(spacing: 8) {
                            ForEach(MockAssistant.suggestions, id: \.self) { suggestion in
                                Button(suggestion) { onSuggestion(suggestion) }
                                    .font(Typography.font(.caption, size: 12, weight: .medium))
                                    .foregroundStyle(Palette.ink)
                                    .nativeGlassButton()
                                    .buttonBorderShape(.capsule)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .containerRelativeFrame(.horizontal, alignment: .leading) { width, _ in width * Bubble.maxWidth }
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedText)
                .font(Typography.font(.subheadline, size: 14))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            if let transaction = cardTransaction {
                TransactionCard(transaction: transaction)
            }
            if let status = cardStatus {
                Text(status)
                    .font(Typography.font(.caption, size: 12, weight: .medium))
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .padding(16)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Bubble.tail, bottomLeadingRadius: Bubble.radius,
                                   bottomTrailingRadius: Bubble.radius, topTrailingRadius: Bubble.radius, style: .continuous)
                .fill(Palette.card)
                .shadow(color: Color(red: 28/255, green: 36/255, blue: 48/255).opacity(0.05), radius: 8, x: 0, y: 2)
        }
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
        case .recorded(_, removed: true): "Đã xoá khoản này, số dư đã được cập nhật lại."
        case .confirmDelete(_, .deleted): "Đã xoá khoản này, số dư đã được cập nhật lại."
        case .confirmDelete(_, .cancelled): "Đã giữ lại khoản này."
        default: nil
        }
    }

    @ViewBuilder
    private var cardButtons: some View {
        switch message.card {
        case .recorded(let snapshot, removed: false) where store.transaction(id: snapshot.id) != nil:
            HStack(spacing: 8) {
                cardButton("Sửa", icon: "solar-pen-linear", color: Palette.ink) { onAction(.edit, message) }
                cardButton("Xoá", icon: "solar-trash-bin-minimalistic-linear", color: Palette.red) { onAction(.remove, message) }
            }
        case .confirmDelete(let snapshot, .pending) where store.transaction(id: snapshot.id) != nil:
            HStack(spacing: 8) {
                Button { onAction(.cancel, message) } label: {
                    Text("Huỷ").frame(maxWidth: .infinity)
                }
                .foregroundStyle(Palette.ink)
                .nativeGlassButton(tint: Palette.muted)
                Button(role: .destructive) { onAction(.confirm, message) } label: {
                    Text("Xoá khoản này").frame(maxWidth: .infinity)
                }
                .foregroundStyle(.white)
                .nativeGlassButton(prominent: true, tint: Palette.red)
            }
            .font(Typography.font(.caption, size: 12, weight: .semibold))
            .buttonBorderShape(.capsule)
        default:
            EmptyView()
        }
    }

    private func cardButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                SolarIcon(icon, size: 14)
                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .font(Typography.font(.caption, size: 12, weight: .semibold))
        .foregroundStyle(color)
        .nativeGlassButton()
        .buttonBorderShape(.capsule)
    }

    /// Hiển thị **in đậm** và _in nghiêng_ theo cú pháp Markdown, giữ nguyên xuống dòng.
    private var formattedText: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: message.text, options: options)) ?? AttributedString(message.text)
    }
}

/// Transaction summary inside an assistant bubble: muted tile, 40pt white icon circle.
private struct TransactionCard: View {
    let transaction: FinanceTransaction

    var body: some View {
        HStack(spacing: 12) {
            IconCircle(icon: transaction.category.icon, iconSize: 18, background: Palette.card)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(transaction.title)
                    .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                    .lineLimit(1)
                Text("\(transaction.category.title) · \(dayText)")
                    .font(Typography.font(.caption2, size: 11))
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(transaction.signedAmountText)
                .font(Typography.font(.subheadline, size: 14, weight: .bold))
                .foregroundStyle(transaction.kind == .income ? Palette.ink : Palette.red)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .cardSurface(radius: CardCorners.flow, color: Palette.muted)
        .accessibilityElement(children: .combine)
    }

    private var dayText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(transaction.date) { return "Hôm nay" }
        if calendar.isDateInYesterday(transaction.date) { return "Hôm qua" }
        return transaction.date.dayMonth
    }
}

enum Bubble {
    // rounded-2xl with a rounded-md tail corner, scaled for short chat bubbles.
    static let radius: CGFloat = 24
    static let tail: CGFloat = 8
    static let maxWidth: CGFloat = 0.78
}
