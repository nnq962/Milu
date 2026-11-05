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
    static let systemIDs: Set<String> = Set(TransactionCategory.allCases.filter(\.isSystem).map(\.rawValue))

    /// Names the system's own categories use ("Điều chỉnh số dư"): a user category may not take
    /// one, or its transactions would read like balance adjustments.
    static let reservedNames: [String] = [TransactionCategory.adjustmentIn.title, TransactionCategory.transferFee.title,
                                          TransactionCategory.loanInterestIncome.title, TransactionCategory.loanInterestExpense.title]
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
        Group(id: "food", kind: .expense, name: "Ăn uống", icon: IconCatalog.emojiName("🍽️"), items: [
            ("breakfast", "Ăn sáng", IconCatalog.emojiName("🍳")), ("lunch", "Ăn trưa", IconCatalog.emojiName("🍚")),
            ("dinner", "Ăn tối", IconCatalog.emojiName("🍜")), ("coffee", "Cà phê", IconCatalog.emojiName("☕")),
            ("milktea", "Trà sữa", IconCatalog.emojiName("🧋")), ("market", "Đi chợ", IconCatalog.emojiName("🛒")),
        ]),
        Group(id: "transport", kind: .expense, name: "Di chuyển", icon: IconCatalog.emojiName("🚗"), items: [
            ("fuel", "Xăng", IconCatalog.emojiName("⛽")), ("parking", "Gửi xe", IconCatalog.emojiName("🅿️")),
            ("taxi", "Taxi, xe ôm", IconCatalog.emojiName("🚕")), ("bus", "Xe buýt", IconCatalog.emojiName("🚌")),
            ("repair", "Sửa xe", IconCatalog.emojiName("🛞")),
        ]),
        Group(id: "bills", kind: .expense, name: "Hoá đơn", icon: IconCatalog.emojiName("⚡"), items: [
            ("electricity", "Tiền điện", IconCatalog.emojiName("⚡")), ("water", "Tiền nước", IconCatalog.emojiName("💧")),
            ("internet", "Internet", IconCatalog.emojiName("🛜")), ("phone", "Điện thoại", IconCatalog.emojiName("📞")),
            ("gas", "Gas", IconCatalog.emojiName("🔥")),
        ]),
        Group(id: "housing", kind: .expense, name: "Nhà cửa", icon: IconCatalog.emojiName("🏠"), items: [
            ("rent", "Thuê nhà", IconCatalog.emojiName("🔑")), ("fixes", "Sửa chữa", IconCatalog.emojiName("🛠️")),
            ("appliances", "Đồ gia dụng", IconCatalog.emojiName("🔌")), ("cleaning", "Dọn dẹp", IconCatalog.emojiName("🧹")),
        ]),
        Group(id: "shopping", kind: .expense, name: "Mua sắm", icon: IconCatalog.emojiName("🛍️"), items: [
            ("clothes", "Quần áo", IconCatalog.emojiName("👕")), ("shoes", "Giày dép", IconCatalog.emojiName("👟")),
            ("beauty", "Mỹ phẩm", IconCatalog.emojiName("💄")), ("devices", "Đồ điện tử", IconCatalog.emojiName("📱")),
            ("online", "Mua online", IconCatalog.emojiName("📦")),
        ]),
        Group(id: "entertainment", kind: .expense, name: "Giải trí", icon: IconCatalog.emojiName("🎬"), items: [
            ("movies", "Xem phim", IconCatalog.emojiName("🎬")), ("travel", "Du lịch", IconCatalog.emojiName("🧳")),
            ("games", "Game", IconCatalog.emojiName("🎮")), ("parties", "Tiệc tùng", IconCatalog.emojiName("🎉")),
        ]),
        Group(id: "health", kind: .expense, name: "Sức khoẻ", icon: IconCatalog.emojiName("🩹"), items: [
            ("medicine", "Thuốc", IconCatalog.emojiName("💊")), ("doctor", "Khám bệnh", IconCatalog.emojiName("🩺")),
            ("sport", "Thể thao", IconCatalog.emojiName("🏋️")), ("insurance", "Bảo hiểm", IconCatalog.emojiName("☂️")),
        ]),
        Group(id: "education", kind: .expense, name: "Học tập", icon: IconCatalog.emojiName("📚"), items: [
            ("fees", "Học phí", IconCatalog.emojiName("🎓")), ("books", "Sách", IconCatalog.emojiName("📖")),
            ("courses", "Khoá học", IconCatalog.emojiName("🏫")),
        ]),
        Group(id: "family", kind: .expense, name: "Gia đình", icon: IconCatalog.emojiName("🫶"), items: [
            ("kids", "Con cái", IconCatalog.emojiName("👶")), ("gifts", "Quà tặng", IconCatalog.emojiName("🎁")),
            ("occasions", "Hiếu hỉ", IconCatalog.emojiName("💍")), ("pets", "Thú cưng", IconCatalog.emojiName("🐾")),
        ]),
        Group(id: "otherExpense", kind: .expense, name: "Chi khác", icon: IconCatalog.emojiName("🗂️"), items: [
            ("other", "Khác", IconCatalog.emojiName("🗂️")),
        ]),
        Group(id: "salary", kind: .income, name: "Lương", icon: IconCatalog.emojiName("💰"), items: [
            ("main", "Lương chính", IconCatalog.emojiName("💰")), ("side", "Làm thêm", IconCatalog.emojiName("💼")),
        ]),
        Group(id: "bonus", kind: .income, name: "Thưởng", icon: IconCatalog.emojiName("🎁"), items: [
            ("bonus", "Tiền thưởng", IconCatalog.emojiName("🎁")), ("given", "Được cho, tặng", IconCatalog.emojiName("🫶")),
        ]),
        Group(id: "investment", kind: .income, name: "Đầu tư", icon: IconCatalog.emojiName("📈"), items: [
            ("interest", "Lãi tiết kiệm", IconCatalog.emojiName("🏦")), ("dividends", "Cổ tức", IconCatalog.emojiName("📈")),
        ]),
        Group(id: "otherIncome", kind: .income, name: "Thu khác", icon: IconCatalog.emojiName("💵"), items: [
            ("sales", "Bán đồ", IconCatalog.emojiName("🏷️")), ("refund", "Hoàn tiền", IconCatalog.emojiName("🪙")),
            ("other", "Khác", IconCatalog.emojiName("🗂️")),
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
