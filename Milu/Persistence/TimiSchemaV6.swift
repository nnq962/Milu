import Foundation
import SwiftData

/// Version 6: a loan says whether it was there before the app (`isExisting`), and if not, the
/// account its money left or came into and when (`accountID`, `loanDate`); and its interest, a
/// percent of the principal each month (`monthlyInterestRate`, user request 2026-10-29). Every
/// other table is unchanged from V5.
enum TimiSchemaV6: VersionedSchema {
    static let versionIdentifier = Schema.Version(6, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimiSchemaV1.AccountRecord.self, TimiSchemaV2.CategoryRecord.self, TimiSchemaV1.TransactionRecord.self,
         LoanRecord.self, TimiSchemaV1.ReminderRecord.self, TimiSchemaV5.ContactRecord.self,
         TimiSchemaV4.RelationshipRecord.self]
    }

    /// Money lent to or borrowed from a person. As V3, plus where the money went and the interest.
    @Model
    final class LoanRecord {
        @Attribute(.unique) var id: UUID
        /// "lent" | "borrowed"
        var direction: String
        /// Who borrowed, or who lent to the user: the person's name, kept equal to it.
        var counterparty: String
        /// The `ContactRecord` this loan is with.
        var contactID: UUID?
        var principal: Int64
        /// Still to be repaid; 0 when settled.
        var outstanding: Int64
        var dueDate: Date?
        var note: String
        var settledAt: Date?
        /// **New in V6.** From before the app: no account's balance moved. True for rows from V5,
        /// which never moved one.
        var isExisting: Bool = true
        /// **New in V6.** A new loan: the account the money left (lent) or came into (borrowed).
        var accountID: UUID?
        /// **New in V6.** When the money moved; nil on rows from V5 (`createdAt` stands in).
        var loanDate: Date?
        /// **New in V6.** Percent of the principal due each month, the same every month; 0 = none.
        var monthlyInterestRate: Double = 0
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
}
