//
//  Components.swift
//  Timi
//

import SwiftUI

/// Biểu tượng bo góc trên nền màu nhạt, dùng cho danh mục và tài khoản.
struct IconBadge: View {
    let name: String
    let color: Color
    var size: CGFloat = 40

    var body: some View {
        SolarIcon(name, size: size * 0.5)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

/// Thẻ nền trắng có tiêu đề và một nút phụ tuỳ chọn ở góc phải.
struct CardSection<Content: View>: View {
    let title: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(Typography.headline)
                Spacer()
                if let actionTitle, let onAction {
                    Button(actionTitle, action: onAction)
                        .font(Typography.subheadline.weight(.medium))
                }
            }
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct TransactionRow: View {
    @Environment(FinanceStore.self) private var store
    let transaction: FinanceTransaction
    /// Tắt khi đang ở trong màn chi tiết tài khoản (tên tài khoản đã hiện ở tiêu đề).
    var showsAccount = true

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(name: transaction.category.icon, color: transaction.category.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(Typography.body.weight(.medium))
                    .lineLimit(1)
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(transaction.signedAmountText)
                .font(Typography.callout.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(transaction.kind == .income ? .green : .primary)
        }
    }

    private var subtitle: String {
        let detail = showsAccount
            ? store.account(id: transaction.accountID)?.name ?? "—"
            : transaction.date.relativeDayTitle
        return "\(transaction.category.title) · \(detail)"
    }
}
