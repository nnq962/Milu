//
//  MockAssistant.swift
//  Timi
//

import Foundation

/// Trợ lý AI "giả lập": nhận diện vài câu hỏi phổ biến bằng từ khoá rồi trả lời
/// từ dữ liệu thật trong `FinanceStore`. Sau này có thể thay bằng một mô hình AI
/// thật mà không phải sửa giao diện chat.
struct MockAssistant {
    let store: FinanceStore

    static let welcome = """
        Xin chào! Mình là **Timi**, trợ lý tài chính của bạn.

        Bạn có thể hỏi mình về chi tiêu, thu nhập, số dư tài khoản hoặc nhờ gợi ý cách tiết kiệm.

        _Bản thử nghiệm: câu trả lời được tính từ dữ liệu mẫu trong app._
        """

    func reply(to question: String) -> String {
        let text = Self.normalize(question)
        if text.contains("lon nhat") { return biggestExpense() }
        if text.contains("tiet kiem") { return savingTips() }
        if text.contains("so du") || text.contains("tai khoan") || text.contains("tai san") { return balanceSummary() }
        if text.contains("thu nhap") || text.contains("luong") { return incomeSummary() }
        if text.contains("chi") || text.contains("tieu") { return spendingSummary() }
        if text.contains("chao") || text.contains("hello") { return "Chào bạn! Hôm nay bạn muốn xem gì về tài chính nào?" }
        return fallback
    }

    /// Bỏ dấu tiếng Việt để so khớp từ khoá: "Tiết kiệm" → "tiet kiem"
    static func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "đ", with: "d")
            .folding(options: .diacriticInsensitive, locale: .vietnam)
    }

    // MARK: - Các câu trả lời

    private func spendingSummary() -> String {
        let expense = store.total(.expense)
        let income = store.total(.income)
        guard expense > 0 else { return "Tháng này bạn chưa có khoản chi nào." }

        let topCategories = store.expensesByCategory().prefix(3)
            .map { "• \($0.category.title): \($0.amount.vnd) (\(($0.amount / expense).percentText))" }
            .joined(separator: "\n")

        var answer = "Tháng này bạn đã chi **\(expense.vnd)**.\n\nNhiều nhất là:\n\(topCategories)"
        if income > expense {
            answer += "\n\nBạn vẫn còn dư **\((income - expense).vnd)** so với thu nhập. Rất tốt!"
        } else if income > 0 {
            answer += "\n\nChi tiêu đang vượt thu nhập **\((expense - income).vnd)**. Bạn nên cân nhắc cắt giảm nhé."
        }
        return answer
    }

    private func biggestExpense() -> String {
        let expenses = store.monthlyTransactions().filter { $0.kind == .expense }
        guard let biggest = expenses.max(by: { $0.amount < $1.amount }) else {
            return "Tháng này bạn chưa có khoản chi nào."
        }
        let components = Calendar.current.dateComponents([.day, .month], from: biggest.date)
        let day = "\(components.day ?? 0)/\(components.month ?? 0)"
        return "Khoản chi lớn nhất tháng này là **\(biggest.title)**: **\(biggest.amount.vnd)** (\(biggest.category.title), ngày \(day))."
    }

    private func incomeSummary() -> String {
        let income = store.total(.income)
        guard income > 0 else { return "Tháng này bạn chưa ghi nhận khoản thu nào." }
        let lines = store.monthlyTransactions()
            .filter { $0.kind == .income }
            .map { "• \($0.title): \($0.amount.vnd)" }
            .joined(separator: "\n")
        return "Tháng này bạn đã nhận **\(income.vnd)**, gồm:\n\(lines)"
    }

    private func balanceSummary() -> String {
        let lines = store.accounts
            .sorted { $0.balance > $1.balance }
            .map { "• \($0.name): \($0.balance.vnd)" }
            .joined(separator: "\n")
        var answer = "Tổng tài sản ròng của bạn là **\(store.netWorth.vnd)**.\n\n\(lines)"
        if store.totalDebt > 0 {
            answer += "\n\nBạn đang có dư nợ **\(store.totalDebt.vnd)**, nhớ thanh toán đúng hạn để tránh bị tính lãi nhé."
        }
        return answer
    }

    private func savingTips() -> String {
        var tips = ["Một vài gợi ý cho bạn:"]
        if let top = store.expensesByCategory().first {
            tips.append("• **\(top.category.title)** đang là khoản chi lớn nhất (\(top.amount.vnd)). \(tip(for: top.category))")
        }
        let income = store.total(.income)
        if income > 0 {
            tips.append("• Theo quy tắc **50/30/20**, với thu nhập \(income.vnd) bạn nên để dành ít nhất **\((income * 0.2).vnd)** mỗi tháng.")
        }
        tips.append("• Chuyển tiền vào tài khoản tiết kiệm ngay khi nhận lương, trước khi bắt đầu chi tiêu.")
        return tips.joined(separator: "\n")
    }

    private func tip(for category: TransactionCategory) -> String {
        switch category {
        case .food: "Thử nấu ăn ở nhà vài bữa mỗi tuần và hạn chế đồ uống mua ngoài."
        case .transport: "Gộp các chuyến đi hoặc dùng xe buýt, metro cho quãng đường quen thuộc."
        case .shopping: "Áp dụng quy tắc chờ 48 giờ trước khi mua món không thiết yếu."
        case .bills: "Rà lại các gói cước, dịch vụ đăng ký và tắt bớt thiết bị điện khi không dùng."
        case .entertainment: "Huỷ bớt các dịch vụ đăng ký ít dùng và đặt hạn mức giải trí mỗi tháng."
        default: "Hãy đặt ngân sách riêng cho danh mục này và theo dõi mỗi tuần."
        }
    }

    private var fallback: String {
        """
        Mình chưa hiểu câu hỏi này lắm.

        Ở bản thử nghiệm, mình có thể trả lời về:
        • Chi tiêu tháng này
        • Khoản chi lớn nhất
        • Thu nhập
        • Số dư tài khoản
        • Gợi ý tiết kiệm
        """
    }
}
