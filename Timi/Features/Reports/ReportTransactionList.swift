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
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Giao dịch · \(transactions.count)", style: .group) { EmptyView() }
                .padding(.bottom, Spacing.headerGap - Spacing.s)
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
                            TimiIcon("hugeicons-arrow-right-01", size: 16)
                                .foregroundStyle(Palette.secondary)
                        }
                        .padding(.horizontal, RowMetrics.horizontal)
                        .frame(minHeight: RowMetrics.minHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.row)
                    .overlay(alignment: .top) { RowDivider() }
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
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
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
