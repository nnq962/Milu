import Foundation

/// Hạn mức chi tiêu (user choice 2026-10-30): one limit for the whole month plus, if wanted, one for
/// some groups of "Hạng mục" (Ăn uống, Mua sắm…). The same limits every month; what is not spent
/// is not carried over. Spending counts as on the reports (`total(.expense)`): transfer fees and
/// loan interest in, excluded transactions and locked accounts out. Amber from 80%, red when over.
struct BudgetProgress {
    let limit: Double
    let spent: Double

    var ratio: Double { limit > 0 ? spent / limit : 0 }
    /// What can still be spent; below 0 once over.
    var left: Double { limit - spent }
    var isOver: Bool { spent > limit }
    /// From 80% up to the limit: worth a warning, not over yet.
    var isNearing: Bool { !isOver && ratio >= 0.8 }

    /// What can be spent each day from today to the month's end, today included; nil for a month
    /// that is over or not started, or once nothing is left.
    func dailyAllowance(in month: Date, today: Date = .now) -> Double? {
        let calendar = Calendar.current
        guard left > 0, calendar.isDate(month, equalTo: today, toGranularity: .month),
              let days = calendar.range(of: .day, in: .month, for: today)?.count else { return nil }
        return left / Double(days - calendar.component(.day, from: today) + 1)
    }
}

/// The groups' limits, by group id, saved as JSON so `@AppStorage` can keep them.
struct CategoryBudgets: RawRepresentable, Equatable {
    var limits: [String: Double] = [:]

    init(limits: [String: Double] = [:]) { self.limits = limits }

    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let limits = try? JSONDecoder().decode([String: Double].self, from: data) else { return nil }
        self.limits = limits
    }

    var rawValue: String {
        guard let data = try? JSONEncoder().encode(limits) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    /// A group's limit; 0 when it has none. Setting 0 removes it.
    subscript(groupID: String) -> Double {
        get { limits[groupID] ?? 0 }
        set { limits[groupID] = newValue > 0 ? newValue : nil }
    }

    var total: Double { limits.values.reduce(0, +) }

    /// Only the limits of `groupIDs`: a group hidden or deleted since takes its limit with it, so
    /// it no longer holds part of the month's (review fix 2026-10-30).
    func keeping(_ groupIDs: Set<String>) -> CategoryBudgets {
        CategoryBudgets(limits: limits.filter { groupIDs.contains($0.key) })
    }
}

/// The groups' limits together never go over the month's (user rule 2026-10-30), so a group can
/// only get a limit once the month has one. Each returns what is wrong, or nil when it may be saved.
enum BudgetRules {
    /// What a group may still be given: the month's limit less the other groups'.
    static func room(for groupID: String, month: Double, groups: CategoryBudgets) -> Double {
        max(month - (groups.total - groups[groupID]), 0)
    }

    static func monthError(_ value: Double, groups: CategoryBudgets) -> String? {
        guard value < groups.total else { return nil }
        return value == 0
            ? "Bỏ hạn mức các hạng mục trước."
            : "Tối thiểu \(groups.total.vnd)."
    }

    static func groupError(_ value: Double, groupID: String, month: Double, groups: CategoryBudgets) -> String? {
        guard value > 0 else { return nil }
        guard month > 0 else { return "Đặt hạn mức tháng trước." }
        let room = room(for: groupID, month: month, groups: groups)
        guard value > room else { return nil }
        return "Chỉ còn \(room.vnd) chưa phân bổ."
    }
}

/// The note under a spending being written (user choice 2026-10-30): what its group's limit (or,
/// without one, the month's) has left once it is counted. Grey while fine, amber from 80%, red
/// when it goes over; it never stops the save.
struct BudgetNotice: Equatable {
    enum Level { case fine, nearing, over }

    /// "Ăn uống" or "Hạn mức tháng".
    let name: String
    let limit: Double
    /// Spent before this one.
    let spent: Double
    let amount: Double

    var after: BudgetProgress { BudgetProgress(limit: limit, spent: spent + amount) }

    var level: Level {
        after.isOver ? .over : after.isNearing ? .nearing : .fine
    }

    /// "Ăn uống còn 170.000đ → vượt 30.000đ": full amounts, as every figure in the app (user
    /// choice 2026-10-31).
    var text: String {
        let before = BudgetProgress(limit: limit, spent: spent)
        func words(_ progress: BudgetProgress, was: Bool) -> String {
            progress.isOver ? "\(was ? "đã vượt" : "vượt") \((-progress.left).vnd)" : "còn \(progress.left.vnd)"
        }
        let (now, then) = (words(before, was: true), words(after, was: false))
        return "\(name) \(now) → \(then)"
    }

    /// The more pressing of the group's and the month's; the group's when they are as bad.
    static func pick(group: BudgetNotice?, month: BudgetNotice?) -> BudgetNotice? {
        guard let group else { return month }
        guard let month else { return group }
        return month.level.rank > group.level.rank ? month : group
    }
}

private extension BudgetNotice.Level {
    var rank: Int {
        switch self {
        case .fine: 0
        case .nearing: 1
        case .over: 2
        }
    }
}
