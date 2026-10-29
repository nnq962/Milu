import SwiftUI

enum LoanDirection: String, CaseIterable, Identifiable {
    case lent, borrowed

    var id: Self { self }

    var title: String {
        switch self {
        case .lent: "Cho vay"
        case .borrowed: "Đi vay"
        }
    }
}

/// Khoản cho vay hoặc đi vay với người khác. Cho vay cộng vào tài sản ròng, đi vay tính vào nợ.
struct Loan: Identifiable, Hashable {
    /// Stable across launches: the same id is stored in the database.
    var id = UUID()
    /// Người vay hoặc người cho mình vay.
    var name: String
    var direction: LoanDirection
    /// Số tiền gốc ban đầu.
    var principal: Double
    /// Số còn phải thu (cho vay) hoặc còn phải trả (đi vay).
    var outstanding: Double
    var dueDate: Date?
    /// The person in "Danh bạ"; `name` is kept equal to their name. Nil only until the store links
    /// the loan on save.
    var contactID: Contact.ID? = nil
    /// From before the app (user choice 2026-10-29): no account's balance moved, and what is left
    /// to repay was typed. A new loan moves its principal out of (lent) or into (borrowed)
    /// `accountID` on `date`, and shows on "Thu chi" (neither income nor spending).
    var isExisting = false
    var accountID: Account.ID? = nil
    /// When it was lent or borrowed.
    var date = Date.now
    /// Percent of the principal due each month, the same every month (not on what is left,
    /// user choice 2026-10-29): 25tr at 1,5% is 375.000đ a month. 0 means none.
    var monthlyInterestRate: Double = 0

    var isSettled: Bool { outstanding <= 0 }

    /// "Đã trả 40%", never "100%" while something is left nor "0%" once something came back.
    var paidText: String {
        if isSettled { return "Đã trả đủ" }
        guard paidRatio > 0 else { return "Chưa trả" }
        let percent = min(max((paidRatio * 100).rounded(.down), 1), 99)
        return "Đã trả \(Int(percent))%"
    }
    /// Interest each month, on the principal.
    var monthlyInterest: Double { principal * monthlyInterestRate / 100 }
    /// The account the money moved with, a new loan only.
    var movedAccountID: Account.ID? { isExisting ? nil : accountID }
    var paidRatio: Double { principal > 0 ? min(max((principal - outstanding) / principal, 0), 1) : 0 }
}
