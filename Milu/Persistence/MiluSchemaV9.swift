import Foundation
import SwiftData

/// Version 9: "Giao dịch định kỳ" (user request 2026-11-12). A table of rules (`RecurringRuleRecord`)
/// and, on a transaction, the rule that recorded it (`recurringRuleID`). Every other table is V8's.
/// Both only add, with defaults, so the move is lightweight and fits iCloud.
enum MiluSchemaV9: VersionedSchema {
    static let versionIdentifier = Schema.Version(9, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MiluSchemaV8.AccountRecord.self, MiluSchemaV8.CategoryRecord.self, TransactionRecord.self,
         MiluSchemaV8.LoanRecord.self, MiluSchemaV8.ReminderRecord.self, MiluSchemaV8.ContactRecord.self,
         MiluSchemaV8.RelationshipRecord.self, MiluSchemaV8.LoanPaymentRecord.self, RecurringRuleRecord.self]
    }

    /// As V8's, plus the rule that recorded it.
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
        /// **New in V9.** The `RecurringRuleRecord` that recorded it; nil for one recorded by hand.
        var recurringRuleID: UUID?
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

    /// **New in V9.** A spending or income that comes back on a schedule (`RecurringRule`).
    @Model
    final class RecurringRuleRecord {
        var id: UUID = UUID()
        /// "expense" | "income"
        var kind: String = "expense"
        var amount: Int64 = 0
        var categoryID: String = ""
        var accountID: UUID?
        var note: String = ""
        /// "daily" | "weekly" | "monthly" | "yearly"
        var frequency: String = "monthly"
        var interval: Int = 1
        var startDate: Date = MiluSchemaV8.epoch
        var endDate: Date?
        var autoRecords: Bool = false
        var lastHandled: Date?
        var pausedAt: Date?
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

        init(id: UUID) {
            self.id = id
            self.createdAt = .now
            self.updatedAt = .now
        }
    }
}

typealias TransactionRecord = MiluSchemaV9.TransactionRecord
typealias RecurringRuleRecord = MiluSchemaV9.RecurringRuleRecord
