import Foundation
import OSLog
import SwiftData

/// Reads and writes Milu's records in SwiftData. `FinanceStore` keeps the screens' arrays in
/// memory and calls this after every change, so each edit is saved at once (write-through).
/// All database code lives here; screens never touch SwiftData directly.
@MainActor
final class FinanceDatabase {
    private let context: ModelContext
    private let log = Logger(subsystem: "com.quyetnguyen.Milu", category: "database")
    /// Above 0 inside `batch`: writes wait for one save at its end.
    private var batchDepth = 0

    init(context: ModelContext) {
        self.context = context
    }

    /// The iCloud container the database syncs through (made on the developer account, 2026-11-12).
    static let cloudContainerID = "iCloud.com.quyetnguyen.Milu"

    /// The on-device database, kept in sync with the user's private iCloud database when
    /// `syncsWithICloud` (the app with its iCloud entitlement; signed out of iCloud it simply stays
    /// on the phone). If it cannot be opened with iCloud it opens without; if it cannot be opened
    /// at all, a database in memory, so the app still starts (that session's changes are then not
    /// kept).
    /// `inMemory`: a database that lives only while the app runs, for tests (same schema and
    /// migration plan as the real one, never synced).
    static func makeContainer(inMemory: Bool = false, syncsWithICloud: Bool = true) -> ModelContainer {
        let schema = Schema(versionedSchema: MiluSchemaV8.self)
        let log = Logger(subsystem: "com.quyetnguyen.Milu", category: "database")
        var configurations: [(ModelConfiguration, String)] = []
        if inMemory {
            configurations.append((ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none), "in memory"))
        } else {
            if syncsWithICloud {
                configurations.append((ModelConfiguration("Milu", schema: schema, cloudKitDatabase: .private(cloudContainerID)), "iCloud"))
            }
            configurations.append((ModelConfiguration("Milu", schema: schema, cloudKitDatabase: .none), "on device"))
        }
        for (configuration, label) in configurations {
            do {
                return try ModelContainer(for: schema, migrationPlan: MiluMigrationPlan.self, configurations: configuration)
            } catch {
                log.fault("Cannot open the database (\(label, privacy: .public)): \(error)")
            }
        }
        return try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    }

    // MARK: - Đọc

    struct Snapshot {
        var accounts: [Account]
        var archivedAccounts: [Account]
        var savingsGoals: [SavingsGoal]
        var transactions: [FinanceTransaction]
        var accountTransfers: [AccountTransfer]
        var goalTransfers: [GoalTransfer]
        var loans: [Loan]
        var loanPayments: [LoanPayment]
        var paymentReminders: [PaymentReminder]
        var categories: [Category]
        var contacts: [Contact]
        /// Only the ones the user added; the built-in ones are `ContactRelationship`.
        var relationships: [Relationship]
    }

    /// Every row, with balances worked out from the history (`BalanceLedger`); a balance that
    /// moved is written back. Duplicate rows from two devices go first (`removeDuplicates`).
    func load() -> Snapshot {
        removeDuplicates()
        let (snapshot, rows) = readAll()
        return settled(snapshot, rows: rows)
    }

    /// Sets each opening balance so that, with the history, it makes the balance stored today: once,
    /// after the move to V8 (`MiluMigrationPlan.needsRebaseKey`) and after seeding sample data, whose
    /// balances were never the sum of its history. Balances on screen do not change.
    func rebaseOpeningBalances() {
        let (snapshot, rows) = readAll()
        let moved = movements(in: snapshot)
        for row in rows {
            row.openingBalance = row.balance - Int64(dong: moved[row.id] ?? 0)
        }
        commit()
    }

    private func movements(in snapshot: Snapshot) -> [UUID: Double] {
        BalanceLedger.movements(transactions: snapshot.transactions, accountTransfers: snapshot.accountTransfers,
                                goalTransfers: snapshot.goalTransfers, loans: snapshot.loans,
                                loanPayments: snapshot.loanPayments)
    }

    /// The snapshot with every balance = opening + what the history moved.
    private func settled(_ snapshot: Snapshot, rows: [AccountRecord]) -> Snapshot {
        let moved = movements(in: snapshot)
        var balances: [UUID: Double] = [:]
        var changed = false
        for row in rows {
            let balance = row.openingBalance + Int64(dong: moved[row.id] ?? 0)
            balances[row.id] = Double(dong: balance)
            if row.balance != balance {
                row.balance = balance
                changed = true
            }
        }
        if changed { commit() }
        var snapshot = snapshot
        for index in snapshot.accounts.indices {
            snapshot.accounts[index].balance = balances[snapshot.accounts[index].id] ?? snapshot.accounts[index].balance
        }
        for index in snapshot.archivedAccounts.indices {
            snapshot.archivedAccounts[index].balance = balances[snapshot.archivedAccounts[index].id]
                ?? snapshot.archivedAccounts[index].balance
        }
        for index in snapshot.savingsGoals.indices {
            snapshot.savingsGoals[index].saved = balances[snapshot.savingsGoals[index].id] ?? snapshot.savingsGoals[index].saved
        }
        return snapshot
    }

    /// Every row as stored, and the account rows (goals too) the balances live on.
    private func readAll() -> (Snapshot, [AccountRecord]) {
        // Every row is loaded: closed goals are listed on "Hũ đã hoàn thành", archived accounts on
        // "Đã lưu trữ"; both keep their history.
        let goalType = SavingsGoal.accountType
        let accountRows = fetch(FetchDescriptor<AccountRecord>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]))
        let accounts = accountRows.filter { $0.type != goalType }.map(Account.init)
        let goalIDs = Set(accountRows.filter { $0.type == goalType }.map(\.id))
        // Once, not once per record (review 2026-11-09: rebuilt for each of thousands of rows at launch).
        let accountIDs = Set(accountRows.filter { $0.type != goalType }.map(\.id))
        let transactionRows = fetch(FetchDescriptor<TransactionRecord>(sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]))
        let snapshot = Snapshot(
            accounts: accounts.filter { !$0.isArchived },
            // The most recently archived first, as the screen lists them.
            archivedAccounts: accounts.filter(\.isArchived)
                .sorted { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) },
            savingsGoals: accountRows.filter { $0.type == goalType }.map(SavingsGoal.init),
            transactions: transactionRows.compactMap(FinanceTransaction.init),
            accountTransfers: transactionRows.compactMap(AccountTransfer.init),
            goalTransfers: transactionRows.compactMap {
                GoalTransfer($0, goalIDs: goalIDs, accountIDs: accountIDs)
            },
            loans: fetch(FetchDescriptor<LoanRecord>(sortBy: [SortDescriptor(\.createdAt)])).map(Loan.init),
            loanPayments: fetch(FetchDescriptor<LoanPaymentRecord>(sortBy: [SortDescriptor(\.paidAt, order: .reverse)]))
                .map(LoanPayment.init),
            paymentReminders: fetch(FetchDescriptor<ReminderRecord>(sortBy: [SortDescriptor(\.dueDate)])).map(PaymentReminder.init),
            categories: fetch(FetchDescriptor<CategoryRecord>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]))
                .filter { !Category.systemIDs.contains($0.id) }
                .map(Category.init),
            contacts: fetch(FetchDescriptor<ContactRecord>(sortBy: [SortDescriptor(\.createdAt)])).map(Contact.init),
            relationships: fetch(FetchDescriptor<RelationshipRecord>(sortBy: [SortDescriptor(\.createdAt)]))
                .map(Relationship.init)
        )
        return (snapshot, accountRows)
    }

    /// Two devices can each make a row with the same `id` before they sync (the built-in
    /// categories, which every install adds): the oldest stays, being the one the user may have
    /// changed since, and the others go.
    func removeDuplicates() {
        var removed = 0
        removed += removeDuplicates(of: AccountRecord.self, id: \.id)
        removed += removeDuplicates(of: CategoryRecord.self, id: \.id)
        removed += removeDuplicates(of: TransactionRecord.self, id: \.id)
        removed += removeDuplicates(of: LoanRecord.self, id: \.id)
        removed += removeDuplicates(of: LoanPaymentRecord.self, id: \.id)
        removed += removeDuplicates(of: ReminderRecord.self, id: \.id)
        removed += removeDuplicates(of: ContactRecord.self, id: \.id)
        removed += removeDuplicates(of: RelationshipRecord.self, id: \.id)
        if removed > 0 {
            log.info("Removed \(removed) duplicate rows")
            commit()
        }
    }

    private func removeDuplicates<T: PersistentModel & Dated, ID: Hashable>(of type: T.Type, id: KeyPath<T, ID>) -> Int {
        var seen: [ID: T] = [:]
        var removed = 0
        for row in fetch(FetchDescriptor<T>()) {
            let key = row[keyPath: id]
            guard let kept = seen[key] else {
                seen[key] = row
                continue
            }
            if row.createdAt < kept.createdAt {
                seen[key] = row
                context.delete(kept)
            } else {
                context.delete(row)
            }
            removed += 1
        }
        return removed
    }

    var isEmpty: Bool {
        ((try? context.fetchCount(FetchDescriptor<AccountRecord>())) ?? 0) == 0
    }

    // MARK: - Ghi

    func save(_ account: Account) {
        record(AccountRecord.self, id: account.id) {
            AccountRecord(id: $0, openingBalance: Int64(dong: account.balance), sortOrder: nextSortOrder())
        }
        .apply(account)
        commit()
    }

    func save(_ goal: SavingsGoal) {
        record(AccountRecord.self, id: goal.id) {
            AccountRecord(id: $0, type: SavingsGoal.accountType, openingBalance: Int64(dong: goal.saved),
                          sortOrder: nextSortOrder())
        }
        .apply(goal)
        commit()
    }

    /// Puts a row after all others: a restored account goes back to the end of the list, as on screen.
    func moveToEnd(_ id: UUID) {
        let order = nextSortOrder()
        guard let row = fetch(FetchDescriptor<AccountRecord>(predicate: AccountRecord.matching(id))).first else { return }
        row.sortOrder = order
        commit()
    }

    /// After every existing row, so something new stays at the end after a relaunch too.
    private func nextSortOrder() -> Int {
        var last = FetchDescriptor<AccountRecord>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        last.fetchLimit = 1
        return (fetch(last).first?.sortOrder ?? -1) + 1
    }

    /// Runs several writes and saves them as one, so one action (a transfer moving two balances)
    /// is never kept half done.
    func batch(_ body: () -> Void) {
        batchDepth += 1
        body()
        batchDepth -= 1
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

    func save(_ transfer: GoalTransfer) {
        record(TransactionRecord.self, id: transfer.id) { TransactionRecord(id: $0) }.apply(transfer)
        commit()
    }

    func save(_ transfer: AccountTransfer) {
        record(TransactionRecord.self, id: transfer.id) { TransactionRecord(id: $0) }.apply(transfer)
        commit()
    }

    // MARK: - Hạng mục

    func save(_ category: Category) {
        let row = categoryRecord(category.id) ?? {
            let row = CategoryRecord(id: category.id, kind: category.kind.rawValue, name: category.name,
                                     icon: category.icon, isBuiltIn: category.isBuiltIn, sortOrder: category.sortOrder)
            context.insert(row)
            return row
        }()
        row.apply(category)
        commit()
    }

    func deleteCategory(id: String) {
        if let row = categoryRecord(id) { context.delete(row) }
        commit()
    }

    private func categoryRecord(_ id: String) -> CategoryRecord? {
        fetch(FetchDescriptor<CategoryRecord>(predicate: #Predicate { $0.id == id })).first
    }

    /// Whether the default categories were ever added. Adding them happens once (a new install, or
    /// right after the move from V1), never again, so what the user deletes stays deleted, even
    /// all of it. A database that already has items (added before this flag existed) counts too.
    var defaultCategoriesAdded: Bool {
        if UserDefaults.standard.bool(forKey: Self.defaultsAddedKey) { return true }
        var descriptor = FetchDescriptor<CategoryRecord>(predicate: #Predicate { $0.parentID != nil })
        descriptor.fetchLimit = 1
        let hasItems = !fetch(descriptor).isEmpty
        if hasItems { UserDefaults.standard.set(true, forKey: Self.defaultsAddedKey) }
        return hasItems
    }

    private static let defaultsAddedKey = "categories.defaultsAdded"

    /// Adds the default groups and items that are not there yet: a new install gets them all, a
    /// database from V1 (12 flat categories, now groups) gets the items and the new groups. Rows
    /// that exist are left as the user has them, except two names from V1 brought to the current
    /// spelling. The balance-adjustment categories are added too, as the system needs them.
    func addMissingDefaultCategories() {
        UserDefaults.standard.set(true, forKey: Self.defaultsAddedKey)
        let existing = Dictionary(uniqueKeysWithValues: fetch(FetchDescriptor<CategoryRecord>()).map { ($0.id, $0) })
        for category in DefaultCategories.all where existing[category.id] == nil {
            let row = CategoryRecord(id: category.id, kind: category.kind.rawValue, name: category.name,
                                     icon: category.icon, isBuiltIn: true, sortOrder: category.sortOrder)
            row.apply(category)
            context.insert(row)
        }
        for category in [TransactionCategory.adjustmentIn, .adjustmentOut] where existing[category.rawValue] == nil {
            context.insert(CategoryRecord(category, sortOrder: 10_000))
        }
        for (old, new) in ["Hóa đơn": "Hoá đơn", "Sức khỏe": "Sức khoẻ"] {
            for row in existing.values where row.isBuiltIn && row.name == old { row.name = new }
        }
        // V1 seeded the groups 0…11; put them in the default order.
        for category in DefaultCategories.all where category.isGroup {
            if let row = existing[category.id], row.sortOrder < 100, row.isBuiltIn { row.sortOrder = category.sortOrder }
        }
        commit()
    }

    /// Icons the categories once had that are not in `IconCatalog` (so they could not be picked
    /// again), and look like the "Xem tất cả" / "Thêm" buttons: swapped for catalog ones.
    private static let retiredIcons = ["hugeicons-more-horizontal": "hugeicons-dashboard-square-01",
                                       "hugeicons-add-01": "hugeicons-money-add-02"]

    /// Rows from V1 may still hold the old Solar names of these icons ("solar-add-linear").
    func replaceRetiredIcons() {
        let rows = fetch(FetchDescriptor<CategoryRecord>())
            .filter { Self.retiredIcons[IconCatalog.migrated($0.icon)] != nil }
        guard !rows.isEmpty else { return }
        for row in rows { row.icon = Self.retiredIcons[IconCatalog.migrated(row.icon)] ?? row.icon }
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

    func save(_ payment: LoanPayment) {
        record(LoanPaymentRecord.self, id: payment.id) { LoanPaymentRecord(id: $0) }.apply(payment)
        commit()
    }

    func deleteLoanPayment(id: UUID) {
        delete(LoanPaymentRecord.self, id: id)
    }

    // MARK: - Danh bạ

    func save(_ contact: Contact) {
        record(ContactRecord.self, id: contact.id) { ContactRecord(id: $0) }.apply(contact)
        commit()
    }

    func deleteContact(id: UUID) {
        delete(ContactRecord.self, id: id)
    }

    func save(_ relationship: Relationship) {
        let row = relationshipRecord(relationship.id) ?? {
            let row = RelationshipRecord(id: relationship.id)
            context.insert(row)
            return row
        }()
        row.apply(relationship)
        commit()
    }

    func deleteRelationship(id: String) {
        if let row = relationshipRecord(id) { context.delete(row) }
        commit()
    }

    private func relationshipRecord(_ id: String) -> RelationshipRecord? {
        fetch(FetchDescriptor<RelationshipRecord>(predicate: #Predicate { $0.id == id })).first
    }

    func save(_ reminder: PaymentReminder) {
        record(ReminderRecord.self, id: reminder.id) { ReminderRecord(id: $0) }.apply(reminder)
        commit()
    }

    // MARK: - Dữ liệu mẫu

    /// Fills an empty database with the built-in categories and the sample data.
    func seed() {
        addMissingDefaultCategories()
        for (index, account) in SampleData.accounts.enumerated() {
            let row = AccountRecord(id: account.id, openingBalance: Int64(dong: account.balance), sortOrder: index)
            row.apply(account)
            row.createdAt = SampleData.openedAt(account)
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
        for transfer in SampleData.goalTransfers {
            let row = TransactionRecord(id: transfer.id)
            row.apply(transfer)
            row.createdAt = transfer.date
            context.insert(row)
        }
        for contact in SampleData.contacts {
            let row = ContactRecord(id: contact.id)
            row.apply(contact)
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
        // The sample balances are not the sum of the sample history: open them where they show.
        rebaseOpeningBalances()
    }

    /// Deletes every row, then seeds again: Cài đặt → Nhà phát triển → Đặt lại dữ liệu mẫu.
    func resetToSampleData() {
        UserDefaults.standard.set(false, forKey: StorageKey.sampleDataOff)
        deleteEverything()
        seed()
    }

    /// Xoá mọi dòng của mọi bảng, để trống như lúc mới cài: dùng cho "Xoá toàn bộ dữ liệu"
    /// (`DataReset`) và cho đặt lại dữ liệu mẫu.
    func deleteEverything() {
        do {
            // Row by row, not `delete(model:)`: a batch delete skips the iCloud mirror, so the rows
            // would come back from iCloud (and stay on the other devices).
            deleteAll(TransactionRecord.self)
            deleteAll(AccountRecord.self)
            deleteAll(CategoryRecord.self)
            deleteAll(LoanRecord.self)
            deleteAll(LoanPaymentRecord.self)
            deleteAll(ReminderRecord.self)
            deleteAll(ContactRecord.self)
            deleteAll(RelationshipRecord.self)
            // Saved before seeding, so the default categories are added to an empty table rather
            // than skipped as "already there".
            try context.save()
        } catch {
            log.error("Reset failed: \(error)")
        }
    }

    // MARK: - Nội bộ

    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        for row in fetch(FetchDescriptor<T>()) { context.delete(row) }
    }

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
        guard batchDepth == 0 else { return }
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

extension LoanPaymentRecord: IdentifiedRecord {
    static func matching(_ id: UUID) -> Predicate<LoanPaymentRecord> { #Predicate { $0.id == id } }
}

extension LoanRecord: IdentifiedRecord {
    static func matching(_ id: UUID) -> Predicate<LoanRecord> { #Predicate { $0.id == id } }
}

extension ContactRecord: IdentifiedRecord {
    static func matching(_ id: UUID) -> Predicate<ContactRecord> { #Predicate { $0.id == id } }
}

extension ReminderRecord: IdentifiedRecord {
    static func matching(_ id: UUID) -> Predicate<ReminderRecord> { #Predicate { $0.id == id } }
}

/// A row with the date it was made, to tell which of two duplicates came first.
protocol Dated {
    var createdAt: Date { get }
}

extension AccountRecord: Dated {}
extension CategoryRecord: Dated {}
extension TransactionRecord: Dated {}
extension LoanRecord: Dated {}
extension LoanPaymentRecord: Dated {}
extension ReminderRecord: Dated {}
extension ContactRecord: Dated {}
extension RelationshipRecord: Dated {}
