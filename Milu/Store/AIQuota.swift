import Foundation
import Observation

/// Trợ lý AI's question allowance, by the week (user choice 2026-11-12): the free plan gets 10
/// lượt a week, full again at 0:00 on Monday; Pro gets 150. Each "Làm quen với Milu" step done
/// pays 5 lượt once, to use within 7 days. A question takes from the bonus first (it runs out),
/// then from the week; recording or deleting a transaction takes none, and a question Milu could
/// not answer is given back (`refund`). With none left, Trợ lý AI stops sending and invites to
/// Pro. Saved in UserDefaults; Pro is not on sale yet.
@Observable
final class AIQuota {
    static let weeklyFree = 10
    static let weeklyPro = 150
    static let stepBonus = 5
    /// How long a step's bonus lasts.
    static let bonusDays = 7

    /// A step's bonus: what is left of it, and when it runs out.
    struct Grant: Codable, Equatable {
        var left: Int
        var expires: Date
    }

    private let defaults: UserDefaults
    private let now: () -> Date
    private var week: String
    private var used: Int
    private var grants: [Grant]
    /// Onboarding steps already paid out, so each pays once.
    private var claimed: Set<String>
    /// Where the last question's lượt came from, for `refund`.
    @ObservationIgnored private var lastSpend: Spend?

    private enum Spend {
        case week(String)
        case grant(expires: Date)
    }

    /// No limit at all: every question goes and none is counted. On in Debug builds, for testing
    /// (user request 2026-11-10); a Release build always counts.
    let isUnlimited: Bool
    static let unlimitedInDebug: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()

    init(defaults: UserDefaults = .standard, unlimited: Bool = false, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        isUnlimited = unlimited
        let today = now()
        week = defaults.string(forKey: Keys.week) ?? Self.weekKey(today)
        used = defaults.integer(forKey: Keys.used)
        grants = defaults.data(forKey: Keys.grants)
            .flatMap { try? JSONDecoder().decode([Grant].self, from: $0) } ?? []
        claimed = Set(defaults.stringArray(forKey: Keys.claimed) ?? [])
        migrateFromMonths(today: today)
    }

    /// Reads the saved allowance again: another device used some, or a reinstall's came back from
    /// iCloud (`CloudSettings`).
    func reload() {
        week = defaults.string(forKey: Keys.week) ?? Self.weekKey(now())
        used = defaults.integer(forKey: Keys.used)
        grants = defaults.data(forKey: Keys.grants)
            .flatMap { try? JSONDecoder().decode([Grant].self, from: $0) } ?? []
        claimed = Set(defaults.stringArray(forKey: Keys.claimed) ?? [])
    }

    // MARK: What is left

    /// Questions asked this week (0 once a new week starts).
    var usedThisWeek: Int { week == Self.weekKey(now()) ? used : 0 }
    /// The week's lượt on the plan in use: 10 free, 150 on Milu Pro.
    var weeklyAllowance: Int { MiluPlan.isPro ? Self.weeklyPro : Self.weeklyFree }
    var weeklyLeft: Int { max(weeklyAllowance - usedThisWeek, 0) }
    /// Bonus lượt not yet used nor run out.
    var bonus: Int { liveGrants.reduce(0) { $0 + $1.left } }
    /// When the soonest bonus runs out, if there is any.
    var bonusExpires: Date? { liveGrants.map(\.expires).min() }
    var remaining: Int { weeklyLeft + bonus }
    var isEmpty: Bool { !isUnlimited && remaining == 0 }

    /// When the week fills up again: 0:00 next Monday.
    var renewsOn: Date {
        Self.calendar.dateInterval(of: .weekOfYear, for: now())?.end ?? now()
    }

    private var liveGrants: [Grant] {
        let moment = now()
        return grants.filter { $0.left > 0 && $0.expires > moment }
    }

    // MARK: Spending

