import CryptoKit
import Foundation

/// A spending or income that comes back on a schedule: rent each month, a subscription, a salary
/// (user request 2026-11-12, "Giao dịch định kỳ"). Each time it falls due Milu either records it by
/// itself (`autoRecords`) or asks first, the default: an amount that was not really paid would put
/// a balance wrong.
///
/// `lastHandled` is the last day it fell due that was recorded or skipped; what falls due after it
/// is still to do. The transactions it records carry its id (`FinanceTransaction.recurringRuleID`)
/// and an id worked out from the rule and the day (`transactionID`), so two devices recording the
/// same day make one transaction, which iCloud's copies then merge.
struct RecurringRule: Identifiable, Hashable {
    enum Frequency: String, CaseIterable {
        case daily, weekly, monthly, yearly
    }

    var id = UUID()
    var kind: TransactionKind
    var amount: Double
    var categoryID: String
    var accountID: Account.ID
    var note: String = ""
    var frequency: Frequency = .monthly
    /// Every how many days, weeks, months or years.
    var interval: Int = 1
    /// The first day it falls due; the time of day the recorded transactions take.
    var startDate: Date
    /// The last day it may fall due; nil for no end.
    var endDate: Date?
    var autoRecords = false
    var lastHandled: Date?
    /// Paused: nothing falls due, nothing is asked, until it is resumed.
    var pausedAt: Date?
    /// "Không tính vào báo cáo": every transaction it records stays out of Báo cáo and the limits
    /// (audit 2026-11-15: a rule kept no such mark, so only the first one did).
    var isExcluded = false
    var createdAt = Date.now

    var isPaused: Bool { pausedAt != nil }

    // MARK: Lịch

    /// A rule's days are Vietnam's, wherever the iPhone is: "the 15th" stays the 15th, the same
    /// day on every device, and so the same transaction (`transactionID`). In the iPhone's own
    /// time zone, a trip abroad moved the day, and the payment was recorded twice (audit round 2,
    /// 2026-11-15). At home it is the iPhone's own calendar, as before.
    static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = home
        return calendar
    }

    private static let home = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current

    /// "15/12" for a rule's day, the day the rule counts, in any time zone (audit round 3,
    /// 2026-11-16: abroad, the iPhone's calendar named the day before).
    static func shortDay(_ day: Date, now: Date = .now) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        let text = String(format: "%02d/%02d", parts.day ?? 0, parts.month ?? 0)
        return parts.year == calendar.component(.year, from: now) ? text : "\(text)/\(parts.year ?? 0)"
    }

    /// Whole days from today to a rule's day, both as the rule counts them: 0 today.
    static func daysFromToday(_ day: Date, now: Date = .now) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: day)).day ?? 0
    }

    /// A rule's day at `hour` on the iPhone's clock: the same date wherever the iPhone is.
    static func localDate(of day: Date, hour: Int) -> Date? {
        var parts = calendar.dateComponents([.year, .month, .day], from: day)
        parts.hour = hour
        return Calendar.current.date(from: parts)
    }

    /// The `n`th day it falls due (0 is `startDate`'s), nil past `endDate`. Counted from the start
    /// each time, so the 31st falls on the 30th in a short month and is back on the 31st after.
    func occurrence(_ n: Int, calendar: Calendar = Self.calendar) -> Date? {
        occurrence(n, start: calendar.startOfDay(for: startDate), end: endDate.map(calendar.startOfDay), calendar: calendar)
    }

    /// `occurrence(_:)` with the start and end days worked out once, for a walk over many.
    private func occurrence(_ n: Int, start: Date, end: Date?, calendar: Calendar) -> Date? {
        let step = n * max(interval, 1)
        let day: Date? = switch frequency {
        case .daily: calendar.date(byAdding: .day, value: step, to: start)
        case .weekly: calendar.date(byAdding: .day, value: step * 7, to: start)
        case .monthly: calendar.date(byAdding: .month, value: step, to: start)
        case .yearly: calendar.date(byAdding: .year, value: step, to: start)
        }
        guard let day else { return nil }
        if let end, day > end { return nil }
        return day
    }

    /// An `n` that falls no later than `day`, near it: a walk to `day` starts there, not at the
    /// start (audit 2026-11-15: a daily rule two years old walked 730 days on every call, several
    /// times on every draw of Tổng quan and inside the list's sort).
    private func index(before day: Date, start: Date, calendar: Calendar) -> Int {
        guard day > start else { return 0 }
        let unit = max(interval, 1)
        let count: Int = switch frequency {
        case .daily: (calendar.dateComponents([.day], from: start, to: day).day ?? 0) / unit
        case .weekly: (calendar.dateComponents([.day], from: start, to: day).day ?? 0) / (7 * unit)
        case .monthly: (calendar.dateComponents([.month], from: start, to: day).month ?? 0) / unit
        case .yearly: (calendar.dateComponents([.year], from: start, to: day).year ?? 0) / unit
        }
        // One back: a month's 31st falls on the 30th, and a count can land a day past.
        return max(count - 1, 0)
    }

    /// The days it falls due after `after` (from the start when nil) up to `through`, at most
    /// `limit` of them.
    func occurrences(after: Date?, through: Date, limit: Int = 400, calendar: Calendar = Self.calendar) -> [Date] {
        let end = calendar.startOfDay(for: through)
        let floor = after.map { calendar.startOfDay(for: $0) }
        let start = calendar.startOfDay(for: startDate)
        let last = endDate.map(calendar.startOfDay)
        var days: [Date] = []
        var n = floor.map { index(before: $0, start: start, calendar: calendar) } ?? 0
        let first = n
        while days.count < limit, let day = occurrence(n, start: start, end: last, calendar: calendar), day <= end {
            if floor.map({ day > $0 }) ?? true { days.append(day) }
            n += 1
            if n - first > 50_000 { break }
        }
        return days
    }

    /// The first day it falls due after `date` (the day itself excluded), if any.
    func nextOccurrence(after date: Date, calendar: Calendar = Self.calendar) -> Date? {
        let day = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: startDate)
        let last = endDate.map(calendar.startOfDay)
        var n = index(before: day, start: start, calendar: calendar)
        let first = n
        while let next = occurrence(n, start: start, end: last, calendar: calendar) {
            if next > day { return next }
            n += 1
            if n - first > 50_000 { return nil }
        }
        return nil
    }

    /// When the transaction of `day` happened: that day at the start's time of day, never later
    /// than now.
    func transactionDate(on day: Date, now: Date = .now, calendar: Calendar = Self.calendar) -> Date {
        let time = calendar.dateComponents([.hour, .minute], from: startDate)
        let date = calendar.date(bySettingHour: time.hour ?? 9, minute: time.minute ?? 0, second: 0, of: day) ?? day
        return min(date, now)
    }

    /// The same id for the same rule and day on every device.
    static func transactionID(rule: UUID, day: Date, calendar: Calendar = Self.calendar) -> UUID {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        let key = "\(rule.uuidString)|\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
        var bytes = Array(SHA256.hash(data: Data(key.utf8)).prefix(16))
        // A version 5 style UUID (name-based), so it never looks like a random one.
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }

    /// "Hằng tháng", "Mỗi 2 tuần".
    var scheduleText: String { RepeatChoice.text(frequency: frequency, interval: interval) }

    /// With the day it comes back on: "Hằng tháng · ngày 15", "Hằng tuần · Thứ Hai", "Hằng năm ·
    /// 05/09"; a daily one is only "Hằng ngày".
    func scheduleDetail(calendar: Calendar = Self.calendar) -> String {
        let day: String? = switch frequency {
        case .daily: nil
        case .weekly: Self.weekdayName(calendar.component(.weekday, from: startDate))
        case .monthly: "ngày \(calendar.component(.day, from: startDate))"
        case .yearly: startDate.dayMonth
        }
        return [scheduleText, day].compactMap { $0 }.joined(separator: " · ")
    }

    /// 1 (Sunday) … 7, as Calendar counts.
    static func weekdayName(_ weekday: Int) -> String {
        weekday == 1 ? "Chủ nhật" : "Thứ \(["Hai", "Ba", "Tư", "Năm", "Sáu", "Bảy"][max(0, min(5, weekday - 2))])"
    }
}

