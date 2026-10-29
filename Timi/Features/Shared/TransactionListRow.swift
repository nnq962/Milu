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
            row(subtitle: "\(categoryText) · \(store.account(id: transaction.accountID)?.name ?? store.goal(id: transaction.accountID)?.name ?? "Hũ đã xoá")", trailing: nil)
        case .day:
            // Amount level with the title, the short date under it.
            row(subtitle: categoryText,
                trailing: Self.dayMonth(transaction.date))
        case .time:
            row(subtitle: categoryText,
                trailing: transaction.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam)))
        }
    }

    /// The second line. A named transaction: its category. One without a name already shows its
    /// category as the title: its note, or else the item's group ("Ăn uống"). Then, when it is not
    /// counted (left out by the user, or on a locked account), "Không tính".
    private var categoryText: String {
        if transaction.isAdjustment { return "Không tính vào báo cáo" }
        // "Chuyển sang MoMo", with the account's name as it is now: the title already says fee.
        if transaction.isTransferFee {
            let transfer = store.accountTransfer(id: AccountTransfer.id(ofFee: transaction.id))
            if let name = transfer.flatMap({ store.account(id: $0.toAccountID)?.name }) { return "Chuyển sang \(name)" }
            if !transaction.note.isEmpty { return transaction.note }
        }
        let base: String
        // A name that only repeats the category (saved before names went away) counts as none.
        if !transaction.title.isEmpty, transaction.title != store.categoryName(transaction.categoryID) {
            base = store.categoryName(transaction.categoryID)
        } else if !transaction.note.isEmpty {
            base = transaction.note.components(separatedBy: .newlines).first ?? ""
        } else {
            base = store.category(id: transaction.categoryID)?.parentID.map(store.categoryName) ?? ""
        }
        guard !store.isReportable(transaction) else { return base }
        return base.isEmpty ? "Không tính" : "\(base) · Không tính"
    }

    /// "27/10".
    static func dayMonth(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.day, .month], from: date)
        return String(format: "%02d/%02d", parts.day ?? 0, parts.month ?? 0)
    }

    private func row(subtitle: String, trailing: String?) -> some View {
        ListRow(
            icon: store.categoryIcon(transaction.categoryID),
            title: store.title(of: transaction),
            subtitle: subtitle,
            trailingSubtitle: trailing,
            amount: transaction.amount,
            amountTone: transaction.kind == .income ? .signedIncome : .signedExpense,
            showsChevron: false
        )
    }
}
