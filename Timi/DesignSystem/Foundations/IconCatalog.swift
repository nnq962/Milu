import Foundation

/// One icon a user can give a savings goal or a category. `name` is the asset name and also what
/// the database stores: "hugeicons-" + the Hugeicons id, so the web draws it as `hugeicons:<id>`.
struct CatalogIcon: Identifiable, Hashable {
    let name: String
    /// Read by VoiceOver and shown beside the icon in a form row.
    let title: String

    var id: String { name }

    init(_ name: String, _ title: String) {
        self.name = name
        self.title = title
    }
}

struct IconGroup: Identifiable {
    let title: String
    let icons: [CatalogIcon]

    var id: String { title }
}

/// The icons users pick from (Hugeicons Stroke Rounded, free, MIT), grouped by what money goes on.
/// Adding an icon: put its SVG in Assets.xcassets as "hugeicons-<id>" and add one line here.
enum IconCatalog {
    static let groups: [IconGroup] = [
        IconGroup(title: "Tài chính", icons: [
            CatalogIcon("hugeicons-piggy-bank", "Tiết kiệm"),
            CatalogIcon("hugeicons-safe-box", "Quỹ dự phòng"),
            CatalogIcon("hugeicons-target-02", "Mục tiêu"),
            CatalogIcon("hugeicons-wallet-01", "Ví"),
            CatalogIcon("hugeicons-money-02", "Tiền mặt"),
            CatalogIcon("hugeicons-coins-01", "Tiền xu"),
            CatalogIcon("hugeicons-credit-card", "Thẻ"),
            CatalogIcon("hugeicons-bank", "Ngân hàng"),
            CatalogIcon("hugeicons-money-bag-02", "Lương"),
            CatalogIcon("hugeicons-briefcase-dollar", "Kinh doanh"),
            CatalogIcon("hugeicons-hand-coins", "Cho vay"),
            CatalogIcon("hugeicons-money-receive-02", "Nhận tiền"),
            CatalogIcon("hugeicons-money-send-02", "Chuyển tiền"),
            CatalogIcon("hugeicons-invoice-01", "Hoá đơn"),
            CatalogIcon("hugeicons-receipt-dollar", "Biên lai"),
            CatalogIcon("hugeicons-chart-increase", "Đầu tư"),
            CatalogIcon("hugeicons-gold", "Vàng"),
            CatalogIcon("hugeicons-bitcoin", "Tiền số"),
            CatalogIcon("hugeicons-taxes", "Thuế"),
            CatalogIcon("hugeicons-percent", "Lãi suất"),
            CatalogIcon("hugeicons-umbrella-dollar", "Bảo hiểm"),
            CatalogIcon("hugeicons-cashback", "Hoàn tiền"),
        ]),
        IconGroup(title: "Ăn uống", icons: [
            CatalogIcon("hugeicons-restaurant-01", "Ăn uống"),
            CatalogIcon("hugeicons-rice-bowl-01", "Cơm"),
            CatalogIcon("hugeicons-noodles", "Bún phở"),
            CatalogIcon("hugeicons-coffee-02", "Cà phê"),
            CatalogIcon("hugeicons-bubble-tea-01", "Trà sữa"),
            CatalogIcon("hugeicons-tea", "Trà"),
            CatalogIcon("hugeicons-soft-drink-01", "Đồ uống"),
            CatalogIcon("hugeicons-beer", "Bia"),
            CatalogIcon("hugeicons-bottle-wine", "Rượu"),
            CatalogIcon("hugeicons-hamburger-01", "Đồ ăn nhanh"),
            CatalogIcon("hugeicons-pizza-01", "Pizza"),
            CatalogIcon("hugeicons-cake-slice", "Bánh ngọt"),
            CatalogIcon("hugeicons-ice-cream-01", "Kem"),
            CatalogIcon("hugeicons-bread-01", "Bánh mì"),
            CatalogIcon("hugeicons-egg-fried", "Ăn sáng"),
            CatalogIcon("hugeicons-fish", "Hải sản"),
            CatalogIcon("hugeicons-milk-bottle", "Sữa"),
            CatalogIcon("hugeicons-cooking-pot", "Nấu ăn"),
            CatalogIcon("hugeicons-shopping-basket-01", "Đi chợ"),
        ]),
        IconGroup(title: "Đi lại", icons: [
            CatalogIcon("hugeicons-motorbike-01", "Xe máy"),
            CatalogIcon("hugeicons-car-01", "Ô tô"),
            CatalogIcon("hugeicons-taxi", "Taxi"),
            CatalogIcon("hugeicons-bus-01", "Xe buýt"),
            CatalogIcon("hugeicons-train-01", "Tàu"),
            CatalogIcon("hugeicons-airplane-01", "Máy bay"),
            CatalogIcon("hugeicons-boat", "Thuyền"),
            CatalogIcon("hugeicons-bicycle", "Xe đạp"),
            CatalogIcon("hugeicons-fuel-station", "Xăng"),
            CatalogIcon("hugeicons-car-parking-01", "Gửi xe"),
            CatalogIcon("hugeicons-road", "Phí đường"),
            CatalogIcon("hugeicons-tire", "Sửa xe"),
            CatalogIcon("hugeicons-truck-delivery", "Giao hàng"),
        ]),
        IconGroup(title: "Nhà cửa", icons: [
            CatalogIcon("hugeicons-home-01", "Nhà"),
            CatalogIcon("hugeicons-apartment", "Chung cư"),
            CatalogIcon("hugeicons-key-01", "Thuê nhà"),
            CatalogIcon("hugeicons-flash", "Tiền điện"),
            CatalogIcon("hugeicons-droplet", "Tiền nước"),
            CatalogIcon("hugeicons-wifi-01", "Internet"),
            CatalogIcon("hugeicons-call-02", "Cước điện thoại"),
            CatalogIcon("hugeicons-tv-01", "Truyền hình"),
            CatalogIcon("hugeicons-fire-02", "Gas"),
            CatalogIcon("hugeicons-tools", "Sửa chữa"),
            CatalogIcon("hugeicons-sofa-01", "Nội thất"),
            CatalogIcon("hugeicons-bed", "Phòng ngủ"),
            CatalogIcon("hugeicons-fridge", "Đồ gia dụng"),
            CatalogIcon("hugeicons-washing-machine", "Giặt là"),
            CatalogIcon("hugeicons-clean", "Dọn dẹp"),
            CatalogIcon("hugeicons-plant-01", "Cây cảnh"),
        ]),
        IconGroup(title: "Mua sắm", icons: [
            CatalogIcon("hugeicons-shopping-bag-01", "Mua sắm"),
            CatalogIcon("hugeicons-shopping-cart-01", "Siêu thị"),
            CatalogIcon("hugeicons-package", "Đặt hàng online"),
            CatalogIcon("hugeicons-t-shirt", "Quần áo"),
            CatalogIcon("hugeicons-running-shoes", "Giày dép"),
            CatalogIcon("hugeicons-hand-bag-01", "Túi xách"),
            CatalogIcon("hugeicons-perfume", "Mỹ phẩm"),
            CatalogIcon("hugeicons-diamond-02", "Trang sức"),
            CatalogIcon("hugeicons-watch-01", "Đồng hồ"),
            CatalogIcon("hugeicons-glasses", "Kính"),
            CatalogIcon("hugeicons-smart-phone-01", "Điện thoại"),
            CatalogIcon("hugeicons-laptop", "Máy tính"),
            CatalogIcon("hugeicons-headphones", "Tai nghe"),
            CatalogIcon("hugeicons-camera-01", "Máy ảnh"),
            CatalogIcon("hugeicons-discount-tag-01", "Khuyến mãi"),
            CatalogIcon("hugeicons-store-01", "Cửa hàng"),
        ]),
        IconGroup(title: "Sức khoẻ", icons: [
            CatalogIcon("hugeicons-first-aid-kit", "Sức khoẻ"),
            CatalogIcon("hugeicons-medicine-02", "Thuốc"),
            CatalogIcon("hugeicons-hospital-01", "Bệnh viện"),
            CatalogIcon("hugeicons-stethoscope-02", "Khám bệnh"),
            CatalogIcon("hugeicons-dental-tooth", "Nha khoa"),
            CatalogIcon("hugeicons-eye", "Mắt"),
            CatalogIcon("hugeicons-dumbbell-01", "Gym"),
            CatalogIcon("hugeicons-yoga-01", "Yoga"),
            CatalogIcon("hugeicons-swimming", "Bơi"),
            CatalogIcon("hugeicons-football", "Bóng đá"),
            CatalogIcon("hugeicons-badminton", "Cầu lông"),
            CatalogIcon("hugeicons-scissors", "Cắt tóc"),
        ]),
        IconGroup(title: "Giải trí", icons: [
            CatalogIcon("hugeicons-film-02", "Phim"),
            CatalogIcon("hugeicons-ticket-01", "Vé"),
            CatalogIcon("hugeicons-game-controller-01", "Game"),
            CatalogIcon("hugeicons-music-note-01", "Nhạc"),
            CatalogIcon("hugeicons-mic-01", "Karaoke"),
            CatalogIcon("hugeicons-book-open-01", "Sách"),
            CatalogIcon("hugeicons-youtube", "Video"),
            CatalogIcon("hugeicons-luggage-01", "Du lịch"),
            CatalogIcon("hugeicons-beach", "Biển"),
            CatalogIcon("hugeicons-tent", "Cắm trại"),
            CatalogIcon("hugeicons-party", "Tiệc"),
            CatalogIcon("hugeicons-balloons", "Sinh nhật"),
        ]),
        IconGroup(title: "Học tập, công việc", icons: [
            CatalogIcon("hugeicons-mortarboard-02", "Học tập"),
            CatalogIcon("hugeicons-school", "Trường học"),
            CatalogIcon("hugeicons-book-02", "Sách vở"),
            CatalogIcon("hugeicons-pencil-edit-01", "Văn phòng phẩm"),
            CatalogIcon("hugeicons-briefcase-01", "Công việc"),
            CatalogIcon("hugeicons-office-chair", "Văn phòng"),
            CatalogIcon("hugeicons-globe-02", "Du học"),
            CatalogIcon("hugeicons-rocket-01", "Khởi nghiệp"),
        ]),
        IconGroup(title: "Gia đình, bạn bè", icons: [
            CatalogIcon("hugeicons-user-love-01", "Người yêu"),
            CatalogIcon("hugeicons-wedding", "Cưới hỏi"),
            CatalogIcon("hugeicons-baby-01", "Em bé"),
            CatalogIcon("hugeicons-baby-bottle", "Đồ cho bé"),
            CatalogIcon("hugeicons-toy-brick", "Đồ chơi"),
            CatalogIcon("hugeicons-hand-heart", "Gia đình"),
            CatalogIcon("hugeicons-user-group", "Bạn bè"),
            CatalogIcon("hugeicons-gift", "Quà tặng"),
            CatalogIcon("hugeicons-charity", "Từ thiện"),
            CatalogIcon("hugeicons-paw-print", "Thú cưng"),
            CatalogIcon("hugeicons-flower", "Hoa"),
        ]),
        IconGroup(title: "Khác", icons: [
            CatalogIcon("hugeicons-star", "Khác"),
            CatalogIcon("hugeicons-favourite", "Yêu thích"),
            CatalogIcon("hugeicons-calendar-03", "Sự kiện"),
            CatalogIcon("hugeicons-bulb", "Ý tưởng"),
        ]),
    ]

