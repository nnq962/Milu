import Foundation
import SwiftData

/// Version 5: a person in "Danh bạ" knows whether the app made them from a loan's name
/// (`ContactRecord.isAutoCreated`), so they go once their last loan does (user request 2026-10-29).
/// Every other table is unchanged from V4.
enum TimiSchemaV5: VersionedSchema {
    static let versionIdentifier = Schema.Version(5, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimiSchemaV1.AccountRecord.self, TimiSchemaV2.CategoryRecord.self, TimiSchemaV1.TransactionRecord.self,
         TimiSchemaV3.LoanRecord.self, TimiSchemaV1.ReminderRecord.self, ContactRecord.self,
         TimiSchemaV4.RelationshipRecord.self]
    }

    /// A person loans are with: a name and how the user knows them. As V3, plus `isAutoCreated`.
    @Model
    final class ContactRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        /// "family" | "friend" | "colleague" | "acquaintance" | "other", or a `RelationshipRecord` id.
        var relationship: String
        /// **New in V5.** Made by the app from the name typed on a loan, and not edited in Danh bạ
        /// since: deleted with their last loan. False for rows from V4.
        var isAutoCreated: Bool = false
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
}
