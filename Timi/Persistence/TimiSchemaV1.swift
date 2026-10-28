import Foundation
import SwiftData

/// Version 1 of Timi's on-device database. This schema is the reference for every Timi client:
/// the web app will move to it later, so names and rules here are written to map 1:1 onto SQL.
///
/// Rules every table follows:
/// - `id` is a UUID made on the device, so records can be created offline and synced later.
/// - Money is `Int64` in đồng (VND has no minor unit), never `Double`: sums stay exact.
/// - Links between records are plain ids, not SwiftData relationships, as foreign keys in SQL.
/// - Text enums are stored as their raw string (`"expense"`, `"bank"`…), never as Swift enums.
/// - `createdAt` / `updatedAt` on every row, for sync ("changed since…") and conflict resolution.
///
/// Changing a model means adding `TimiSchemaV2` and a stage in `TimiMigrationPlan`; never edit V1.
enum TimiSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AccountRecord.self, CategoryRecord.self, TransactionRecord.self, LoanRecord.self, ReminderRecord.self]
    }

    /// Anywhere money is kept: cash, bank, e-wallet, credit card, or a savings goal (`type == "savings"`,
    /// with the goal columns filled). Goals are accounts so moving money into one can later be a transfer.
    @Model
    final class AccountRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        /// "cash" | "bank" | "eWallet" | "credit" | "savings"
        var type: String
        /// `Institution.id` of the bank or wallet; nil for cash and savings.
        var institutionID: String?
        /// Second line under the name, e.g. "•••• 4821".
        var detail: String
        /// Balance when the account was added; `balance` = opening + its transactions.
        var openingBalance: Int64
        /// Current balance, kept up to date on every transaction (credit cards go negative).
        var balance: Int64
        /// Credit cards only.
        var creditLimit: Int64?
        var paymentDueDate: Date?
        /// Savings goals only.
        var goalTarget: Int64?
        var goalIcon: String?
        var goalDueDate: Date?
        /// Left out of totals and reports.
        var excluded: Bool
        /// Hidden but kept with its history; nil while in use.
        var archivedAt: Date?
        var sortOrder: Int
        var createdAt: Date
        var updatedAt: Date

        init(id: UUID, name: String = "", type: String = "cash", institutionID: String? = nil, detail: String = "",
             openingBalance: Int64 = 0, balance: Int64 = 0, sortOrder: Int = 0, createdAt: Date = .now) {
            self.id = id
            self.name = name
            self.type = type
            self.institutionID = institutionID
            self.detail = detail
            self.openingBalance = openingBalance
            self.balance = balance
            self.excluded = false
            self.sortOrder = sortOrder
            self.createdAt = createdAt
            self.updatedAt = createdAt
        }
    }

    /// A spending or income category. The 12 built-in ones use their `TransactionCategory` raw value
    /// as id ("food", "salary"…); categories the user adds later get a UUID string.
    @Model
    final class CategoryRecord {
        @Attribute(.unique) var id: String
        /// "expense" | "income"
        var kind: String
        var name: String
        /// Solar icon name.
        var icon: String
        var isBuiltIn: Bool
        var sortOrder: Int
        var archivedAt: Date?
        var createdAt: Date
        var updatedAt: Date

        init(id: String, kind: String, name: String, icon: String, isBuiltIn: Bool, sortOrder: Int) {
            self.id = id
            self.kind = kind
            self.name = name
            self.icon = icon
            self.isBuiltIn = isBuiltIn
            self.sortOrder = sortOrder
            self.createdAt = .now
            self.updatedAt = .now
        }
    }

    /// Money in, out, or between two accounts.
    /// - expense / income: `accountID` and `categoryID` set.
    /// - transfer: `fromAccountID` and `toAccountID` set, `fee` may be > 0 (not used by the app yet).
    /// - a loan payment also carries `loanID`.
    @Model
    final class TransactionRecord {
        // Index on occurredAt and accountID once the app targets iOS 18 (#Index is 18+).

        @Attribute(.unique) var id: UUID
        /// "expense" | "income" | "transfer"
        var kind: String
        /// Always > 0; the direction comes from `kind`.
        var amount: Int64
        var fee: Int64
        var accountID: UUID?
        var fromAccountID: UUID?
        var toAccountID: UUID?
        var categoryID: String?
        var loanID: UUID?
        var title: String
        var note: String
        var occurredAt: Date
        var excluded: Bool
        var createdAt: Date
        var updatedAt: Date

        init(id: UUID, kind: String = "expense", amount: Int64 = 0, occurredAt: Date = .now) {
            self.id = id
            self.kind = kind
            self.amount = amount
            self.fee = 0
            self.title = ""
            self.note = ""
            self.occurredAt = occurredAt
            self.excluded = false
            self.createdAt = .now
            self.updatedAt = .now
        }
    }

    /// Money lent to or borrowed from a person or lender.
    @Model
    final class LoanRecord {
        @Attribute(.unique) var id: UUID
        /// "lent" | "borrowed"
        var direction: String
        /// Who borrowed, or who lent to the user.
        var counterparty: String
        var principal: Int64
        /// Still to be repaid; 0 when settled.
        var outstanding: Int64
        var dueDate: Date?
        var note: String
        var settledAt: Date?
        var createdAt: Date
        var updatedAt: Date

        init(id: UUID, direction: String = "lent", counterparty: String = "", principal: Int64 = 0, outstanding: Int64 = 0) {
            self.id = id
            self.direction = direction
            self.counterparty = counterparty
            self.principal = principal
            self.outstanding = outstanding
            self.note = ""
            self.createdAt = .now
            self.updatedAt = .now
        }
    }

    /// A payment coming up ("Cần chú ý"): not money moved yet, so it never touches a balance.
    @Model
    final class ReminderRecord {
        @Attribute(.unique) var id: UUID
        var title: String
        var amount: Int64
        var isIncome: Bool
        var dueDate: Date
        var detail: String
        /// "icon" (value = Solar name) | "initials" (value = the letters)
        var avatarKind: String
        var avatarValue: String
        /// What it is about, when known.
        var loanID: UUID?
        var accountID: UUID?
        var createdAt: Date
        var updatedAt: Date

        init(id: UUID, title: String = "", amount: Int64 = 0, isIncome: Bool = false, dueDate: Date = .now) {
            self.id = id
            self.title = title
            self.amount = amount
            self.isIncome = isIncome
            self.dueDate = dueDate
            self.detail = ""
            self.avatarKind = "icon"
            self.avatarValue = "solar-calendar-linear"
            self.createdAt = .now
            self.updatedAt = .now
        }
    }
}

/// How to move an old database to the current schema. Empty while there is only V1.
enum TimiMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [TimiSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

// The rest of the app names the current version's models without the namespace.
typealias AccountRecord = TimiSchemaV1.AccountRecord
typealias CategoryRecord = TimiSchemaV1.CategoryRecord
typealias TransactionRecord = TimiSchemaV1.TransactionRecord
typealias LoanRecord = TimiSchemaV1.LoanRecord
typealias ReminderRecord = TimiSchemaV1.ReminderRecord
