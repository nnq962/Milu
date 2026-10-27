//
//  FinanceModels.swift
//  Timi
//

import SwiftUI

// MARK: - Tài khoản

enum AccountType: String, CaseIterable, Identifiable {
    case cash, bank, eWallet, credit, savings

    var id: Self { self }

    var title: String {
        switch self {
        case .cash: "Tiền mặt"
        case .bank: "Ngân hàng"
        case .eWallet: "Ví điện tử"
        case .credit: "Thẻ tín dụng"
        case .savings: "Tiết kiệm"
        }
    }

    var icon: String {
        switch self {
        case .cash: "solar-banknote-linear"
        case .bank: "solar-buildings-3-linear"
        case .eWallet: "solar-qr-code-linear"
        case .credit: "solar-card-linear"
        case .savings: "solar-leaf-linear"
        }
    }
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
        case .food: "solar-chef-hat-minimalistic-linear"
        case .transport: "solar-car-linear"
        case .shopping: "solar-bag-linear"
        case .bills: "solar-bolt-linear"
        case .entertainment: "solar-clapperboard-play-linear"
        case .health: "solar-medical-kit-linear"
        case .education: "solar-book-linear"
        case .otherExpense: "solar-menu-dots-linear"
        case .salary: "solar-case-round-linear"
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

/// Khoản tiền đang cho vay; dư nợ phải thu được tính vào tài sản ròng.
struct LoanReceivable: Identifiable {
    let id = UUID()
    var borrower: String
    var outstandingAmount: Double
}

/// Scheduled amounts shown on the overview, separate from posted transactions/balances.
struct PaymentReminder: Identifiable {
    let id = UUID()
    var title: String
    var amount: Double
    var isIncome: Bool
    var dueDate: Date

    var dueDescription: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now),
                                           to: calendar.startOfDay(for: dueDate)).day ?? 0
        let date = "\(calendar.component(.day, from: dueDate))/\(calendar.component(.month, from: dueDate))"
        let remaining = days > 0 ? "còn \(days) ngày" : days == 0 ? "hôm nay" : "quá hạn \(-days) ngày"
        return "Hạn \(date) · \(remaining)"
    }
}
