import SwiftUI

// Components from the first prototype, still used by screens not yet on the design system
// (account detail, the Overview day sheet, the old account/goal/loan forms). Replace each with
// its design-system counterpart (ListRow, IconCircle, TimiAmountField) as those screens move.

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

/// Large VND amount input that groups thousands while typing.
struct AmountField: View {
    @Binding var text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            TextField("0", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
            Text("đ")
        }
        .font(Typography.font(.title2, size: 24, weight: .bold))
        .monospacedDigit()
        .onChange(of: text) { _, newValue in
            let formatted = newValue.groupedVNDInput
            if formatted != newValue { text = formatted }
        }
    }
}
