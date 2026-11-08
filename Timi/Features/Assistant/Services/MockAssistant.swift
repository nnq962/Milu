//
//  MockAssistant.swift
//  Timi
//

import Foundation

/// What the assistant answers: text plus an optional action card the chat renders.
struct AssistantReply {
    enum Action {
        /// A transaction the assistant just recorded (card offers Sửa / Xoá).
        case recorded(FinanceTransaction)
        /// A transaction the user asked to delete; nothing changes until they confirm.
        case confirmDelete(FinanceTransaction)
    }

    var text: String
    var action: Action? = nil
}

/// Trợ lý AI "giả lập": nhận diện vài câu hỏi và lệnh phổ biến bằng từ khoá rồi trả lời
/// từ dữ liệu thật trong `FinanceStore`. Sau này có thể thay bằng một mô hình AI
/// thật mà không phải sửa giao diện chat.
struct MockAssistant {
    let store: FinanceStore

    static func welcome(name: String) -> String {
        "Chào \(name)! Mình là Milu. Bạn có thể hỏi mình về tài chính hoặc nhờ mình ghi, sửa, xoá giao dịch."
    }

    static let suggestions = ["Tháng này tôi tiêu gì nhiều nhất?", "Ghi một khoản chi", "Ai đang nợ tôi?"]

    func reply(to question: String) -> AssistantReply {
        let text = Self.normalize(question)
        if Self.hasWord(text, ["xoa", "huy"]) { return deleteCommand(question) }
        if Self.hasWord(text, ["ghi", "them"]) { return recordCommand(question) }
        if text.contains("no toi") || text.contains("cho vay") || text.contains("vay no") { return .init(text: loansSummary()) }
        if text.contains("lon nhat") { return .init(text: biggestExpense()) }
        if text.contains("tiet kiem") { return .init(text: savingTips()) }
        if text.contains("so du") || text.contains("tai khoan") || text.contains("tai san") { return .init(text: balanceSummary()) }
        if text.contains("thu nhap") || text.contains("luong") { return .init(text: incomeSummary()) }
        if text.contains("chi") || text.contains("tieu") { return .init(text: spendingSummary()) }
        if text.contains("chao") || text.contains("hello") { return .init(text: "Chào bạn! Hôm nay bạn muốn xem gì về tài chính nào?") }
        return .init(text: fallback)
    }

    // MARK: - Ghi giao dịch

    private func recordCommand(_ question: String) -> AssistantReply {
        guard let amount = Self.amount(in: question) else {
            return .init(text: "Bạn cho mình biết tên khoản và số tiền nhé, ví dụ: **ghi ăn trưa 60.000 hôm nay** hoặc **ghi nhận lương 25tr**.")
        }
        guard let account = store.paymentAccounts.first ?? store.accounts.first else {
            return .init(text: "Bạn chưa có tài khoản nào. Hãy thêm một tài khoản ở tab Tài khoản trước nhé.")
        }
        let category = Self.category(for: Self.normalize(question))
        let title = Self.title(from: question, fallback: category.title)
        let date = Self.date(in: Self.normalize(question)) ?? .now
        // What was said ("Ăn trưa") goes in the note when it says more than the category.
        let transaction = FinanceTransaction(amount: amount, category: category,
                                             accountID: account.id, date: Self.keepingTime(of: .now, on: date),
                                             note: title == category.title ? "" : title)
        store.add(transaction)
        let kind = category.kind == .income ? "khoản thu" : "khoản chi"
        return .init(text: "Mình đã ghi \(kind) này vào \(account.name):", action: .recorded(transaction))
    }

    // MARK: - Xoá giao dịch

    private func deleteCommand(_ question: String) -> AssistantReply {
        let text = Self.normalize(question)
        let day = Self.date(in: text)
        let keywords = Self.keywords(from: text)
        let candidates = store.transactions.filter { transaction in
            if let day, !Calendar.current.isDate(transaction.date, inSameDayAs: day) { return false }
            guard !keywords.isEmpty else { return true }
            let haystack = Self.normalize("\(transaction.note) \(store.categoryName(transaction.categoryID))")
            return keywords.allSatisfy { haystack.contains($0) }
        }
        guard let match = candidates.first, keywords.isEmpty == false || day != nil else {
            return .init(text: "Mình chưa tìm thấy khoản nào khớp. Bạn thử nói rõ tên và ngày, ví dụ: **xoá khoản tiền điện hôm qua**.")
        }
        let note = candidates.count > 1 ? " (có \(candidates.count) khoản khớp, mình chọn khoản gần nhất)" : ""
        return .init(text: "Bạn muốn xoá khoản này\(note)? Sau khi xoá, số dư sẽ được cập nhật lại.", action: .confirmDelete(match))
    }