    static let all: [CatalogIcon] = groups.flatMap(\.icons)

    static func icon(named name: String) -> CatalogIcon? {
        all.first { $0.name == name }
    }

    /// The current asset for an icon name stored before the switch to Hugeicons (Solar and MDI
    /// names); names already current pass through.
    static func migrated(_ name: String) -> String {
        legacy[name] ?? name
    }

    private static let legacy: [String: String] = [
        "material-symbols-add-rounded": "hugeicons-add-01",
        "mdi-airplane": "hugeicons-luggage-01",
        "mdi-car-outline": "hugeicons-car-01",
        "mdi-piggy-bank": "hugeicons-piggy-bank",
        "mdi-piggy-bank-outline": "hugeicons-piggy-bank",
        "solar-add-circle-linear": "hugeicons-add-circle",
        "solar-add-linear": "hugeicons-add-01",
        "solar-alt-arrow-down-linear": "hugeicons-arrow-down-01",
        "solar-alt-arrow-left-linear": "hugeicons-arrow-left-01",
        "solar-alt-arrow-right-linear": "hugeicons-arrow-right-01",
        "solar-arrow-up-linear": "hugeicons-arrow-up-02",
        "solar-bag-3-linear": "hugeicons-shopping-bag-01",
        "solar-bag-heart-linear": "hugeicons-shopping-bag-01",
        "solar-banknote-2-linear": "hugeicons-money-02",
        "solar-bell-bing-linear": "hugeicons-alert-circle",
        "solar-bell-linear": "hugeicons-notification-01",
        "solar-bolt-linear": "hugeicons-flash",
        "solar-book-linear": "hugeicons-book-02",
        "solar-buildings-2-linear": "hugeicons-bank",
        "solar-calendar-linear": "hugeicons-calendar-03",
        "solar-camera-linear": "hugeicons-camera-01",
        "solar-car-linear": "hugeicons-car-01",
        "solar-card-bold": "hugeicons-credit-card",
        "solar-card-linear": "hugeicons-credit-card",
        "solar-chat-round-line-linear": "hugeicons-bubble-chat",
        "solar-check-read-linear": "hugeicons-checkmark-circle-02",
        "solar-clapperboard-play-linear": "hugeicons-film-02",
        "solar-clock-circle-linear": "hugeicons-clock-01",
        "solar-crown-bold": "hugeicons-crown",
        "solar-cup-hot-linear": "hugeicons-restaurant-01",
        "solar-danger-triangle-linear": "hugeicons-alert-02",
        "solar-document-text-linear": "hugeicons-file-02",
        "solar-dumbbell-large-linear": "hugeicons-dumbbell-01",
        "solar-gamepad-linear": "hugeicons-game-controller-01",
        "solar-gift-linear": "hugeicons-gift",
        "solar-graph-up-linear": "hugeicons-chart-increase",
        "solar-hand-heart-linear": "hugeicons-hand-heart",
        "solar-hand-money-linear": "hugeicons-hand-coins",
        "solar-hearts-linear": "hugeicons-wedding",
        "solar-history-linear": "hugeicons-history",
        "solar-home-2-bold": "hugeicons-home-01",
        "solar-home-2-linear": "hugeicons-home-01",
        "solar-inbox-linear": "hugeicons-inbox",
        "solar-laptop-linear": "hugeicons-laptop",
        "solar-letter-linear": "hugeicons-mail-01",
        "solar-magic-wand-2-bold": "hugeicons-ai-magic",
        "solar-magic-wand-2-linear": "hugeicons-ai-magic",
        "solar-magnifer-linear": "hugeicons-search-01",
        "solar-medical-kit-linear": "hugeicons-first-aid-kit",
        "solar-menu-dots-linear": "hugeicons-more-horizontal",
        "solar-microphone-3-linear": "hugeicons-mic-01",
        "solar-pallete-2-linear": "hugeicons-paint-board",
        "solar-paw-linear": "hugeicons-paw-print",
        "solar-pen-linear": "hugeicons-pencil-edit-01",
        "solar-pen-new-square-linear": "hugeicons-pencil-edit-02",
        "solar-plane-linear": "hugeicons-luggage-01",
        "solar-question-circle-linear": "hugeicons-help-circle",
        "solar-safe-square-linear": "hugeicons-safe-box",
        "solar-scooter-linear": "hugeicons-motorbike-01",
        "solar-shield-check-linear": "hugeicons-security-check",
        "solar-smartphone-linear": "hugeicons-smart-phone-01",
        "solar-sofa-linear": "hugeicons-sofa-01",
        "solar-square-academic-cap-linear": "hugeicons-mortarboard-02",
        "solar-star-linear": "hugeicons-star",
        "solar-stars-minimalistic-bold": "hugeicons-ai-magic",
        "solar-suitcase-linear": "hugeicons-luggage-01",
        "solar-tag-linear": "hugeicons-tag-01",
        "solar-transfer-horizontal-bold": "hugeicons-arrow-data-transfer-horizontal",
        "solar-transfer-horizontal-linear": "hugeicons-arrow-data-transfer-horizontal",
        "solar-trash-bin-minimalistic-linear": "hugeicons-delete-02",
        "solar-user-linear": "hugeicons-user",
        "solar-wallet-linear": "hugeicons-wallet-01",
        "solar-wallet-money-linear": "hugeicons-money-bag-02",
        "solar-widget-4-linear": "hugeicons-dashboard-square-01",
    ]
}
