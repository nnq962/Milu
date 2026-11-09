import Foundation
import SwiftData
import Testing
@testable import Timi

/// What is written to the database comes back the same after a relaunch: each test writes through
/// one store, then opens a second store on the same (in-memory) database, as the app does on its
/// next launch, and compares. One table holds transactions, transfers between accounts and money
/// in and out of goals, told apart when read back (`RecordMapping`): a mistake there loses data
/// only after a relaunch, which the other tests never do (review 2026-11-09).
@MainActor
struct PersistenceTests {
    /// Whole seconds, as stored.
    private let day = Date(timeIntervalSince1970: 1_793_000_000)

    private func open(_ container: ModelContainer) -> FinanceStore {
        FinanceStore(database: FinanceDatabase(context: ModelContext(container)))
    }

    /// A store on a new empty database, with a wallet, a bank account and an empty goal of its own
    /// (the sample data may be there too, depending on this device's settings).
    private func makeStore() -> (FinanceStore, ModelContainer, wallet: Account, bank: Account, goal: SavingsGoal) {
        let container = FinanceDatabase.makeContainer(inMemory: true)
        let store = open(container)
        let wallet = Account(name: "Ví test", type: .cash, balance: 1_000_000, openedAt: day)
        let bank = Account(name: "Ngân hàng test", type: .bank, balance: 5_000_000, openedAt: day)
        let goal = SavingsGoal(name: "Hũ test", icon: SavingsGoal.defaultIcon, saved: 0, target: 10_000_000)
        store.add(wallet)
        store.add(bank)
        store.save(goal)
        return (store, container, wallet, bank, goal)
    }

    @Test func everyKindOfRecordComesBackAfterARelaunch() {
        let (store, container, wallet, bank, goal) = makeStore()
        store.add(FinanceTransaction(amount: 200_000, category: .food, accountID: wallet.id, date: day, note: "Bún chả"))
        store.add(AccountTransfer(fromAccountID: bank.id, toAccountID: wallet.id, amount: 1_000_000, fee: 11_000, date: day))
        store.add(GoalTransfer(goalID: goal.id, accountID: bank.id, direction: .deposit, amount: 2_000_000, date: day))
        let loan = Loan(name: "An", direction: .lent, principal: 500_000, outstanding: 500_000, dueDate: nil,
                        accountID: wallet.id, date: day)
        store.save(loan)
        store.save(LoanPayment(loanID: loan.id, principal: 100_000, interest: 5_000, accountID: wallet.id,
                               date: day.addingTimeInterval(3600)))

        let reopened = open(container)
        #expect(reopened.transactions == store.transactions)
        #expect(reopened.accountTransfers == store.accountTransfers)
        #expect(reopened.goalTransfers == store.goalTransfers)
        #expect(reopened.loans == store.loans)
        #expect(reopened.loanPayments == store.loanPayments)
        #expect(reopened.savingsGoals == store.savingsGoals)
        // The balances are worked out again from what was stored, and agree.
        #expect(reopened.account(id: wallet.id)?.balance == store.account(id: wallet.id)?.balance)
        #expect(reopened.account(id: bank.id)?.balance == store.account(id: bank.id)?.balance)
        #expect(reopened.goal(id: goal.id)?.saved == 2_000_000)
        // Ví: 1tr − 200k + 1tr − 500k + 105k; bank: 5tr − 1.011.000 − 2tr.
        #expect(reopened.account(id: wallet.id)?.balance == 1_405_000)
        #expect(reopened.account(id: bank.id)?.balance == 1_989_000)
        // Each row read back as what it is: the transfer and the goal's deposit are not spending.
        #expect(reopened.transactions.filter { $0.accountID == wallet.id || $0.accountID == bank.id }.count == 1)
    }

    @Test func changesAndDeletionsComeBackAfterARelaunch() {
        let (store, container, wallet, bank, _) = makeStore()
        var lunch = FinanceTransaction(amount: 200_000, category: .food, accountID: wallet.id, date: day)
        store.add(lunch)
        let transfer = AccountTransfer(fromAccountID: bank.id, toAccountID: wallet.id, amount: 1_000_000, date: day)
        store.add(transfer)
        lunch.amount = 350_000
        lunch.accountID = bank.id
        store.update(lunch)
        store.delete(transfer)

        let reopened = open(container)
        #expect(reopened.transactions.first { $0.id == lunch.id } == lunch)
        #expect(!reopened.accountTransfers.contains { $0.id == transfer.id })
        #expect(reopened.account(id: wallet.id)?.balance == 1_000_000)
        #expect(reopened.account(id: bank.id)?.balance == 4_650_000)
    }

    @Test func aClosedGoalStaysClosedAfterARelaunch() {
        let (store, container, wallet, bank, goal) = makeStore()
        store.add(GoalTransfer(goalID: goal.id, accountID: bank.id, direction: .deposit, amount: 3_000_000, date: day))
        store.spend(from: goal, categoryID: TransactionCategory.shopping.rawValue, amount: 2_000_000,
                    date: day, leftoverAccount: wallet.id)

        let reopened = open(container)
        let saved = reopened.goal(id: goal.id)
        #expect(saved?.isClosed == true)
        #expect(saved?.saved == 0)
        #expect(saved?.closingNote == store.goal(id: goal.id)?.closingNote)
        #expect(reopened.account(id: wallet.id)?.balance == 2_000_000)
    }

    @Test func erasingEverythingDeletesEveryRecord() {
        let (store, container, wallet, _, _) = makeStore()
        store.add(FinanceTransaction(amount: 200_000, category: .food, accountID: wallet.id, date: day))
        store.database?.deleteEverything()

        let snapshot = FinanceDatabase(context: ModelContext(container)).load()
        #expect(snapshot.accounts.isEmpty)
        #expect(snapshot.archivedAccounts.isEmpty)
        #expect(snapshot.savingsGoals.isEmpty)
        #expect(snapshot.transactions.isEmpty)
        #expect(snapshot.accountTransfers.isEmpty)
        #expect(snapshot.goalTransfers.isEmpty)
        #expect(snapshot.loans.isEmpty)
        #expect(snapshot.loanPayments.isEmpty)
        #expect(snapshot.paymentReminders.isEmpty)
        #expect(snapshot.contacts.isEmpty)
        #expect(snapshot.relationships.isEmpty)
    }
}
