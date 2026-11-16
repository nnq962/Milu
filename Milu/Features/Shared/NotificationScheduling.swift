import SwiftUI

/// Keeps the notifications in step with the data and the choices in Cài đặt → Thông báo
/// (`Reminders`): the reminder is planned again when its choices change and on every return to the
/// app; the limits are checked after every change to spending.
struct NotificationScheduling: ViewModifier {
    @Environment(FinanceStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(StorageKey.dailyReminder) private var dailyReminder = false
    @AppStorage(StorageKey.dailyReminderMinutes) private var reminderMinutes = DailyReminderPlan.defaultMinutes
    @AppStorage(StorageKey.budgetAlerts) private var budgetAlerts = false
    @AppStorage(StorageKey.recurringAlerts) private var recurringAlerts = false
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = 0.0
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = CategoryBudgets()

    private let reminders = Reminders.shared
    /// Planned again on coming back from the background only: every inactive moment (Control
    /// Center, a Face ID prompt) took them all down and put them back (audit round 2, 2026-11-15).
    @State private var wasInBackground = false
    /// The pass under way: a new one stops it, so a stale one cannot put back a removed rule.
    @State private var planning: Task<Void, Never>?

    func body(content: Content) -> some View {
        watchingChanges(content)
            .task { await refresh(checkingQuietly: false) }
            // Just allowed: what is on is planned now, not at the next return to the app.
            .onReceive(NotificationCenter.default.publisher(for: Reminders.allowedNotification)) { _ in
                Task { await refresh(checkingQuietly: true) }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { wasInBackground = true }
                // A new day since: plan from it.
                if phase == .active, wasInBackground {
                    wasInBackground = false
                    Task { await planReminder() }
                    replanRecurring()
                }
            }
    }

    /// What is planned again as the data and the choices change (apart from `body`, which the
    /// compiler could not type-check in one piece).
    private func watchingChanges(_ content: Content) -> some View {
        content
            .onChange(of: store.transactions) { Task { await checkLimits(quietly: false) } }
            // A transfer's fee, a loan's interest, an account locked or brought back move the
            // month's spending too (audit round 2, 2026-11-15: no alert for those).
            .onChange(of: store.total(.expense)) { Task { await checkLimits(quietly: false) } }
            .onChange(of: dailyReminder) { Task { await planReminder() } }
            .onChange(of: recurringAlerts) { replanRecurring() }
            .onChange(of: store.recurringRules) { replanRecurring() }
            // An account archived or brought back changes what the reminders say.
            .onChange(of: store.accounts.map(\.id)) { replanRecurring() }
            .onChange(of: reminderMinutes) { Task { await planReminder() } }
            // Turned on, or a limit changed: note where things stand without announcing it.
            .onChange(of: budgetAlerts) { _, on in if on { Task { await checkLimits(quietly: true) } } }
            .onChange(of: monthlyBudget) { Task { await checkLimits(quietly: true) } }
            .onChange(of: categoryBudgets) { Task { await checkLimits(quietly: true) } }
    }

    private func replanRecurring() {
        planning?.cancel()
        planning = Task { await planRecurring() }
    }

    private func refresh(checkingQuietly quietly: Bool) async {
        await planReminder()
        await planRecurring()
        await checkLimits(quietly: quietly)
    }

    private func planRecurring() async {
        let due = store.dueRecurring(days: RecurringReminderPlan.days)
        let titles = Dictionary(store.recurringRules.map { ($0.id, store.title(of: $0)) }, uniquingKeysWith: { a, _ in a })
        let needsAccount = Set(store.recurringRules.filter { !store.canRecord(onto: $0.accountID) }.map(\.id))
        await reminders.scheduleRecurring(due, titles: titles, needsAccount: needsAccount, enabled: recurringAlerts)
    }

    private func planReminder() async {
        await reminders.scheduleDaily(enabled: dailyReminder, minutes: reminderMinutes)
    }

    private func checkLimits(quietly: Bool) async {
        await reminders.checkBudgets(limits, enabled: budgetAlerts, quietly: quietly)
    }

    /// The month's limit and each group's, with what was spent this month as the reports count it.
    private var limits: [BudgetAlertPlan.Limit] {
        var limits = [BudgetAlertPlan.Limit(id: "month", name: "Chi tiêu tháng này", limit: monthlyBudget,
                                            spent: store.total(.expense))]
        guard monthlyBudget > 0 else { return limits }
        let spent = Dictionary(store.expensesByCategory().map { ($0.groupID, $0.amount) }, uniquingKeysWith: +)
        let groups = store.budgetGroupIDs
        for (id, limit) in categoryBudgets.limits where groups.contains(id) && limit > 0 {
            limits.append(.init(id: id, name: store.categoryName(id), limit: limit, spent: spent[id] ?? 0))
        }
        return limits
    }
}

extension View {
    func notificationScheduling() -> some View { modifier(NotificationScheduling()) }
}
