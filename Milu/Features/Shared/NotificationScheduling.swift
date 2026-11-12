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
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = 0.0
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = CategoryBudgets()

    private let reminders = Reminders.shared

    func body(content: Content) -> some View {
        content
            .task { await refresh(checkingQuietly: false) }
            .onChange(of: store.transactions) { Task { await checkLimits(quietly: false) } }
            .onChange(of: dailyReminder) { Task { await planReminder() } }
            .onChange(of: reminderMinutes) { Task { await planReminder() } }
            // Turned on, or a limit changed: note where things stand without announcing it.
            .onChange(of: budgetAlerts) { _, on in if on { Task { await checkLimits(quietly: true) } } }
            .onChange(of: monthlyBudget) { Task { await checkLimits(quietly: true) } }
            .onChange(of: categoryBudgets) { Task { await checkLimits(quietly: true) } }
            .onChange(of: scenePhase) { _, phase in
                // A new day since: plan from it.
                if phase == .active { Task { await planReminder() } }
            }
    }

    private func refresh(checkingQuietly quietly: Bool) async {
        await planReminder()
        await checkLimits(quietly: quietly)
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
