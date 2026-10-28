import SwiftUI

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all, income, expense, transfer

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Tất cả"
        case .income: "Thu"
        case .expense: "Chi"
        case .transfer: "Chuyển khoản"
        }
    }

    func matches(_ transaction: FinanceTransaction) -> Bool {
        switch self {
        case .all: true
        case .income: transaction.kind == .income
        case .expense: transaction.kind == .expense
        // The app has no transfer transactions yet; the chip stays to match the design.
        case .transfer: false
        }
    }
}

struct FilterChips: View {
    @Binding var selection: TransactionFilter

    var body: some View {
        ChipRow(options: TransactionFilter.allCases, selection: $selection) { $0.title }
    }
}
