import Foundation
import SwiftData

/// Version 7: a loan's repayments ("Thu nợ" / "Trả nợ", user request 2026-10-29), each with the
/// principal it pays off, the interest, the account the money moved with and the day. Every other
/// table is unchanged from V6.
enum MiluSchemaV7: VersionedSchema {
    static let versionIdentifier = Schema.Version(7, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MiluSchemaV1.AccountRecord.self, MiluSchemaV2.CategoryRecord.self, MiluSchemaV1.TransactionRecord.self,
         MiluSchemaV6.LoanRecord.self, MiluSchemaV1.ReminderRecord.self, MiluSchemaV5.ContactRecord.self,
         MiluSchemaV4.RelationshipRecord.self, LoanPaymentRecord.self]
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
enum MiluMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [MiluSchemaV1.self, MiluSchemaV2.self, MiluSchemaV3.self, MiluSchemaV4.self, MiluSchemaV5.self,
         MiluSchemaV6.self, MiluSchemaV7.self]
    }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: MiluSchemaV1.self, toVersion: MiluSchemaV2.self),
         .lightweight(fromVersion: MiluSchemaV2.self, toVersion: MiluSchemaV3.self),
         .lightweight(fromVersion: MiluSchemaV3.self, toVersion: MiluSchemaV4.self),
         .lightweight(fromVersion: MiluSchemaV4.self, toVersion: MiluSchemaV5.self),
         .lightweight(fromVersion: MiluSchemaV5.self, toVersion: MiluSchemaV6.self),
         .lightweight(fromVersion: MiluSchemaV6.self, toVersion: MiluSchemaV7.self)]
    }
}

// The rest of the app names the current version's models without the namespace.
typealias AccountRecord = MiluSchemaV1.AccountRecord
typealias CategoryRecord = MiluSchemaV2.CategoryRecord
typealias TransactionRecord = MiluSchemaV1.TransactionRecord
typealias LoanRecord = MiluSchemaV6.LoanRecord
typealias ReminderRecord = MiluSchemaV1.ReminderRecord
typealias ContactRecord = MiluSchemaV5.ContactRecord
typealias RelationshipRecord = MiluSchemaV4.RelationshipRecord
typealias LoanPaymentRecord = MiluSchemaV7.LoanPaymentRecord
