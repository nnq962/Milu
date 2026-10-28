//
//  FinanceStore.swift
//  Timi
//

import Foundation
import Observation

/// Nguồn dữ liệu chung của app. Các màn hình đọc store qua `@Environment`
/// và tự vẽ lại khi dữ liệu thay đổi nhờ `@Observable`.
///
/// With a `FinanceDatabase` (the app), every change is also written to SwiftData at once and the
/// arrays are loaded from it at launch. Without one (previews), it lives in memory on sample data.
@Observable
final class FinanceStore {
    @ObservationIgnored private let database: FinanceDatabase?

    var accounts: [Account]
    var loans: [Loan]
    var paymentReminders: [PaymentReminder]
    var savingsGoals: [SavingsGoal]
    /// Luôn sắp xếp mới nhất lên đầu.
    var transactions: [FinanceTransaction]
    /// Nạp/rút hũ, mới nhất lên đầu.
    var goalTransfers: [GoalTransfer]

    init(accounts: [Account] = SampleData.accounts, transactions: [FinanceTransaction] = SampleData.transactions, loans: [Loan] = SampleData.loans, paymentReminders: [PaymentReminder] = SampleData.paymentReminders, savingsGoals: [SavingsGoal] = SampleData.savingsGoals) {
        self.accounts = accounts
        self.loans = loans
        self.paymentReminders = paymentReminders
        self.savingsGoals = savingsGoals
        self.transactions = transactions.sorted { $0.date > $1.date }
        self.goalTransfers = []
        self.database = nil
    }

    /// The app's store: opens the saved data, seeding the sample data on the very first launch.
    init(database: FinanceDatabase) {
        self.database = database
        if database.isEmpty { database.seed() }
        let snapshot = database.load()
        accounts = snapshot.accounts
        savingsGoals = snapshot.savingsGoals
        transactions = snapshot.transactions
        goalTransfers = snapshot.goalTransfers
        loans = snapshot.loans
        paymentReminders = snapshot.paymentReminders
    }

    /// Throws away every change and starts again from the sample data.
    func resetToSampleData() {
        guard let database else { return }
        database.resetToSampleData()
        let snapshot = database.load()
        accounts = snapshot.accounts
        savingsGoals = snapshot.savingsGoals
        transactions = snapshot.transactions
        goalTransfers = snapshot.goalTransfers
        loans = snapshot.loans
        paymentReminders = snapshot.paymentReminders
    }

    // MARK: - Tài khoản

    /// Accounts that count towards totals and reports.
    var countedAccounts: [Account] {
        accounts.filter { !$0.excluded }
    }

