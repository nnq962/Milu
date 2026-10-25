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
        case .cash: "banknote.fill"
        case .bank: "building.columns.fill"
        case .eWallet: "qrcode"
        case .credit: "creditcard.fill"
        case .savings: "leaf.fill"
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
        case .food: "fork.knife"
        case .transport: "car.fill"
        case .shopping: "bag.fill"
        case .bills: "bolt.fill"
        case .entertainment: "film.fill"
        case .health: "cross.case.fill"
        case .education: "book.fill"
        case .otherExpense: "ellipsis"
        case .salary: "briefcase.fill"
        case .bonus: "gift.fill"
        case .investment: "chart.line.uptrend.xyaxis"
        case .otherIncome: "plus"
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
