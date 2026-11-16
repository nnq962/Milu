import Foundation

/// Giao dịch định kỳ: rules that come back on a schedule, what falls due, recording and skipping.
extension FinanceStore {
    func recurringRule(id: RecurringRule.ID) -> RecurringRule? {
        recurringRules.first { $0.id == id }
    }

    /// Adds or changes a rule. Transactions it recorded stay as they were.
    func save(_ rule: RecurringRule) {
        if let index = recurringRules.firstIndex(where: { $0.id == rule.id }) {
            recurringRules[index] = rule
        } else {
            recurringRules.append(rule)
        }
        database?.save(rule)
    }

    /// Deletes a rule; what it recorded stays in the history.
    func delete(_ rule: RecurringRule) {
        recurringRules.removeAll { $0.id == rule.id }
        database?.deleteRecurringRule(id: rule.id)
    }

    /// A new transaction that comes back on `schedule`: it is recorded now, and its rule starts
    /// from its day. Dated in the past, nothing between it and today is recorded (review
    /// 2026-11-12: "Tiền nhà" dated 5/9 filled in 5/10 and 5/11 by itself); today's, if due, is,
    /// as for a rule made in Cài đặt (`firstHandled(forRepeating:)`).
    func add(_ transaction: FinanceTransaction, repeating schedule: (frequency: RecurringRule.Frequency, interval: Int),
             autoRecords: Bool, now: Date = .now) {
        let rule = RecurringRule(kind: transaction.kind, amount: transaction.amount, categoryID: transaction.categoryID,
                                 accountID: transaction.accountID, note: transaction.note,
                                 frequency: schedule.frequency, interval: schedule.interval,
                                 startDate: transaction.date, autoRecords: autoRecords,
                                 lastHandled: Self.firstHandled(forRepeating: transaction.date, now: now),
                                 isExcluded: transaction.isExcluded)
        var first = transaction
        first.id = RecurringRule.transactionID(rule: rule.id, day: transaction.date)
        first.recurringRuleID = rule.id
        persist {
            save(rule)
            add(first)
        }
        recordDueRecurring(only: rule.id, now: now)
    }

    /// A transaction already recorded, changed and made to repeat from now on (user choice
    /// 2026-11-12): its rule starts on its day, but nothing before today is recorded for it, so
    /// a balance never moves by itself for the past when a past transaction is made to repeat.
    /// Today's, if due, is, as for a rule made in Cài đặt.
    func update(_ transaction: FinanceTransaction, startRepeating schedule: (frequency: RecurringRule.Frequency, interval: Int),
                autoRecords: Bool, now: Date = .now) {
        let rule = RecurringRule(kind: transaction.kind, amount: transaction.amount, categoryID: transaction.categoryID,
                                 accountID: transaction.accountID, note: transaction.note,
                                 frequency: schedule.frequency, interval: schedule.interval,
                                 startDate: transaction.date, autoRecords: autoRecords,
                                 lastHandled: Self.firstHandled(forRepeating: transaction.date, now: now),
                                 isExcluded: transaction.isExcluded)
        var linked = transaction
        linked.recurringRuleID = rule.id
        persist {
            save(rule)
            update(linked)
        }
        recordDueRecurring(only: rule.id, now: now)
    }

