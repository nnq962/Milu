import Foundation

/// Every key the app saves in UserDefaults (`@AppStorage`), in one place so a screen that reads
/// a setting and one that writes it cannot drift apart by a typo. `AIQuota` and
/// `FinanceDatabase` keep their own private keys next to the code that owns them.
enum StorageKey {
    /// Hạn mức chi tiêu mỗi tháng (Tổng quan, Thu chi, Cài đặt).
    static let monthlyBudget = "overview.monthlyBudget"
    /// Hạn mức của từng nhóm hạng mục (`CategoryBudgets`).
    static let categoryBudgets = "budget.categoryLimits"
    static let dailyReminder = "settings.dailyReminder"
    /// Local wall-clock time, stored as minutes after midnight (default 21:00).
    static let dailyReminderMinutes = "settings.dailyReminderMinutes"
    static let budgetAlerts = "settings.budgetAlerts"
    /// "Nhắc khoản định kỳ": a notification at 8:00 on the day a recurring rule falls due.
    static let recurringAlerts = "settings.recurringAlerts"
    /// "Khoá bằng Face ID" (Milu Pro) and after how long away it locks again (`AppLock.Delay`).
    /// Per device, never synced.
    static let appLock = "security.appLock"
    static let appLockDelay = "security.appLockDelay"
    /// The App Store's last answer on Milu Pro (`ProStore`), for before it answers again.
    static let proActive = "pro.active"
    /// Debug only: act as Milu Pro, to try its features before it is on sale.
    static let debugPro = "debug.proPlan"
    /// Debug: the plan "bought" with the made-up prices (`ProStore.isMocking`).
    static let debugMockPlan = "debug.mockProPlan"
    /// "Giao diện": `AppAppearance` (Hệ thống, Sáng, Tối).
    static let appearance = "settings.appearance"
    /// The name the user gave themselves (Cài đặt's card, the initial on the bar); empty until set.
    static let profileName = "settings.profileName"
    /// The picture by the name (`ProfileAvatar.raw`): the initial or a Milu face.
    static let profileAvatar = "settings.profileAvatar"
    /// The account the last transaction was added to, picked first next time.
    static let lastAccountID = "transactions.lastAccountID"
    /// The welcome pages were seen (`WelcomeView`): never shown again, here or after a reinstall
    /// (synced through iCloud), and kept by "Xoá toàn bộ dữ liệu".
    static let welcomeSeen = "onboarding.welcomeSeen"
    /// Ticks "Hỏi AI một câu hỏi" in Làm quen với Milu.
    static let askedAI = "onboarding.askedAI"
    /// True after "Xoá toàn bộ dữ liệu": an empty database stays empty, the sample data is not
    /// seeded again (user report 2026-11-02: it came straight back, so erasing seemed to do nothing).
    static let sampleDataOff = "data.sampleDataOff"
}
