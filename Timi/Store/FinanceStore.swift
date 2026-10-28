//
//  FinanceStore.swift
//  Timi
//

import Foundation
import Observation

/// Nguồn dữ liệu chung của app. Các màn hình đọc store qua `@Environment`
/// và tự vẽ lại khi dữ liệu thay đổi nhờ `@Observable`.
@Observable
final class FinanceStore {
    var accounts: [Account]
    var loans: [Loan]
    var paymentReminders: [PaymentReminder]
    var savingsGoals: [SavingsGoal]
    /// Luôn sắp xếp mới nhất lên đầu.
    var transactions: [FinanceTransaction]

    init(accounts: [Account] = SampleData.accounts, transactions: [FinanceTransaction] = SampleData.transactions, loans: [Loan] = SampleData.loans, paymentReminders: [PaymentReminder] = SampleData.paymentReminders, savingsGoals: [SavingsGoal] = SampleData.savingsGoals) {
        self.accounts = accounts
        self.loans = loans
        self.paymentReminders = paymentReminders
        self.savingsGoals = savingsGoals
        self.transactions = transactions.sorted { $0.date > $1.date }
    }

    // MARK: - Tài khoản

    var netWorth: Double {
        accounts.reduce(0) { $0 + $1.balance } + totalLent - totalBorrowed + totalSaved
    }

    /// Số còn phải thu từ các khoản cho vay chưa tất toán.
    var totalLent: Double {
        loans.filter { $0.direction == .lent }.reduce(0) { $0 + $1.outstanding }
    }

    /// Số còn phải trả của các khoản đi vay (không gồm thẻ tín dụng).
    var totalBorrowed: Double {
        loans.filter { $0.direction == .borrowed }.reduce(0) { $0 + $1.outstanding }
    }

    var totalSaved: Double {
        savingsGoals.reduce(0) { $0 + $1.saved }
    }

    /// Số dư dương của các tài khoản cộng tiền trong hũ.
    var totalAssets: Double {
        accounts.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance } + totalSaved
    }

    var paymentAccounts: [Account] {
        accounts.filter { AccountType.paymentTypes.contains($0.type) }
    }

    /// "Tổng số dư" của màn Tài khoản: tài khoản thanh toán và hũ, không gồm thẻ tín dụng.
    var paymentBalance: Double {
        paymentAccounts.reduce(0) { $0 + $1.balance } + totalSaved
    }

    func accounts(of type: AccountType) -> [Account] {
        accounts.filter { $0.type == type }
    }

    /// Ngày của giao dịch gần nhất thuộc tài khoản này.
    func lastActivity(of account: Account) -> Date? {
        transactions.first { $0.accountID == account.id }?.date
    }

    func add(_ account: Account) {
        accounts.append(account)
    }

    // MARK: - Hũ tiết kiệm

    func save(_ goal: SavingsGoal) {
        if let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) {
            savingsGoals[index] = goal
        } else {
            savingsGoals.append(goal)
        }
    }

    func delete(_ goal: SavingsGoal) {
        savingsGoals.removeAll { $0.id == goal.id }
    }

    /// Dư nợ thẻ/tài khoản âm cộng các khoản đi vay.
    var totalDebt: Double {
        accounts.filter { $0.balance < 0 }.reduce(0) { $0 - $1.balance } + totalBorrowed
    }

    // MARK: - Vay nợ

    func save(_ loan: Loan) {
        if let index = loans.firstIndex(where: { $0.id == loan.id }) {
            loans[index] = loan
        } else {
            loans.append(loan)
        }
    }

    func delete(_ loan: Loan) {
        loans.removeAll { $0.id == loan.id }
    }

    func account(id: Account.ID) -> Account? {
        accounts.first { $0.id == id }
    }

    func accountTransactions(_ account: Account) -> [FinanceTransaction] {
        transactions.filter { $0.accountID == account.id }
    }

    // MARK: - Thêm / xoá giao dịch

    func add(_ transaction: FinanceTransaction) {
        transactions.append(transaction)
        transactions.sort { $0.date > $1.date }
        adjustBalance(of: transaction.accountID, by: transaction.signedAmount)
    }

    /// Thay một giao dịch đã có và cập nhật lại số dư của tài khoản cũ lẫn mới.
    func update(_ transaction: FinanceTransaction) {
        guard let index = transactions.firstIndex(where: { $0.id == transaction.id }) else { return }
        let old = transactions[index]
        adjustBalance(of: old.accountID, by: -old.signedAmount)
        transactions[index] = transaction
        transactions.sort { $0.date > $1.date }
        adjustBalance(of: transaction.accountID, by: transaction.signedAmount)
    }

    func transaction(id: FinanceTransaction.ID) -> FinanceTransaction? {
        transactions.first { $0.id == id }
    }

    func delete(_ transaction: FinanceTransaction) {
        // Chat cards can ask twice; only reverse the balance for a transaction that still exists.
        guard transactions.contains(where: { $0.id == transaction.id }) else { return }
        transactions.removeAll { $0.id == transaction.id }
        adjustBalance(of: transaction.accountID, by: -transaction.signedAmount)
    }

    private func adjustBalance(of accountID: Account.ID, by delta: Double) {
        guard let index = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[index].balance += delta
    }

    // MARK: - Thống kê

    func monthlyTransactions(for date: Date = .now) -> [FinanceTransaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }
    }

    func total(_ kind: TransactionKind, inMonthOf date: Date = .now) -> Double {
        monthlyTransactions(for: date)
            .filter { $0.kind == kind }
            .reduce(0) { $0 + $1.amount }
    }

    /// Chi tiêu trong tháng gộp theo danh mục, lớn nhất lên đầu.
    func expensesByCategory(inMonthOf date: Date = .now) -> [CategoryTotal] {
        let expenses = monthlyTransactions(for: date).filter { $0.kind == .expense }
        return Dictionary(grouping: expenses, by: \.category)
            .map { category, items in
                CategoryTotal(category: category, amount: items.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.amount > $1.amount }
    }
}

struct CategoryTotal: Identifiable {
    let category: TransactionCategory
    let amount: Double

    var id: TransactionCategory { category }
}