    /// The day a rule made from a transaction has handled: the transaction's own (it is that day's),
    /// or yesterday when it is older, so nothing before today is recorded but today's still is
    /// recorded or asked (audit round 5, 2026-11-16: "Tiền nhà" of last month made to repeat on its
    /// day this month was never recorded nor asked, while a rule made in Cài đặt was).
    static func firstHandled(forRepeating date: Date, now: Date = .now) -> Date {
        let calendar = RecurringRule.calendar
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) ?? now
        return max(calendar.startOfDay(for: date), yesterday)
    }

    /// A rule made in Cài đặt: like one made from a transaction, nothing before today is recorded
    /// for it (user choice 2026-11-12); a start in the past only sets its day of the month.
    static func firstHandled(forNewRuleStarting start: Date, now: Date = .now) -> Date? {
        let calendar = RecurringRule.calendar
        let today = calendar.startOfDay(for: now)
        guard calendar.startOfDay(for: start) < today else { return nil }
        return calendar.date(byAdding: .day, value: -1, to: today)
    }

    // MARK: Tới hạn

    /// Records what has fallen due by today on the rules that record by themselves (all of it,
    /// when the app was not opened for a while), and returns what was recorded. Recording an
    /// occurrence another device already recorded makes nothing new: its id is the same.
    ///
    /// `only` limits it to one rule: the one the user just saved or moved to another account.
    /// The others record only through `MiluApp.autoRecord`, which waits for iCloud first (audit
    /// round 5, 2026-11-16: saving any rule during a download recorded a rule paused or deleted
    /// on another device from the copy before it).
    @discardableResult
    func recordDueRecurring(only ruleID: RecurringRule.ID? = nil, now: Date = .now) -> [FinanceTransaction] {
        var recorded: [FinanceTransaction] = []
        persist {
            // All the days at once: the list sorted once, each balance moved once, the rows saved
            // together (audit round 5, 2026-11-16: months of a daily rule went in a day at a time,
            // the whole list sorted and the database searched twice for each, as Milu came to the
            // front).
            var known = Set(transactions.map(\.id))
            var moves: [Account.ID: Double] = [:]
            // A rule whose account was archived or deleted records nothing and does not move on:
            // its days wait for the user, who picks another account (`waitingRecurring`).
            for rule in recurringRules where rule.autoRecords && !rule.isPaused && canRecord(onto: rule.accountID)
                && (ruleID == nil || rule.id == ruleID) {
                let days = rule.occurrences(after: rule.lastHandled ?? dayBefore(rule.startDate), through: now)
                guard let last = days.last else { continue }
                for day in days where rule.amount > 0 {
                    let transaction = occurrenceTransaction(rule, on: day, amount: rule.amount, now: now)
                    // Recording a day another device already recorded makes nothing new.
                    guard known.insert(transaction.id).inserted else { continue }
                    recorded.append(transaction)
                    moves[rule.accountID, default: 0] += transaction.signedAmount
                }
                var handled = rule
                handled.lastHandled = last
                moveOn(handled)
            }
            guard !recorded.isEmpty else { return }
            transactions.append(contentsOf: recorded)
            transactions.sort { $0.date > $1.date }
            for (accountID, delta) in moves { adjustBalance(of: accountID, by: delta) }
            database?.save(recorded)
        }
        return recorded
    }

    /// The rules that ask first, each with the earliest day it fell due and is still to do, oldest
    /// first, with how many more of it wait after that day (`moreWaiting`).
    func waitingRecurring(now: Date = .now) -> [RecurringOccurrence] {
        recurringRules.compactMap { rule -> RecurringOccurrence? in
            guard !rule.isPaused, !rule.autoRecords || !canRecord(onto: rule.accountID) else { return nil }
            let days = rule.occurrences(after: rule.lastHandled ?? dayBefore(rule.startDate), through: now)
            guard let first = days.first else { return nil }
            return RecurringOccurrence(rule: rule, day: first, moreWaiting: days.count - 1)
        }
        .sorted { $0.day < $1.day }
    }

    /// What falls due after today within `days`, soonest first: one per rule, its next day.
    func upcomingRecurring(days: Int = 7, now: Date = .now) -> [RecurringOccurrence] {
        let calendar = RecurringRule.calendar
        guard let horizon = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now)) else { return [] }
        return recurringRules.compactMap { rule -> RecurringOccurrence? in
            guard !rule.isPaused, let next = rule.nextOccurrence(after: now), next <= horizon else { return nil }
            return RecurringOccurrence(rule: rule, day: next)
        }
        .sorted { $0.day < $1.day }
    }

    /// Every day a running rule falls due from today through `days` ahead, still to do: what the
    /// due-day notifications are planned from.
    func dueRecurring(days: Int, now: Date = .now) -> [RecurringOccurrence] {
        let calendar = RecurringRule.calendar
        guard let horizon = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now)) else { return [] }
        return recurringRules.filter { !$0.isPaused }.flatMap { rule in
            let after = max(rule.lastHandled ?? dayBefore(rule.startDate), dayBefore(now))
            return rule.occurrences(after: after, through: horizon, limit: 64).map { RecurringOccurrence(rule: rule, day: $0) }
        }
        .sorted { $0.day < $1.day }
    }

    /// The day a rule falls due next, from today on (today's if still to do).
    func nextDue(_ rule: RecurringRule, now: Date = .now) -> Date? {
        let handledOrYesterday = max(rule.lastHandled ?? dayBefore(rule.startDate), dayBefore(now))
        return rule.nextOccurrence(after: handledOrYesterday)
    }

    /// Whether a rule's transactions can go onto this account: one in use, not archived or deleted.
    func canRecord(onto accountID: Account.ID) -> Bool {
        accounts.contains { $0.id == accountID }
    }

    /// "Ghi": records the occurrence for `amount` (it may differ this time) onto `accountID` (the
    /// rule's, or another when the rule's was archived or deleted) and moves the rule on. Nothing
    /// moves on when it could not be recorded; false then.
    @discardableResult
    func confirm(_ occurrence: RecurringOccurrence, amount: Double, accountID: Account.ID? = nil,
                 now: Date = .now) -> Bool {
        var done = false
        persist {
            // The rule as it is now: changed after the day was listed ("Sửa khoản định kỳ" from
            // the "Ghi" sheet), it records as changed (audit round 3, 2026-11-16: the old item,
            // note, "Không tính" and even kind went in).
            let rule = recurringRule(id: occurrence.rule.id) ?? occurrence.rule
            let id = RecurringRule.transactionID(rule: rule.id, day: occurrence.day)
            record(rule, on: occurrence.day, amount: amount, accountID: accountID, now: now, byUser: true)
            guard transaction(id: id) != nil else { return }
            markHandled(occurrence)
            done = true
        }
        return done
    }

    /// "Bỏ qua lần này": nothing recorded, the rule moves on.
    func skip(_ occurrence: RecurringOccurrence) {
        markHandled(occurrence)
    }

    private func markHandled(_ occurrence: RecurringOccurrence) {
        guard var rule = recurringRule(id: occurrence.rule.id) else { return }
        rule.lastHandled = max(rule.lastHandled ?? .distantPast, occurrence.day)
        moveOn(rule)
    }

    /// The rule's `lastHandled` moved on, nothing else written (`FinanceDatabase.saveHandled`).
    private func moveOn(_ rule: RecurringRule) {
        guard let index = recurringRules.firstIndex(where: { $0.id == rule.id }) else { return }
        recurringRules[index].lastHandled = rule.lastHandled
        database?.saveHandled(rule)
    }

    /// Records one day of a rule, unless it is there already; nil when it was, or when its account
    /// cannot take it (archived, gone).
    @discardableResult
    private func record(_ rule: RecurringRule, on day: Date, amount: Double, accountID: Account.ID? = nil,
                        now: Date, byUser: Bool) -> FinanceTransaction? {
        let accountID = accountID ?? rule.accountID
        let transaction = occurrenceTransaction(rule, on: day, amount: amount, accountID: accountID, now: now)
        guard self.transaction(id: transaction.id) == nil, amount > 0, canRecord(onto: accountID) else { return nil }
        let before = transactions.count
        // Recorded by Milu, not by the user: no "Làm quen" step is paid for it.
        let creation = lastCreated
        add(transaction)
        if !byUser { lastCreated = creation }
        return transactions.count > before ? transaction : nil
    }

    /// One day of a rule as a transaction: its id the same on every device, on the rule's account
    /// unless another is given.
    private func occurrenceTransaction(_ rule: RecurringRule, on day: Date, amount: Double,
                                       accountID: Account.ID? = nil, now: Date) -> FinanceTransaction {
        var transaction = FinanceTransaction(id: RecurringRule.transactionID(rule: rule.id, day: day), amount: amount,
                                             categoryID: rule.categoryID, kind: rule.kind,
                                             accountID: accountID ?? rule.accountID,
                                             date: rule.transactionDate(on: day, now: now), note: rule.note)
        transaction.recurringRuleID = rule.id
        transaction.isExcluded = rule.isExcluded
        return transaction
    }

    private func dayBefore(_ date: Date) -> Date {
        let calendar = RecurringRule.calendar
        return calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date)) ?? date
    }
}
