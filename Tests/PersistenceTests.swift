import Foundation
import SwiftData
import Testing
@testable import Milu

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

    /// Two devices each recorded a repayment before they synced; the loan row kept one device's
    /// figure. What is owed is worked out again from both repayments (audit 2026-11-15).
    @Test func aLoanOwesItsPrincipalLessEveryRepayment() throws {
        let (store, container, wallet, _, _) = makeStore()
        let loan = Loan(name: "An", direction: .lent, principal: 10_000_000, outstanding: 10_000_000, dueDate: nil,
                        accountID: wallet.id, date: day)
        store.save(loan)
        store.save(LoanPayment(loanID: loan.id, principal: 3_000_000, accountID: wallet.id, date: day.addingTimeInterval(3600)))
        store.save(LoanPayment(loanID: loan.id, principal: 2_000_000, accountID: wallet.id, date: day.addingTimeInterval(7200)))
        // The other device's write won: 10tr − 3tr only.
        let context = ModelContext(container)
        let row = try #require(try context.fetch(FetchDescriptor<LoanRecord>()).first { $0.id == loan.id })
        row.outstanding = 7_000_000
        try context.save()

        let reopened = open(container)
        #expect(reopened.loan(id: loan.id)?.outstanding == 5_000_000)
        // One from before Milu: never more than the principal less what came back through Milu.
        let old = Loan(name: "Bình", direction: .lent, principal: 8_000_000, outstanding: 6_000_000, dueDate: nil,
                       isExisting: true)
        reopened.save(old)
        reopened.save(LoanPayment(loanID: old.id, principal: 1_000_000, accountID: wallet.id, date: day))
        #expect(open(container).loan(id: old.id)?.outstanding == 5_000_000)
    }

    /// A loan from before Milu, partly repaid before it: two devices each record a repayment before
    /// they sync, and the row keeps one device's figure. What it owed when entered is kept apart,
    /// so what is left comes out right on both (audit round 2, 2026-11-15: it stayed at one
    /// device's figure, 2tr too high).
    @Test func aLoanFromBeforeMiluOwesWhatItOwedLessEveryRepayment() throws {
        let (store, container, wallet, _, _) = makeStore()
        let old = Loan(name: "Cường", direction: .lent, principal: 10_000_000, outstanding: 6_000_000, dueDate: nil,
                       isExisting: true)
        store.save(old)
        #expect(store.loan(id: old.id)?.openingOutstanding == 6_000_000)
        store.save(LoanPayment(loanID: old.id, principal: 2_000_000, accountID: wallet.id, date: day))
        store.save(LoanPayment(loanID: old.id, principal: 1_000_000, accountID: wallet.id, date: day.addingTimeInterval(60)))
        // The iPad's write won: 6tr − 1tr only.
        let context = ModelContext(container)
        let row = try #require(try context.fetch(FetchDescriptor<LoanRecord>()).first { $0.id == old.id })
        row.outstanding = 5_000_000
        try context.save()
        let reopened = open(container)
        let loan = try #require(reopened.loan(id: old.id))
        #expect(loan.outstanding == 3_000_000)
        #expect(LoanDetailSheet.repaidBeforeMilu(loan, payments: reopened.payments(of: loan)) == 4_000_000)

        // Changed in its form to 2,5tr left: it owed 5,5tr when entered.
        var edited = loan
        edited.outstanding = 2_500_000
        reopened.save(edited)
        #expect(open(container).loan(id: old.id)?.outstanding == 2_500_000)
        #expect(open(container).loan(id: old.id)?.openingOutstanding == 5_500_000)
    }

    /// One stored before the opening figure was kept gets it at the next launch, from what it says
    /// now and its repayments, and owes the same as before.
    @Test func aLoanStoredBeforeTheOpeningFigureGetsIt() throws {
        let (store, container, wallet, _, _) = makeStore()
        let old = Loan(name: "Dũng", direction: .borrowed, principal: 8_000_000, outstanding: 5_000_000, dueDate: nil,
                       isExisting: true)
        store.save(old)
        store.save(LoanPayment(loanID: old.id, principal: 1_000_000, accountID: wallet.id, date: day))
        let context = ModelContext(container)
        let row = try #require(try context.fetch(FetchDescriptor<LoanRecord>()).first { $0.id == old.id })
        row.openingOutstanding = nil
        try context.save()
        let reopened = open(container)
        #expect(reopened.loan(id: old.id)?.outstanding == 4_000_000)
        #expect(reopened.loan(id: old.id)?.openingOutstanding == 5_000_000)
        let stored = try ModelContext(container).fetch(FetchDescriptor<LoanRecord>()).first { $0.id == old.id }
        #expect(stored?.openingOutstanding == 5_000_000)
    }

    /// A built-in category the user deleted stays deleted after a reinstall: the new install adds
    /// the built-in ones again, and the deleted one's older row, brought by iCloud, wins (audit 2026-11-15).
    @Test func aDeletedBuiltInCategoryStaysDeletedAfterAReinstall() throws {
        let phone = FinanceDatabase.makeContainer(inMemory: true)
        FinanceDatabase(context: ModelContext(phone)).addMissingDefaultCategories()
        let store = FinanceStore(database: FinanceDatabase(context: ModelContext(phone)), seedsSampleData: false)
        let milkTea = try #require(store.category(id: "food.milktea"))
        store.remove(milkTea)
        #expect(store.category(id: "food.milktea") == nil)
        #expect(FinanceStore(database: FinanceDatabase(context: ModelContext(phone)), seedsSampleData: false)
            .category(id: "food.milktea") == nil)
        let mark = try #require(try ModelContext(phone).fetch(FetchDescriptor<CategoryRecord>()).first { $0.id == "food.milktea" })
        #expect(mark.archivedAt == Category.deletedMark)

        // The new install: every built-in one, made now; then the phone's row comes down.
        let newPhone = FinanceDatabase.makeContainer(inMemory: true)
        FinanceDatabase(context: ModelContext(newPhone)).addMissingDefaultCategories()
        let context = ModelContext(newPhone)
        let synced = CategoryRecord(id: mark.id, kind: mark.kind, parentID: mark.parentID, name: mark.name,
                                    icon: mark.icon, isBuiltIn: true, sortOrder: mark.sortOrder)
        synced.archivedAt = mark.archivedAt
        synced.createdAt = mark.createdAt.addingTimeInterval(-60)
        context.insert(synced)
        try context.save()
        let reinstalled = FinanceStore(database: FinanceDatabase(context: ModelContext(newPhone)), seedsSampleData: false)
        #expect(reinstalled.category(id: "food.milktea") == nil)
        #expect(reinstalled.category(id: "food.coffee") != nil)

        // One deleted outright by an older version: marked at the first launch of this one, as
        // old as can be.
        UserDefaults.standard.removeObject(forKey: FinanceDatabase.deletedDefaultsMarkedKey)
        let gone = ModelContext(newPhone)
        let coffee = try #require(try gone.fetch(FetchDescriptor<CategoryRecord>()).first { $0.id == "food.coffee" })
        gone.delete(coffee)
        try gone.save()
        let relaunched = FinanceStore(database: FinanceDatabase(context: ModelContext(newPhone)), seedsSampleData: false)
        #expect(relaunched.category(id: "food.coffee") == nil)
        let coffeeMark = try ModelContext(newPhone).fetch(FetchDescriptor<CategoryRecord>()).first { $0.id == "food.coffee" }
        #expect(coffeeMark?.archivedAt == Category.deletedMark)
        #expect(coffeeMark?.createdAt == MiluSchemaV8.epoch)
    }

    /// A category table iCloud emptied (signed out, another Apple ID) gets no deletion marks, nor
    /// does it later as the account's data comes down in parts (audit round 2, 2026-11-15: marks
    /// for every built-in category won over the real rows on every device).
    @Test func anEmptiedCategoryTableIsNotMarkedDeleted() throws {
        UserDefaults.standard.set(true, forKey: FinanceDatabase.defaultsAddedKey)
        UserDefaults.standard.removeObject(forKey: FinanceDatabase.deletedDefaultsMarkedKey)
        let emptied = FinanceDatabase.makeContainer(inMemory: true)
        _ = FinanceStore(database: FinanceDatabase(context: ModelContext(emptied)), seedsSampleData: false)
        #expect(try ModelContext(emptied).fetch(FetchDescriptor<CategoryRecord>()).isEmpty)

        // The first rows come down: a group of each kind, none of their items yet.
        let context = ModelContext(emptied)
        for group in DefaultCategories.all.filter({ $0.parentID == nil }).prefix(30) {
            context.insert(CategoryRecord(id: group.id, kind: group.kind.rawValue, name: group.name,
                                          icon: group.icon, isBuiltIn: true, sortOrder: group.sortOrder))
        }
        try context.save()
        let before = try ModelContext(emptied).fetchCount(FetchDescriptor<CategoryRecord>())
        _ = FinanceStore(database: FinanceDatabase(context: ModelContext(emptied)), seedsSampleData: false)
        let marks = try ModelContext(emptied).fetch(FetchDescriptor<CategoryRecord>())
            .filter { $0.archivedAt == Category.deletedMark }
        #expect(marks.isEmpty)
        #expect(try ModelContext(emptied).fetchCount(FetchDescriptor<CategoryRecord>()) == before)
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
