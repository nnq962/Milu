/// The pictures of categories and goals are Fluent Emoji Flat (`MiluEmoji2D`) since 2026-11-05
/// (user request: one 2D set in place of the line icons and the 3D pictures). Categories and goals
/// saved before then hold a Hugeicons name; this maps each to its emoji as the record is read, so
/// no stored ID changes and an old row shows the same thing a new one does.
enum LineIconEmoji {
    private static let map: [String: String] = [
        // Goals.
        "hugeicons-piggy-bank": "💰",
        "hugeicons-money-bag-02": "💰",
        "hugeicons-umbrella-dollar": "☂️",
        "hugeicons-diamond-02": "💎",
        "hugeicons-briefcase-01": "💼",
        "hugeicons-rocket-01": "🚀",
        "hugeicons-car-01": "🚗",
        "hugeicons-motorbike-01": "🏍️",
        "hugeicons-bicycle": "🚲",
        "hugeicons-airplane-01": "✈️",
        "hugeicons-luggage-01": "🧳",
        "hugeicons-beach": "🏖️",
        "hugeicons-tent": "🏕️",
        "hugeicons-boat": "⛵",
        "hugeicons-smart-phone-01": "📱",
        "hugeicons-laptop": "💻",
        "hugeicons-computer": "🖥️",
        "hugeicons-watch-01": "⌚",
        "hugeicons-camera-01": "📷",
        "hugeicons-headphones": "🎧",
        "hugeicons-tv-01": "📺",
        "hugeicons-game-controller-01": "🎮",
        "hugeicons-home-01": "🏠",
        "hugeicons-sofa-01": "🛋️",
        "hugeicons-bed": "🛏️",
        "hugeicons-plant-01": "🪴",
        "hugeicons-wedding": "💍",
        "hugeicons-baby-01": "👶",
        "hugeicons-cat": "🐈",
        "hugeicons-gift": "🎁",
        "hugeicons-birthday-cake": "🎂",
        "hugeicons-favourite": "❤️",
        "hugeicons-mortarboard-02": "🎓",
        "hugeicons-book-02": "📚",
        "hugeicons-stethoscope-02": "🩺",
        "hugeicons-guitar": "🎸",
        "hugeicons-shopping-bag-01": "🛍️",
        // The built-in categories (`Category.groups`).
        "hugeicons-restaurant-01": "🍽️",
        "hugeicons-egg-fried": "🍳",
        "hugeicons-rice-bowl-01": "🍚",
        "hugeicons-noodles": "🍜",
        "hugeicons-coffee-02": "☕",
        "hugeicons-bubble-tea-01": "🧋",
        "hugeicons-shopping-basket-01": "🛒",
        "hugeicons-fuel-station": "⛽",
        "hugeicons-car-parking-01": "🅿️",
        "hugeicons-taxi": "🚕",
        "hugeicons-bus-01": "🚌",
        "hugeicons-tire": "🛞",
        "hugeicons-flash": "⚡",
        "hugeicons-droplet": "💧",
        "hugeicons-wifi-01": "🛜",
        "hugeicons-call-02": "📞",
        "hugeicons-fire-02": "🔥",
        "hugeicons-key-01": "🔑",
        "hugeicons-tools": "🛠️",
        "hugeicons-fridge": "🔌",
        "hugeicons-clean": "🧹",
        "hugeicons-t-shirt": "👕",
        "hugeicons-running-shoes": "👟",
        "hugeicons-perfume": "💄",
        "hugeicons-package": "📦",
        "hugeicons-film-02": "🎬",
        "hugeicons-party": "🎉",
        "hugeicons-first-aid-kit": "🩹",
        "hugeicons-medicine-02": "💊",
        "hugeicons-dumbbell-01": "🏋️",
        "hugeicons-book-open-01": "📖",
        "hugeicons-school": "🏫",
        "hugeicons-hand-heart": "🫶",
        "hugeicons-paw-print": "🐾",
        "hugeicons-dashboard-square-01": "🗂️",
        "hugeicons-chart-increase": "📈",
        "hugeicons-percent": "🏦",
        "hugeicons-money-add-02": "💵",
        "hugeicons-store-01": "🏷️",
        "hugeicons-cashback": "🪙",
    ]

    /// The emoji asset for a line icon saved before the switch; any other name as it is.
    static func asset(for name: String) -> String {
        map[name].map(IconCatalog.emojiName) ?? name
    }
}

/// Resolves the illustration for both current and older saved goals, without changing stored IDs.
enum GoalArtwork {
    static func name(for icon: String) -> String {
        let name = LineIconEmoji.asset(for: icon)
        guard IconCatalog.isEmoji(name) else { return SavingsGoal.defaultIcon }
        return IconCatalog.assetName(for: name, fallbackEmoji: "💰")
    }
}
