import SwiftUI

/// Day totals beside each date heading: both sides in full, a single side compact.
struct DayTotals: View {
    let items: [FinanceTransaction]

    var body: some View {
        let income = items.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        let expense = items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        HStack(spacing: 12) {
            if income > 0 && expense > 0 {
                Text("+\(income.formatted(.number.locale(.vietnam)))")
                Text("-\(expense.formatted(.number.locale(.vietnam)))").foregroundStyle(Palette.red)
            } else if income > 0 {
                Text("+\(income.vndCompact)")
            } else {
                Text("-\(expense.vndCompact)").foregroundStyle(Palette.secondaryText)
            }
        }
        .font(Typography.font(.caption2, size: 11, weight: .semibold))
        .monospacedDigit()
    }
}

/// Transaction row: lime icon circle for income, muted for expenses.
struct FlowRow: View {
    let transaction: FinanceTransaction

    var body: some View {
        let income = transaction.kind == .income
        HStack(spacing: 12) {
            IconCircle(icon: transaction.category.icon, background: income ? Palette.lime : Palette.muted)
            VStack(alignment: .leading, spacing: 0) {
                Text(transaction.title)
                    .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                    .designLineHeight(20, relativeTo: .subheadline)
                    .lineLimit(1)
                Text("\(transaction.category.title) · \(transaction.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam)))")
                    .font(Typography.font(.caption2, size: 11))
                    .foregroundStyle(Palette.secondaryText)
                    .designLineHeight(16.5, relativeTo: .caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(transaction.signedAmountText)
                .font(Typography.font(.subheadline, size: 14, weight: .bold))
                .foregroundStyle(income ? Palette.ink : Palette.red)
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
