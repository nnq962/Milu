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
///
/// This file holds the data and loading; each area is an extension in its own file:
/// `FinanceStore+Accounts`, `+Goals`, `+Transfers`, `+Loans`, `+Contacts`, `+Transactions`,
/// `+Categories`, `+Reports`.
@Observable
final class FinanceStore {
    @ObservationIgnored let database: FinanceDatabase?

    var accounts: [Account]
    /// "Lưu trữ": out of every list, picker and total; reached from "Đã lưu trữ" on Tài khoản.
    var archivedAccounts: [Account]
    var loans: [Loan]
    /// Repayments of loans ("Thu nợ" / "Trả nợ"), newest first.
    var loanPayments: [LoanPayment]
    var paymentReminders: [PaymentReminder]
    var savingsGoals: [SavingsGoal]
    /// Luôn sắp xếp mới nhất lên đầu.
    var transactions: [FinanceTransaction]
    /// "Hạng mục" (Cài đặt): groups and their items, spending and income, in display order.
    var categories: [Category]
    /// Nạp/rút hũ, mới nhất lên đầu.
    var goalTransfers: [GoalTransfer]
    /// Chuyển khoản giữa hai tài khoản, mới nhất lên đầu.
    var accountTransfers: [AccountTransfer]
    /// "Danh bạ" (Cài đặt): who loans are with, in the order added; screens list `sortedContacts`.
    var contacts: [Contact]
    /// Relationships the user added in Danh bạ, in the order added; screens list `relationships`.
    var customRelationships: [Relationship]

    init(accounts: [Account] = SampleData.accounts, transactions: [FinanceTransaction] = SampleData.transactions, loans: [Loan] = SampleData.loans, paymentReminders: [PaymentReminder] = SampleData.paymentReminders, savingsGoals: [SavingsGoal] = SampleData.savingsGoals) {
        self.accounts = accounts
        self.archivedAccounts = []
        self.loans = loans
        self.loanPayments = []
        self.paymentReminders = paymentReminders
        self.savingsGoals = savingsGoals
        self.transactions = transactions.sorted { $0.date > $1.date }
        self.goalTransfers = SampleData.goalTransfers.sorted { $0.date > $1.date }
        self.accountTransfers = []
        self.categories = DefaultCategories.all
        self.contacts = SampleData.contacts
        self.customRelationships = []
        self.database = nil
    }

    /// The app's store: opens the saved data, seeding the sample data on the very first launch.
    init(database: FinanceDatabase) {
        self.database = database
        if database.isEmpty {
            database.seed()
        } else if !database.defaultCategoriesAdded {
            // A database from V1: its 12 categories became groups; add their items once.
            database.addMissingDefaultCategories()
        }
        database.replaceRetiredIcons()
        let snapshot = database.load()
        accounts = snapshot.accounts
        archivedAccounts = snapshot.archivedAccounts
        savingsGoals = snapshot.savingsGoals
        transactions = snapshot.transactions
        goalTransfers = snapshot.goalTransfers
        accountTransfers = snapshot.accountTransfers
        categories = snapshot.categories
        loans = snapshot.loans
        loanPayments = snapshot.loanPayments
        paymentReminders = snapshot.paymentReminders
        contacts = snapshot.contacts
        customRelationships = snapshot.relationships
        linkLoansToContacts()
        foldFeeRows()
        moveTitlesToNotes()
    }

    /// Throws away every change and starts again from the sample data.
    func resetToSampleData() {
        guard let database else { return }
        database.resetToSampleData()
        let snapshot = database.load()
        accounts = snapshot.accounts
        archivedAccounts = snapshot.archivedAccounts
        savingsGoals = snapshot.savingsGoals
        transactions = snapshot.transactions
        goalTransfers = snapshot.goalTransfers
        accountTransfers = snapshot.accountTransfers
        categories = snapshot.categories
        loans = snapshot.loans
        loanPayments = snapshot.loanPayments
        paymentReminders = snapshot.paymentReminders
        contacts = snapshot.contacts
        customRelationships = snapshot.relationships
    }
}
