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
    /// "Giao diện": `AppAppearance` (Hệ thống, Sáng, Tối).
    static let appearance = "settings.appearance"
    /// The account the last transaction was added to, picked first next time.
    static let lastAccountID = "transactions.lastAccountID"
    /// Ticks "Hỏi AI một câu hỏi" in Làm quen với Milu.
    static let askedAI = "onboarding.askedAI"
    /// True after "Xoá toàn bộ dữ liệu": an empty database stays empty, the sample data is not
    /// seeded again (user report 2026-11-02: it came straight back, so erasing seemed to do nothing).
    static let sampleDataOff = "data.sampleDataOff"
}
