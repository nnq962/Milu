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
    var loans: [LoanReceivable]
    var paymentReminders: [PaymentReminder]
    /// Luôn sắp xếp mới nhất lên đầu.
    var transactions: [FinanceTransaction]

    init(accounts: [Account] = SampleData.accounts, transactions: [FinanceTransaction] = SampleData.transactions, loans: [LoanReceivable] = SampleData.loans, paymentReminders: [PaymentReminder] = SampleData.paymentReminders) {
        self.accounts = accounts
        self.loans = loans
        self.paymentReminders = paymentReminders
        self.transactions = transactions.sorted { $0.date > $1.date }
    }

    // MARK: - Tài khoản

    var netWorth: Double {
        accounts.reduce(0) { $0 + $1.balance } + totalLent
    }

    var totalLent: Double {
        loans.reduce(0) { $0 + $1.outstandingAmount }
    }

    var totalAssets: Double {
        accounts.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance }
    }

    var totalDebt: Double {
        accounts.filter { $0.balance < 0 }.reduce(0) { $0 - $1.balance }
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

    func delete(_ transaction: FinanceTransaction) {
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

    /// Tổng chi theo từng ngày trong `days` ngày gần nhất (tính cả hôm nay).
    func dailyExpenses(lastDays days: Int = 7) -> [DailyTotal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let amount = transactions
                .filter { $0.kind == .expense && calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.amount }
            return DailyTotal(date: day, amount: amount)
        }
    }
}

struct CategoryTotal: Identifiable {
    let category: TransactionCategory
    let amount: Double

    var id: TransactionCategory { category }
}

struct DailyTotal: Identifiable {
    let date: Date
    let amount: Double

    var id: Date { date }
}
