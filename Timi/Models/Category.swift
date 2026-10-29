import Foundation

/// A spending or income category in "Hạng mục" (Cài đặt): a group ("Ăn uống") or an item in one
/// ("Ăn sáng"). A transaction will be filed under an item, never a group (user choice 2026-10-29),
/// so every group keeps at least one item that is not hidden.
struct Category: Identifiable, Hashable {
    var id: String
    var kind: TransactionKind
    /// nil for a group; the group's id for an item.
    var parentID: String?
    var name: String
    /// Asset name from `IconCatalog`.
    var icon: String
    var isBuiltIn = false
    var sortOrder = 0
    /// Hidden: kept for the transactions already filed under it, no longer offered (user choice
    /// 2026-10-29, as archiving an account). Stored as the record's `archivedAt`.
    var hiddenAt: Date? = nil

    var isGroup: Bool { parentID == nil }

    /// Names stay on one or two lines in a row.
    static let maxNameLength = 30
    var isHidden: Bool { hiddenAt != nil }

    /// The balance adjustments are categories of the system, never listed in "Hạng mục".
    static let systemIDs: Set<String> = [TransactionCategory.adjustmentIn.rawValue, TransactionCategory.adjustmentOut.rawValue]

    /// Names the system's own categories use ("Điều chỉnh số dư"): a user category may not take
    /// one, or its transactions would read like balance adjustments.
    static let reservedNames: [String] = [TransactionCategory.adjustmentIn.title]
}

/// The categories a new install starts with: the V1 groups (same ids, so existing transactions
/// keep their group) and the items Vietnamese users most often need in each.
enum DefaultCategories {
    struct Group {
        let id: String
        let kind: TransactionKind
        let name: String
        let icon: String
        let items: [(slug: String, name: String, icon: String)]
    }

