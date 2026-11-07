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

struct TransactionFilterTabs: View {
    @Binding var selection: TransactionFilter

    var body: some View {
        // Pills in a tray, as Milu draws Giao dịch (Figma 239:7381; user pick 2026-11-07 after
        // trying iOS's segmented control).
        SegmentPills(selection: $selection, options: TransactionFilter.allCases) { $0.title }
    }
}
