//
//  SampleData.swift
//  Timi
//

import SwiftUI

/// Dữ liệu mẫu để thử giao diện. Ngày giao dịch tính lùi từ hôm nay
/// nên lúc nào mở app cũng có số liệu cho tuần và tháng hiện tại.
enum SampleData {
    static let cash = Account(name: "Ví tiền mặt", type: .cash, balance: 2_350_000)
    static let vietcombank = Account(name: "Vietcombank", type: .bank, balance: 45_800_000, institutionID: "vietcombank")
    static let techcombank = Account(name: "Techcombank", type: .bank, balance: 18_250_000, institutionID: "techcombank")
    static let momo = Account(name: "MoMo", type: .eWallet, balance: 1_120_000, institutionID: "momo")
    static let creditCard = Account(name: "Thẻ VPBank Visa", type: .credit, balance: -6_430_000,
                                    creditLimit: 50_000_000, paymentDueDate: daysFromNow(4), institutionID: "vpbank")

    static let accounts = [cash, vietcombank, techcombank, momo, creditCard]

    /// Prototype fixtures for the design; not real payment schedules or notifications.
    static let monthlyBudget = 30_000_000.0
    static let categoryBudgets = CategoryBudgets(limits: [TransactionCategory.food.rawValue: 6_000_000,
                                                          TransactionCategory.shopping.rawValue: 4_000_000,
                                                          TransactionCategory.entertainment.rawValue: 2_000_000])
    static let paymentReminders = [
        PaymentReminder(title: "Trả nợ thẻ tín dụng", amount: abs(creditCard.balance), isIncome: false,
                        dueDate: daysFromNow(4), detail: "Đi vay · \(creditCard.name)", avatar: .icon("hugeicons-credit-card")),
        PaymentReminder(title: "Minh thanh toán khoản vay", amount: 5_000_000, isIncome: true,
                        dueDate: daysFromNow(8), detail: "Cho vay · Minh Trần", avatar: .initials("M")),
    ]

    // Khoản vay mẫu (tổng cho vay còn 80tr), không phải giao dịch ngân hàng thật.
    // Có từ trước khi dùng app, nên không đổi số dư tài khoản nào.
    static let loans = [
        Loan(name: "Minh Trần", direction: .lent, principal: 75_000_000, outstanding: 45_000_000, dueDate: daysFromNow(8),
             contactID: contacts[0].id, isExisting: true),
        Loan(name: "Hùng Lê", direction: .lent, principal: 35_000_000, outstanding: 35_000_000, dueDate: daysFromNow(46),
             contactID: contacts[1].id, isExisting: true),
    ]

    /// "Danh bạ": the people of the sample loans first, then one with no loan yet.
    static let contacts = [
        Contact(name: "Minh Trần", relationshipID: ContactRelationship.friend.rawValue),
        Contact(name: "Hùng Lê", relationshipID: ContactRelationship.colleague.rawValue),
        Contact(name: "Mẹ", relationshipID: ContactRelationship.family.rawValue),
    ]

