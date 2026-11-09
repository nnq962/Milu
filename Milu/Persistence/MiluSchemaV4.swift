import Foundation
import SwiftData

/// Version 4: relationships the user adds in "Danh bạ" ("Hàng xóm"), each with a name and an icon
/// (user request 2026-10-29). `ContactRecord.relationship` holds either a built-in one ("friend")
/// or the `id` of one of these. Every other table is unchanged from V3.
enum MiluSchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MiluSchemaV1.AccountRecord.self, MiluSchemaV2.CategoryRecord.self, MiluSchemaV1.TransactionRecord.self,
         MiluSchemaV3.LoanRecord.self, MiluSchemaV1.ReminderRecord.self, MiluSchemaV3.ContactRecord.self,
         RelationshipRecord.self]
    }

    /// A relationship the user added. The five built in ("family"…) have no row.
    @Model
    final class RelationshipRecord {
        /// A UUID string, so it never clashes with a built-in id.
        @Attribute(.unique) var id: String
        var name: String
        /// Icon asset name ("hugeicons-home-01").
        var icon: String
        var createdAt: Date
        var updatedAt: Date

        init(id: String, name: String = "", icon: String = "hugeicons-user") {
            self.id = id
            self.name = name
            self.icon = icon
            self.createdAt = .now
            self.updatedAt = .now
        }
    }
}