    /// Takes one question, from the bonus that runs out soonest, else from the week; false when
    /// none are left.
    @discardableResult
    func spend() -> Bool {
        if isUnlimited { return true }
        rollWeek()
        let moment = now()
        if let index = grants.indices.filter({ grants[$0].left > 0 && grants[$0].expires > moment })
            .min(by: { grants[$0].expires < grants[$1].expires }) {
            grants[index].left -= 1
            lastSpend = .grant(expires: grants[index].expires)
        } else if used < weeklyAllowance {
            used += 1
            lastSpend = .week(week)
        } else {
            return false
        }
        save()
        return true
    }

    /// Gives back the last question's lượt: Milu did not answer (no internet, the server down,
    /// stopped with ■), or the question only recorded or deleted a transaction.
    func refund() {
        guard !isUnlimited, let spend = lastSpend else { return }
        lastSpend = nil
        switch spend {
        case .week(let key):
            // Last week's lượt is not given back into this one.
            if key == week, used > 0 { used -= 1 }
        case .grant(let expires):
            if let index = grants.firstIndex(where: { $0.expires == expires }) { grants[index].left += 1 }
        }
        save()
    }

    // MARK: Onboarding

    /// Whether a step's +5 was already paid: the step stays done after its data is gone, so it
    /// never offers again a reward it would not pay (review 2026-11-08).
    func hasClaimed(_ step: String) -> Bool { claimed.contains(step) }

    /// Pays a finished onboarding step's +5, once per step, to use within `bonusDays`.
    func claim(_ step: String) {
        guard !claimed.contains(step) else { return }
        claimed.insert(step)
        grants.append(Grant(left: Self.stepBonus, expires: now().addingTimeInterval(Double(Self.bonusDays) * 86_400)))
        save()
    }

    // MARK: Saving

    private func rollWeek() {
        let current = Self.weekKey(now())
        if week != current {
            week = current
            used = 0
        }
    }

    private func save() {
        // Run-out bonuses go, so the list stays short.
        let moment = now()
        grants.removeAll { $0.left <= 0 || $0.expires <= moment }
        defaults.set(week, forKey: Keys.week)
        defaults.set(used, forKey: Keys.used)
        defaults.set(try? JSONEncoder().encode(grants), forKey: Keys.grants)
        defaults.set(Array(claimed), forKey: Keys.claimed)
    }

    /// The monthly allowance (2026-10-29 to 2026-11-12) gives way to the week: its count is
    /// dropped (a new week starts full) and a bonus still there lasts 7 days from now.
    private func migrateFromMonths(today: Date) {
        guard defaults.object(forKey: Keys.oldMonth) != nil || defaults.object(forKey: Keys.oldBonus) != nil else { return }
        let oldBonus = defaults.integer(forKey: Keys.oldBonus)
        if oldBonus > 0 {
            grants.append(Grant(left: oldBonus, expires: today.addingTimeInterval(Double(Self.bonusDays) * 86_400)))
        }
        week = Self.weekKey(today)
        used = 0
        [Keys.oldMonth, Keys.oldUsed, Keys.oldBonus].forEach(defaults.removeObject(forKey:))
        save()
    }

    /// Weeks from Monday, as in Vietnam.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        return calendar
    }()

    private static func weekKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(parts.yearForWeekOfYear ?? 0)-W\(parts.weekOfYear ?? 0)"
    }

    /// Whether a saved key is the allowance's own, which "Xoá toàn bộ dữ liệu" keeps.
    static func isOwnKey(_ key: String) -> Bool { key.hasPrefix(Keys.prefix) }

    private enum Keys {
        static let prefix = "ai."
        static let week = "ai.week"
        static let used = "ai.weekUsed"
        static let grants = "ai.bonusGrants"
        static let claimed = "ai.claimedSteps"
        // The monthly allowance's, read once to move over.
        static let oldMonth = "ai.month"
        static let oldUsed = "ai.used"
        static let oldBonus = "ai.bonus"
    }
}