    static let groups: [Group] = [
        Group(id: "food", kind: .expense, name: "Ăn uống", icon: "hugeicons-restaurant-01", items: [
            ("breakfast", "Ăn sáng", "hugeicons-egg-fried"), ("lunch", "Ăn trưa", "hugeicons-rice-bowl-01"),
            ("dinner", "Ăn tối", "hugeicons-noodles"), ("coffee", "Cà phê", "hugeicons-coffee-02"),
            ("milktea", "Trà sữa", "hugeicons-bubble-tea-01"), ("market", "Đi chợ", "hugeicons-shopping-basket-01"),
        ]),
        Group(id: "transport", kind: .expense, name: "Di chuyển", icon: "hugeicons-car-01", items: [
            ("fuel", "Xăng", "hugeicons-fuel-station"), ("parking", "Gửi xe", "hugeicons-car-parking-01"),
            ("taxi", "Taxi, xe ôm", "hugeicons-taxi"), ("bus", "Xe buýt", "hugeicons-bus-01"),
            ("repair", "Sửa xe", "hugeicons-tire"),
        ]),
        Group(id: "bills", kind: .expense, name: "Hoá đơn", icon: "hugeicons-flash", items: [
            ("electricity", "Tiền điện", "hugeicons-flash"), ("water", "Tiền nước", "hugeicons-droplet"),
            ("internet", "Internet", "hugeicons-wifi-01"), ("phone", "Điện thoại", "hugeicons-call-02"),
            ("gas", "Gas", "hugeicons-fire-02"),
        ]),
        Group(id: "housing", kind: .expense, name: "Nhà cửa", icon: "hugeicons-home-01", items: [
            ("rent", "Thuê nhà", "hugeicons-key-01"), ("fixes", "Sửa chữa", "hugeicons-tools"),
            ("appliances", "Đồ gia dụng", "hugeicons-fridge"), ("cleaning", "Dọn dẹp", "hugeicons-clean"),
        ]),
        Group(id: "shopping", kind: .expense, name: "Mua sắm", icon: "hugeicons-shopping-bag-01", items: [
            ("clothes", "Quần áo", "hugeicons-t-shirt"), ("shoes", "Giày dép", "hugeicons-running-shoes"),
            ("beauty", "Mỹ phẩm", "hugeicons-perfume"), ("devices", "Đồ điện tử", "hugeicons-smart-phone-01"),
            ("online", "Mua online", "hugeicons-package"),
        ]),
        Group(id: "entertainment", kind: .expense, name: "Giải trí", icon: "hugeicons-film-02", items: [
            ("movies", "Xem phim", "hugeicons-film-02"), ("travel", "Du lịch", "hugeicons-luggage-01"),
            ("games", "Game", "hugeicons-game-controller-01"), ("parties", "Tiệc tùng", "hugeicons-party"),
        ]),
        Group(id: "health", kind: .expense, name: "Sức khoẻ", icon: "hugeicons-first-aid-kit", items: [
            ("medicine", "Thuốc", "hugeicons-medicine-02"), ("doctor", "Khám bệnh", "hugeicons-stethoscope-02"),
            ("sport", "Thể thao", "hugeicons-dumbbell-01"), ("insurance", "Bảo hiểm", "hugeicons-umbrella-dollar"),
        ]),
        Group(id: "education", kind: .expense, name: "Học tập", icon: "hugeicons-book-02", items: [
            ("fees", "Học phí", "hugeicons-mortarboard-02"), ("books", "Sách", "hugeicons-book-open-01"),
            ("courses", "Khoá học", "hugeicons-school"),
        ]),
        Group(id: "family", kind: .expense, name: "Gia đình", icon: "hugeicons-hand-heart", items: [
            ("kids", "Con cái", "hugeicons-baby-01"), ("gifts", "Quà tặng", "hugeicons-gift"),
            ("occasions", "Hiếu hỉ", "hugeicons-wedding"), ("pets", "Thú cưng", "hugeicons-paw-print"),
        ]),
        Group(id: "otherExpense", kind: .expense, name: "Chi khác", icon: "hugeicons-dashboard-square-01", items: [
            ("other", "Khác", "hugeicons-dashboard-square-01"),
        ]),
        Group(id: "salary", kind: .income, name: "Lương", icon: "hugeicons-money-bag-02", items: [
            ("main", "Lương chính", "hugeicons-money-bag-02"), ("side", "Làm thêm", "hugeicons-briefcase-01"),
        ]),
        Group(id: "bonus", kind: .income, name: "Thưởng", icon: "hugeicons-gift", items: [
            ("bonus", "Tiền thưởng", "hugeicons-gift"), ("given", "Được cho, tặng", "hugeicons-hand-heart"),
        ]),
        Group(id: "investment", kind: .income, name: "Đầu tư", icon: "hugeicons-chart-increase", items: [
            ("interest", "Lãi tiết kiệm", "hugeicons-percent"), ("dividends", "Cổ tức", "hugeicons-chart-increase"),
        ]),
        Group(id: "otherIncome", kind: .income, name: "Thu khác", icon: "hugeicons-money-add-02", items: [
            ("sales", "Bán đồ", "hugeicons-store-01"), ("refund", "Hoàn tiền", "hugeicons-cashback"),
            ("other", "Khác", "hugeicons-dashboard-square-01"),
        ]),
    ]

    /// Every default category, groups before their items, in display order.
    static var all: [Category] {
        groups.enumerated().flatMap { index, group -> [Category] in
            let head = Category(id: group.id, kind: group.kind, name: group.name, icon: group.icon,
                                isBuiltIn: true, sortOrder: index * 100)
            let items = group.items.enumerated().map { offset, item in
                Category(id: "\(group.id).\(item.slug)", kind: group.kind, parentID: group.id, name: item.name,
                         icon: item.icon, isBuiltIn: true, sortOrder: index * 100 + offset + 1)
            }
            return [head] + items
        }
    }
}
