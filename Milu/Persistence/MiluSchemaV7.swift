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
