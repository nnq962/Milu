import Foundation
import Testing
@testable import Milu

/// The widgets' summary and links (`WidgetShared`).
struct WidgetSharedTests {
    private let calendar = Calendar(identifier: .gregorian)
    private var day: Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: 19))! }

    private var snapshot: WidgetSnapshot {
        WidgetSnapshot(day: day, spentToday: 185_000, spentThisMonth: 4_200_000, monthlyBudget: 8_000_000,
                       recent: [.init(title: "Cà phê", amount: 55_000, icon: "milu-emoji-2615", iconIsTemplate: false)],
                       hidesAmounts: false)
    }

    @Test func keepsTheFiguresOnTheirDayAndMonth() {
        let evening = day.addingTimeInterval(23 * 3600)
        #expect(snapshot.spentToday(on: evening, calendar: calendar) == 185_000)
        #expect(snapshot.spentThisMonth(on: evening, calendar: calendar) == 4_200_000)
        #expect(snapshot.recent(on: evening, calendar: calendar).count == 1)
    }

    /// Past midnight nothing is spent today yet, even before the app has written the new day; the
    /// month's figures carry on.
    @Test func todayStartsFromNothingTheNextDay() {
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        #expect(snapshot.spentToday(on: nextDay, calendar: calendar) == 0)
        #expect(snapshot.spentThisMonth(on: nextDay, calendar: calendar) == 4_200_000)
    }

    /// On the first of a month, last month's spending and lines are not this month's.
    @Test func theMonthStartsFromNothingOnTheFirst() {
        let december = calendar.date(from: DateComponents(year: 2026, month: 12, day: 1))!
        #expect(snapshot.spentThisMonth(on: december, calendar: calendar) == 0)
        #expect(snapshot.recent(on: december, calendar: calendar).isEmpty)
    }

    @Test func readsOnlyMilusOwnLinks() {
        #expect(WidgetShared.Link(URL(string: "milu://add")!) == .add)
        #expect(WidgetShared.Link(URL(string: "milu://ai")!) == .ai)
        #expect(WidgetShared.Link(URL(string: "milu://overview")!) == .overview)
        #expect(WidgetShared.Link(URL(string: "milu://budget")!) == .budget)
        #expect(WidgetShared.Link.add.url.absoluteString == "milu://add")
        #expect(WidgetShared.Link(URL(string: "milu://loan")!) == nil)
        #expect(WidgetShared.Link(URL(string: "https://add")!) == nil)
    }
}
