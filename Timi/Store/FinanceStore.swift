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

    init(accounts: [Account] = SampleData.accounts, transactions: [FinanceTransaction] = SampleData.transactions, loans: [Loan] = SampleData.loans, paymentReminders: [PaymentReminder] = SampleData.paymentReminders, savingsGoals: [SavingsGoal] = SampleData.savingsGoals) {
        self.accounts = accounts
        self.archivedAccounts = []
        self.loans = loans
        self.paymentReminders = paymentReminders
        self.savingsGoals = savingsGoals
        self.transactions = transactions.sorted { $0.date > $1.date }
        self.goalTransfers = []
        self.categories = DefaultCategories.all
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
        categories = snapshot.categories
        loans = snapshot.loans
        paymentReminders = snapshot.paymentReminders
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
        categories = snapshot.categories
        loans = snapshot.loans
        paymentReminders = snapshot.paymentReminders
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
        !transaction.category.isAdjustment && !lockedAccountIDs.contains(transaction.accountID)
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
            add(FinanceTransaction(title: TransactionCategory.adjustmentIn.title, amount: abs(delta),
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
    /// reports), sends whatever is left to `leftoverAccount`, then closes the goal.
    func spend(from goal: SavingsGoal, title: String, category: TransactionCategory, amount: Double,
               date: Date, leftoverAccount: Account.ID?) {
        persist {
            // Spend no more than the goal holds, and leave nothing behind in a closed goal.
            guard let saved = self.goal(id: goal.id)?.saved, amount > 0, amount <= saved else { return }
            if saved - amount >= 1 {
                guard let leftoverAccount, acceptsMoney(leftoverAccount) else { return }
            }
            add(FinanceTransaction(title: title, amount: amount, category: category, accountID: goal.id, date: date))
            let left = (self.goal(id: goal.id)?.saved ?? 0)
            var note = "Đã dùng: \(title)"
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

    /// An account in use or archived (archived ones still name their history).
    func account(id: Account.ID) -> Account? {
        accounts.first { $0.id == id } ?? archivedAccounts.first { $0.id == id }
    }

    func accountTransactions(_ account: Account) -> [FinanceTransaction] {
        transactions.filter { $0.accountID == account.id }
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
        return transactions.contains { ids.contains($0.category.rawValue) }
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

    func total(_ kind: TransactionKind, inMonthOf date: Date = .now) -> Double {
        monthlyTransactions(for: date).reportable(excluding: lockedAccountIDs)
            .filter { $0.kind == kind }
            .reduce(0) { $0 + $1.amount }
    }

    /// Chi tiêu trong tháng gộp theo danh mục, lớn nhất lên đầu.
    func expensesByCategory(inMonthOf date: Date = .now) -> [CategoryTotal] {
        let expenses = monthlyTransactions(for: date).reportable(excluding: lockedAccountIDs).filter { $0.kind == .expense }
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
