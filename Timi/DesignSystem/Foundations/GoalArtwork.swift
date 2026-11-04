/// Resolves the illustration for both current and older saved goals, without changing stored IDs.
enum GoalArtwork {
    private static let legacy: [String: String] = [
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
    ]

    static func name(for icon: String) -> String {
        let name = legacy[icon].map(IconCatalog.emojiName) ?? icon
        guard IconCatalog.isEmoji(name) else { return SavingsGoal.defaultIcon }
        return IconCatalog.assetName(for: name, fallbackEmoji: "💰")
    }
}
