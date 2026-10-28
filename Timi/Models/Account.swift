import SwiftUI

enum AccountType: String, CaseIterable, Identifiable {
    case cash, bank, eWallet, credit

    var id: Self { self }

    /// Nhóm hiện ở mục "Tài khoản thanh toán"; thẻ tín dụng thuộc phần vay nợ.
    static let paymentTypes: [AccountType] = [.cash, .bank, .eWallet]

    var title: String {
        switch self {
        case .cash: "Tiền mặt"
        case .bank: "Ngân hàng"
        case .eWallet: "Ví điện tử"
        case .credit: "Thẻ tín dụng"
        }
    }

    var icon: String {
        switch self {
        case .cash: "hugeicons-money-02"
        case .bank: "hugeicons-bank"
        case .eWallet: "hugeicons-smart-phone-01"
        case .credit: "hugeicons-credit-card"
        }
    }
}

struct Account: Identifiable, Hashable {
    /// Stable across launches: the same id is stored in the database.
    var id = UUID()
    var name: String
    var type: AccountType
    /// Số dư hiện tại. Thẻ tín dụng mang số âm (đang nợ).
    var balance: Double
    /// Ghi chú người dùng nhập khi thêm tài khoản (có thể trống).
    var detail: String = ""
    /// Chỉ thẻ tín dụng: hạn mức và hạn thanh toán kỳ này, hiện ở mục Đi vay.
    var creditLimit: Double? = nil
    var paymentDueDate: Date? = nil
    /// The bank or e-wallet it belongs to (`Institution.id`); nil for cash or when not picked.
    var institutionID: String? = nil
    /// When the user started tracking it (chosen in the form, now by default).
    var openedAt: Date = .now
    /// "Khoá tài khoản": kept out of totals and reports, and not offered when recording money
    /// (frozen funds, money set aside, someone else's cash…). Stored as `excluded`.
    var isLocked = false

    var institution: Institution? { Institution.find(institutionID) }

    /// The bank's logo when one was picked, otherwise the account type's icon (see `RowIcon`).
    var iconName: String { institution?.logoImage ?? type.icon }
}
