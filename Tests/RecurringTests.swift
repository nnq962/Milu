import Foundation
import SwiftData
import Testing
@testable import Milu

/// "Giao dịch định kỳ": the schedule, recording what falls due, asking first, and never twice.
@MainActor
struct RecurringTests {
    private let calendar = Calendar.current

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func open(_ container: ModelContainer) -> FinanceStore {
        FinanceStore(database: FinanceDatabase(context: ModelContext(container)), seedsSampleData: false)
    }

    private func rule(start: Date, frequency: RecurringRule.Frequency = .monthly, interval: Int = 1,
                      auto: Bool = false, account: UUID = UUID()) -> RecurringRule {
        RecurringRule(kind: .expense, amount: 5_000_000, categoryID: "housing.rent", accountID: account,
                      frequency: frequency, interval: interval, startDate: start, autoRecords: auto)
    }

    // MARK: Lịch

    /// The 31st falls on the last day of a short month, and is back on the 31st after.
    @Test func the31stFitsShortMonths() {
        let rent = rule(start: day(2027, 1, 31))
        #expect(rent.occurrence(1) == calendar.startOfDay(for: day(2027, 2, 28)))
        #expect(rent.occurrence(2) == calendar.startOfDay(for: day(2027, 3, 31)))
        #expect(rent.occurrence(3) == calendar.startOfDay(for: day(2027, 4, 30)))
    }

    @Test func everyTwoWeeksAndAnEnd() {
        var pay = rule(start: day(2027, 1, 1), frequency: .weekly, interval: 2)
        pay.endDate = day(2027, 2, 1)
        let days = pay.occurrences(after: nil, through: day(2027, 3, 1))
        #expect(days.map { calendar.component(.day, from: $0) } == [1, 15, 29])
    }

