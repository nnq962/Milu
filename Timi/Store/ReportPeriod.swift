import Foundation

/// The stretch of time Báo cáo shows (user choice 2026-10-30): a week (Monday to Sunday, as in
/// Vietnam) or a calendar month, moved one at a time with ‹ ›. ("Năm" was tried and dropped the
/// same day, user choice.)
struct ReportPeriod: Hashable {
    enum Unit: String, CaseIterable, Identifiable {
        case week, month
        var id: Self { self }

        var title: String {
            switch self {
            case .week: "Tuần"
            case .month: "Tháng"
            }
        }

        fileprivate var component: Calendar.Component {
            switch self {
            case .week: .weekOfYear
            case .month: .month
            }
        }
    }

    let unit: Unit
    let interval: DateInterval

    init(_ unit: Unit, containing date: Date = .now) {
        self.unit = unit
        interval = Self.calendar.dateInterval(of: unit.component, for: date) ?? DateInterval(start: date, duration: 0)
    }

    static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    var start: Date { interval.start }

    /// The same length of time `count` steps away (-1 is the one before).
    func shifted(by count: Int) -> ReportPeriod {
        ReportPeriod(unit, containing: Self.calendar.date(byAdding: unit.component, value: count, to: start) ?? start)
    }

    var previous: ReportPeriod { shifted(by: -1) }

    /// What this period is compared with (review fix 2026-10-30): the period before, or, while this
    /// one is still running, only as many days of it as have passed here, so 1–5/11 meets 1–5/10
    /// and not the whole of October.
    func comparison(now: Date = .now) -> DateInterval {
        let before = previous.interval
        guard isCurrent(now: now) else { return before }
        let calendar = Self.calendar
        let elapsed = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: now)).day ?? 0
        let end = calendar.date(byAdding: .day, value: elapsed + 1, to: before.start) ?? before.end
        return DateInterval(start: before.start, end: min(end, before.end))
    }

    /// "tháng trước", or "cùng kỳ tháng trước" while this period is still running.
    func comparisonName(now: Date = .now) -> String {
        isCurrent(now: now) ? "cùng kỳ \(previousName)" : previousName
    }
    /// This one and the `count - 1` before it, oldest first, for the bar chart.
    func lastPeriods(_ count: Int) -> [ReportPeriod] { (0..<count).reversed().map { shifted(by: -$0) } }

    /// Whether it holds today; nothing after it has happened yet.
    func isCurrent(now: Date = .now) -> Bool { interval.holds(now) }

    /// "Tháng 10", "Tháng 10/2025", "27/10 – 02/11".
    var title: String {
        let calendar = Self.calendar
        let year = calendar.component(.year, from: start)
        let isThisYear = year == calendar.component(.year, from: .now)
        switch unit {
        case .week:
            // Another year says which, as a month does (review 2026-11-08).
            let last = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            let range = "\(dayMonth(start)) – \(dayMonth(last))"
            let lastYear = calendar.component(.year, from: last)
            return lastYear == calendar.component(.year, from: .now) ? range : "\(range)/\(String(lastYear))"
        case .month:
            let month = calendar.component(.month, from: start)
            return isThisYear ? "Tháng \(month)" : "Tháng \(month)/\(year.formatted(.number.grouping(.never)))"
        }
    }

    /// Under a bar: "27/10", "03/11", "T10".
    var shortTitle: String {
        let calendar = Self.calendar
        switch unit {
        case .week: return dayMonth(start)
        case .month: return "T\(calendar.component(.month, from: start))"
        }
    }

    /// "tháng trước", "tuần trước".
    var previousName: String { "\(unit.title.lowercased()) trước" }

    /// "03/11", as every date of the app (`Date.dayMonth`).
    private func dayMonth(_ date: Date) -> String { date.dayMonth }
}

/// How much a total moved against the period before: nil when there was nothing before to compare.
enum Change {
    static func ratio(_ now: Double, from before: Double) -> Double? {
        before > 0 ? (now - before) / before : nil
    }

    /// "↑ 15%", or the amount once it more than doubled ("↑ 4,2tr", review fix 2026-10-30: "↑ 756%"
    /// read as alarming noise); nil with nothing before, "không đổi" under 0,5%.
    static func text(_ now: Double, from before: Double) -> String? {
        guard let ratio = ratio(now, from: before) else { return nil }
        if abs(ratio) < 0.005 { return "không đổi" }
        let arrow = ratio > 0 ? "↑" : "↓"
        return abs(ratio) > 1 ? "\(arrow) \(abs(now - before).vnd)" : "\(arrow) \(abs(ratio).percentText)"
    }

    /// A line with the arrows said as words, for VoiceOver: "↑ 15%" → "tăng 15%".
    static func spoken(_ text: String) -> String {
        text.replacingOccurrences(of: "↑", with: "tăng").replacingOccurrences(of: "↓", with: "giảm")
    }
}
