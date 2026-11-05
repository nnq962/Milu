import SwiftUI

/// The transactions of a report page (user request 2026-10-30): the first five in a card, then
/// "Xem tất cả" pushing the whole list. A tap opens the same sheet as on Giao dịch, to read and
/// change it; a transfer fee opens its transfer and loan interest its loan, as they have no row
/// of their own.
struct ReportTransactionList: View {
    let title: String
    let transactions: [FinanceTransaction]
    var limit = 5

    var body: some View {
        // A main page's heading, as every part of Báo cáo (strict review 2026-10-31).
        HeaderCard(title: "Giao dịch · \(transactions.count)") {
            VStack(spacing: 0) {
                TransactionRows(transactions: Array(transactions.prefix(limit)))
                if transactions.count > limit {
                    NavigationLink {
                        AllReportTransactionsView(title: title, transactions: transactions)
                    } label: {
                        HStack {
                            Text("Xem tất cả \(transactions.count) giao dịch")
                                .textRole(.body)
                            Spacer(minLength: Spacing.s)
                            RowChevron()
                        }
                        .padding(.horizontal, RowMetrics.horizontal)
                        .frame(minHeight: RowMetrics.minHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.row)
                    // No icon on this row, so the hairline starts where its words do.
                    .overlay(alignment: .top) { RowDivider(column: .none) }
                }
            }
            .listCard()
        }
    }
}

/// Every transaction of the list, in one card.
private struct AllReportTransactionsView: View {
    let title: String
    let transactions: [FinanceTransaction]

    var body: some View {
        ScrollView {
            TransactionRows(transactions: transactions)
                .listCard()
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        // The top margin of every detail page (strict review 2026-10-31).
        .contentMargins(.top, Spacing.s, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The rows, each opening its sheet.
private struct TransactionRows: View {
    let transactions: [FinanceTransaction]

    @Environment(FinanceStore.self) private var store
    @State private var opened: AccountDetailView.Activity?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                Button { opened = activity(for: transaction) } label: {
                    TransactionListRow(transaction: transaction, detail: .day)
                }
                .buttonStyle(.row)
                .overlay(alignment: .top) { if index > 0 { RowDivider() } }
            }
        }
        .sheet(item: $opened) { ActivityEditor(item: $0) }
    }

    /// What a row stands for: itself, or the transfer or repayment a fee or interest comes from.
    private func activity(for transaction: FinanceTransaction) -> AccountDetailView.Activity {
        if let transfer = store.accountTransfers.first(where: { $0.feeID == transaction.id }) {
            return .accountTransfer(transfer)
        }
        if let payment = store.loanPayments.first(where: { $0.interestID == transaction.id }) {
            return .loanPayment(payment)
        }
        return .transaction(transaction)
    }
}
