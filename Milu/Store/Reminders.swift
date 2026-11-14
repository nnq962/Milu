import Foundation
import Observation
import UserNotifications

/// "Nhắc ghi chi tiêu" and "Cảnh báo hạn mức" (Cài đặt → Thông báo, user request 2026-11-12),
/// as notifications made on the iPhone itself: no server.
///
/// - The reminder comes at the chosen time every day, recorded or not (user choice 2026-11-12: it
///   first skipped days already recorded), planned `DailyReminderPlan.days` ahead and again on
///   every return to the app, so it keeps going while the app is opened now and then.
/// - A limit's alert comes once at 80% and once on reaching it, for the month's limit and each
///   group's, each once a month (`BudgetAlertPlan`). Changing a limit starts its alerts afresh.
///
/// Neither shows while Milu is open: the add form already says what a spending does to the limit.
@MainActor
final class Reminders: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Reminders()

    private let center = UNUserNotificationCenter.current()
    /// What a tapped notification asks the screens to do (`ContentView` opens the add form).
    let router = NotificationRouter()

    override private init() {
        super.init()
        center.delegate = self
    }

    // MARK: Permission

    enum Permission { case notAsked, allowed, denied }

    func permission() async -> Permission {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .notAsked
        case .denied: .denied
        default: .allowed
        }
    }

    /// Asks once; after a "no" only Settings can change it, so this just reports it.
    func requestPermission() async -> Bool {
        switch await permission() {
        case .allowed: return true
        case .denied: return false
        case .notAsked: return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    // MARK: Daily reminder

    private static let dailyPrefix = "daily."

    func scheduleDaily(enabled: Bool, minutes: Int, now: Date = .now) async {
        let pending = await center.pendingNotificationRequests().map(\.identifier)
            .filter { $0.hasPrefix(Self.dailyPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        guard enabled, await permission() == .allowed else { return }
        let plan = DailyReminderPlan(minutes: minutes, now: now)
        for date in plan.dates {
            let content = UNMutableNotificationContent()
            let message = DailyReminderPlan.messages.randomElement() ?? DailyReminderPlan.messages[0]
            content.title = message.title
            content.body = message.body
            content.sound = .default
            content.userInfo = [NotificationRouter.actionKey: NotificationRouter.Action.addTransaction.rawValue]
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let request = UNNotificationRequest(identifier: Self.dailyPrefix + DailyReminderPlan.dayKey(date), content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
            try? await center.add(request)
        }
    }

    // MARK: Recurring

    private static let recurringPrefix = "recurring."

    /// One notification at `RecurringReminderPlan.hour` on each day a rule falls due in the next
    /// `RecurringReminderPlan.days` (user request 2026-11-12), planned again whenever the rules
    /// change and on every return to the app.
    func scheduleRecurring(_ occurrences: [RecurringOccurrence], titles: [RecurringRule.ID: String],
                           needsAccount: Set<RecurringRule.ID> = [], enabled: Bool, now: Date = .now) async {
        let pending = await center.pendingNotificationRequests().map(\.identifier)
            .filter { $0.hasPrefix(Self.recurringPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        guard enabled, await permission() == .allowed else { return }
        let calendar = Calendar.current
        for occurrence in occurrences {
            guard let date = calendar.date(bySettingHour: RecurringReminderPlan.hour, minute: 0, second: 0, of: occurrence.day),
                  date > now else { continue }
            let rule = occurrence.rule
            let name = titles[rule.id] ?? "Khoản định kỳ"
            let content = UNMutableNotificationContent()
            content.title = rule.kind == .income ? "Hôm nay có khoản thu 💰" : "Hôm nay tới hạn 📅"
            content.body = needsAccount.contains(rule.id)
                ? "\(name) · \(rule.amount.vnd). Tài khoản đã lưu trữ, mở Milu để chọn tài khoản khác."
                : rule.autoRecords
                ? "\(name) · \(rule.amount.vnd). Milu sẽ tự ghi khi bạn mở app."
                : "\(name) · \(rule.amount.vnd). Mở Milu để ghi hoặc bỏ qua lần này."
            content.sound = .default
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let id = Self.recurringPrefix + rule.id.uuidString + "." + DailyReminderPlan.dayKey(date)
            try? await center.add(UNNotificationRequest(identifier: id, content: content,
                                                        trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
        }
    }

    // MARK: Budget alerts

    /// Sends what crossed a level since the last check. `quietly`: only notes where things stand,
    /// sending nothing (when the alerts are turned on, so the first thing they do is not to
    /// announce a limit passed days ago).
    func checkBudgets(_ limits: [BudgetAlertPlan.Limit], enabled: Bool, quietly: Bool = false,
                      defaults: UserDefaults = .standard, now: Date = .now) async {
        guard enabled else { return }
        var plan = BudgetAlertPlan(sent: Set(defaults.stringArray(forKey: BudgetAlertPlan.sentKey) ?? []), now: now)
        let alerts = plan.alerts(for: limits)
        defaults.set(Array(plan.sent).sorted(), forKey: BudgetAlertPlan.sentKey)
        guard !quietly, await permission() == .allowed else { return }
        for alert in alerts {
            let content = UNMutableNotificationContent()
            content.title = alert.title
            content.body = alert.body
            content.sound = .default
            try? await center.add(UNNotificationRequest(identifier: "budget." + alert.key, content: content, trigger: nil))
        }
    }

    func removeAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: UNUserNotificationCenterDelegate

    /// Nothing over the open app: the add form already shows what a spending does to the limit,
    /// and a reminder to record is moot while recording.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification)
        async -> UNNotificationPresentationOptions { [] }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let raw = response.notification.request.content.userInfo[NotificationRouter.actionKey] as? String
        guard let action = raw.flatMap(NotificationRouter.Action.init(rawValue:)) else { return }
        await MainActor.run { router.pending = action }
    }
}

/// What a tapped notification asks for, picked up by the screens.
@MainActor
@Observable
final class NotificationRouter {
    enum Action: String { case addTransaction }
    static let actionKey = "action"
    var pending: Action?
}

/// When the reminder comes: at `minutes` after midnight on each of the next days, today too if
/// that time is still ahead.
struct DailyReminderPlan {
    /// Planned this far ahead, and again on every change and every opening of the app.
    static let days = 14
    static let defaultMinutes = 21 * 60

    let dates: [Date]

    init(minutes: Int, now: Date, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        dates = (0..<Self.days).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let time = calendar.date(byAdding: .minute, value: minutes, to: day),
                  time > now else { return nil }
            return time
        }
    }

    static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Milu's voice: Gen Z, teasing, never mean (user request 2026-11-12); one picked at random
    /// for each day.
    static let messages: [(title: String, body: String)] = [
        ("Ví ơi ví à 💸", "Tiêu như không có ngày mai mà không ghi là toang đó nha."),
        ("Alo, có ai ở nhà không? 🐾", "Milu đợi bạn ghi chi tiêu từ sáng tới giờ luôn á."),
        ("Trà sữa hôm nay mấy ly rồi? 🧋", "Khai thật đi, Milu không méc ai đâu."),
        ("Tiền đi đâu hết rồi? 🫠", "Không ghi thì cuối tháng chỉ biết hỏi trời thôi."),
        ("Check var nhẹ cái ví 👀", "Ghi chi tiêu hôm nay trước khi nó bốc hơi khỏi trí nhớ."),
        ("Đừng để ví flop nha 📉", "Một phút ghi chi tiêu, cả tháng đỡ hoang mang."),
        ("Hôm nay chốt đơn gì rồi? 🛒", "Mua online thì ghi luôn vào Milu cho nhớ nè."),
        ("Ủa rồi tiền đâu? 🤨", "Milu biết bạn tiêu rồi đó, ghi vào cho minh bạch đi."),
        ("Lương chưa về đã đi? 🏃", "Ghi lại để biết nó chạy đường nào nha."),
        ("Slay thì slay, ghi sổ cũng phải slay ✨", "Vào Milu ghi chi tiêu hôm nay cái nè."),
        ("Ví đang kêu cứu kìa 🆘", "Ghi khoản chi hôm nay để Milu sơ cứu kịp thời."),
        ("Đừng ghost Milu nữa mà 👻", "Hôm nay tiêu gì, kể Milu nghe với."),
        ("Cuối tháng ăn mì gói không? 🍜", "Không muốn thì ghi chi tiêu đều đặn đi nha."),
        ("Nói tiết kiệm mà ta? 🤔", "Hôm nay chưa thấy ghi khoản nào luôn á."),
        ("Một phút thôi, hứa đó ⏱️", "Ghi chi tiêu còn nhanh hơn lướt hết một cái reels."),
        ("Milu hóng drama tài chính 🍿", "Tiêu gì, ở đâu, bao nhiêu? Ghi vào kể Milu nghe."),
        ("Trí nhớ cá vàng tới rồi 🐠", "Ghi ngay kẻo mai quên luôn mình đã tiêu gì."),
        ("Ví mỏng dính rồi kìa 🥲", "Ghi lại để biết nó mỏng vì đâu nha."),
        ("Cà phê sáng, trà chiều, lẩu tối? ☕", "Ghi đủ combo hôm nay vào Milu đi."),
        ("Tiết kiệm là trend, ghi sổ là phải 📒", "Ghi chi tiêu hôm nay cho khỏi out trend nè."),
    ]
}

/// Which limit alerts to send: each level (80%, reached) of each limit once a month. A level is
/// "sent" by key "month|limit id|limit amount|level", so a new month or a changed limit starts
/// afresh; keys from past months are dropped.
struct BudgetAlertPlan {
    struct Limit: Equatable {
        /// "month" for the month's limit, else the group's id.
        let id: String
        /// "Hạn mức tháng" or the group's name.
        let name: String
        let limit: Double
        let spent: Double
    }

    struct Alert: Equatable {
        let key: String
        let title: String
        let body: String
    }

    static let sentKey = "alerts.budgetSent"

    private(set) var sent: Set<String>
    private let month: String

    init(sent: Set<String>, now: Date) {
        let parts = Calendar.current.dateComponents([.year, .month], from: now)
        let month = String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
        self.month = month
        self.sent = sent.filter { $0.hasPrefix(month + "|") }
    }

    /// The alerts due now, the highest level only when both are (80% is not sent after "đã hết").
    mutating func alerts(for limits: [Limit]) -> [Alert] {
        limits.compactMap { limit -> Alert? in
            guard limit.limit > 0 else { return nil }
            let progress = BudgetProgress(limit: limit.limit, spent: limit.spent)
            let base = "\(month)|\(limit.id)|\(Int64(limit.limit))"
            let reached = progress.spent >= progress.limit
            let nearing = progress.ratio >= 0.8
            let reachedKey = base + "|100"
            let nearingKey = base + "|80"
            if reached, !sent.contains(reachedKey) {
                sent.formUnion([reachedKey, nearingKey])
                let over = progress.spent - progress.limit
                return Alert(key: reachedKey, title: "\(limit.name) đã hết hạn mức 😬",
                             body: over >= 1 ? "Đã vượt \(over.vnd) so với hạn mức \(limit.limit.vnd) tháng này."
                                             : "Đã tiêu đủ \(limit.limit.vnd) của tháng này.")
            }
            if nearing, !reached, !sent.contains(nearingKey) {
                sent.insert(nearingKey)
                return Alert(key: nearingKey, title: "\(limit.name) sắp chạm hạn mức ⚠️",
                             body: "Đã dùng \(progress.percentText) hạn mức tháng này, còn \(progress.left.vnd).")
            }
            return nil
        }
    }
}

/// When "Nhắc khoản định kỳ" comes: at 8:00 on the day, for the next two weeks.
enum RecurringReminderPlan {
    static let hour = 8
    static let days = 14

    /// With the first recurring rule, "Nhắc khoản định kỳ" comes on by itself (review 2026-11-12:
    /// off and deep in Cài đặt, a rule that asks first was easy to miss). Only while the user has
    /// never set it: asks for notifications once; refused, it stays off and is not asked again.
    @MainActor
    static func turnOnIfNeverSet(defaults: UserDefaults = .standard) async {
        guard defaults.object(forKey: StorageKey.recurringAlerts) == nil else { return }
        // No Face ID cover over iOS's prompt (`AppLock.whileSystemAsks`).
        let allowed = await AppLock.shared.whileSystemAsks { await Reminders.shared.requestPermission() }
        defaults.set(allowed, forKey: StorageKey.recurringAlerts)
    }
}
