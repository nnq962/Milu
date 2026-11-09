import Foundation
import Testing
@testable import Milu

/// Hũ tiết kiệm's money: deposits and withdrawals move money between an account and the goal and
/// nothing else; spending from it, taking everything out or deleting it never makes money appear
/// or disappear; a correction of an account's balance is written down as a transaction.
@MainActor
struct GoalTests {
    private let wallet = Account(name: "Ví", type: .cash, balance: 1_000_000)
    private let bank = Account(name: "Ngân hàng", type: .bank, balance: 5_000_000)
    private let goal = SavingsGoal(name: "Mua xe", icon: SavingsGoal.defaultIcon, saved: 0, target: 10_000_000)

    /// A wallet, a bank account and the goal holding `saved`, put there from the bank.
    private func makeStore(saved: Double = 3_000_000) -> FinanceStore {
        let store = FinanceStore(accounts: [wallet, bank], transactions: [], loans: [], paymentReminders: [],
                                 savingsGoals: [goal], goalTransfers: [], contacts: [])
        if saved > 0 {
            store.add(GoalTransfer(goalID: goal.id, accountID: bank.id, direction: .deposit, amount: saved, date: .now))
        }
        return store
    }

    private func balance(_ store: FinanceStore, _ account: Account) -> Double? { store.account(id: account.id)?.balance }
    private func saved(_ store: FinanceStore) -> Double? { store.goal(id: goal.id)?.saved }

    // MARK: - Nạp, rút

    @Test func aDepositMovesMoneyFromTheAccountIntoTheGoal() {
        let store = makeStore()
        #expect(saved(store) == 3_000_000)
        #expect(balance(store, bank) == 2_000_000)
        // Not spending: it never counts in reports.
        #expect(store.total(.expense) == 0)
    }

    @Test func noWithdrawalTakesMoreThanTheGoalHolds() {
        let store = makeStore()
        store.add(GoalTransfer(goalID: goal.id, accountID: wallet.id, direction: .withdrawal, amount: 3_500_000, date: .now))
        #expect(saved(store) == 3_000_000)
        #expect(balance(store, wallet) == 1_000_000)
    }

    @Test func changingADepositUndoesTheOldAmountFirst() {
        let store = makeStore()
        guard var deposit = store.goalTransfers.first else { Issue.record("No deposit"); return }
        deposit.amount = 4_000_000
        store.update(deposit)
        #expect(saved(store) == 4_000_000)
        #expect(balance(store, bank) == 1_000_000)
    }

    @Test func aDepositCannotBeDeletedOnceItsMoneyIsSpent() {
        let store = makeStore()
        guard let deposit = store.goalTransfers.first else { Issue.record("No deposit"); return }
        store.add(GoalTransfer(goalID: goal.id, accountID: wallet.id, direction: .withdrawal, amount: 2_000_000, date: .now))
        // Deleting it would leave the goal at −2tr.
        store.delete(deposit)
        #expect(store.goalTransfers.contains { $0.id == deposit.id })
        #expect(saved(store) == 1_000_000)
    }

    // MARK: - Mua ngay

    @Test func spendingSendsTheRestToAnAccountAndClosesTheGoal() {
        let store = makeStore()
        store.spend(from: goal, categoryID: TransactionCategory.shopping.rawValue, amount: 2_000_000,
                    date: .now, leftoverAccount: wallet.id)
        #expect(saved(store) == 0)
        #expect(store.goal(id: goal.id)?.isClosed == true)
        #expect(balance(store, wallet) == 2_000_000)
        // The purchase is spending, recorded on the goal, and counts in reports.
        #expect(store.goalTransactions(goal).map(\.amount) == [2_000_000])
        #expect(store.total(.expense) == 2_000_000)
    }

    @Test func spendingEverythingNeedsNoAccount() {
        let store = makeStore()
        store.spend(from: goal, categoryID: TransactionCategory.shopping.rawValue, amount: 3_000_000,
                    date: .now, leftoverAccount: nil)
        #expect(saved(store) == 0)
        #expect(store.goal(id: goal.id)?.isClosed == true)
    }

