import Foundation
import SwiftData

/// Version 7: a loan's repayments ("Thu nợ" / "Trả nợ", user request 2026-10-29), each with the
/// principal it pays off, the interest, the account the money moved with and the day. Every other
/// table is unchanged from V6.
enum TimiSchemaV7: VersionedSchema {
    static let versionIdentifier = Schema.Version(7, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimiSchemaV1.AccountRecord.self, TimiSchemaV2.CategoryRecord.self, TimiSchemaV1.TransactionRecord.self,
         TimiSchemaV6.LoanRecord.self, TimiSchemaV1.ReminderRecord.self, TimiSchemaV5.ContactRecord.self,
         TimiSchemaV4.RelationshipRecord.self, LoanPaymentRecord.self]
    }

    /// **New in V7.** One repayment of a `LoanRecord`.
    @Model
    final class LoanPaymentRecord {
        @Attribute(.unique) var id: UUID
        var loanID: UUID
        /// Pays off this much of what is left.
        var principal: Int64
        var interest: Int64
        var accountID: UUID
        var paidAt: Date
        var createdAt: Date
        var updatedAt: Date

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

/// How to move an old database to the current schema. Each step only adds columns with a default
/// or a table, so SwiftData migrates it on its own: V1 → V2 makes every category a group; V2 → V3
/// adds "Danh bạ", and `FinanceStore` then gives each loan's name a person (`linkLoansToContacts`);
/// V3 → V4 adds the relationships the user makes; V4 → V5 marks the people the app made; V5 → V6
/// adds a loan's account, date and interest (old loans count as from before the app); V6 → V7
/// adds repayments.
enum TimiMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [TimiSchemaV1.self, TimiSchemaV2.self, TimiSchemaV3.self, TimiSchemaV4.self, TimiSchemaV5.self,
         TimiSchemaV6.self, TimiSchemaV7.self]
    }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: TimiSchemaV1.self, toVersion: TimiSchemaV2.self),
         .lightweight(fromVersion: TimiSchemaV2.self, toVersion: TimiSchemaV3.self),
         .lightweight(fromVersion: TimiSchemaV3.self, toVersion: TimiSchemaV4.self),
         .lightweight(fromVersion: TimiSchemaV4.self, toVersion: TimiSchemaV5.self),
         .lightweight(fromVersion: TimiSchemaV5.self, toVersion: TimiSchemaV6.self),
         .lightweight(fromVersion: TimiSchemaV6.self, toVersion: TimiSchemaV7.self)]
    }
}

// The rest of the app names the current version's models without the namespace.
typealias AccountRecord = TimiSchemaV1.AccountRecord
typealias CategoryRecord = TimiSchemaV2.CategoryRecord
typealias TransactionRecord = TimiSchemaV1.TransactionRecord
typealias LoanRecord = TimiSchemaV6.LoanRecord
typealias ReminderRecord = TimiSchemaV1.ReminderRecord
typealias ContactRecord = TimiSchemaV5.ContactRecord
typealias RelationshipRecord = TimiSchemaV4.RelationshipRecord
typealias LoanPaymentRecord = TimiSchemaV7.LoanPaymentRecord
