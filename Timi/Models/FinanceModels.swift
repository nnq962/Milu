//
//  FinanceModels.swift
//  Timi
//

import SwiftUI

// MARK: - Tài khoản

enum AccountType: String, CaseIterable, Identifiable {
    case cash, bank, eWallet, credit

    var id: Self { self }

    /// Nhóm hiện ở mục "Tài khoản thanh toán"; thẻ tín dụng thuộc phần vay nợ.
    static let paymentTypes: [AccountType] = [.cash, .bank, .eWallet]

    var title: String {
        switch self {
        case .cash: "Tiền mặt"
        case .bank: "Ngân hàng"
        case .eWallet: "Ví điện tử"
        case .credit: "Thẻ tín dụng"
        }
    }

    var icon: String {
        switch self {
        case .cash: "solar-banknote-2-linear"
        case .bank: "solar-buildings-2-linear"
        case .eWallet: "solar-smartphone-linear"
        case .credit: "solar-card-linear"
        }
    }

    var defaultColor: Color {
        switch self {
        case .cash: .orange
        case .bank: .green
        case .eWallet: .pink
        case .credit: .indigo
        }
    }
}

// MARK: - Hũ tiết kiệm

enum GoalIcon: String, CaseIterable, Identifiable {
    case piggyBank = "mdi-piggy-bank"
    case car = "mdi-car-outline"
    case airplane = "mdi-airplane"

    var id: Self { self }

    var title: String {
        switch self {
        case .piggyBank: "Tiết kiệm"
        case .car: "Xe cộ"
        case .airplane: "Du lịch"
        }
    }
}

/// Hũ tiết kiệm có mục tiêu; số đã để dành được tính vào tài sản.
struct SavingsGoal: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: GoalIcon
    var saved: Double
    var target: Double

    var progress: Double { target > 0 ? min(saved / target, 1) : 0 }
    var remaining: Double { max(target - saved, 0) }
}

struct Account: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var type: AccountType
    /// Số dư hiện tại. Thẻ tín dụng mang số âm (đang nợ).
    var balance: Double
    var color: Color
    /// Dòng mô tả phụ, VD: "•••• 4821".
    var detail: String
    /// Chỉ thẻ tín dụng: hạn mức và hạn thanh toán kỳ này, hiện ở mục Đi vay.
    var creditLimit: Double? = nil
    var paymentDueDate: Date? = nil
}

// MARK: - Giao dịch

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

// MARK: - Vay nợ

enum LoanDirection: String, CaseIterable, Identifiable {
    case lent, borrowed

    var id: Self { self }

    var title: String {
        switch self {
        case .lent: "Cho vay"
        case .borrowed: "Đi vay"
        }
    }
}

/// Khoản cho vay hoặc đi vay với người khác. Cho vay cộng vào tài sản ròng, đi vay tính vào nợ.
struct Loan: Identifiable, Hashable {
    let id = UUID()
    /// Người vay hoặc người cho mình vay.
    var name: String
    var direction: LoanDirection
    /// Số tiền gốc ban đầu.
    var principal: Double
    /// Số còn phải thu (cho vay) hoặc còn phải trả (đi vay).
    var outstanding: Double
    var dueDate: Date?

    var isSettled: Bool { outstanding <= 0 }
    var paidRatio: Double { principal > 0 ? min(max((principal - outstanding) / principal, 0), 1) : 0 }
}

/// Scheduled amounts shown on the overview, separate from posted transactions/balances.
struct PaymentReminder: Identifiable {
    enum Avatar {
        case initials(String)
        case icon(String)
    }

    let id = UUID()
    var title: String
    var amount: Double
    var isIncome: Bool
    var dueDate: Date
    /// Dòng phụ ở mục Cần chú ý của tab Vay nợ, VD: "Cho vay · Minh Trần".
    var detail: String = ""
    var avatar: Avatar = .icon("solar-calendar-linear")

    var dueDescription: String { dueDate.dueDescription }
}