    @Test func spendingIsRefusedWhenItWouldLoseMoney() {
        let store = makeStore()
        // More than it holds.
        store.spend(from: goal, categoryID: TransactionCategory.shopping.rawValue, amount: 3_500_000,
                    date: .now, leftoverAccount: wallet.id)
        // A rest with nowhere to go.
        store.spend(from: goal, categoryID: TransactionCategory.shopping.rawValue, amount: 1_000_000,
                    date: .now, leftoverAccount: nil)
        #expect(saved(store) == 3_000_000)
        #expect(store.goal(id: goal.id)?.isClosed == false)
        #expect(store.transactions.isEmpty)
    }

    @Test func aGoalsSpendingCanGrowOnlyAsFarAsItHolds() {
        let store = makeStore()
        let purchase = FinanceTransaction(amount: 1_000_000, categoryID: TransactionCategory.shopping.rawValue,
                                          kind: .expense, accountID: goal.id, date: .now)
        var more = purchase
        more.amount = 4_000_000
        #expect(store.accepts(more, replacing: purchase))
        more.amount = 4_000_001
        #expect(!store.accepts(more, replacing: purchase))
    }

    // MARK: - Rút hết, xoá

    @Test func withdrawingEverythingEmptiesAndClosesTheGoal() {
        let store = makeStore()
        store.withdrawAll(from: goal, to: wallet.id, date: .now, note: "")
        #expect(saved(store) == 0)
        #expect(store.goal(id: goal.id)?.isClosed == true)
        #expect(balance(store, wallet) == 4_000_000)
    }

    @Test func deletingAGoalGivesItsMoneyBackFirst() {
        let store = makeStore()
        store.delete(goal, returningTo: wallet.id)
        #expect(store.goal(id: goal.id) == nil)
        #expect(balance(store, wallet) == 4_000_000)
    }

    @Test func aGoalHoldingMoneyIsNotDeletedWithoutSomewhereForIt() {
        let store = makeStore()
        store.delete(goal)
        #expect(store.goal(id: goal.id) != nil)
        #expect(saved(store) == 3_000_000)
    }

    @Test func noMoneyMovesIntoALockedAccount() {
        var locked = wallet
        locked.isLocked = true
        let store = FinanceStore(accounts: [locked, bank], transactions: [], loans: [], paymentReminders: [],
                                 savingsGoals: [goal], goalTransfers: [], contacts: [])
        store.add(GoalTransfer(goalID: goal.id, accountID: bank.id, direction: .deposit, amount: 1_000_000, date: .now))
        store.withdrawAll(from: goal, to: locked.id, date: .now, note: "")
        #expect(saved(store) == 1_000_000)
        #expect(balance(store, locked) == 1_000_000)
    }

    // MARK: - Điều chỉnh số dư

    @Test func correctingABalanceRecordsTheDifference() {
        let store = makeStore(saved: 0)
        store.update(wallet, balance: 1_250_000)
        #expect(balance(store, wallet) == 1_250_000)
        let adjustment = store.transactions.first
        #expect(adjustment?.categoryID == TransactionCategory.adjustmentIn.rawValue)
        #expect(adjustment?.amount == 250_000)
        // Kept out of reports.
        #expect(store.total(.income) == 0)
    }

    @Test func correctingABalanceDownRecordsMoneyOut() {
        let store = makeStore(saved: 0)
        store.update(wallet, balance: 900_000)
        #expect(balance(store, wallet) == 900_000)
        #expect(store.transactions.first?.categoryID == TransactionCategory.adjustmentOut.rawValue)
    }

    @Test func savingTheSameBalanceRecordsNothing() {
        let store = makeStore(saved: 0)
        var renamed = wallet
        renamed.name = "Ví mới"
        store.update(renamed, balance: 1_000_000)
        #expect(store.account(id: wallet.id)?.name == "Ví mới")
        #expect(store.transactions.isEmpty)
    }
}
