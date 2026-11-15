import Foundation
import SwiftData

/// Version 10 (audit round 2, 2026-11-15): two columns, both optional or with a default, so the
/// move is lightweight and fits iCloud. Every other table is V8's or V9's.
/// - On a loan from before Milu, what was owed when it was entered (`openingOutstanding`): what is
///   left is then rebuilt from it and the repayments, as a new loan's is from its principal. The
///   figure stored alone was only the last device's to write it.
/// - On a recurring rule, "Không tính vào báo cáo" (`excluded`): every transaction it records
///   stays out of Báo cáo and the limits, not only the first.
///
/// iCloud needs both in its production schema before a build with them ships: in CloudKit
/// Console, container iCloud.com.quyetnguyen.Milu, Development, record type `CD_LoanRecord` field
/// `CD_openingOutstanding` and record type `CD_RecurringRuleRecord` field `CD_excluded`, both
/// INT(64); then "Deploy Schema Changes".
enum MiluSchemaV10: VersionedSchema {
    static let versionIdentifier = Schema.Version(10, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MiluSchemaV8.AccountRecord.self, MiluSchemaV8.CategoryRecord.self, MiluSchemaV9.TransactionRecord.self,
         LoanRecord.self, MiluSchemaV8.ReminderRecord.self, MiluSchemaV8.ContactRecord.self,
         MiluSchemaV8.RelationshipRecord.self, MiluSchemaV8.LoanPaymentRecord.self, RecurringRuleRecord.self]
    }

    /// As V8's, plus what a loan from before Milu owed when it was entered.
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
        /// **New in V10.** A loan from before Milu: what was left to repay when it was entered (or
        /// last changed in its form), before any repayment through Milu. Nil on a new loan, and on
        /// one stored before V10 until the app fills it in (`FinanceDatabase.settleLoans`).
        var openingOutstanding: Int64?
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

        init(id: UUID, direction: String = "lent", counterparty: String = "", principal: Int64 = 0, outstanding: Int64 = 0) {
            self.id = id
            self.direction = direction
            self.counterparty = counterparty
            self.principal = principal
            self.outstanding = outstanding
            self.note = ""
            self.isExisting = true
            self.monthlyInterestRate = 0
            self.createdAt = .now
            self.updatedAt = .now
        }
    }

    /// As V9's, plus "Không tính vào báo cáo".
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
        /// **New in V10.** What it records stays out of Báo cáo and the limits.
        var excluded: Bool = false
        var createdAt: Date = MiluSchemaV8.epoch
        var updatedAt: Date = MiluSchemaV8.epoch

        init(id: UUID) {
            self.id = id
            self.createdAt = .now
            self.updatedAt = .now
        }
    }
}

typealias LoanRecord = MiluSchemaV10.LoanRecord
typealias RecurringRuleRecord = MiluSchemaV10.RecurringRuleRecord
