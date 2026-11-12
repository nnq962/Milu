import Foundation
import SwiftData

/// Version 8: ready for iCloud (user choice 2026-11-12: sync through the user's own iCloud, no
/// sign-in). CloudKit allows no unique constraint and needs a default on every non-optional
/// column, so each table is V7's with `@Attribute(.unique)` dropped and a default on every column;
/// names and types are unchanged. Without the constraint two devices can each make a row with the
/// same `id` (the built-in categories): `FinanceDatabase.removeDuplicates` keeps one.
///
/// Balances are no longer trusted as stored: two devices writing the same account would keep only
/// the last one's. They are worked out from `openingBalance` and the history on every load
/// (`BalanceLedger`); the move to V8 sets each `openingBalance` so today's balances stay as they
/// are (`FinanceDatabase.rebaseOpeningBalances`).
enum MiluSchemaV8: VersionedSchema {
    static let versionIdentifier = Schema.Version(8, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AccountRecord.self, CategoryRecord.self, TransactionRecord.self, LoanRecord.self, ReminderRecord.self,
         ContactRecord.self, RelationshipRecord.self, LoanPaymentRecord.self]
    }

    /// Fixed default for dates: CloudKit wants one, every row sets its own.
    static let epoch = Date(timeIntervalSince1970: 0)

    @Model
    final class AccountRecord {
        var id: UUID = UUID()
        var name: String = ""
        /// "cash" | "bank" | "eWallet" | "credit" | "savings"
        var type: String = "cash"
        var institutionID: String?
        var detail: String = ""
        /// Balance when the account was added; with the history it makes `balance` (`BalanceLedger`).
        var openingBalance: Int64 = 0
        /// The last balance worked out, kept for readers of the row; the ledger is the truth.
        var balance: Int64 = 0
        var creditLimit: Int64?
        var paymentDueDate: Date?
        var goalTarget: Int64?
        var goalIcon: String?
        var goalDueDate: Date?
        var excluded: Bool = false
        var archivedAt: Date?
        var sortOrder: Int = 0
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

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

    @Model
    final class CategoryRecord {
        var id: String = ""
        /// "expense" | "income"
        var kind: String = "expense"
        var parentID: String?
        var name: String = ""
        var icon: String = ""
        var isBuiltIn: Bool = false
        var sortOrder: Int = 0
        var archivedAt: Date?
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

        init(id: String, kind: String, parentID: String? = nil, name: String, icon: String,
             isBuiltIn: Bool, sortOrder: Int) {
            self.id = id
            self.kind = kind
            self.parentID = parentID
            self.name = name
            self.icon = icon
            self.isBuiltIn = isBuiltIn
            self.sortOrder = sortOrder
            self.createdAt = .now
            self.updatedAt = .now
        }
    }

    @Model
    final class TransactionRecord {
        var id: UUID = UUID()
        /// "expense" | "income" | "transfer"
        var kind: String = "expense"
        var amount: Int64 = 0
        var fee: Int64 = 0
        var accountID: UUID?
        var fromAccountID: UUID?
        var toAccountID: UUID?
        var categoryID: String?
        var loanID: UUID?
        var title: String = ""
        var note: String = ""
        var occurredAt: Date = MiluSchemaV8.epoch
        var excluded: Bool = false
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

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

    @Model
    final class LoanRecord {
        var id: UUID = UUID()
        /// "lent" | "borrowed"
        var direction: String = "lent"
        var counterparty: String = ""
        var contactID: UUID?
        var principal: Int64 = 0
        var outstanding: Int64 = 0
        var dueDate: Date?
        var note: String = ""
        var settledAt: Date?
        var isExisting: Bool = true
        var accountID: UUID?
        var loanDate: Date?
        var monthlyInterestRate: Double = 0
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

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

    @Model
    final class ReminderRecord {
        var id: UUID = UUID()
        var title: String = ""
        var amount: Int64 = 0
        var isIncome: Bool = false
        var dueDate: Date = MiluSchemaV8.epoch
        var detail: String = ""
        var avatarKind: String = "icon"
        var avatarValue: String = "hugeicons-calendar-03"
        var loanID: UUID?
        var accountID: UUID?
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

        init(id: UUID, title: String = "", amount: Int64 = 0, isIncome: Bool = false, dueDate: Date = .now) {
            self.id = id
            self.title = title
            self.amount = amount
            self.isIncome = isIncome
            self.dueDate = dueDate
            self.detail = ""
            self.avatarKind = "icon"
            self.avatarValue = "hugeicons-calendar-03"
            self.createdAt = .now
            self.updatedAt = .now
        }
    }

    @Model
    final class ContactRecord {
        var id: UUID = UUID()
        var name: String = ""
        var relationship: String = "other"
        var isAutoCreated: Bool = false
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

        init(id: UUID, name: String = "", relationship: String = "other") {
            self.id = id
            self.name = name
            self.relationship = relationship
            self.createdAt = .now
            self.updatedAt = .now
        }
    }

    @Model
    final class RelationshipRecord {
        var id: String = ""
        var name: String = ""
        var icon: String = "hugeicons-user"
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

        init(id: String, name: String = "", icon: String = "hugeicons-user") {
            self.id = id
            self.name = name
            self.icon = icon
            self.createdAt = .now
            self.updatedAt = .now
        }
    }

    @Model
    final class LoanPaymentRecord {
        var id: UUID = UUID()
        var loanID: UUID = UUID()
        var principal: Int64 = 0
        var interest: Int64 = 0
        var accountID: UUID = UUID()
        var paidAt: Date = MiluSchemaV8.epoch
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

        init(id: UUID, loanID: UUID = UUID(), principal: Int64 = 0, interest: Int64 = 0, accountID: UUID = UUID(),
             paidAt: Date = .now) {
            self.id = id
            self.loanID = loanID
            self.principal = principal
            self.interest = interest
            self.accountID = accountID
            self.paidAt = paidAt
            self.createdAt = .now
            self.updatedAt = .now
        }
    }
}

/// How to move an old database to the current schema. V1 → V7 each only add columns with a
/// default or a table, so SwiftData migrates them on its own: V1 → V2 makes every category a
/// group; V2 → V3 adds "Danh bạ", and `FinanceStore` then gives each loan's name a person
/// (`linkLoansToContacts`); V3 → V4 adds the relationships the user makes; V4 → V5 marks the people
/// the app made; V5 → V6 adds a loan's account, date and interest (old loans count as from before
/// the app); V6 → V7 adds repayments. V7 → V8 drops the unique constraints and adds defaults (for
/// iCloud), then asks for the opening balances to be set from today's (`needsRebase`).
enum MiluMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [MiluSchemaV1.self, MiluSchemaV2.self, MiluSchemaV3.self, MiluSchemaV4.self, MiluSchemaV5.self,
         MiluSchemaV6.self, MiluSchemaV7.self, MiluSchemaV8.self]
    }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: MiluSchemaV1.self, toVersion: MiluSchemaV2.self),
         .lightweight(fromVersion: MiluSchemaV2.self, toVersion: MiluSchemaV3.self),
         .lightweight(fromVersion: MiluSchemaV3.self, toVersion: MiluSchemaV4.self),
         .lightweight(fromVersion: MiluSchemaV4.self, toVersion: MiluSchemaV5.self),
         .lightweight(fromVersion: MiluSchemaV5.self, toVersion: MiluSchemaV6.self),
         .lightweight(fromVersion: MiluSchemaV6.self, toVersion: MiluSchemaV7.self),
         .custom(fromVersion: MiluSchemaV7.self, toVersion: MiluSchemaV8.self, willMigrate: nil, didMigrate: { _ in
             // Done once the store is open, after the launch fix-ups (`FinanceStore.init`).
             UserDefaults.standard.set(true, forKey: needsRebaseKey)
         })]
    }

    /// Set by the move to V8: the opening balances still have to be set from today's balances.
    static let needsRebaseKey = "db.needsBalanceRebase"
}

// The rest of the app names the current version's models without the namespace.
typealias AccountRecord = MiluSchemaV8.AccountRecord
typealias CategoryRecord = MiluSchemaV8.CategoryRecord
typealias TransactionRecord = MiluSchemaV8.TransactionRecord
typealias LoanRecord = MiluSchemaV8.LoanRecord
typealias ReminderRecord = MiluSchemaV8.ReminderRecord
typealias ContactRecord = MiluSchemaV8.ContactRecord
typealias RelationshipRecord = MiluSchemaV8.RelationshipRecord
typealias LoanPaymentRecord = MiluSchemaV8.LoanPaymentRecord