    private static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
    }

    // Hũ tiết kiệm mẫu (màn Tài khoản).
    static let savingsGoals = [
        SavingsGoal(name: "Hũ tiết kiệm", icon: "hugeicons-piggy-bank", saved: 28_000_000, target: 40_000_000),
        SavingsGoal(name: "Mua xe", icon: "hugeicons-car-01", saved: 15_000_000, target: 50_000_000,
                    dueDate: Calendar.current.date(byAdding: .month, value: 14, to: .now)),
        SavingsGoal(name: "Du lịch Đà Nẵng", icon: "hugeicons-luggage-01", saved: 8_000_000, target: 20_000_000,
                    dueDate: Calendar.current.date(byAdding: .month, value: 6, to: .now)),
    ]

    static let transactions: [FinanceTransaction] = [
        make("Cà phê Highlands", 55_000, "food.coffee", momo, daysAgo: 0, hour: 8),
        make("Cơm trưa văn phòng", 45_000, "food.lunch", cash, daysAgo: 0, hour: 12),
        make("Grab về nhà", 72_000, "transport.taxi", momo, daysAgo: 1, hour: 19),
        make("Đi chợ WinMart", 685_000, "food.market", vietcombank, daysAgo: 1, hour: 18),
        make("Netflix", 260_000, "entertainment.movies", creditCard, daysAgo: 2, hour: 21),
        make("Bún chả", 50_000, "food.lunch", cash, daysAgo: 2, hour: 12),
        make("Đổ xăng", 120_000, "transport.fuel", cash, daysAgo: 3, hour: 7),
        make("Lãi tiết kiệm", 850_000, "investment.interest", vietcombank, daysAgo: 3, hour: 9),
        make("Áo khoác Uniqlo", 980_000, "shopping.clothes", creditCard, daysAgo: 4, hour: 20),
        make("Tiền điện", 742_000, "bills.electricity", vietcombank, daysAgo: 5, hour: 10),
        make("Trà sữa", 45_000, "food.milktea", momo, daysAgo: 5, hour: 15),
        make("Xem phim CGV", 240_000, "entertainment.movies", momo, daysAgo: 6, hour: 20),
        make("Khám răng", 450_000, "health.doctor", techcombank, daysAgo: 7, hour: 9),
        make("Ăn tối cùng bạn", 520_000, "food.dinner", techcombank, daysAgo: 8, hour: 19),
        make("Tiền Internet", 220_000, "bills.internet", vietcombank, daysAgo: 9, hour: 9),
        make("Khóa học tiếng Anh", 1_500_000, "education.courses", techcombank, daysAgo: 10, hour: 10),
        make("Dự án freelance", 4_500_000, "salary.side", techcombank, daysAgo: 11, hour: 16),
        make("Grab đi làm", 65_000, "transport.taxi", momo, daysAgo: 12, hour: 8),
        make("Mua sách", 210_000, "education.books", momo, daysAgo: 13, hour: 17),
        make("Tiền nước", 95_000, "bills.water", vietcombank, daysAgo: 14, hour: 9),
        make("Đi chợ cuối tuần", 430_000, "food.market", cash, daysAgo: 15, hour: 9),
        make("Thuốc cảm", 85_000, "health.medicine", cash, daysAgo: 16, hour: 20),
        make("Thưởng dự án", 3_000_000, "bonus.bonus", vietcombank, daysAgo: 18, hour: 10),
        make("Lương tháng", 25_000_000, "salary.main", vietcombank, daysAgo: 20, hour: 9),
        make("Tiền nhà", 6_000_000, "housing.rent", vietcombank, daysAgo: 21, hour: 8),
        make("Giày thể thao", 1_250_000, "shopping.shoes", creditCard, daysAgo: 22, hour: 19),
    ]

    /// The goals' history: deposits that add up to what each sample goal holds, so a goal with money
    /// in it no longer says "Chưa nạp lần nào" (review 2026-10-31). History only: the sample
    /// balances are set as they are, so these move no money.
    static let goalTransfers: [GoalTransfer] = [
        deposit(7_000_000, into: savingsGoals[0], from: vietcombank, daysAgo: 28),
        deposit(7_000_000, into: savingsGoals[0], from: vietcombank, daysAgo: 21),
        deposit(14_000_000, into: savingsGoals[0], from: techcombank, daysAgo: 14),
        deposit(5_000_000, into: savingsGoals[1], from: vietcombank, daysAgo: 25),
        deposit(5_000_000, into: savingsGoals[1], from: techcombank, daysAgo: 15),
        deposit(5_000_000, into: savingsGoals[1], from: vietcombank, daysAgo: 6),
        deposit(5_000_000, into: savingsGoals[2], from: techcombank, daysAgo: 18),
        deposit(3_000_000, into: savingsGoals[2], from: cash, daysAgo: 4),
    ]

    /// When a sample account started being tracked: the day of the first money it moved, so
    /// "Từ ngày …" on its page is not after the history under it (review 2026-10-31: it said the
    /// day the app was installed). Today when it moved none.
    static func openedAt(_ account: Account) -> Date {
        let dates = transactions.filter { $0.accountID == account.id }.map(\.date)
            + goalTransfers.filter { $0.accountID == account.id }.map(\.date)
        return Calendar.current.startOfDay(for: dates.min() ?? .now)
    }

    private static func deposit(_ amount: Double, into goal: SavingsGoal, from account: Account,
                                daysAgo: Int) -> GoalTransfer {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let date = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
        return GoalTransfer(goalID: goal.id, accountID: account.id, direction: .deposit, amount: amount, date: date)
    }

    private static func make(
        _ title: String,
        _ amount: Double,
        _ item: String,
        _ account: Account,
        daysAgo: Int,
        hour: Int
    ) -> FinanceTransaction {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let date = calendar.date(bySettingHour: hour, minute: 15, second: 0, of: day) ?? day
        // "food.coffee" is in the group "food".
        let group = item.split(separator: ".").first.map(String.init) ?? item
        let kind = DefaultCategories.groups.first { $0.id == group }?.kind ?? .expense
        // What it was for goes in the note; a transaction has no name of its own.
        return FinanceTransaction(amount: amount, categoryID: item, kind: kind,
                                  accountID: account.id, date: date, note: title)
    }
}
