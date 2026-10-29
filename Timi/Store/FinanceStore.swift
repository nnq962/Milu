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
    /// "Lưu trữ": out of every list, picker and total; reached from "Đã lưu trữ" on Tài khoản.
    var archivedAccounts: [Account]
    var loans: [Loan]
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
        self.paymentReminders = paymentReminders
        self.savingsGoals = savingsGoals
        self.transactions = transactions.sorted { $0.date > $1.date }
        self.goalTransfers = []
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
        paymentReminders = snapshot.paymentReminders
        contacts = snapshot.contacts
        customRelationships = snapshot.relationships
    }

    // MARK: - Tài khoản

    /// Accounts that count towards totals and reports.
    var countedAccounts: [Account] {
        accounts.filter { !$0.isLocked }
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

    /// What open goals hold (a closed goal is empty: its money was spent or taken out).
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
        paymentAccounts.filter { !$0.isLocked }.reduce(0) { $0 + $1.balance } + totalSaved
    }

    /// Payment accounts that are locked: kept out of `paymentBalance`.
    var lockedPaymentAccounts: [Account] {
        paymentAccounts.filter(\.isLocked)
    }

    /// Locked accounts: out of totals and out of reports.
    var lockedAccountIDs: Set<Account.ID> {
        Set((accounts + archivedAccounts).filter(\.isLocked).map(\.id))
    }

    /// Whether a transaction counts in totals, charts and the assistant.
    func isReportable(_ transaction: FinanceTransaction) -> Bool {
        !transaction.isAdjustment && !transaction.isExcluded && !lockedAccountIDs.contains(transaction.accountID)
    }

    /// Accounts money can be recorded on: every account but the locked ones.
    var usableAccounts: [Account] {
        accounts.filter { !$0.isLocked }
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
        persist {
            guard let current = self.account(id: account.id) else { return }
            var edited = account
            edited.balance = current.balance
            replace(edited)
            let delta = balance - edited.balance
            guard abs(delta) >= 1 else { return }
            add(FinanceTransaction(amount: abs(delta),
                                   category: delta > 0 ? .adjustmentIn : .adjustmentOut,
                                   accountID: account.id, date: .now))
        }
    }

    /// Writes an account back wherever it lives (in use or archived).
    private func replace(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        } else if let index = archivedAccounts.firstIndex(where: { $0.id == account.id }) {
            archivedAccounts[index] = account
        }
        database?.save(account)
    }

    /// Whether anything was ever recorded on the account; such an account is archived, not deleted.
    func hasHistory(_ account: Account) -> Bool {
        transactions.contains { $0.accountID == account.id } || goalTransfers.contains { $0.accountID == account.id }
            || accountTransfers.contains { $0.fromAccountID == account.id || $0.toAccountID == account.id }
    }

    /// Hides an account with history: out of lists, pickers and totals, history kept. What it
    /// holds simply stops counting (user choice 2026-10-29: no step to bring it to 0đ first).
    func archive(_ account: Account) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        var archived = accounts.remove(at: index)
        archived.archivedAt = .now
        archivedAccounts.insert(archived, at: 0)
        database?.save(archived)
    }

    /// Puts an archived account back at the end of the list.
    func unarchive(_ account: Account) {
        guard let index = archivedAccounts.firstIndex(where: { $0.id == account.id }) else { return }
        var restored = archivedAccounts.remove(at: index)
        restored.archivedAt = nil
        accounts.append(restored)
        persist {
            database?.save(restored)
            database?.moveToEnd(restored.id)
        }
    }

    /// Deletes an account that has no history (see `hasHistory`); one with history is archived
    /// instead, so no balance, report or goal history changes (user choice 2026-10-29).
    func delete(_ account: Account) {
        guard !hasHistory(account) else { return }
        accounts.removeAll { $0.id == account.id }
        archivedAccounts.removeAll { $0.id == account.id }
        database?.deleteAccount(id: account.id)
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

    /// Removes the goal. What it still holds goes back to `returningTo` first, as a withdrawal, so
    /// no money disappears (user choice 2026-10-29). Its deposits, withdrawals and spending stay in
    /// the accounts' history ("Nạp vào hũ đã xoá"), so their balances still add up.
    func delete(_ goal: SavingsGoal, returningTo accountID: Account.ID? = nil) {
        persist {
            if let saved = self.goal(id: goal.id)?.saved, saved >= 1 {
                // Never drop money: it has to go somewhere first (a closed goal is always empty).
                guard let accountID, acceptsMoney(accountID), self.goal(id: goal.id)?.isClosed == false else { return }
                add(GoalTransfer(goalID: goal.id, accountID: accountID, direction: .withdrawal,
                                 amount: saved, date: .now))
            }
            savingsGoals.removeAll { $0.id == goal.id }
            database?.deleteAccount(id: goal.id)
        }
    }

    /// Goals still being saved for, and those that reached their target.
    var activeGoals: [SavingsGoal] { savingsGoals.filter { !$0.isClosed } }
    /// Closed goals, the most recently closed first.
    var completedGoals: [SavingsGoal] {
        savingsGoals.filter(\.isClosed).sorted { ($0.closedAt ?? .distantPast) > ($1.closedAt ?? .distantPast) }
    }

    /// "Đóng hũ" on a reopened goal that holds nothing: back to "Hũ đã hoàn thành" with the note it
    /// ended with before (kept while it was open).
    func closeEmpty(_ goalID: SavingsGoal.ID) {
        guard let goal = goal(id: goalID), !goal.isClosed, goal.saved < 1 else { return }
        close(goalID, note: goal.closingNote.isEmpty ? "Đã hoàn thành" : goal.closingNote)
    }

    /// Ends a goal: it leaves the cards and totals for "Hũ đã hoàn thành", saying how it ended.
    func close(_ goalID: SavingsGoal.ID, note: String) {
        guard let index = savingsGoals.firstIndex(where: { $0.id == goalID }) else { return }
        savingsGoals[index].closedAt = .now
        savingsGoals[index].closingNote = note
        database?.save(savingsGoals[index])
    }

    /// "Dùng tiền": spends from the goal (an expense recorded on the goal itself, so it counts in
    /// reports), sends whatever is left to `leftoverAccount`, then closes the goal. Like any
    /// transaction it has no name; the closing note says the category ("Đã dùng: Mua xe máy").
    func spend(from goal: SavingsGoal, categoryID: String, amount: Double,
               date: Date, leftoverAccount: Account.ID?) {
        persist {
            // Spend no more than the goal holds, and leave nothing behind in a closed goal.
            guard let saved = self.goal(id: goal.id)?.saved, amount > 0, amount <= saved else { return }
            if saved - amount >= 1 {
                guard let leftoverAccount, acceptsMoney(leftoverAccount) else { return }
            }
            add(FinanceTransaction(amount: amount, categoryID: categoryID, kind: .expense,
                                   accountID: goal.id, date: date))
            let left = (self.goal(id: goal.id)?.saved ?? 0)
            var note = "Đã dùng: \(categoryName(categoryID))"
            if left >= 1, let leftoverAccount {
                add(GoalTransfer(goalID: goal.id, accountID: leftoverAccount, direction: .withdrawal,
                                 amount: left, date: date))
                note += " · \(left.vndCompact) về \(account(id: leftoverAccount)?.name ?? "tài khoản")"
            }
            close(goal.id, note: note)
        }
    }

    /// Transactions recorded on a goal ("Dùng tiền").
    func goalTransactions(_ goal: SavingsGoal) -> [FinanceTransaction] {
        transactions.filter { $0.accountID == goal.id }
    }

    func goal(id: SavingsGoal.ID) -> SavingsGoal? {
        savingsGoals.first { $0.id == id }
    }

    /// Moves money between an account and a goal: one goes down by what the other goes up.
    func add(_ transfer: GoalTransfer) {
        persist {
            // An open goal and an unlocked account in use, or money would move into something hidden.
            guard let goal = goal(id: transfer.goalID), !goal.isClosed, acceptsMoney(transfer.accountID),
                  transfer.amount > 0, goal.saved + transfer.goalDelta >= 0 else { return }
            goalTransfers.append(transfer)
            goalTransfers.sort { $0.date > $1.date }
            adjustBalance(of: transfer.goalID, by: transfer.goalDelta)
            adjustBalance(of: transfer.accountID, by: -transfer.goalDelta)
            database?.save(transfer)
        }
    }

    /// False for what a closed goal holds in its history (its spending and its transfers): it can
    /// only change once the goal is reopened, or money would come back into a goal no one sees.
    func isEditable(_ transaction: FinanceTransaction) -> Bool { readOnlyReason(transaction) == nil }

    func isEditable(_ transfer: GoalTransfer) -> Bool { readOnlyReason(transfer) == nil }

    /// Why a transaction cannot be changed, in the words shown to the user; nil when it can. History
    /// on an archived account or a closed goal is frozen until it is restored or reopened, so money
    /// never moves into something hidden; a deleted goal's spending has nowhere to go back to.
    func readOnlyReason(_ transaction: FinanceTransaction) -> String? {
        if let account = account(id: transaction.accountID) {
            return account.isArchived ? Self.archivedReason : nil
        }
        guard let goal = goal(id: transaction.accountID) else { return Self.deletedGoalReason }
        return goal.isClosed ? Self.closedGoalReason : nil
    }

    func readOnlyReason(_ transfer: GoalTransfer) -> String? {
        guard let goal = goal(id: transfer.goalID) else { return Self.deletedGoalReason }
        if goal.isClosed { return Self.closedGoalReason }
        if account(id: transfer.accountID)?.isArchived == true { return Self.archivedReason }
        return nil
    }

    static let archivedReason = "Tài khoản đã lưu trữ. Khôi phục tài khoản để sửa."
    static let closedGoalReason = "Hũ đã hoàn thành. Mở lại hũ để sửa."
    static let deletedGoalReason = "Hũ đã bị xoá nên không sửa được."

    /// Whether `new` may replace `old`: an account in use and not archived, or the same open goal
    /// still spending no more than it holds.
    private func accepts(_ new: FinanceTransaction, replacing old: FinanceTransaction) -> Bool {
        if let account = account(id: new.accountID) { return !account.isArchived }
        guard let goal = goal(id: new.accountID), !goal.isClosed, new.accountID == old.accountID,
              new.kind == .expense, old.kind == .expense else { return false }
        return new.amount <= goal.saved + old.amount
    }

    /// Where money can be moved to or from: an unlocked account in use.
    private func acceptsMoney(_ accountID: Account.ID) -> Bool {
        accounts.contains { $0.id == accountID && !$0.isLocked }
    }

    /// "Rút hết về tài khoản": everything out, then the goal closes, saved as one.
    func withdrawAll(from goal: SavingsGoal, to accountID: Account.ID, date: Date, note: String) {
        persist {
            guard let saved = self.goal(id: goal.id)?.saved, saved >= 1, acceptsMoney(accountID) else { return }
            add(GoalTransfer(goalID: goal.id, accountID: accountID, direction: .withdrawal,
                             amount: saved, date: date, note: note))
            close(goal.id, note: "Đã rút về \(account(id: accountID)?.name ?? "tài khoản")")
        }
    }

    /// Replaces a deposit or withdrawal: the old one is undone on both sides, the new one applied.
    func update(_ transfer: GoalTransfer) {
        persist {
            guard let index = goalTransfers.firstIndex(where: { $0.id == transfer.id }),
                  isEditable(goalTransfers[index]),
                  transfer.goalID == goalTransfers[index].goalID,
                  transfer.accountID == goalTransfers[index].accountID || acceptsMoney(transfer.accountID),
                  // The goal cannot go below 0đ with the new amount.
                  (goal(id: transfer.goalID)?.saved ?? 0) - goalTransfers[index].goalDelta + transfer.goalDelta >= 0
            else { return }
            let old = goalTransfers[index]
            adjustBalance(of: old.goalID, by: -old.goalDelta)
            adjustBalance(of: old.accountID, by: old.goalDelta)
            goalTransfers[index] = transfer
            goalTransfers.sort { $0.date > $1.date }
            adjustBalance(of: transfer.goalID, by: transfer.goalDelta)
            adjustBalance(of: transfer.accountID, by: -transfer.goalDelta)
            database?.save(transfer)
        }
    }

    /// Undoes a deposit or withdrawal on both sides.
    func delete(_ transfer: GoalTransfer) {
        persist {
            guard goalTransfers.contains(where: { $0.id == transfer.id }), isEditable(transfer),
                  (goal(id: transfer.goalID)?.saved ?? 0) - transfer.goalDelta >= 0 else { return }
            goalTransfers.removeAll { $0.id == transfer.id }
            adjustBalance(of: transfer.goalID, by: -transfer.goalDelta)
            adjustBalance(of: transfer.accountID, by: transfer.goalDelta)
            database?.deleteTransaction(id: transfer.id)
        }
    }

    /// Puts a closed goal back among the cards, so its history can be changed again.
    /// Keeps the closing note, so "Đóng hũ" can put it back as it was.
    func reopen(_ goalID: SavingsGoal.ID) {
        guard let index = savingsGoals.firstIndex(where: { $0.id == goalID }) else { return }
        savingsGoals[index].closedAt = nil
        database?.save(savingsGoals[index])
    }

    func transfers(of goal: SavingsGoal) -> [GoalTransfer] {
        goalTransfers.filter { $0.goalID == goal.id }
    }

    func transfers(of account: Account) -> [GoalTransfer] {
        goalTransfers.filter { $0.accountID == account.id }
    }

    // MARK: - Chuyển khoản

    func accountTransfer(id: AccountTransfer.ID) -> AccountTransfer? {
        accountTransfers.first { $0.id == id }
    }

    /// Transfers into or out of an account.
    func accountTransfers(of account: Account) -> [AccountTransfer] {
        accountTransfers.filter { $0.fromAccountID == account.id || $0.toAccountID == account.id }
    }

    /// Why a transfer cannot be changed; nil when it can. An archived account on either side
    /// freezes it, as its other history. A locked one does not: like a transaction on a locked
    /// account it can change, keeping that account on its side (`accepts(_:replacing:)`).
    func readOnlyReason(_ transfer: AccountTransfer) -> String? {
        let sides = [transfer.fromAccountID, transfer.toAccountID].compactMap { account(id: $0) }
        return sides.count < 2 || sides.contains(where: \.isArchived) ? Self.archivedReason : nil
    }

    /// Two different accounts, a positive amount and a fee of 0 or more. Each side is an unlocked
    /// account in use, or (when changing a transfer) the locked one it already had on that side.
    private func accepts(_ transfer: AccountTransfer, replacing old: AccountTransfer? = nil) -> Bool {
        func fits(_ id: Account.ID, was oldID: Account.ID?) -> Bool {
            acceptsMoney(id) || (id == oldID && accounts.contains { $0.id == id })
        }
        return transfer.fromAccountID != transfer.toAccountID && transfer.amount > 0 && transfer.fee >= 0
            && fits(transfer.fromAccountID, was: old?.fromAccountID) && fits(transfer.toAccountID, was: old?.toAccountID)
    }

    /// Moves `amount` from one account to the other; a fee is spent from the source as well.
    func add(_ transfer: AccountTransfer) {
        persist {
            guard accepts(transfer) else { return }
            accountTransfers.append(transfer)
            accountTransfers.sort { $0.date > $1.date }
            apply(transfer, sign: 1)
            database?.save(transfer)
        }
    }

    /// Replaces a transfer: the old one is undone on both accounts, the new one applied.
    func update(_ transfer: AccountTransfer) {
        persist {
            guard let index = accountTransfers.firstIndex(where: { $0.id == transfer.id }),
                  readOnlyReason(accountTransfers[index]) == nil else { return }
            let old = accountTransfers[index]
            apply(old, sign: -1)
            guard accepts(transfer, replacing: old) else {
                apply(old, sign: 1)
                return
            }
            accountTransfers[index] = transfer
            accountTransfers.sort { $0.date > $1.date }
            apply(transfer, sign: 1)
            database?.save(transfer)
        }
    }

    func delete(_ transfer: AccountTransfer) {
        persist {
            guard accountTransfers.contains(where: { $0.id == transfer.id }), readOnlyReason(transfer) == nil else { return }
            accountTransfers.removeAll { $0.id == transfer.id }
            apply(transfer, sign: -1)
            database?.deleteTransaction(id: transfer.id)
        }
    }

    /// Applies (1) or undoes (-1) a transfer on both balances: the source pays the amount and
    /// the fee, the destination gets the amount.
    private func apply(_ transfer: AccountTransfer, sign: Double) {
        adjustBalance(of: transfer.fromAccountID, by: -(transfer.amount + transfer.fee) * sign)
        adjustBalance(of: transfer.toAccountID, by: transfer.amount * sign)
    }

    /// Fees were once a separate "Phí chuyển khoản" expense next to their transfer (user choice
    /// 2026-10-29: only the transfer is kept). Each such row goes; its transfer already holds the
    /// fee, and the source's balance already paid it, so nothing else moves.
    private func foldFeeRows() {
        let feeIDs = Set(accountTransfers.filter { $0.fee > 0 }.map(\.feeID))
        let rows = transactions.filter { feeIDs.contains($0.id) }
        guard !rows.isEmpty else { return }
        persist {
            transactions.removeAll { feeIDs.contains($0.id) }
            for row in rows { database?.deleteTransaction(id: row.id) }
        }
    }

    /// Transactions once had a name of their own ("Bún chả"); they now show their category (user
    /// choice 2026-10-29). A name that says more than the category goes into the note, before
    /// what the note had, so nothing is lost; then the name is cleared.
    private func moveTitlesToNotes() {
        let named = transactions.indices.filter { !transactions[$0].title.isEmpty }
        guard !named.isEmpty else { return }
        persist {
            for index in named {
                var transaction = transactions[index]
                if transaction.title != categoryName(transaction.categoryID) {
                    transaction.note = [transaction.title, transaction.note].filter { !$0.isEmpty }.joined(separator: "\n")
                }
                transaction.title = ""
                transactions[index] = transaction
                database?.save(transaction)
            }
        }
    }

    /// Transfer fees as the spending they are, for totals and reports only: a fee has no row of its
    /// own in any list (it shows on its transfer).
    private func feeExpenses(inMonthOf date: Date) -> [FinanceTransaction] {
        accountTransfers
            .filter { $0.fee > 0 && Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }
            .map(\.feeExpense)
    }

    /// Dư nợ thẻ/tài khoản âm cộng các khoản đi vay.
    var totalDebt: Double {
        countedAccounts.filter { $0.balance < 0 }.reduce(0) { $0 - $1.balance } + totalBorrowed
    }

    // MARK: - Vay nợ

    /// Also files the loan under the person its name names (see `link`); a person the app made who
    /// is left with no loan goes. A new loan (not from before the app) moves its principal out of
    /// or into its account; changing it undoes the old move first.
    func save(_ loan: Loan) {
        let old = loans.first { $0.id == loan.id }
        persist {
            let loan = link(loan)
            if let old { moveMoney(of: old, sign: -1) }
            if let index = loans.firstIndex(where: { $0.id == loan.id }) {
                loans[index] = loan
            } else {
                loans.append(loan)
            }
            moveMoney(of: loan, sign: 1)
            database?.save(loan)
            if let previous = old?.contactID, previous != loan.contactID { removeIfUnused(previous) }
        }
    }

    /// Applies (1) or undoes (-1) a new loan's money on its account: lending takes it out,
    /// borrowing brings it in. A loan from before the app moves nothing.
    private func moveMoney(of loan: Loan, sign: Double) {
        guard let accountID = loan.movedAccountID else { return }
        adjustBalance(of: accountID, by: (loan.direction == .lent ? -loan.principal : loan.principal) * sign)
    }

    /// New loans whose money moved, newest first: rows of "Thu chi" (neither income nor spending)
    /// and of the account's history.
    var loanMoves: [Loan] {
        loans.filter { $0.movedAccountID != nil }.sorted { $0.date > $1.date }
    }

    func loanMoves(of account: Account) -> [Loan] {
        loanMoves.filter { $0.movedAccountID == account.id }
    }

    /// "Đánh dấu đã tất toán": nothing left to repay.
    func settle(_ loan: Loan) {
        var loan = loan
        loan.outstanding = 0
        save(loan)
    }

    func loan(id: Loan.ID) -> Loan? {
        loans.first { $0.id == id }
    }

    /// Accounts a new loan can move money with: unlocked ones in use, plus the one it already has.
    func loanAccountOptions(keeping kept: Account.ID?) -> [Account.ID] {
        accounts.filter { !$0.isLocked || $0.id == kept }.map(\.id)
    }

    /// The loan with its person in "Danh bạ": its own while the name still matches, else the one
    /// with the name typed, else someone new ("Khác"), so every loan has a person. The name is
    /// written as the person's. Until the loan form picks from Danh bạ, the name is how it says who.
    private func link(_ loan: Loan) -> Loan {
        // As long as a name typed in Danh bạ may be; the loan form has no limit.
        let name = String(Contact.clean(loan.name).prefix(Contact.maxNameLength))
        guard !name.isEmpty else { return loan }
        var loan = loan
        let person: Contact
        if let own = loan.contactID.flatMap({ contact(id: $0) }), own.hasName(name) {
            person = own
        } else if let named = contact(named: name) {
            person = named
        } else {
            person = Contact(name: name, relationshipID: ContactRelationship.other.rawValue, isAutoCreated: true)
            contacts.append(person)
            database?.save(person)
        }
        loan.contactID = person.id
        loan.name = person.name
        return loan
    }

    /// Loans from before "Danh bạ" (V2) have only a name: each gets its person, once, at launch.
    private func linkLoansToContacts() {
        let unlinked = loans.filter { loan in loan.contactID.flatMap { contact(id: $0) } == nil }
        guard !unlinked.isEmpty else { return }
        persist { for loan in unlinked { save(loan) } }
    }

    func delete(_ loan: Loan) {
        persist {
            if let saved = self.loan(id: loan.id) { moveMoney(of: saved, sign: -1) }
            loans.removeAll { $0.id == loan.id }
            database?.deleteLoan(id: loan.id)
            if let person = loan.contactID { removeIfUnused(person) }
        }
    }

    /// A person the app made from a loan's name ("Minh Tran", fixed to "Minh Trần" on the loan)
    /// goes once no loan names them; someone the user added or edited stays.
    private func removeIfUnused(_ id: Contact.ID) {
        guard let person = contact(id: id), person.isAutoCreated, loans(of: person).isEmpty else { return }
        contacts.removeAll { $0.id == id }
        database?.deleteContact(id: id)
    }

    /// An account in use or archived (archived ones still name their history).
    func account(id: Account.ID) -> Account? {
        accounts.first { $0.id == id } ?? archivedAccounts.first { $0.id == id }
    }

    func accountTransactions(_ account: Account) -> [FinanceTransaction] {
        transactions.filter { $0.accountID == account.id }
    }

    // MARK: - Danh bạ

    /// "Danh bạ" A→Z as Vietnamese sorts names ("Dũng" before "Đức", "Anh" before "Ăn"), whatever
    /// language the phone is set to.
    var sortedContacts: [Contact] {
        contacts.sorted {
            $0.name.compare($1.name, options: [.caseInsensitive, .numeric], locale: .vietnam) == .orderedAscending
        }
    }

    func contact(id: Contact.ID) -> Contact? {
        contacts.first { $0.id == id }
    }

    /// The person with this name (case aside, accents count), as names are unique.
    func contact(named name: String) -> Contact? {
        contacts.first { $0.hasName(name) }
    }

    func loans(of contact: Contact) -> [Loan] {
        loans.filter { $0.contactID == contact.id }
    }

    /// Adds or changes a person. Their loans show the name, so a new one is written onto them too.
    func save(_ contact: Contact) {
        persist {
            if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                contacts[index] = contact
            } else {
                contacts.append(contact)
            }
            database?.save(contact)
            for index in loans.indices where loans[index].contactID == contact.id && loans[index].name != contact.name {
                loans[index].name = contact.name
                database?.save(loans[index])
            }
        }
    }

    /// Only someone with no loans, settled ones included: a loan never loses who it is with (user
    /// choice 2026-10-29).
    func canDelete(_ contact: Contact) -> Bool {
        loans(of: contact).isEmpty
    }

    func delete(_ contact: Contact) {
        guard canDelete(contact) else { return }
        contacts.removeAll { $0.id == contact.id }
        database?.deleteContact(id: contact.id)
    }

    /// Every relationship to pick from: the built-in ones, those the user added, then "Khác" last.
    var relationships: [Relationship] {
        let builtIn = ContactRelationship.allCases.filter { $0 != .other }.map(\.relationship)
        return builtIn + customRelationships + [ContactRelationship.other.relationship]
    }

    /// "Khác" for an id that is gone, so a person always shows a relationship.
    func relationship(id: String) -> Relationship {
        ContactRelationship(rawValue: id)?.relationship
            ?? customRelationships.first { $0.id == id }
            ?? ContactRelationship.other.relationship
    }

    func contacts(in relationship: Relationship) -> [Contact] {
        contacts.filter { $0.relationshipID == relationship.id }
    }

    /// Adds or changes a relationship the user made.
    func save(_ relationship: Relationship) {
        guard !relationship.isBuiltIn else { return }
        if let index = customRelationships.firstIndex(where: { $0.id == relationship.id }) {
            customRelationships[index] = relationship
        } else {
            customRelationships.append(relationship)
        }
        database?.save(relationship)
    }

    /// Deletes a relationship the user made; the people in it move to "Khác" (user choice 2026-10-29).
    func delete(_ relationship: Relationship) {
        guard !relationship.isBuiltIn else { return }
        persist {
            for index in contacts.indices where contacts[index].relationshipID == relationship.id {
                contacts[index].relationshipID = ContactRelationship.other.rawValue
                database?.save(contacts[index])
            }
            customRelationships.removeAll { $0.id == relationship.id }
            database?.deleteRelationship(id: relationship.id)
        }
    }

    // MARK: - Thêm / xoá giao dịch

    func add(_ transaction: FinanceTransaction) {
        persist {
            // Not onto an archived account or a closed or deleted goal (a balance adjustment on a
            // locked account is fine: it is the user's own correction).
            if let account = account(id: transaction.accountID) {
                guard !account.isArchived else { return }
            } else {
                guard goal(id: transaction.accountID).map({ !$0.isClosed }) == true else { return }
            }
            transactions.append(transaction)
            transactions.sort { $0.date > $1.date }
            adjustBalance(of: transaction.accountID, by: transaction.signedAmount)
            database?.save(transaction)
        }
    }

    /// Thay một giao dịch đã có và cập nhật lại số dư của tài khoản cũ lẫn mới.
    func update(_ transaction: FinanceTransaction) {
        persist {
            guard let index = transactions.firstIndex(where: { $0.id == transaction.id }),
                  isEditable(transactions[index]), accepts(transaction, replacing: transactions[index])
            else { return }
            let old = transactions[index]
            adjustBalance(of: old.accountID, by: -old.signedAmount)
            transactions[index] = transaction
            transactions.sort { $0.date > $1.date }
            adjustBalance(of: transaction.accountID, by: transaction.signedAmount)
            database?.save(transaction)
        }
    }

    func transaction(id: FinanceTransaction.ID) -> FinanceTransaction? {
        transactions.first { $0.id == id }
    }

    func delete(_ transaction: FinanceTransaction) {
        persist {
            // Chat cards can ask twice; only reverse the balance for a transaction that still exists.
            guard transactions.contains(where: { $0.id == transaction.id }), isEditable(transaction) else { return }
            transactions.removeAll { $0.id == transaction.id }
            adjustBalance(of: transaction.accountID, by: -transaction.signedAmount)
            database?.deleteTransaction(id: transaction.id)
        }
    }

    /// Moves an account's balance, or a goal's saved amount when the money was spent from a goal.
    private func adjustBalance(of accountID: Account.ID, by delta: Double) {
        if let index = accounts.firstIndex(where: { $0.id == accountID }) {
            accounts[index].balance += delta
            database?.save(accounts[index])
        } else if let index = archivedAccounts.firstIndex(where: { $0.id == accountID }) {
            archivedAccounts[index].balance += delta
            database?.save(archivedAccounts[index])
        } else if let index = savingsGoals.firstIndex(where: { $0.id == accountID }) {
            savingsGoals[index].saved += delta
            database?.save(savingsGoals[index])
        }
    }

    /// One save for the whole of `body` (see `FinanceDatabase.batch`).
    private func persist(_ body: () -> Void) {
        if let database { database.batch(body) } else { body() }
    }

    // MARK: - Hạng mục

    /// What a transaction is called: its category ("Ăn trưa"); it has no name of its own.
    func title(of transaction: FinanceTransaction) -> String {
        categoryName(transaction.categoryID)
    }

    /// The name a transaction shows for its category: the item ("Ăn sáng"), an old transaction's
    /// group ("Ăn uống"), or the system's ("Điều chỉnh số dư").
    func categoryName(_ id: String) -> String {
        category(id: id)?.name ?? TransactionCategory(rawValue: id)?.title ?? "Hạng mục đã xoá"
    }

    func categoryIcon(_ id: String) -> String {
        category(id: id)?.icon ?? TransactionCategory(rawValue: id)?.icon ?? "hugeicons-tag-01"
    }

    /// The group a category belongs to (itself for a group or a system category).
    func groupID(of id: String) -> String {
        category(id: id)?.parentID ?? id
    }

    /// Items that can be picked for a new transaction: in use, in a group in use, of `kind`.
    func pickableItems(_ kind: TransactionKind) -> [Category] {
        groups(kind).flatMap { items(of: $0) }
    }

    /// The items last used for `kind`, newest first, still pickable.
    func recentItems(_ kind: TransactionKind, limit: Int = 4) -> [Category] {
        let pickable = Dictionary(uniqueKeysWithValues: pickableItems(kind).map { ($0.id, $0) })
        var seen = Set<String>()
        // By when it was recorded, not its date: one recorded today for last week is recent too.
        return transactions.sorted { $0.createdAt > $1.createdAt }.compactMap { transaction -> Category? in
            guard let item = pickable[transaction.categoryID], seen.insert(item.id).inserted else { return nil }
            return item
        }
        .prefix(limit).map { $0 }
    }

    func groups(_ kind: TransactionKind, hidden: Bool = false) -> [Category] {
        categories.filter { $0.isGroup && $0.kind == kind && $0.isHidden == hidden }
    }

    /// A group's items in use (or the hidden ones).
    func items(of group: Category, hidden: Bool = false) -> [Category] {
        categories.filter { $0.parentID == group.id && $0.isHidden == hidden }
    }

    func category(id: String) -> Category? {
        categories.first { $0.id == id }
    }

    /// Hidden groups and hidden items of one kind, for "Hạng mục đã ẩn". An item inside a hidden
    /// group is not listed on its own: it comes back with its group.
    func hiddenCategories(_ kind: TransactionKind) -> [Category] {
        let hiddenGroups = Set(categories.filter { $0.isGroup && $0.isHidden }.map(\.id))
        return categories.filter { $0.kind == kind && $0.isHidden && !hiddenGroups.contains($0.parentID ?? "") }
            .sorted { ($0.hiddenAt ?? .distantPast) > ($1.hiddenAt ?? .distantPast) }
    }

    /// Whether a transaction is filed under it (for a group: under it or any of its items); such a
    /// category is hidden, not deleted.
    ///
    /// Until the transaction form is wired to these categories, it still offers the 12 built-in
    /// groups (`TransactionCategory`), so those count as used: they are hidden, never deleted, or a
    /// new transaction could point at a group that no longer exists.
    func hasHistory(_ category: Category) -> Bool {
        if category.isGroup, TransactionCategory(rawValue: category.id) != nil { return true }
        let ids = Set([category.id] + categories.filter { $0.parentID == category.id }.map(\.id))
        return transactions.contains { ids.contains($0.categoryID) }
    }

    /// Adds or changes a category. A new group comes with its first item (a transaction is always
    /// filed under an item): `firstItem` names it, or it takes the group's name.
    func save(_ category: Category, firstItem: String? = nil) {
        persist {
            var category = category
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index] = category
            } else {
                category.sortOrder = (categories.map(\.sortOrder).max() ?? 0) + 100
                categories.append(category)
                if category.isGroup {
                    let item = Category(id: UUID().uuidString, kind: category.kind, parentID: category.id,
                                        name: firstItem ?? category.name, icon: category.icon,
                                        sortOrder: category.sortOrder + 1)
                    categories.append(item)
                    database?.save(item)
                }
            }
            sortCategories()
            database?.save(category)
        }
    }

    /// Hides (with history) or deletes (without) a category; a group takes its items with it. The
    /// last item of a group cannot go on its own (see `canRemove`).
    ///
    /// A group with history is hidden together with its items (same time), so "Hiện lại" brings
    /// them back as they were; a group without history is deleted with its items.
    func remove(_ category: Category) {
        guard canRemove(category) else { return }
        persist {
            if category.isGroup {
                let members = categories.filter { $0.parentID == category.id }
                if hasHistory(category) {
                    let now = Date.now
                    for item in members where !item.isHidden { setHidden(item.id, at: now) }
                    setHidden(category.id, at: now)
                } else {
                    for item in members { deleteOne(item.id) }
                    deleteOne(category.id)
                }
            } else if hasHistory(category) {
                setHidden(category.id, at: .now)
            } else {
                deleteOne(category.id)
            }
        }
    }

    /// An item can be moved to another group unless it is the last one in use in its own.
    func canMove(_ category: Category) -> Bool { canRemove(category) }

    /// An item can go unless it is the last one still in use in its group; a group, unless it is
    /// the last one in use of its kind (spending or income always has somewhere to go).
    func canRemove(_ category: Category) -> Bool {
        guard !category.isHidden else { return true }
        guard let parentID = category.parentID else { return groups(category.kind).count > 1 }
        guard let group = self.category(id: parentID) else { return true }
        return items(of: group).count > 1
    }

    private func setHidden(_ id: String, at date: Date?) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[index].hiddenAt = date
        database?.save(categories[index])
    }

    private func deleteOne(_ id: String) {
        categories.removeAll { $0.id == id }
        database?.deleteCategory(id: id)
    }

    /// Shows a hidden category again. An item's hidden group comes back with it. A group comes
    /// back with the items hidden together with it, not those the user had hidden on their own
    /// before; if none is left, its first item comes back too, so it is never empty.
    func unhide(_ category: Category) {
        persist {
            guard let current = self.category(id: category.id) else { return }
            // An item in a hidden group: the whole group comes back, with the items hidden with it.
            if let parentID = current.parentID, let parent = self.category(id: parentID), parent.isHidden {
                unhide(parent)
            }
            setHidden(current.id, at: nil)
            if current.isGroup, let hiddenAt = current.hiddenAt {
                let members = categories.filter { $0.parentID == current.id }
                for item in members where item.hiddenAt.map({ $0 >= hiddenAt }) == true {
                    setHidden(item.id, at: nil)
                }
                if let group = self.category(id: current.id), items(of: group).isEmpty, let first = members.first {
                    setHidden(first.id, at: nil)
                }
            }
        }
    }

    /// Items to count and show: in use, in a group in use.
    var visibleItemCount: Int {
        let hiddenGroups = Set(categories.filter { $0.isGroup && $0.isHidden }.map(\.id))
        return categories.filter { !$0.isGroup && !$0.isHidden && !hiddenGroups.contains($0.parentID ?? "") }.count
    }

    private func sortCategories() {
        categories.sort { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Thống kê

    func monthlyTransactions(for date: Date = .now) -> [FinanceTransaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }
    }

    /// What a month's totals, charts and the assistant count: its transactions that are reported,
    /// and the fees of its transfers (spending, though they have no row).
    func reportableTransactions(inMonthOf date: Date = .now) -> [FinanceTransaction] {
        (monthlyTransactions(for: date) + feeExpenses(inMonthOf: date)).reportable(excluding: lockedAccountIDs)
    }

    func total(_ kind: TransactionKind, inMonthOf date: Date = .now) -> Double {
        reportableTransactions(inMonthOf: date)
            .filter { $0.kind == kind }
            .reduce(0) { $0 + $1.amount }
    }

    /// Chi tiêu trong tháng gộp theo nhóm hạng mục ("Ăn sáng" và "Ăn trưa" vào "Ăn uống"), lớn nhất
    /// lên đầu.
    func expensesByCategory(inMonthOf date: Date = .now) -> [CategoryTotal] {
        let expenses = reportableTransactions(inMonthOf: date).filter { $0.kind == .expense }
        return Dictionary(grouping: expenses) { groupID(of: $0.categoryID) }
            .map { groupID, items in
                CategoryTotal(groupID: groupID, name: categoryName(groupID), icon: categoryIcon(groupID),
                              amount: items.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.amount > $1.amount }
    }
}

struct CategoryTotal: Identifiable {
    /// A group of "Hạng mục", or a system category ("Phí chuyển khoản").
    let groupID: String
    let name: String
    let icon: String
    let amount: Double

    var id: String { groupID }
}
