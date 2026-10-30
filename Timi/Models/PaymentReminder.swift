import SwiftUI

/// Scheduled amounts shown on the overview, separate from posted transactions/balances.
struct PaymentReminder: Identifiable {
    enum Avatar {
        case initials(String)
        case icon(String)
    }

    /// Stable across launches: the same id is stored in the database.
    var id = UUID()
    var title: String
    var amount: Double
    var isIncome: Bool
    var dueDate: Date
    /// Dòng phụ ở mục Cần chú ý của tab Vay nợ, VD: "Cho vay · Minh Trần".
    var detail: String = ""
    var avatar: Avatar = .icon("hugeicons-calendar-03")

}
