import SwiftUI

/// One transaction as a design-system `ListRow`: category icon, title, a subtitle and the signed
/// amount (income "+", spending "-" in red). Rows on a white card; put `RowDivider` between them.
struct TransactionListRow: View {
    let transaction: FinanceTransaction
    /// What follows the category in the subtitle: the account, or the day when the account is known.
    var detail: Detail = .account

    enum Detail { case account, day, time }

    @Environment(FinanceStore.self) private var store

    var body: some View {
        ListRow(
            icon: transaction.category.icon,
            title: transaction.title,
            subtitle: "\(transaction.category.title) · \(detailText)",
            amount: transaction.amount,
            amountTone: transaction.kind == .income ? .signedIncome : .signedExpense,
            showsChevron: false
        )
    }

    private var detailText: String {
        switch detail {
        case .account: store.account(id: transaction.accountID)?.name ?? "—"
        case .day: transaction.date.relativeDayTitle
        case .time: transaction.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
        }
    }
}
