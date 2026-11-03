import Foundation

/// The 3D pictures (Microsoft's Fluent Emoji, MIT, `Fluent3D` in Assets) of savings goals, and of
/// the empty states that stand for them. A goal still stores a line icon's name (`SavingsGoal.icon`),
/// as transaction rows draw it (user request 2026-11-03: the goal picker shows 3D, transactions keep
/// the line set); this maps it to its picture. An icon with no picture gets the money bag.
enum Picture3D {
    struct Choice: Identifiable {
        /// The line icon stored on the goal.
        let icon: String
        let title: String
        /// The `Fluent3D` slug, without "fluent-".
        let slug: String
        var id: String { icon }
        var picture: String { "fluent-\(slug)" }
    }

    struct Group: Identifiable {
        let title: String
        let choices: [Choice]
        var id: String { title }
    }

    /// Every goal picture, grouped as the picker shows them.
    static let groups: [Group] = [
        Group(title: "Tiết kiệm", choices: [
            Choice(icon: "hugeicons-piggy-bank", title: "Tiết kiệm", slug: "pig"),
            Choice(icon: "hugeicons-money-bag-02", title: "Túi tiền", slug: "money"),
            Choice(icon: "hugeicons-umbrella-dollar", title: "Quỹ dự phòng", slug: "umbrella"),
            Choice(icon: "hugeicons-diamond-02", title: "Trang sức", slug: "gem"),
            Choice(icon: "hugeicons-briefcase-01", title: "Công việc", slug: "briefcase"),
            Choice(icon: "hugeicons-rocket-01", title: "Mục tiêu lớn", slug: "rocket"),
        ]),
        Group(title: "Đi lại, du lịch", choices: [
            Choice(icon: "hugeicons-car-01", title: "Ô tô", slug: "transport"),
            Choice(icon: "hugeicons-motorbike-01", title: "Xe máy", slug: "motorbike"),
            Choice(icon: "hugeicons-bicycle", title: "Xe đạp", slug: "bicycle"),
            Choice(icon: "hugeicons-airplane-01", title: "Chuyến bay", slug: "airplane"),
            Choice(icon: "hugeicons-luggage-01", title: "Du lịch", slug: "luggage"),
            Choice(icon: "hugeicons-beach", title: "Biển", slug: "beach"),
            Choice(icon: "hugeicons-tent", title: "Cắm trại", slug: "camping"),
            Choice(icon: "hugeicons-boat", title: "Thuyền", slug: "sailboat"),
        ]),
        Group(title: "Đồ công nghệ", choices: [
            Choice(icon: "hugeicons-smart-phone-01", title: "Điện thoại", slug: "phone"),
            Choice(icon: "hugeicons-laptop", title: "Laptop", slug: "laptop"),
            Choice(icon: "hugeicons-computer", title: "Máy tính", slug: "desktop"),
            Choice(icon: "hugeicons-watch-01", title: "Đồng hồ", slug: "watch"),
            Choice(icon: "hugeicons-camera-01", title: "Máy ảnh", slug: "camera"),
            Choice(icon: "hugeicons-headphones", title: "Tai nghe", slug: "headphone"),
            Choice(icon: "hugeicons-tv-01", title: "TV", slug: "television"),
            Choice(icon: "hugeicons-game-controller-01", title: "Game", slug: "videogame"),
        ]),
        Group(title: "Nhà cửa, gia đình", choices: [
            Choice(icon: "hugeicons-home-01", title: "Nhà", slug: "housing"),
            Choice(icon: "hugeicons-sofa-01", title: "Nội thất", slug: "couch"),
            Choice(icon: "hugeicons-bed", title: "Phòng ngủ", slug: "bed"),
            Choice(icon: "hugeicons-plant-01", title: "Cây cảnh", slug: "plant"),
            Choice(icon: "hugeicons-wedding", title: "Đám cưới", slug: "ring"),
            Choice(icon: "hugeicons-baby-01", title: "Em bé", slug: "baby"),
            Choice(icon: "hugeicons-cat", title: "Thú cưng", slug: "cat"),
            Choice(icon: "hugeicons-gift", title: "Quà tặng", slug: "family"),
            Choice(icon: "hugeicons-birthday-cake", title: "Sinh nhật", slug: "cake"),
            Choice(icon: "hugeicons-favourite", title: "Người thương", slug: "heart"),
        ]),
        Group(title: "Học tập, sức khoẻ, sở thích", choices: [
            Choice(icon: "hugeicons-mortarboard-02", title: "Học phí", slug: "graduation"),
            Choice(icon: "hugeicons-book-02", title: "Sách", slug: "education"),
            Choice(icon: "hugeicons-stethoscope-02", title: "Sức khoẻ", slug: "stethoscope"),
            Choice(icon: "hugeicons-guitar", title: "Nhạc cụ", slug: "guitar"),
            Choice(icon: "hugeicons-shopping-bag-01", title: "Mua sắm", slug: "shopping"),
        ]),
    ]

    private static let byIcon = Dictionary(uniqueKeysWithValues: groups.flatMap(\.choices).map { ($0.icon, $0) })

    static func choice(for icon: String) -> Choice? { byIcon[icon] }

    /// The 3D picture of a goal's icon; the money bag for one with no picture of its own.
    static func name(for icon: String) -> String {
        byIcon[icon]?.picture ?? "fluent-money"
    }
}
