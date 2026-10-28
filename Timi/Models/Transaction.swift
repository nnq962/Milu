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

    var id: Self { self }

    var kind: TransactionKind {
        switch self {
        case .salary, .bonus, .investment, .otherIncome: .income
        default: .expense
        }
    }

    var title: String {
        switch self {
        case .food: "Ăn uống"
        case .transport: "Di chuyển"
        case .shopping: "Mua sắm"
        case .bills: "Hóa đơn"
        case .entertainment: "Giải trí"
        case .health: "Sức khỏe"
        case .education: "Học tập"
        case .otherExpense: "Chi khác"
        case .salary: "Lương"
        case .bonus: "Thưởng"
        case .investment: "Đầu tư"
        case .otherIncome: "Thu khác"
        }
    }

    var icon: String {
        switch self {
        case .food: "solar-cup-hot-linear"
        case .transport: "solar-car-linear"
        case .shopping: "solar-bag-3-linear"
        case .bills: "solar-bolt-linear"
        case .entertainment: "solar-clapperboard-play-linear"
        case .health: "solar-medical-kit-linear"
        case .education: "solar-book-linear"
        case .otherExpense: "solar-menu-dots-linear"
        case .salary: "solar-wallet-money-linear"
        case .bonus: "solar-gift-linear"
        case .investment: "solar-graph-up-linear"
        case .otherIncome: "solar-add-linear"
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
        case .otherExpense, .otherIncome: .gray
        case .salary: .green
        case .bonus: .mint
        case .investment: .teal
        }
    }

    static func categories(for kind: TransactionKind) -> [TransactionCategory] {
        allCases.filter { $0.kind == kind }
    }
}

struct FinanceTransaction: Identifiable, Hashable {
    let id = UUID()
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

extension FinanceTransaction {
    /// "+25.000.000đ" hoặc "-55.000đ"
    var signedAmountText: String {
        (kind == .income ? "+" : "-") + amount.vnd
    }
}
