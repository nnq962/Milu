import SwiftUI

/// The transactions of one calendar day, with the day's totals.
struct DayTransactionsSheet: View {
    let date: Date

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let items = store.transactions
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
        VStack(alignment: .leading, spacing: Spacing.l) {
            SheetHeader(title: date.relativeDayTitle.capitalizedFirstLetter)
            ScrollView {
                if items.isEmpty {
                    EmptyStateCard(icon: "solar-inbox-linear", title: "Chưa có giao dịch",
                                   message: "Ngày này chưa ghi khoản thu chi nào.")
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, transaction in
                            TransactionListRow(transaction: transaction, detail: .time)
                                .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                        }
                    }
                    .sleekCard(padding: 0)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, Spacing.page)
        .timiSheetStyle([.medium, .large])
    }
}
