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
    let id = UUID()
    /// Người vay hoặc người cho mình vay.
    var name: String
    var direction: LoanDirection
    /// Số tiền gốc ban đầu.
    var principal: Double
    /// Số còn phải thu (cho vay) hoặc còn phải trả (đi vay).
    var outstanding: Double
    var dueDate: Date?

    var isSettled: Bool { outstanding <= 0 }
    var paidRatio: Double { principal > 0 ? min(max((principal - outstanding) / principal, 0), 1) : 0 }
}
