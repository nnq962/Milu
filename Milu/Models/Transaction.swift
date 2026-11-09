import SwiftUI

enum TransactionKind: String, CaseIterable, Identifiable, Codable {
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
    /// "Phí chuyển khoản": the fee of a transfer between two accounts, counted in reports as
    /// spending from the source; it lives on its transfer and has no row of its own.
    case transferFee
    /// "Lãi cho vay" / "Lãi đi vay": the interest of a loan's repayment (`LoanPayment`), counted
    /// in reports as income or spending; it lives on its repayment and has no row of its own.
    case loanInterestIncome, loanInterestExpense

    var id: Self { self }

    var kind: TransactionKind {
        switch self {
        case .salary, .bonus, .investment, .otherIncome, .adjustmentIn, .loanInterestIncome: .income
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
        case .transferFee: "Phí chuyển khoản"
        case .loanInterestIncome: "Lãi cho vay"
        case .loanInterestExpense: "Lãi đi vay"
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
        case .transferFee: "hugeicons-receipt-dollar"
        case .loanInterestIncome, .loanInterestExpense: "hugeicons-percent"
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
        case .otherExpense, .otherIncome, .adjustmentIn, .adjustmentOut, .transferFee,
             .loanInterestIncome, .loanInterestExpense: .gray
        case .salary: .green
        case .bonus: .mint
        case .investment: .teal
        }
    }

    var isAdjustment: Bool { self == .adjustmentIn || self == .adjustmentOut }
    /// The system's own categories, never picked by the user nor listed in "Hạng mục".
    var isSystem: Bool { isAdjustment || self == .transferFee || self == .loanInterestIncome || self == .loanInterestExpense }

    /// The built-in groups a user could pick before items existed, without the system ones.
    static var pickable: [TransactionCategory] { allCases.filter { !$0.isSystem } }

    static func categories(for kind: TransactionKind) -> [TransactionCategory] {
        pickable.filter { $0.kind == kind }
    }
}

/// Codable: a snapshot of it is kept in a saved chat's card (`ChatMessage.Card`).
struct FinanceTransaction: Identifiable, Hashable, Codable {
    /// Stable across launches: the same id is stored in the database.
    var id = UUID()
    /// Always empty now: a transaction has no name of its own and shows its category (user choice
    /// 2026-10-29). Names saved before ("Bún chả") are moved into `note` when the store opens.
    var title: String
    /// Luôn là số dương; chiều tiền (thu hay chi) theo `kind`.
    var amount: Double
    /// An item of "Hạng mục" ("food.breakfast"); a built-in group ("food") for a transaction from
    /// before items existed (kept as it was, user choice 2026-10-29); or a system category
    /// (`TransactionCategory`: balance adjustments, transfer fees).
    var categoryID: String
    var kind: TransactionKind
    var accountID: Account.ID
    var date: Date
    var note: String = ""
    /// When it was recorded (not `date`, when it happened); orders "Gần đây" in the category picker.
    var createdAt = Date.now
    /// "Không tính vào báo cáo", chosen by the user: still moves the balance, but stays out of
    /// totals, charts and the assistant, as a balance adjustment does.
    var isExcluded = false

    init(id: UUID = UUID(), title: String = "", amount: Double, categoryID: String, kind: TransactionKind,
         accountID: Account.ID, date: Date, note: String = "", isExcluded: Bool = false) {
        self.id = id
        self.title = title
        self.amount = amount
        self.categoryID = categoryID
        self.kind = kind
        self.accountID = accountID
        self.date = date
        self.note = note
        self.isExcluded = isExcluded
    }

    /// On a system category or a built-in group (sample data, the assistant, balance adjustments).
    init(id: UUID = UUID(), title: String = "", amount: Double, category: TransactionCategory,
         accountID: Account.ID, date: Date, note: String = "") {
        self.init(id: id, title: title, amount: amount, categoryID: category.rawValue, kind: category.kind,
                  accountID: accountID, date: date, note: note)
    }

    /// The system category it is on, if any.
    var systemCategory: TransactionCategory? {
        TransactionCategory(rawValue: categoryID).flatMap { $0.isSystem ? $0 : nil }
    }
    var isAdjustment: Bool { systemCategory?.isAdjustment == true }

    /// Số tiền có dấu: thu là dương, chi là âm.
    var signedAmount: Double { kind == .income ? amount : -amount }
}

extension Sequence<FinanceTransaction> {
    /// What totals, charts and the assistant count: no balance adjustments, nothing the user left
    /// out, and nothing recorded on a locked account (`lockedAccounts`, from
    /// `FinanceStore.lockedAccountIDs`).
    func reportable(excluding lockedAccounts: Set<Account.ID>) -> [FinanceTransaction] {
        filter { !$0.isAdjustment && !$0.isExcluded && !lockedAccounts.contains($0.accountID) }
    }
}

extension FinanceTransaction {
    /// "+25.000.000đ" hoặc "-55.000đ"
    var signedAmountText: String {
        (kind == .income ? "+" : "-") + amount.vnd
    }
}
