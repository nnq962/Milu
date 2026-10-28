import Foundation
import OSLog
import SwiftData

/// Reads and writes Timi's records in SwiftData. `FinanceStore` keeps the screens' arrays in
/// memory and calls this after every change, so each edit is saved at once (write-through).
/// All database code lives here; screens never touch SwiftData directly.
@MainActor
final class FinanceDatabase {
    private let context: ModelContext
    private let log = Logger(subsystem: "Timi", category: "database")

    init(context: ModelContext) {
        self.context = context
    }

    /// The on-device database; falls back to memory only if the file cannot be opened, so the app
    /// still starts (that session's changes are then not kept).
    static func makeContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: TimiSchemaV1.self)
        do {
            return try ModelContainer(for: schema, migrationPlan: TimiMigrationPlan.self,
                                      configurations: ModelConfiguration("Timi", schema: schema))
        } catch {
            Logger(subsystem: "Timi", category: "database").fault("Cannot open the database: \(error)")
            return try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }

    // MARK: - Đọc

    struct Snapshot {
        var accounts: [Account]
        var savingsGoals: [SavingsGoal]
        var transactions: [FinanceTransaction]
        var loans: [Loan]
        var paymentReminders: [PaymentReminder]
    }

    func load() -> Snapshot {
        let accountRows = fetch(FetchDescriptor<AccountRecord>(
            predicate: #Predicate { $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]))
        let goalType = SavingsGoal.accountType
        return Snapshot(
            accounts: accountRows.filter { $0.type != goalType }.map(Account.init),
            savingsGoals: accountRows.filter { $0.type == goalType }.map(SavingsGoal.init),
            transactions: fetch(FetchDescriptor<TransactionRecord>(sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]))
                .compactMap(FinanceTransaction.init),
            loans: fetch(FetchDescriptor<LoanRecord>(sortBy: [SortDescriptor(\.createdAt)])).map(Loan.init),
            paymentReminders: fetch(FetchDescriptor<ReminderRecord>(sortBy: [SortDescriptor(\.dueDate)])).map(PaymentReminder.init)
        )
    }

    var isEmpty: Bool {
        ((try? context.fetchCount(FetchDescriptor<AccountRecord>())) ?? 0) == 0
    }

    // MARK: - Ghi

    func save(_ account: Account) {
        record(AccountRecord.self, id: account.id) { AccountRecord(id: $0, openingBalance: Int64(dong: account.balance)) }
            .apply(account)
        commit()
    }

    func save(_ goal: SavingsGoal) {
        record(AccountRecord.self, id: goal.id) { AccountRecord(id: $0, type: SavingsGoal.accountType, openingBalance: Int64(dong: goal.saved)) }
            .apply(goal)
        commit()
    }

    func deleteAccount(id: UUID, transactionIDs: [UUID] = []) {
        for transactionID in transactionIDs {
            for row in fetch(FetchDescriptor<TransactionRecord>(predicate: TransactionRecord.matching(transactionID))) {
                context.delete(row)
            }
        }
        delete(AccountRecord.self, id: id)
    }

    func save(_ transaction: FinanceTransaction) {
        record(TransactionRecord.self, id: transaction.id) { TransactionRecord(id: $0) }.apply(transaction)
        commit()
    }

    func deleteTransaction(id: UUID) {
        delete(TransactionRecord.self, id: id)
    }

    func save(_ loan: Loan) {
        record(LoanRecord.self, id: loan.id) { LoanRecord(id: $0) }.apply(loan)
        commit()
    }

    func deleteLoan(id: UUID) {
        delete(LoanRecord.self, id: id)
    }

    func save(_ reminder: PaymentReminder) {
        record(ReminderRecord.self, id: reminder.id) { ReminderRecord(id: $0) }.apply(reminder)
        commit()
    }

    // MARK: - Dữ liệu mẫu

    /// Fills an empty database with the built-in categories and the sample data.
    func seed() {
        for (index, category) in TransactionCategory.allCases.enumerated() {
            context.insert(CategoryRecord(category, sortOrder: index))
        }
        for (index, account) in SampleData.accounts.enumerated() {
            let row = AccountRecord(id: account.id, openingBalance: Int64(dong: account.balance), sortOrder: index)
            row.apply(account)
            context.insert(row)
        }
        for (index, goal) in SampleData.savingsGoals.enumerated() {
            let row = AccountRecord(id: goal.id, type: SavingsGoal.accountType, openingBalance: 0, sortOrder: 100 + index)
            row.apply(goal)
            context.insert(row)
        }
        for transaction in SampleData.transactions {
            let row = TransactionRecord(id: transaction.id)
            row.apply(transaction)
            row.createdAt = transaction.date
            context.insert(row)
        }
        for loan in SampleData.loans {
            let row = LoanRecord(id: loan.id)
            row.apply(loan)
            context.insert(row)
        }
        for reminder in SampleData.paymentReminders {
            let row = ReminderRecord(id: reminder.id)
            row.apply(reminder)
            context.insert(row)
        }
        commit()
    }

    /// Deletes every row, then seeds again: Cài đặt → Nhà phát triển → Đặt lại dữ liệu mẫu.
    func resetToSampleData() {
        do {
            try context.delete(model: TransactionRecord.self)
            try context.delete(model: AccountRecord.self)
            try context.delete(model: CategoryRecord.self)
            try context.delete(model: LoanRecord.self)
            try context.delete(model: ReminderRecord.self)
        } catch {
            log.error("Reset failed: \(error)")
        }
        seed()
    }

    // MARK: - Nội bộ

    private func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        do {
            return try context.fetch(descriptor)
        } catch {
            log.error("Fetch \(T.self) failed: \(error)")
            return []
        }
    }

    /// The row with `id`, or a new one made by `make` and inserted.
    private func record<T: IdentifiedRecord>(_ type: T.Type, id: UUID, make: (UUID) -> T) -> T {
        if let existing = fetch(FetchDescriptor<T>(predicate: T.matching(id))).first {
            return existing
        }
        let row = make(id)
        context.insert(row)
        return row
    }

    private func delete<T: IdentifiedRecord>(_ type: T.Type, id: UUID) {
        for row in fetch(FetchDescriptor<T>(predicate: T.matching(id))) {
            context.delete(row)
        }
        commit()
    }

    private func commit() {
        do {
            try context.save()
        } catch {
            log.error("Save failed: \(error)")
        }
    }
}

/// A record keyed by a UUID `id`, so one lookup serves every table.
protocol IdentifiedRecord: PersistentModel {
    static func matching(_ id: UUID) -> Predicate<Self>
}

extension AccountRecord: IdentifiedRecord {
    static func matching(_ id: UUID) -> Predicate<AccountRecord> { #Predicate { $0.id == id } }
}

extension TransactionRecord: IdentifiedRecord {
    static func matching(_ id: UUID) -> Predicate<TransactionRecord> { #Predicate { $0.id == id } }
}

extension LoanRecord: IdentifiedRecord {
    static func matching(_ id: UUID) -> Predicate<LoanRecord> { #Predicate { $0.id == id } }
}

extension ReminderRecord: IdentifiedRecord {
    static func matching(_ id: UUID) -> Predicate<ReminderRecord> { #Predicate { $0.id == id } }
}