    @Test func theSameDayGivesTheSameTransactionID() {
        let id = UUID()
        #expect(RecurringRule.transactionID(rule: id, day: day(2027, 5, 1, hour: 8))
                == RecurringRule.transactionID(rule: id, day: day(2027, 5, 1, hour: 20)))
        #expect(RecurringRule.transactionID(rule: id, day: day(2027, 5, 1))
                != RecurringRule.transactionID(rule: id, day: day(2027, 6, 1)))
    }

    // MARK: Ghi

    private func storeWithWallet() -> (FinanceStore, ModelContainer, Account) {
        let container = FinanceDatabase.makeContainer(inMemory: true)
        let store = open(container)
        let wallet = Account(name: "Ví", type: .cash, balance: 50_000_000, openedAt: day(2026, 1, 1))
        store.add(wallet)
        return (store, container, wallet)
    }

    /// A repeating transaction records itself now; a rule that records by itself fills in every day
    /// missed when the app opens, once only, and the link to the rule survives a relaunch.
    @Test func autoRecordsWhatWasMissedOnce() throws {
        let (store, container, wallet) = storeWithWallet()
        let first = FinanceTransaction(amount: 260_000, categoryID: "housing.rent", kind: .expense,
                                       accountID: wallet.id, date: day(2027, 1, 5))
        store.add(first, repeating: (.monthly, 1), autoRecords: true)
        #expect(store.transactions.count == 1)
        let ruleID = try #require(store.recurringRules.first?.id)

        let recorded = store.recordDueRecurring(now: day(2027, 3, 20))
        #expect(recorded.map { calendar.component(.month, from: $0.date) } == [2, 3])
        #expect(store.recordDueRecurring(now: day(2027, 3, 20)).isEmpty)
        #expect(store.transactions.count == 3)
        let balance = try #require(store.account(id: wallet.id)?.balance)
        #expect(balance == 49_220_000.0, "\(balance)")

        let reopened = open(container)
        #expect(reopened.transactions.allSatisfy { $0.recurringRuleID == ruleID })
        #expect(reopened.recordDueRecurring(now: day(2027, 3, 20)).isEmpty)
    }

    /// A rule that asks: the earliest day waits with how many more behind it; "Ghi" records it for
    /// the amount typed, "Bỏ qua" records nothing; both move it on.
    @Test func askingFirstWaitsThenRecordsOrSkips() {
        let (store, _, wallet) = storeWithWallet()
        store.save(rule(start: day(2027, 1, 10), account: wallet.id))
        var waiting = store.waitingRecurring(now: day(2027, 3, 15))
        #expect(waiting.count == 1)
        #expect(waiting.first?.moreWaiting == 2)
        #expect(waiting.first.map { calendar.component(.month, from: $0.day) } == 1)
        #expect(store.recordDueRecurring(now: day(2027, 3, 15)).isEmpty)

        store.confirm(waiting[0], amount: 4_800_000, now: day(2027, 3, 15))
        #expect(store.transactions.first?.amount == 4_800_000)
        waiting = store.waitingRecurring(now: day(2027, 3, 15))
        #expect(waiting.first.map { calendar.component(.month, from: $0.day) } == 2)

        store.skip(waiting[0])
        waiting = store.waitingRecurring(now: day(2027, 3, 15))
        #expect(waiting.first.map { calendar.component(.month, from: $0.day) } == 3)
        #expect(store.transactions.count == 1)
    }

    /// Paused: nothing waits and nothing is recorded.
    @Test func pausedDoesNothing() {
        let (store, _, wallet) = storeWithWallet()
        var paused = rule(start: day(2027, 1, 10), auto: true, account: wallet.id)
        paused.pausedAt = day(2027, 1, 11)
        store.save(paused)
        #expect(store.recordDueRecurring(now: day(2027, 6, 1)).isEmpty)
        #expect(store.waitingRecurring(now: day(2027, 6, 1)).isEmpty)
        #expect(store.upcomingRecurring(now: day(2027, 6, 1)).isEmpty)
    }

    /// What comes in the next week, soonest first.
    @Test func upcomingInTheNextWeek() {
        let (store, _, wallet) = storeWithWallet()
        store.save(rule(start: day(2027, 1, 18), account: wallet.id))
        store.save(rule(start: day(2027, 1, 12), frequency: .weekly, account: wallet.id))
        let upcoming = store.upcomingRecurring(days: 7, now: day(2027, 1, 13))
        #expect(upcoming.map { calendar.component(.day, from: $0.day) } == [18, 19])
    }

    /// An old transaction made to repeat: linked to its rule, nothing recorded for the months
    /// already past, the next one after today waits.
    @Test func repeatingAnOldTransactionDoesNotBackfill() throws {
        let (store, _, wallet) = storeWithWallet()
        let old = FinanceTransaction(amount: 5_000_000, categoryID: "housing.rent", kind: .expense,
                                     accountID: wallet.id, date: day(2027, 1, 5))
        store.add(old)
        store.update(old, startRepeating: (.monthly, 1), autoRecords: true, now: day(2027, 4, 10))
        let rule = try #require(store.recurringRules.first)
        #expect(store.transaction(id: old.id)?.recurringRuleID == rule.id)
        #expect(store.recordDueRecurring(now: day(2027, 4, 10)).isEmpty)
        #expect(store.transactions.count == 1)
        #expect(store.nextDue(rule, now: day(2027, 4, 10)).map { calendar.component(.month, from: $0) } == 5)
    }

    /// The rule's account archived: an automatic rule records nothing and waits instead of moving
    /// on; "Ghi" onto another account records it; onto the archived one it does not move on.
    @Test func archivedAccountWaitsForAnotherAccount() throws {
        let (store, _, wallet) = storeWithWallet()
        let bank = Account(name: "Ngân hàng", type: .bank, balance: 1_000_000, openedAt: day(2026, 1, 1))
        store.add(bank)
        store.save(rule(start: day(2027, 1, 10), auto: true, account: wallet.id))
        store.archive(try #require(store.account(id: wallet.id)))
        #expect(store.recordDueRecurring(now: day(2027, 1, 20)).isEmpty)
        let waiting = try #require(store.waitingRecurring(now: day(2027, 1, 20)).first)
        #expect(!store.confirm(waiting, amount: 5_000_000, now: day(2027, 1, 20)))
        #expect(store.waitingRecurring(now: day(2027, 1, 20)).count == 1)
        #expect(store.confirm(waiting, amount: 5_000_000, accountID: bank.id, now: day(2027, 1, 20)))
        #expect(store.transactions.first?.accountID == bank.id)
        #expect(store.waitingRecurring(now: day(2027, 1, 20)).isEmpty)
    }

    /// A rule made in Cài đặt starting in the past: nothing before today is owed.
    @Test func newRuleInThePastDoesNotBackfill() {
        let (store, _, wallet) = storeWithWallet()
        let now = day(2027, 4, 10)
        var past = rule(start: day(2027, 1, 10), auto: true, account: wallet.id)
        past.lastHandled = FinanceStore.firstHandled(forNewRuleStarting: past.startDate, now: now)
        store.save(past)
        let recorded = store.recordDueRecurring(now: now)
        #expect(recorded.map { calendar.component(.month, from: $0.date) } == [4])
        #expect(FinanceStore.firstHandled(forNewRuleStarting: day(2027, 4, 20), now: now) == nil)
    }

    /// A transaction dated in the past made to repeat: nothing between it and today is recorded.
    @Test func backdatedRepeatingTransactionDoesNotBackfill() {
        let (store, _, wallet) = storeWithWallet()
        let rent = FinanceTransaction(amount: 5_000_000, categoryID: "housing.rent", kind: .expense,
                                      accountID: wallet.id, date: day(2027, 9, 5))
        store.add(rent, repeating: (.monthly, 1), autoRecords: true, now: day(2027, 11, 12))
        #expect(store.recordDueRecurring(now: day(2027, 11, 12)).isEmpty)
        #expect(store.recordDueRecurring(now: day(2027, 12, 6)).count == 1)
    }

    @Test func scheduleSaysWhichDay() {
        #expect(rule(start: day(2027, 1, 15)).scheduleDetail() == "Hằng tháng · ngày 15")
        #expect(rule(start: day(2027, 11, 15), frequency: .weekly).scheduleDetail() == "Hằng tuần · Thứ Hai")
        #expect(rule(start: day(2027, 9, 5), frequency: .yearly).scheduleDetail() == "Hằng năm · 05/09")
    }

    /// What the due-day notifications are planned from: today on, still to do, paused ones left out.
    @Test func dueDaysForNotifications() {
        let (store, _, wallet) = storeWithWallet()
        var weekly = rule(start: day(2027, 1, 6), frequency: .weekly, account: wallet.id)
        weekly.lastHandled = day(2027, 1, 13)
        store.save(weekly)
        var paused = rule(start: day(2027, 1, 14), account: wallet.id)
        paused.pausedAt = day(2027, 1, 1)
        store.save(paused)
        let due = store.dueRecurring(days: 14, now: day(2027, 1, 13, hour: 10))
        #expect(due.map { calendar.component(.day, from: $0.day) } == [20, 27])
    }
}
