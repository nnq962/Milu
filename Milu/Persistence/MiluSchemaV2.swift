import Foundation
import SwiftData

/// Version 2: categories get a level. A category is either a group ("Ăn uống", `parentID == nil`)
/// or an item inside one ("Ăn sáng", `parentID` = the group's id), for both spending and income
/// (user request 2026-10-29). Every other table is unchanged from V1.
enum MiluSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MiluSchemaV1.AccountRecord.self, CategoryRecord.self, MiluSchemaV1.TransactionRecord.self,
         MiluSchemaV1.LoanRecord.self, MiluSchemaV1.ReminderRecord.self]
    }

    /// A spending or income category. The built-in ones keep fixed ids: the V1 groups use their
    /// `TransactionCategory` raw value ("food", "salary"…), their items "food.breakfast"; categories
    /// the user adds get a UUID string.
    @Model
    final class CategoryRecord {
        @Attribute(.unique) var id: String
        /// "expense" | "income"
        var kind: String
        /// nil for a group; the group's `id` for an item in it.
        var parentID: String?
        var name: String
        /// Icon asset name ("hugeicons-car-01"); older rows may hold a Solar name (`IconCatalog.migrated` maps it).
        var icon: String
        var isBuiltIn: Bool
        var sortOrder: Int
        /// Hidden: kept for the transactions that use it, no longer offered.
        var archivedAt: Date?
        var createdAt: Date
        var updatedAt: Date

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
}
