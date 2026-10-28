import SwiftUI

/// One transaction as a design-system `ListRow`: category icon, title, a subtitle and the signed
/// amount (income "+", spending "-" in red); with a day or time, that goes under the amount. Rows on a white card; put `RowDivider` between them.
struct TransactionListRow: View {
    let transaction: FinanceTransaction
    /// What follows the category in the subtitle: the account, or the day when the account is known.
    var detail: Detail = .account

    enum Detail { case account, day, time }

    @Environment(FinanceStore.self) private var store

    var body: some View {
        switch detail {
        case .account:
            row(subtitle: "\(categoryText) · \(store.account(id: transaction.accountID)?.name ?? "—")", trailing: nil)
        case .day:
            // Amount level with the title, the short date under it.
            row(subtitle: categoryText,
                trailing: Self.dayMonth(transaction.date))
        case .time:
            row(subtitle: categoryText,
                trailing: transaction.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam)))
        }
    }

    /// The category, or for a balance adjustment (whose title already says so) that it is not counted.
    private var categoryText: String {
        transaction.category.isAdjustment ? "Không tính vào báo cáo" : transaction.category.title
    }

    /// "27/10".
    static func dayMonth(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.day, .month], from: date)
        return String(format: "%02d/%02d", parts.day ?? 0, parts.month ?? 0)
    }

    private func row(subtitle: String, trailing: String?) -> some View {
        ListRow(
            icon: transaction.category.icon,
            title: transaction.title,
            subtitle: subtitle,
            trailingSubtitle: trailing,
            amount: transaction.amount,
            amountTone: transaction.kind == .income ? .signedIncome : .signedExpense,
            showsChevron: false
        )
    }
}