    // MARK: - Hiểu câu lệnh

    private static func hasWord(_ text: String, _ words: [String]) -> Bool {
        let tokens = Set(text.split(whereSeparator: { !$0.isLetter }).map(String.init))
        return words.contains { tokens.contains($0) }
    }

    /// "60.000", "60k", "1,5tr", "2 triệu", "25tr" → số tiền VND.
    static func amount(in text: String) -> Double? {
        let pattern = #"(\d[\d.,]*)\s*(k|nghìn|ngàn|tr|triệu|củ|đ|đồng|vnd)?(?![\p{L}])"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        for match in regex.matches(in: text, range: range) {
            guard let numberRange = Range(match.range(at: 1), in: text) else { continue }
            let raw = String(text[numberRange])
            let unit = Range(match.range(at: 2), in: text).map { text[$0].lowercased() } ?? ""
            let multiplier: Double = switch unit {
            case "k", "nghìn", "ngàn": 1_000
            case "tr", "triệu", "củ": 1_000_000
            default: 1
            }
            // With a unit, "1,5" / "1.5" is a decimal; without one, dots and commas group thousands.
            let value: Double?
            if multiplier > 1 {
                value = Double(raw.replacingOccurrences(of: ",", with: "."))
            } else {
                value = Double(raw.filter(\.isNumber))
            }
            if let value, value * multiplier >= 1_000 { return (value * multiplier).rounded() }
        }
        return nil
    }

    static func date(in normalized: String) -> Date? {
        let calendar = Calendar.current
        if normalized.contains("hom kia") { return calendar.date(byAdding: .day, value: -2, to: .now) }
        if normalized.contains("hom qua") { return calendar.date(byAdding: .day, value: -1, to: .now) }
        if normalized.contains("hom nay") { return .now }
        return nil
    }

    private static func keepingTime(of time: Date, on day: Date) -> Date {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: parts.hour ?? 12, minute: parts.minute ?? 0, second: 0, of: day) ?? day
    }

    static func category(for normalized: String) -> TransactionCategory {
        let rules: [(TransactionCategory, [String])] = [
            (.salary, ["luong"]),
            (.bonus, ["thuong", "li xi"]),
            (.investment, ["lai", "co tuc", "dau tu"]),
            (.otherIncome, ["nhan tien", "duoc tra", "thu nhap", "ban "]),
            (.food, ["an", "uong", "com", "pho", "bun", "ca phe", "cafe", "tra sua", "trua", "toi", "sang", "nha hang", "di cho"]),
            (.transport, ["grab", "taxi", "xang", "xe", "gui xe", "be ", "tau", "may bay"]),
            (.bills, ["dien", "nuoc", "internet", "wifi", "tien nha", "hoa don", "cuoc"]),
            (.shopping, ["mua", "sieu thi", "quan ao", "giay", "shopee", "lazada"]),
            (.entertainment, ["phim", "netflix", "spotify", "game", "du lich"]),
            (.health, ["thuoc", "kham", "benh vien", "nha khoa"]),
            (.education, ["sach", "hoc", "khoa hoc"]),
        ]
        let padded = " \(normalized) "
        for (category, words) in rules where words.contains(where: { padded.contains(" \($0)") }) {
            return category
        }
        return normalized.contains("nhan") ? .otherIncome : .otherExpense
    }

    /// "Ghi giúp mình: ăn trưa 60.000 hôm nay" → "Ăn trưa"
    private static func title(from question: String, fallback: String) -> String {
        var text = question
        let fillers = ["ghi giúp mình", "ghi giúp tôi", "ghi giùm", "ghi lại", "ghi", "thêm giúp mình", "thêm",
                       "một khoản chi", "một khoản thu", "khoản chi", "khoản thu", "khoản",
                       "hôm nay", "hôm qua", "hôm kia", "giúp mình", "giúp tôi", "nhé", "nha"]
        for filler in fillers {
            text = text.replacingOccurrences(of: filler, with: " ", options: [.caseInsensitive, .diacriticInsensitive])
        }
        text = text.replacingOccurrences(of: #"\d[\d.,]*\s*(k|nghìn|ngàn|tr|triệu|củ|đ|đồng|vnd)?(?![\p{L}])"#,
                                         with: " ", options: [.regularExpression, .caseInsensitive])
        let cleaned = text.components(separatedBy: CharacterSet.letters.union(.whitespaces).inverted).joined(separator: " ")
            .split(separator: " ").joined(separator: " ")
        guard !cleaned.isEmpty else { return fallback }
        return cleaned.prefix(1).uppercased() + cleaned.dropFirst()
    }

    /// Words that identify a transaction in a delete request, without command and date words.
    private static func keywords(from normalized: String) -> [String] {
        // A Set literal with a repeated element traps at runtime, so keep each word once.
        let stop: Set<String> = ["xoa", "huy", "giup", "minh", "toi", "khoan", "giao", "dich", "cai", "nay", "do",
                                 "hom", "qua", "kia", "tien", "nhe", "nha", "voi", "the", "la"]
        let words = normalized.split(whereSeparator: { !$0.isLetter }).map(String.init).filter { !stop.contains($0) }
        return words
    }

    /// Bỏ dấu tiếng Việt để so khớp từ khoá: "Tiết kiệm" → "tiet kiem"
    static func normalize(_ text: String) -> String { text.searchKey }

    // MARK: - Các câu trả lời

    private func spendingSummary() -> String {
        let expense = store.total(.expense)
        let income = store.total(.income)
        guard expense > 0 else { return "Tháng này bạn chưa có khoản chi nào." }

        let topCategories = store.expensesByCategory().prefix(3)
            .map { "• \($0.name): \($0.amount.vnd) (\(($0.amount / expense).percentText))" }
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
        let expenses = store.reportableTransactions().filter { $0.kind == .expense }
        guard let biggest = expenses.max(by: { $0.amount < $1.amount }) else {
            return "Tháng này bạn chưa có khoản chi nào."
        }
        let day = biggest.date.dayMonth
        // "Đi chợ WinMart (Đi chợ, …)" when the note says what it was; just the category otherwise.
        let category = store.categoryName(biggest.categoryID)
        let what = biggest.note.isEmpty ? "**\(category)**"
            : "**\(biggest.note.components(separatedBy: .newlines)[0])** (\(category))"
        return "Khoản chi lớn nhất tháng này là \(what): **\(biggest.amount.vnd)**, ngày \(day)."
    }

    private func incomeSummary() -> String {
        let income = store.total(.income)
        guard income > 0 else { return "Tháng này bạn chưa ghi nhận khoản thu nào." }
        let lines = store.reportableTransactions()
            .filter { $0.kind == .income }
            .map { "• \($0.note.isEmpty ? store.categoryName($0.categoryID) : $0.note.components(separatedBy: .newlines)[0]): \($0.amount.vnd)" }
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
            tips.append("• **\(top.name)** đang là khoản chi lớn nhất (\(top.amount.vnd)). \(tip(for: TransactionCategory(rawValue: top.groupID)))")
        }
        let income = store.total(.income)
        if income > 0 {
            tips.append("• Theo quy tắc **50/30/20**, với thu nhập \(income.vnd) bạn nên để dành ít nhất **\((income * 0.2).vnd)** mỗi tháng.")
        }
        tips.append("• Chuyển tiền vào tài khoản tiết kiệm ngay khi nhận lương, trước khi bắt đầu chi tiêu.")
        return tips.joined(separator: "\n")
    }

    private func tip(for category: TransactionCategory?) -> String {
        switch category {
        case .food: "Thử nấu ăn ở nhà vài bữa mỗi tuần và hạn chế đồ uống mua ngoài."
        case .transport: "Gộp các chuyến đi hoặc dùng xe buýt, metro cho quãng đường quen thuộc."
        case .shopping: "Áp dụng quy tắc chờ 48 giờ trước khi mua món không thiết yếu."
        case .bills: "Rà lại các gói cước, dịch vụ đăng ký và tắt bớt thiết bị điện khi không dùng."
        case .entertainment: "Huỷ bớt các dịch vụ đăng ký ít dùng và đặt hạn mức giải trí mỗi tháng."
        default: "Hãy đặt ngân sách riêng cho danh mục này và theo dõi mỗi tuần."
        }
    }

    private func loansSummary() -> String {
        let lent = store.loans.filter { $0.direction == .lent && !$0.isSettled }
        guard !lent.isEmpty else { return "Hiện chưa có ai đang nợ bạn." }
        let lines = lent.map { loan in
            "• \(loan.name): còn \(loan.outstanding.vnd)" + (loan.dueDate.map { " · hạn \($0.dayMonth)" } ?? "")
        }.joined(separator: "\n")
        return "Có \(lent.count) người đang nợ bạn, tổng **\(store.totalLent.vnd)**:\n\(lines)"
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
        • Ai đang nợ bạn
        • Ghi hoặc xoá giao dịch, VD: "ghi ăn trưa 60.000 hôm nay"
        """
    }
}
