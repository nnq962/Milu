import SwiftUI

/// The transactions of one calendar day.
struct DayTransactionsSheet: View {
    let date: Date

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let items = store.transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        NavigationStack {
            List {
                if items.isEmpty {
                    Text("Chưa có giao dịch trong ngày này.").font(Typography.body).foregroundStyle(Palette.secondaryText)
                } else {
                    ForEach(items) { TransactionRow(transaction: $0) }
                }
            }
            .navigationTitle(date.formatted(.dateTime.day().month().locale(.vietnam)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Đóng") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
