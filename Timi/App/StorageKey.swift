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
    static let budgetAlerts = "settings.budgetAlerts"
    static let news = "settings.news"
    /// "Giao diện": `AppAppearance` (Hệ thống, Sáng, Tối).
    static let appearance = "settings.appearance"
    /// The account the last transaction was added to, picked first next time.
    static let lastAccountID = "transactions.lastAccountID"
    /// Ticks "Hỏi AI một câu hỏi" in Làm quen với Timi.
    static let askedAI = "onboarding.askedAI"
}
