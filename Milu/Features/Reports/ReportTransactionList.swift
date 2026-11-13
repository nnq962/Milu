import SwiftUI

/// The transactions of a report page (user request 2026-10-30): the first five in a card, then
/// "Xem tất cả" pushing the whole list. A tap opens the same sheet as on Giao dịch, to read and
/// change it; a transfer fee opens its transfer and loan interest its loan, as they have no row
/// of their own.
struct ReportTransactionList: View {
    let title: String
    let transactions: [FinanceTransaction]
    var limit = 5

    /// Pushed from the card rather than by its last row, so the row going (six down to five)
    /// does not close the open list (review 2026-11-08).
    @State private var isShowingAll = false

    var body: some View {
        // A main page's heading over the card, as every part of Báo cáo (user report 2026-11-08).
        OutsideHeaderSection(title: "Giao dịch · \(transactions.count)") {
            VStack(spacing: 0) {
                TransactionRows(transactions: Array(transactions.prefix(limit)))
                if transactions.count > limit {
                    Button { isShowingAll = true } label: {
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
                    .separatorAbove { RowDivider(column: .none) }
                }
            }
            .listCard()
        }
        .navigationDestination(isPresented: $isShowingAll) {
            AllReportTransactionsView(title: title, transactions: transactions)
        }
    }
}

/// Every transaction of the list, in one card.
private struct AllReportTransactionsView: View {
    let title: String
    let transactions: [FinanceTransaction]

    var body: some View {
        ScrollView {
            // Built as they scroll in: a month of a busy group is hundreds of rows (review
            // 2026-11-08, "Hiệu năng").
            TransactionRows(transactions: transactions, isLazy: true)
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
    var isLazy = false

    @Environment(FinanceStore.self) private var store
    @State private var opened: AccountDetailView.Activity?

    var body: some View {
        Group {
            if isLazy {
                LazyVStack(spacing: 0) { rows }
            } else {
                VStack(spacing: 0) { rows }
            }
        }
        .sheet(item: $opened) { ActivityEditor(item: $0) }
    }

    private var rows: some View {
        ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
            Button { opened = activity(for: transaction) } label: {
                TransactionListRow(transaction: transaction, detail: .day)
            }
            .buttonStyle(.row)
            .separatorAbove(index > 0, order: index) { RowDivider() }
        }
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
