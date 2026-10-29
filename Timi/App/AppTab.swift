import SwiftUI

enum AppTab: Hashable {
    case overview, accounts, transactions, assistant
    /// The + beside the tab bar: never shown as a page, picking it opens "Thêm giao dịch".
    case add
}
