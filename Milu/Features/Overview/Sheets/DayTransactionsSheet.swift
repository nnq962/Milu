import SwiftUI

/// The transactions of one calendar day, in a list block like Giao dịch's. The same list the
/// calendar shades the day by (`reportableTransactions`: transfer fees and loan interest in,
/// adjustments, excluded ones and locked accounts out), so a day with figures never opens empty
/// and one without never opens with rows (re-review 2026-10-31).
struct DayTransactionsSheet: View {
    let date: Date

    @Environment(FinanceStore.self) private var store
    @State private var viewing: FinanceTransaction?

    var body: some View {
        let day = Calendar.current.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 0)
        let items = store.reportableTransactions(in: day).sorted { $0.date > $1.date }
        // The day as Giao dịch names it ("Thứ Hai, 3/11", the year in another year), so the same day
        // reads the same in both places (review 2026-11-08).
        SheetScaffold(title: date.transactionDayTitle) {
            if items.isEmpty {
                // The title says what the day holds; the line under it, the same every day, says
                // what this list leaves out, so a transfer or a loan just recorded is not looked
                // for here in vain (review 2026-11-08).
                EmptyStateCard(title: Calendar.current.isDateInToday(date) ? "Hôm nay chưa có thu chi" : "Ngày này không có thu chi",
                               message: "Chuyển khoản, vay nợ, tiền vào ra hũ và khoản \"Không tính\" không hiện ở đây.",
                               picture: IconCatalog.emojiName("📅"))
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
                        .separatorAbove(index > 0, order: index) { RowDivider() }
                    }
                }
                .listCard()
            }
        }
        .miluSheetStyle([.medium, .large])
        .sheet(item: $viewing) { TransactionDetailSheet(transactionID: $0.id) }
    }
}
