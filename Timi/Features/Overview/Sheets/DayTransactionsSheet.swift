import SwiftUI

/// The transactions of one calendar day, in a list block like Giao dịch's. The same list the
/// calendar shades the day by (`reportableTransactions`: transfer fees and loan interest in,
/// adjustments, excluded ones and locked accounts out), so a red day never opens empty and a
/// clear one never opens with rows (re-review 2026-10-31).
struct DayTransactionsSheet: View {
    let date: Date

    @Environment(FinanceStore.self) private var store
    @State private var viewing: FinanceTransaction?

    var body: some View {
        let day = Calendar.current.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 0)
        let items = store.reportableTransactions(in: day).sorted { $0.date > $1.date }
        SheetScaffold(title: date.relativeDayTitle.capitalizedFirstLetter) {
            if items.isEmpty {
                EmptyStateCard(icon: "hugeicons-inbox", title: "Chưa có giao dịch",
                               message: "Thu chi của ngày này sẽ hiện ở đây.")
            } else {
                VStack(spacing: 0) {
                    // A row opens to read, then change or delete from its pencil, as on Giao dịch
                    // (user report 2026-10-30: they did not open here).
                    // A transfer fee or loan interest has no page of its own: it shows, not opens.
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, transaction in
                        Group {
                            if store.transaction(id: transaction.id) != nil {
                                Button { viewing = transaction } label: {
                                    TransactionListRow(transaction: transaction, detail: .time)
                                }
                                .buttonStyle(.row)
                            } else {
                                TransactionListRow(transaction: transaction, detail: .time)
                            }
                        }
                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .listCard()
            }
        }
        .timiSheetStyle([.medium, .large])
        .sheet(item: $viewing) { TransactionDetailSheet(transactionID: $0.id) }
    }
}
