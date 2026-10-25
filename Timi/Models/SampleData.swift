//
//  SampleData.swift
//  Timi
//

import SwiftUI

/// Dữ liệu mẫu để thử giao diện. Ngày giao dịch tính lùi từ hôm nay
/// nên lúc nào mở app cũng có số liệu cho tuần và tháng hiện tại.
enum SampleData {
    static let cash = Account(name: "Ví tiền mặt", type: .cash, balance: 2_350_000, color: .orange, detail: "Chi tiêu hằng ngày")
    static let vietcombank = Account(name: "Vietcombank", type: .bank, balance: 45_800_000, color: .green, detail: "•••• 4821")
    static let techcombank = Account(name: "Techcombank", type: .bank, balance: 18_250_000, color: .red, detail: "•••• 1907")
    static let momo = Account(name: "MoMo", type: .eWallet, balance: 1_120_000, color: .pink, detail: "0912 •••• 88")
    static let creditCard = Account(name: "Thẻ VPBank Visa", type: .credit, balance: -6_430_000, color: .indigo, detail: "•••• 3360 · Hạn mức 50 tr")
    static let savings = Account(name: "Sổ tiết kiệm 12 tháng", type: .savings, balance: 120_000_000, color: .teal, detail: "Lãi suất 5,2%/năm")

    static let accounts = [cash, vietcombank, techcombank, momo, creditCard, savings]

    static let transactions: [FinanceTransaction] = [
        make("Cà phê Highlands", 55_000, .food, momo, daysAgo: 0, hour: 8),
        make("Cơm trưa văn phòng", 45_000, .food, cash, daysAgo: 0, hour: 12),
        make("Grab về nhà", 72_000, .transport, momo, daysAgo: 1, hour: 19),
        make("Đi chợ WinMart", 685_000, .food, vietcombank, daysAgo: 1, hour: 18),
        make("Netflix", 260_000, .entertainment, creditCard, daysAgo: 2, hour: 21),
        make("Bún chả", 50_000, .food, cash, daysAgo: 2, hour: 12),
        make("Đổ xăng", 120_000, .transport, cash, daysAgo: 3, hour: 7),
        make("Lãi tiết kiệm", 850_000, .investment, savings, daysAgo: 3, hour: 9),
        make("Áo khoác Uniqlo", 980_000, .shopping, creditCard, daysAgo: 4, hour: 20),
        make("Tiền điện", 742_000, .bills, vietcombank, daysAgo: 5, hour: 10),
        make("Trà sữa", 45_000, .food, momo, daysAgo: 5, hour: 15),
        make("Xem phim CGV", 240_000, .entertainment, momo, daysAgo: 6, hour: 20),
        make("Khám răng", 450_000, .health, techcombank, daysAgo: 7, hour: 9),
        make("Ăn tối cùng bạn", 520_000, .food, techcombank, daysAgo: 8, hour: 19),
        make("Tiền Internet", 220_000, .bills, vietcombank, daysAgo: 9, hour: 9),
        make("Khóa học tiếng Anh", 1_500_000, .education, techcombank, daysAgo: 10, hour: 10),
        make("Dự án freelance", 4_500_000, .otherIncome, techcombank, daysAgo: 11, hour: 16),
        make("Grab đi làm", 65_000, .transport, momo, daysAgo: 12, hour: 8),
        make("Mua sách", 210_000, .education, momo, daysAgo: 13, hour: 17),
        make("Tiền nước", 95_000, .bills, vietcombank, daysAgo: 14, hour: 9),
        make("Đi chợ cuối tuần", 430_000, .food, cash, daysAgo: 15, hour: 9),
        make("Thuốc cảm", 85_000, .health, cash, daysAgo: 16, hour: 20),
        make("Thưởng dự án", 3_000_000, .bonus, vietcombank, daysAgo: 18, hour: 10),
        make("Lương tháng", 25_000_000, .salary, vietcombank, daysAgo: 20, hour: 9),
        make("Tiền nhà", 6_000_000, .bills, vietcombank, daysAgo: 21, hour: 8),
        make("Giày thể thao", 1_250_000, .shopping, creditCard, daysAgo: 22, hour: 19),
    ]

    private static func make(
        _ title: String,
        _ amount: Double,
        _ category: TransactionCategory,
        _ account: Account,
        daysAgo: Int,
        hour: Int
    ) -> FinanceTransaction {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let date = calendar.date(bySettingHour: hour, minute: 15, second: 0, of: day) ?? day
        return FinanceTransaction(title: title, amount: amount, category: category, accountID: account.id, date: date)
    }
}
