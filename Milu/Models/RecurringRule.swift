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
    var createdAt = Date.now

    var isPaused: Bool { pausedAt != nil }

    // MARK: Lịch

    /// The `n`th day it falls due (0 is `startDate`'s), nil past `endDate`. Counted from the start
    /// each time, so the 31st falls on the 30th in a short month and is back on the 31st after.
    func occurrence(_ n: Int, calendar: Calendar = .current) -> Date? {
        let start = calendar.startOfDay(for: startDate)
        let step = n * max(interval, 1)
        let day: Date? = switch frequency {
        case .daily: calendar.date(byAdding: .day, value: step, to: start)
        case .weekly: calendar.date(byAdding: .day, value: step * 7, to: start)
        case .monthly: calendar.date(byAdding: .month, value: step, to: start)
        case .yearly: calendar.date(byAdding: .year, value: step, to: start)
        }
        guard let day else { return nil }
        if let endDate, day > calendar.startOfDay(for: endDate) { return nil }
        return day
    }

    /// The days it falls due after `after` (from the start when nil) up to `through`, at most
    /// `limit` of them.
    func occurrences(after: Date?, through: Date, limit: Int = 400, calendar: Calendar = .current) -> [Date] {
        let end = calendar.startOfDay(for: through)
        let floor = after.map { calendar.startOfDay(for: $0) }
        var days: [Date] = []
        var n = 0
        while days.count < limit, let day = occurrence(n, calendar: calendar), day <= end {
            if floor.map({ day > $0 }) ?? true { days.append(day) }
            n += 1
            // A daily rule years old: no need to walk every day already handled one by one.
            if n > 50_000 { break }
        }
        return days
    }

    /// The first day it falls due after `date` (the day itself excluded), if any.
    func nextOccurrence(after date: Date, calendar: Calendar = .current) -> Date? {
        let day = calendar.startOfDay(for: date)
        var n = 0
        while let next = occurrence(n, calendar: calendar) {
            if next > day { return next }
            n += 1
            if n > 50_000 { return nil }
        }
        return nil
    }

    /// When the transaction of `day` happened: that day at the start's time of day, never later
    /// than now.
    func transactionDate(on day: Date, now: Date = .now, calendar: Calendar = .current) -> Date {
        let time = calendar.dateComponents([.hour, .minute], from: startDate)
        let date = calendar.date(bySettingHour: time.hour ?? 9, minute: time.minute ?? 0, second: 0, of: day) ?? day
        return min(date, now)
    }

    /// The same id for the same rule and day on every device.
    static func transactionID(rule: UUID, day: Date, calendar: Calendar = .current) -> UUID {
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
    func scheduleDetail(calendar: Calendar = .current) -> String {
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