/// What "Lặp lại" offers: the usual schedules, as Calendar does.
enum RepeatChoice: String, CaseIterable, Identifiable {
    case none, daily, weekly, biweekly, monthly, quarterly, yearly

    var id: Self { self }

    var schedule: (frequency: RecurringRule.Frequency, interval: Int)? {
        switch self {
        case .none: nil
        case .daily: (.daily, 1)
        case .weekly: (.weekly, 1)
        case .biweekly: (.weekly, 2)
        case .monthly: (.monthly, 1)
        case .quarterly: (.monthly, 3)
        case .yearly: (.yearly, 1)
        }
    }

    init(frequency: RecurringRule.Frequency, interval: Int) {
        self = Self.allCases.first { $0.schedule?.frequency == frequency && $0.schedule?.interval == interval } ?? .monthly
    }

    var title: String {
        guard let schedule else { return "Không" }
        return Self.text(frequency: schedule.frequency, interval: schedule.interval)
    }

    static func text(frequency: RecurringRule.Frequency, interval: Int) -> String {
        let unit = switch frequency {
        case .daily: "ngày"
        case .weekly: "tuần"
        case .monthly: "tháng"
        case .yearly: "năm"
        }
        return interval <= 1 ? "Hằng \(unit)" : "Mỗi \(interval) \(unit)"
    }
}

/// One day a rule falls due, waiting or coming.
struct RecurringOccurrence: Identifiable, Hashable {
    let rule: RecurringRule
    let day: Date
    /// Due days of the same rule after this one, up to today, still to do (the app was not opened
    /// for a while, or its account was archived).
    var moreWaiting = 0

    var id: String { "\(rule.id.uuidString)|\(day.timeIntervalSince1970)" }
}
