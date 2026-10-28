import SwiftUI

/// Scheduled amounts shown on the overview, separate from posted transactions/balances.
struct PaymentReminder: Identifiable {
    enum Avatar {
        case initials(String)
        case icon(String)
    }

    let id = UUID()
    var title: String
    var amount: Double
    var isIncome: Bool
    var dueDate: Date
    /// Dòng phụ ở mục Cần chú ý của tab Vay nợ, VD: "Cho vay · Minh Trần".
    var detail: String = ""
    var avatar: Avatar = .icon("solar-calendar-linear")

    var dueDescription: String { dueDate.dueDescription }
}
