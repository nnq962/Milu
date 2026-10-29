import SwiftUI

enum TransactionKind: String, CaseIterable, Identifiable {
    case expense, income

    var id: Self { self }

    var title: String {
        switch self {
        case .expense: "Chi tiêu"
        case .income: "Thu nhập"
        }
    }
}

enum TransactionCategory: String, CaseIterable, Identifiable {
    // Chi tiêu
    case food, transport, shopping, bills, entertainment, health, education, otherExpense
    // Thu nhập
    case salary, bonus, investment, otherIncome
    /// "Điều chỉnh số dư": the difference when the user corrects an account's balance. Never
    /// offered in the pickers and kept out of totals and reports.
    case adjustmentIn, adjustmentOut

    var id: Self { self }

    var kind: TransactionKind {
        switch self {
        case .salary, .bonus, .investment, .otherIncome, .adjustmentIn: .income
        default: .expense
        }
    }

    var title: String {
        switch self {
        case .food: "Ăn uống"
        case .transport: "Di chuyển"
        case .shopping: "Mua sắm"
        case .bills: "Hoá đơn"
        case .entertainment: "Giải trí"
        case .health: "Sức khoẻ"
        case .education: "Học tập"
        case .otherExpense: "Chi khác"
        case .salary: "Lương"
        case .bonus: "Thưởng"
        case .investment: "Đầu tư"
        case .otherIncome: "Thu khác"
        case .adjustmentIn, .adjustmentOut: "Điều chỉnh số dư"
        }
    }

    var icon: String {
        switch self {
        case .food: "hugeicons-restaurant-01"
        case .transport: "hugeicons-car-01"
        case .shopping: "hugeicons-shopping-bag-01"
        case .bills: "hugeicons-flash"
        case .entertainment: "hugeicons-film-02"
        case .health: "hugeicons-first-aid-kit"
        case .education: "hugeicons-book-02"
        case .otherExpense: "hugeicons-dashboard-square-01"
        case .salary: "hugeicons-money-bag-02"
        case .bonus: "hugeicons-gift"
        case .investment: "hugeicons-chart-increase"
        case .otherIncome: "hugeicons-money-add-02"
        case .adjustmentIn, .adjustmentOut: "hugeicons-pencil-edit-01"
        }
    }

    var color: Color {
        switch self {
        case .food: .orange
        case .transport: .blue
        case .shopping: .pink
        case .bills: .purple
        case .entertainment: .cyan
        case .health: .indigo
        case .education: .brown
        case .otherExpense, .otherIncome, .adjustmentIn, .adjustmentOut: .gray
        case .salary: .green
        case .bonus: .mint
        case .investment: .teal
        }
    }

    var isAdjustment: Bool { self == .adjustmentIn || self == .adjustmentOut }

    /// The categories a user can pick, without the balance adjustments.
    static var pickable: [TransactionCategory] { allCases.filter { !$0.isAdjustment } }

    static func categories(for kind: TransactionKind) -> [TransactionCategory] {
        pickable.filter { $0.kind == kind }
    }
}

struct FinanceTransaction: Identifiable, Hashable {
    /// Stable across launches: the same id is stored in the database.
    var id = UUID()
    var title: String
    /// Luôn là số dương; chiều tiền (thu hay chi) suy ra từ danh mục.
    var amount: Double
    var category: TransactionCategory
    var accountID: Account.ID
    var date: Date
    var note: String = ""

    var kind: TransactionKind { category.kind }

    /// Số tiền có dấu: thu là dương, chi là âm.
    var signedAmount: Double { kind == .income ? amount : -amount }
}

extension Sequence<FinanceTransaction> {
    /// What totals, charts and the assistant count: no balance adjustments, and nothing recorded on
    /// a locked account (`lockedAccounts`, from `FinanceStore.lockedAccountIDs`).
    func reportable(excluding lockedAccounts: Set<Account.ID>) -> [FinanceTransaction] {
        filter { !$0.category.isAdjustment && !lockedAccounts.contains($0.accountID) }
    }
}

extension FinanceTransaction {
    /// "+25.000.000đ" hoặc "-55.000đ"
    var signedAmountText: String {
        (kind == .income ? "+" : "-") + amount.vnd
    }
}
