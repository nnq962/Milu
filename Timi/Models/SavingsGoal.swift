import SwiftUI

/// Hũ tiết kiệm có mục tiêu; số đã để dành được tính vào tài sản.
struct SavingsGoal: Identifiable, Hashable {
    static let defaultIcon = "hugeicons-piggy-bank"
    /// The quick choices in the goal form (two rows of six, the last place is "more"): what people
    /// most often save for.
    static let suggestedIcons = ["hugeicons-piggy-bank", "hugeicons-umbrella-dollar", "hugeicons-home-01",
                                 "hugeicons-car-01", "hugeicons-motorbike-01", "hugeicons-luggage-01",
                                 "hugeicons-mortarboard-02", "hugeicons-laptop", "hugeicons-smart-phone-01",
                                 "hugeicons-wedding", "hugeicons-baby-01"]

    /// Stable across launches: the same id is stored in the database.
    var id = UUID()
    var name: String
    /// Asset name from `IconCatalog` ("hugeicons-car-01").
    var icon: String
    var saved: Double
    var target: Double
    /// The date the user wants to reach the target by; nil when there is none.
    var dueDate: Date? = nil

    var progress: Double { target > 0 ? min(saved / target, 1) : 0 }
    var remaining: Double { max(target - saved, 0) }

    /// Whole months left until `dueDate`, counting a part month as one; at least 1.
    static func monthsLeft(until dueDate: Date, from now: Date = .now) -> Int {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.month, .day],
                                            from: calendar.startOfDay(for: now),
                                            to: calendar.startOfDay(for: dueDate))
        let months = (parts.month ?? 0) + ((parts.day ?? 0) > 0 ? 1 : 0)
        return max(months, 1)
    }

    /// What to put aside each month to reach `remaining` by `dueDate`, rounded up to 1.000đ.
    static func monthlySaving(remaining: Double, until dueDate: Date, from now: Date = .now) -> Double {
        let perMonth = remaining / Double(monthsLeft(until: dueDate, from: now))
        return (perMonth / 1_000).rounded(.up) * 1_000
    }
}
