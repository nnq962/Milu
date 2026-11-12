import Foundation
import SwiftData
import Testing
@testable import Milu

/// The database ready for iCloud (V8, 2026-11-12): balances are worked out from the history on
/// every load, so they must equal what the app moves as things are recorded; the move from V7
/// keeps every balance; two devices' copies of one row become one.
@MainActor
@Suite(.serialized)
struct CloudSyncTests {
    private let day = Date(timeIntervalSince1970: 1_793_000_000)

    private func open(_ container: ModelContainer) -> FinanceStore {
        FinanceStore(database: FinanceDatabase(context: ModelContext(container)), seedsSampleData: false)
    }

    /// Every way money moves, changed and undone, then a relaunch: the balances worked out from
    /// the history are the ones the app kept as it went.
    @Test func balancesFromTheHistoryMatchTheOnesKeptAsItWent() {
        let container = FinanceDatabase.makeContainer(inMemory: true)
        let store = open(container)
        let wallet = Account(name: "Ví", type: .cash, balance: 1_000_000, openedAt: day)
        let bank = Account(name: "Ngân hàng", type: .bank, balance: 8_000_000, openedAt: day)
        let card = Account(name: "Thẻ", type: .credit, balance: 0, openedAt: day)
        let goal = SavingsGoal(name: "Hũ", icon: SavingsGoal.defaultIcon, saved: 0, target: 10_000_000)
        let other = SavingsGoal(name: "Hũ 2", icon: SavingsGoal.defaultIcon, saved: 0, target: 5_000_000)
        store.add(wallet)
        store.add(bank)
        store.add(card)
        store.save(goal)
        store.save(other)

        // Transactions: added, changed to another account, deleted.
        var lunch = FinanceTransaction(amount: 120_000, category: .food, accountID: wallet.id, date: day)
        store.add(lunch)
        lunch.amount = 150_000
        lunch.accountID = card.id
        store.update(lunch)
        let salary = FinanceTransaction(amount: 20_000_000, category: .salary, accountID: bank.id, date: day)
        store.add(salary)
        let taxi = FinanceTransaction(amount: 80_000, category: .transport, accountID: wallet.id, date: day)
        store.add(taxi)
        store.delete(taxi)

        // Transfers with a fee: added, changed, deleted.
        var transfer = AccountTransfer(fromAccountID: bank.id, toAccountID: wallet.id, amount: 2_000_000, fee: 11_000, date: day)
        store.add(transfer)
        transfer.amount = 3_000_000
        store.update(transfer)
        let undone = AccountTransfer(fromAccountID: bank.id, toAccountID: card.id, amount: 500_000, date: day)
        store.add(undone)
        store.delete(undone)

        // Goals: deposits changed and undone, spending from one, deleting another.
        var deposit = GoalTransfer(goalID: goal.id, accountID: bank.id, direction: .deposit, amount: 4_000_000, date: day)
        store.add(deposit)
        deposit.amount = 5_000_000
        store.update(deposit)
        let extra = GoalTransfer(goalID: goal.id, accountID: wallet.id, direction: .deposit, amount: 100_000, date: day)
        store.add(extra)
        store.delete(extra)
        store.add(GoalTransfer(goalID: other.id, accountID: bank.id, direction: .deposit, amount: 1_000_000, date: day))
        store.delete(other, returningTo: wallet.id)
        store.spend(from: goal, categoryID: TransactionCategory.shopping.rawValue, amount: 3_000_000,
                    date: day, leftoverAccount: wallet.id)

        // Loans: lent, changed, repaid, a repayment changed and deleted; another lent then deleted.
        var loan = Loan(name: "An", direction: .lent, principal: 1_000_000, outstanding: 1_000_000, dueDate: nil,
                        accountID: wallet.id, date: day)
        store.save(loan)
        loan.principal = 1_500_000
        loan.outstanding = 1_500_000
        store.save(loan)
        var payment = LoanPayment(loanID: loan.id, principal: 500_000, interest: 20_000, accountID: bank.id,
                                  date: day.addingTimeInterval(3600))
        store.save(payment)
        payment.principal = 600_000
        store.save(payment)
        let late = LoanPayment(loanID: loan.id, principal: 100_000, interest: 0, accountID: wallet.id,
                               date: day.addingTimeInterval(7200))
        store.save(late)
        store.delete(late)
        let borrowed = Loan(name: "Bình", direction: .borrowed, principal: 2_000_000, outstanding: 2_000_000,
                            dueDate: nil, accountID: bank.id, date: day)
        store.save(borrowed)
        store.save(LoanPayment(loanID: borrowed.id, principal: 1_000_000, interest: 50_000, accountID: bank.id,
                               date: day.addingTimeInterval(3600)))
        store.delete(borrowed)

        // Typing a new balance records the difference.
        store.update(card, balance: -400_000)

        let reopened = open(container)
        for account in [wallet, bank, card] {
            #expect(reopened.account(id: account.id)?.balance == store.account(id: account.id)?.balance,
                    "\(account.name)")
        }
        #expect(reopened.goal(id: goal.id)?.saved == store.goal(id: goal.id)?.saved)
        #expect(reopened.account(id: card.id)?.balance == -400_000)
    }

    /// A balance stored by another device (the last write wins in iCloud) gives way to the history.
    @Test func aStoredBalanceGivesWayToTheHistory() throws {
        let container = FinanceDatabase.makeContainer(inMemory: true)
        let store = open(container)
        let wallet = Account(name: "Ví", type: .cash, balance: 1_000_000, openedAt: day)
        store.add(wallet)
        store.add(FinanceTransaction(amount: 100_000, category: .food, accountID: wallet.id, date: day))
        store.add(FinanceTransaction(amount: 200_000, category: .food, accountID: wallet.id, date: day))
        // As if the other device's write of the account (after only the first one) won.
        let context = ModelContext(container)
        let id = wallet.id
        let row = try #require(try context.fetch(FetchDescriptor<AccountRecord>(predicate: #Predicate { $0.id == id })).first)
        row.balance = 900_000
        try context.save()

        #expect(open(container).account(id: wallet.id)?.balance == 700_000)
    }

    /// The same built-in category from two devices: one stays, the older one.
    @Test func duplicateRowsBecomeOne() throws {
        let container = FinanceDatabase.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let first = CategoryRecord(id: "food", kind: "expense", name: "Ăn uống của tôi", icon: "hugeicons-rice-bowl-01",
                                   isBuiltIn: true, sortOrder: 0)
        first.createdAt = day
        let second = CategoryRecord(id: "food", kind: "expense", name: "Ăn uống", icon: "hugeicons-rice-bowl-01",
                                    isBuiltIn: true, sortOrder: 0)
        second.createdAt = day.addingTimeInterval(86_400)
        context.insert(first)
        context.insert(second)
        try context.save()

        let snapshot = FinanceDatabase(context: context).load()
        let food = snapshot.categories.filter { $0.id == "food" }
        #expect(food.count == 1)
        #expect(food.first?.name == "Ăn uống của tôi")
    }

    /// A database from V7 (stored balances that are not the sum of the history, as the sample
    /// data's): after the move to V8 every balance is still what it was.
    @Test func movingFromV7KeepsEveryBalance() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "Milu.store")
        let accountID = UUID()
        let goalID = UUID()
        do {
            let schema = Schema(versionedSchema: MiluSchemaV7.self)
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
            let context = ModelContext(container)
            context.insert(MiluSchemaV1.AccountRecord(id: accountID, name: "Ví", openingBalance: 5_000_000, balance: 2_345_000))
            context.insert(MiluSchemaV1.AccountRecord(id: goalID, name: "Hũ", type: SavingsGoal.accountType,
                                                     openingBalance: 0, balance: 750_000))
            let spending = MiluSchemaV1.TransactionRecord(id: UUID(), kind: "expense", amount: 300_000, occurredAt: day)
            spending.accountID = accountID
            spending.categoryID = TransactionCategory.food.rawValue
            context.insert(spending)
            let category = MiluSchemaV2.CategoryRecord(id: "food", kind: "expense", name: "Ăn uống", icon: "x",
                                                       isBuiltIn: true, sortOrder: 0)
            context.insert(category)
            try context.save()
        }
        UserDefaults.standard.removeObject(forKey: MiluMigrationPlan.needsRebaseKey)
        defer { UserDefaults.standard.removeObject(forKey: MiluMigrationPlan.needsRebaseKey) }

        let schema = Schema(versionedSchema: MiluSchemaV8.self)
        let container = try ModelContainer(for: schema, migrationPlan: MiluMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
        #expect(UserDefaults.standard.bool(forKey: MiluMigrationPlan.needsRebaseKey))
        let store = open(container)
        #expect(!UserDefaults.standard.bool(forKey: MiluMigrationPlan.needsRebaseKey))
        #expect(store.account(id: accountID)?.balance == 2_345_000)
        #expect(store.goal(id: goalID)?.saved == 750_000)
        // And from then on the history moves it.
        store.add(FinanceTransaction(amount: 45_000, category: .food, accountID: accountID, date: day))
        #expect(open(container).account(id: accountID)?.balance == 2_300_000)
    }
}
