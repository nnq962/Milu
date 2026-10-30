import Foundation
import Observation

/// Trợ lý AI's question allowance (user choice 2026-10-29): the free plan gets 20 a month, full
/// again on the 1st; each "Làm quen với Timi" step done adds 5 once, kept until used. A question
/// takes from the month first, then from the bonus. With none left, Trợ lý AI stops sending and
/// invites to Pro. Saved in UserDefaults; Pro (300 a month) is not on sale yet.
@Observable
final class AIQuota {
    static let monthlyFree = 20
    static let monthlyPro = 300
    static let stepBonus = 5

    private let defaults: UserDefaults
    private var month: String
    private var used: Int
    /// Bonus questions still unused.
    private(set) var bonus: Int
    /// Onboarding steps already paid out, so each pays once.
    private var claimed: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        month = defaults.string(forKey: Keys.month) ?? Self.monthKey(.now)
        used = defaults.integer(forKey: Keys.used)
        bonus = defaults.integer(forKey: Keys.bonus)
        claimed = Set(defaults.stringArray(forKey: Keys.claimed) ?? [])
    }

    /// Questions asked this month (0 once a new month starts).
    var usedThisMonth: Int { month == Self.monthKey(.now) ? used : 0 }
    var monthlyLeft: Int { max(Self.monthlyFree - usedThisMonth, 0) }
    var remaining: Int { monthlyLeft + bonus }
    var isEmpty: Bool { remaining == 0 }

    /// When the month fills up again: the 1st of next month.
    var renewsOn: Date {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        return calendar.date(byAdding: .month, value: 1, to: start) ?? .now
    }

    /// Takes one question; false when none are left.
    @discardableResult
    func spend() -> Bool {
        let now = Self.monthKey(.now)
        if month != now { month = now; used = 0 }
        if used < Self.monthlyFree {
            used += 1
        } else if bonus > 0 {
            bonus -= 1
        } else {
            return false
        }
        save()
        return true
    }

    /// Pays a finished onboarding step's +5, once per step.
    func claim(_ step: String) {
        guard !claimed.contains(step) else { return }
        claimed.insert(step)
        bonus += Self.stepBonus
        save()
    }

    private func save() {
        defaults.set(month, forKey: Keys.month)
        defaults.set(used, forKey: Keys.used)
        defaults.set(bonus, forKey: Keys.bonus)
        defaults.set(Array(claimed), forKey: Keys.claimed)
    }

    private static func monthKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)"
    }

    private enum Keys {
        static let month = "ai.month"
        static let used = "ai.used"
        static let bonus = "ai.bonus"
        static let claimed = "ai.claimedSteps"
    }
}
