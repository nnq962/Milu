import Foundation

/// Hũ tiết kiệm: nạp, rút, dùng tiền, đóng và mở lại.
extension FinanceStore {
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

    /// "Mua ngay": spends from the goal (an expense recorded on the goal itself, so it counts in
    /// reports), sends whatever is left to `leftoverAccount`, then closes the goal. Like any
    /// transaction it has no name; the closing note says the category ("Đã dùng: Mua xe máy").
    func spend(from goal: SavingsGoal, categoryID: String, amount: Double,
               date: Date, note: String = "", isExcluded: Bool = false, leftoverAccount: Account.ID?) {
        persist {
            // Spend no more than the goal holds, and leave nothing behind in a closed goal.
            guard let saved = self.goal(id: goal.id)?.saved, amount > 0, amount <= saved else { return }
            if saved - amount >= 1 {
                guard let leftoverAccount, acceptsMoney(leftoverAccount) else { return }
            }
            add(FinanceTransaction(amount: amount, categoryID: categoryID, kind: .expense,
                                   accountID: goal.id, date: date, note: note, isExcluded: isExcluded))
            let left = (self.goal(id: goal.id)?.saved ?? 0)
            var note = "Đã dùng: \(categoryName(categoryID))"
            if left >= 1, let leftoverAccount {
                // A second later, so the goal's history (newest first) lists it above the purchase.
                let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1),
                                                     to: Calendar.current.startOfDay(for: date)) ?? date
                add(GoalTransfer(goalID: goal.id, accountID: leftoverAccount, direction: .withdrawal,
                                 amount: left, date: min(date.addingTimeInterval(1), max(endOfDay, date))))
                note += " · \(left.vnd) về \(account(id: leftoverAccount)?.name ?? "tài khoản")"
            }
            close(goal.id, note: note)
        }
    }

    /// Transactions recorded on a goal ("Mua ngay").
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
    func accepts(_ new: FinanceTransaction, replacing old: FinanceTransaction) -> Bool {
        if let account = account(id: new.accountID) { return !account.isArchived }
        guard let goal = goal(id: new.accountID), !goal.isClosed, new.accountID == old.accountID,
              new.kind == .expense, old.kind == .expense else { return false }
        return new.amount <= goal.saved + old.amount
    }

    /// Where money can be moved to or from: an unlocked account in use.
    func acceptsMoney(_ accountID: Account.ID) -> Bool {
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
}
