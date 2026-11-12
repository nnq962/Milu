import Foundation
import Testing
@testable import Milu

/// When "Nhắc ghi chi tiêu" comes and which limit alerts are sent (`Reminders`).
struct RemindersTests {
    private let calendar = Calendar.current

    private func at(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: Date(timeIntervalSince1970: 1_794_000_000)))!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    // MARK: Daily reminder

    /// Before the time: today and the next days, at 21:00, recorded or not.
    @Test func comesTonightAndEachNextDay() {
        let plan = DailyReminderPlan(minutes: 21 * 60, now: at(9))
        #expect(plan.dates.count == DailyReminderPlan.days)
        #expect(plan.dates.first == at(21))
        #expect(plan.dates.dropFirst().first == at(21, dayOffset: 1))
    }

    /// Past the time today: from tomorrow.
    @Test func pastTheTimeStartsTomorrow() {
        let plan = DailyReminderPlan(minutes: 20 * 60 + 30, now: at(22))
        #expect(plan.dates.first == at(20, 30, dayOffset: 1))
    }

    /// Twenty different lines, each short enough for a lock screen.
    @Test func twentyLinesToPickFrom() {
        let messages = DailyReminderPlan.messages
        #expect(messages.count == 20)
        #expect(Set(messages.map(\.title)).count == 20)
        #expect(messages.allSatisfy { $0.title.count <= 45 && $0.body.count <= 90 })
    }

    // MARK: Limit alerts

    private func limit(spent: Double, limit: Double = 1_000_000, id: String = "food") -> BudgetAlertPlan.Limit {
        .init(id: id, name: "Ăn uống", limit: limit, spent: spent)
    }

    /// 80% once, then reaching it once; nothing more that month.
    @Test func eachLevelOnceAMonth() {
        var plan = BudgetAlertPlan(sent: [], now: at(12))
        #expect(plan.alerts(for: [limit(spent: 500_000)]).isEmpty)
        let nearing = plan.alerts(for: [limit(spent: 820_000)])
        #expect(nearing.count == 1)
        #expect(nearing.first?.title == "Ăn uống sắp chạm hạn mức ⚠️")
        #expect(plan.alerts(for: [limit(spent: 900_000)]).isEmpty)
        let reached = plan.alerts(for: [limit(spent: 1_050_000)])
        #expect(reached.first?.title == "Ăn uống đã hết hạn mức 😬")
        #expect(reached.first?.body.contains("50.000đ") == true)
        #expect(plan.alerts(for: [limit(spent: 1_200_000)]).isEmpty)
    }

    /// From under 80% straight past the limit: only "đã hết", not the 80% after it.
    @Test func aJumpPastTheLimitSendsOnlyTheHigherOne() {
        var plan = BudgetAlertPlan(sent: [], now: at(12))
        #expect(plan.alerts(for: [limit(spent: 1_100_000)]).count == 1)
        #expect(plan.alerts(for: [limit(spent: 1_100_000)]).isEmpty)
    }

    /// A new month, or a changed limit, starts afresh.
    @Test func aNewMonthOrAChangedLimitStartsAfresh() {
        var plan = BudgetAlertPlan(sent: [], now: at(12))
        _ = plan.alerts(for: [limit(spent: 850_000)])
        var nextMonth = BudgetAlertPlan(sent: plan.sent, now: at(12, dayOffset: 40))
        #expect(nextMonth.alerts(for: [limit(spent: 850_000)]).count == 1)
        #expect(plan.alerts(for: [limit(spent: 850_000, limit: 1_050_000)]).count == 1)
    }

    /// No limit, no alert.
    @Test func noLimitNoAlert() {
        var plan = BudgetAlertPlan(sent: [], now: at(12))
        #expect(plan.alerts(for: [limit(spent: 5_000_000, limit: 0)]).isEmpty)
    }
}
