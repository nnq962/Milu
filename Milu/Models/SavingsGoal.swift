import SwiftUI

/// Hũ tiết kiệm có mục tiêu; số đã để dành được tính vào tài sản.
struct SavingsGoal: Identifiable, Hashable {
    static let defaultIcon = IconCatalog.emojiName("💰")
    /// The quick choices in the goal form (two rows of six, the last place is "more"): what people
    /// most often save for.
    static let suggestedIcons = ["💰", "☂️", "🏠", "🚗", "🏍️", "🧳", "🎓", "💻", "📱", "💍", "👶"]
        .map(IconCatalog.emojiName)

    /// Stable across launches: the same id is stored in the database.
    var id = UUID()
    var name: String
    /// Asset ID chosen from the icon catalog.
    var icon: String
    var saved: Double
    var target: Double
    /// The date the user wants to reach the target by; nil when there is none.
    var dueDate: Date? = nil
    /// When the goal was closed (its money spent or taken out after reaching the target); nil
    /// while it is still being saved for. Stored as the record's `archivedAt`.
    var closedAt: Date? = nil
    /// How it ended, said on "Hũ đã hoàn thành": "Đã dùng: Mua xe", "Đã rút về Vietcombank".
    /// Stored as the record's `detail`.
    var closingNote: String = ""

    var progress: Double { target > 0 ? min(saved / target, 1) : 0 }
    /// "99%": rounded down, so a goal only reads "100%" once it is reached.
    var progressText: String { (floor(progress * 100) / 100).percentText }
    var remaining: Double { max(target - saved, 0) }
    /// Saved as much as the target: the goal then offers to use the money, take it out, or aim higher.
    var isReached: Bool { target > 0 && saved >= target }
    /// Done with: kept on "Hũ đã hoàn thành", out of the cards and totals.
    var isClosed: Bool { closedAt != nil }

    /// Whole months left until `dueDate`, counting a part month as one; at least 1.
    static func monthsLeft(until dueDate: Date, from now: Date = .now) -> Int {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.month, .day],
                                            from: calendar.startOfDay(for: now),
                                            to: calendar.startOfDay(for: dueDate))
        let months = (parts.month ?? 0) + ((parts.day ?? 0) > 0 ? 1 : 0)
        return max(months, 1)
    }

    /// The deadline is behind and money is still missing: no monthly amount makes sense any more.
    var isOverdue: Bool {
        guard let dueDate, remaining > 0, closedAt == nil else { return false }
        return Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: .now)
    }

    /// What to put aside each month to reach `remaining` by `dueDate`, rounded up to 1.000đ.
    static func monthlySaving(remaining: Double, until dueDate: Date, from now: Date = .now) -> Double {
        let perMonth = remaining / Double(monthsLeft(until: dueDate, from: now))
        return (perMonth / 1_000).rounded(.up) * 1_000
    }
}
