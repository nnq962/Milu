import Foundation
import SwiftData

/// Version 3: "Danh bạ" (user request 2026-10-29). A new table of people, and a loan keeps the id of
/// the person it is with (`LoanRecord.contactID`). Every other table is unchanged from V2.
enum TimiSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimiSchemaV1.AccountRecord.self, TimiSchemaV2.CategoryRecord.self, TimiSchemaV1.TransactionRecord.self,
         LoanRecord.self, TimiSchemaV1.ReminderRecord.self, ContactRecord.self]
    }

    /// A person loans are with: a name and how the user knows them.
    @Model
    final class ContactRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        /// "family" | "friend" | "colleague" | "acquaintance" | "other"
        var relationship: String
        var createdAt: Date
        var updatedAt: Date

        init(id: UUID, name: String = "", relationship: String = "other") {
            self.id = id
            self.name = name
            self.relationship = relationship
            self.createdAt = .now
            self.updatedAt = .now
        }
    }

    /// Money lent to or borrowed from a person or lender. As V1, plus `contactID`.
    @Model
    final class LoanRecord {
        @Attribute(.unique) var id: UUID
        /// "lent" | "borrowed"
        var direction: String
        /// Who borrowed, or who lent to the user: the person's name, kept equal to it.
        var counterparty: String
        /// **New in V3.** The `ContactRecord` this loan is with; nil on rows from V2 until the app
        /// links them at launch.
        var contactID: UUID?
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
}
