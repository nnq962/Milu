import SwiftUI

/// One transaction as a design-system `ListRow`: category icon, title, a subtitle and the signed
/// amount (income "+", spending "-" in red); with a day or time, that goes under the amount. Rows on a card; put `RowDivider` between them.
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
            // The app's one short date: "6/11", with the year in another (strict review 2026-10-31).
            row(subtitle: categoryText, trailing: transaction.date.shortDay)
        case .time:
            row(subtitle: categoryText,
                trailing: transaction.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam)))
        }
    }

    /// The second line, under the category: its note (first line), or else the item's group ("Ăn
    /// uống"), or else the account, never the title again ("Tiền nước / Tiền nước" said nothing;
    /// HIG review 2026-10-30). Then, when it is not counted (left out by the user, or on a locked
    /// account), "Không tính".
    private var categoryText: String {
        if transaction.isAdjustment { return "Không tính vào báo cáo" }
        let title = store.title(of: transaction)
        let note = transaction.note.components(separatedBy: .newlines).first ?? ""
        let group = store.category(id: transaction.categoryID)?.parentID.map(store.categoryName) ?? ""
        let account = store.account(id: transaction.accountID)?.name ?? store.goal(id: transaction.accountID)?.name ?? ""
        let base = [note, group, account].first { !$0.isEmpty && $0.compare(title, options: .caseInsensitive) != .orderedSame } ?? ""
        guard !store.isReportable(transaction) else { return base }
        return base.isEmpty ? "Không tính" : "\(base) · Không tính"
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
