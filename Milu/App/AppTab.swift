import SwiftUI

enum AppTab: Hashable {
    /// Trợ lý AI is no tab: Tổng quan pushes it as a page of its own (user request 2026-10-30).
    case overview, accounts, transactions
    /// The + beside the tab bar: never shown as a page, picking it opens "Thêm giao dịch".
    case add
}