    var netWorth: Double {
        countedAccounts.reduce(0) { $0 + $1.balance } + totalLent - totalBorrowed + totalSaved
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
        countedAccounts.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance } + totalSaved
    }

    var paymentAccounts: [Account] {
        accounts.filter { AccountType.paymentTypes.contains($0.type) }
    }

    /// "Tổng số dư" của màn Tài khoản: tài khoản thanh toán và hũ, không gồm thẻ tín dụng.
    var paymentBalance: Double {
        paymentAccounts.filter { !$0.excluded }.reduce(0) { $0 + $1.balance } + totalSaved
    }

    func accounts(of type: AccountType) -> [Account] {
        accounts.filter { $0.type == type }
    }

    func add(_ account: Account) {
        accounts.append(account)
        database?.save(account)
    }

    /// Saves the edited details and, when `balance` differs from the current one, records the
    /// difference as an "Điều chỉnh số dư" transaction (kept out of reports), so the history
    /// still adds up to the balance.
    func update(_ account: Account, balance: Double) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        var edited = account
        edited.balance = accounts[index].balance
        accounts[index] = edited
        database?.save(edited)
        let delta = balance - edited.balance
        guard abs(delta) >= 1 else { return }
        add(FinanceTransaction(title: TransactionCategory.adjustmentIn.title, amount: abs(delta),
                               category: delta > 0 ? .adjustmentIn : .adjustmentOut,
                               accountID: account.id, date: .now))
    }

    /// Removes the account, every transaction recorded on it and its goal transfers (the goals
    /// keep what they hold).
    func delete(_ account: Account) {
        let ids = transactions.filter { $0.accountID == account.id }.map(\.id)
            + goalTransfers.filter { $0.accountID == account.id }.map(\.id)
        transactions.removeAll { $0.accountID == account.id }
        goalTransfers.removeAll { $0.accountID == account.id }
        accounts.removeAll { $0.id == account.id }
        database?.deleteAccount(id: account.id, transactionIDs: ids)
    }

    // MARK: - Hũ tiết kiệm

    func save(_ goal: SavingsGoal) {
        if let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) {
            savingsGoals[index] = goal
        } else {
            savingsGoals.append(goal)
        }
        database?.save(goal)
    }

    /// Removes the goal and its transfers; what it held is not given back to the accounts.
    func delete(_ goal: SavingsGoal) {
        let ids = goalTransfers.filter { $0.goalID == goal.id }.map(\.id)
        goalTransfers.removeAll { $0.goalID == goal.id }
        savingsGoals.removeAll { $0.id == goal.id }
        database?.deleteAccount(id: goal.id, transactionIDs: ids)
    }

    func goal(id: SavingsGoal.ID) -> SavingsGoal? {
        savingsGoals.first { $0.id == id }
    }

    /// Moves money between an account and a goal: one goes down by what the other goes up.
    func add(_ transfer: GoalTransfer) {
        guard let goalIndex = savingsGoals.firstIndex(where: { $0.id == transfer.goalID }) else { return }
        goalTransfers.append(transfer)
        goalTransfers.sort { $0.date > $1.date }
        savingsGoals[goalIndex].saved += transfer.goalDelta
        database?.save(savingsGoals[goalIndex])
        adjustBalance(of: transfer.accountID, by: -transfer.goalDelta)
        database?.save(transfer)
    }

    func transfers(of goal: SavingsGoal) -> [GoalTransfer] {
        goalTransfers.filter { $0.goalID == goal.id }
    }

    func transfers(of account: Account) -> [GoalTransfer] {
        goalTransfers.filter { $0.accountID == account.id }
    }

    /// Dư nợ thẻ/tài khoản âm cộng các khoản đi vay.
    var totalDebt: Double {
        countedAccounts.filter { $0.balance < 0 }.reduce(0) { $0 - $1.balance } + totalBorrowed
    }

    // MARK: - Vay nợ

    func save(_ loan: Loan) {
        if let index = loans.firstIndex(where: { $0.id == loan.id }) {
            loans[index] = loan
        } else {
            loans.append(loan)
        }
        database?.save(loan)
    }

    func delete(_ loan: Loan) {
        loans.removeAll { $0.id == loan.id }
        database?.deleteLoan(id: loan.id)
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
        database?.save(transaction)
    }

    /// Thay một giao dịch đã có và cập nhật lại số dư của tài khoản cũ lẫn mới.
    func update(_ transaction: FinanceTransaction) {
        guard let index = transactions.firstIndex(where: { $0.id == transaction.id }) else { return }
        let old = transactions[index]
        adjustBalance(of: old.accountID, by: -old.signedAmount)
        transactions[index] = transaction
        transactions.sort { $0.date > $1.date }
        adjustBalance(of: transaction.accountID, by: transaction.signedAmount)
        database?.save(transaction)
    }

    func transaction(id: FinanceTransaction.ID) -> FinanceTransaction? {
        transactions.first { $0.id == id }
    }

    func delete(_ transaction: FinanceTransaction) {
        // Chat cards can ask twice; only reverse the balance for a transaction that still exists.
        guard transactions.contains(where: { $0.id == transaction.id }) else { return }
        transactions.removeAll { $0.id == transaction.id }
        adjustBalance(of: transaction.accountID, by: -transaction.signedAmount)
        database?.deleteTransaction(id: transaction.id)
    }

    private func adjustBalance(of accountID: Account.ID, by delta: Double) {
        guard let index = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[index].balance += delta
        database?.save(accounts[index])
    }

    // MARK: - Thống kê

    func monthlyTransactions(for date: Date = .now) -> [FinanceTransaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }
    }

    func total(_ kind: TransactionKind, inMonthOf date: Date = .now) -> Double {
        monthlyTransactions(for: date).reportable
            .filter { $0.kind == kind }
            .reduce(0) { $0 + $1.amount }
    }

    /// Chi tiêu trong tháng gộp theo danh mục, lớn nhất lên đầu.
    func expensesByCategory(inMonthOf date: Date = .now) -> [CategoryTotal] {
        let expenses = monthlyTransactions(for: date).reportable.filter { $0.kind == .expense }
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
