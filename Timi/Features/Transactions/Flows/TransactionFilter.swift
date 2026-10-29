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

    /// "Thu" and "Chi" list what their totals count, so not balance adjustments (only "Tất cả" does).
    func matches(_ transaction: FinanceTransaction) -> Bool {
        switch self {
        case .all: true
        case .income: transaction.kind == .income && !transaction.isAdjustment
        case .expense: transaction.kind == .expense && !transaction.isAdjustment
        // Transfers are not transactions: the list adds them itself (`AccountTransfer`).
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
