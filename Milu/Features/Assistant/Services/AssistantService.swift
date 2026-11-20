import Foundation

/// Where Milu's answers come from. The chat asks this and nothing else, so a real AI (an API)
/// takes the mock's place here without the chat changing (user request 2026-11-11: the API
/// first, the effects after).
///
/// To plug an API in: write a type that conforms (send `history` and `question`, turn the reply
/// into an `AssistantReply`), and return it from `AssistantServices.make(store:)`.
protocol AssistantService {
    /// Milu's answer to `question`. `history` is the chat so far, oldest first, without it.
    /// `onStep` hears of each thing Milu does on the phone on the way (a tool it runs), for the
    /// chat to show as it thinks.
    func reply(to question: String, history: [ChatMessage],
               onStep: @escaping (ThinkingStep) -> Void) async throws -> AssistantReply
}

/// One thing Milu does on the phone while it thinks: a tool the model asked for, said as the
/// chat shows it (user design 2026-11-15, Figma "12 · Milu · Trợ lý AI": real steps, not three
/// dots).
struct ThinkingStep: Identifiable, Equatable {
    let id = UUID()
    /// While it runs: "Đang xem chi tiêu tháng 11…".
    let running: String
    /// Once done: "Đã xem chi tiêu tháng 11", also kept with the answer (`ChatMessage.Thought`).
    let done: String
    /// The tool it is, for the live test of Milu AI (`AILiveTests`) to tell what the model did.
    var tool: String?

    private init(_ verb: String, _ what: String) {
        running = "Đang \(verb) \(what)…"
        done = "Đã \(verb) \(what)"
    }

    /// The step for a tool the model asked for, with the time or the words it asked about.
    static func tool(_ name: String, arguments: JSONValue) -> ThinkingStep {
        let period = Self.period(arguments).map { " " + $0 } ?? ""
        switch name {
        case SummarizeTransactions().name:
            return ThinkingStep("xem", (arguments["kind"]?.string == "income" ? "thu nhập" : "chi tiêu") + period)
        case ListTransactions().name:
            let search = arguments["search"]?.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return ThinkingStep("tìm", (search.isEmpty ? "giao dịch" : "“\(search)”") + period)
        case GetAccounts().name: return ThinkingStep("xem", "số dư các tài khoản")
        case GetLoans().name: return ThinkingStep("xem", "các khoản vay")
        case GetBudget().name:
            let month = arguments["month"]?.string.flatMap(ToolDates.month).map { " " + ToolDates.monthName($0) } ?? ""
            return ThinkingStep("xem", "hạn mức chi tiêu" + month)
        case GetSavingsGoals().name: return ThinkingStep("xem", "các hũ tiết kiệm")
        case GetRecurring().name: return ThinkingStep("xem", "giao dịch định kỳ")
        case GetUpcoming().name: return ThinkingStep("xem", "các khoản sắp đến hạn")
        case GetMonthlyTrend().name:
            // Kept in range as the tool keeps it: `Int()` of a huge number stopped the app here,
            // before the tool ran (audit round 4, 2026-11-16).
            let months = ToolArgs.int(arguments["months"], default: 6, in: 2...24)
            return ThinkingStep("so sánh", "\(months) tháng gần đây")
        case ListTransfers().name: return ThinkingStep("tìm", "các lần chuyển tiền" + period)
        // Nothing is recorded here: a card is made for "Lưu" (2026-11-17).
        case RecordTransaction().name: return ThinkingStep("kiểm tra", "khoản cần ghi")
        case DeleteTransaction().name: return ThinkingStep("tìm", "khoản cần xoá")
        // Nothing is added here either: a card is made for "Lưu" (2026-11-20).
        case AddAccount().name: return ThinkingStep("kiểm tra", "tài khoản cần thêm")
        case GetAppInfo().name:
            let what = switch arguments["topic"]?.string.flatMap({ GetAppInfo.Topic(rawValue: $0.lowercased()) }) {
            case .aiQuota: "lượt AI của bạn"
            case .pro: "gói Milu Pro"
            case .privacy: "chính sách quyền riêng tư"
            case .data: "dữ liệu và iCloud"
            case .security: "cài đặt bảo mật"
            case .terms: "điều khoản sử dụng"
            case .features: "các tính năng của Milu"
            case .support, nil: "thông tin về Milu"
            }
            return ThinkingStep("xem", what)
        default: return ThinkingStep("xem", "dữ liệu")
        }
    }

    /// "hôm nay", "tháng 11", "năm 2026", "3/11 – 9/11": the days a tool was asked about.
    private static func period(_ arguments: JSONValue) -> String? {
        guard let from = arguments["from"]?.string.flatMap(ToolDates.day),
              let to = arguments["to"]?.string.flatMap(ToolDates.day) else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        func day(_ date: Date) -> String {
            let parts = calendar.dateComponents([.day, .month, .year], from: date)
            let year = calendar.component(.year, from: today)
            return "\(parts.day ?? 1)/\(parts.month ?? 1)" + (parts.year == year ? "" : "/\(parts.year ?? year)")
        }
        if calendar.isDate(from, inSameDayAs: to) {
            if calendar.isDateInToday(from) { return "hôm nay" }
            if calendar.isDateInYesterday(from) { return "hôm qua" }
            return "ngày " + day(from)
        }
        let month = calendar.dateInterval(of: .month, for: from)
        let lastOfMonth = month.flatMap { calendar.date(byAdding: .day, value: -1, to: $0.end) }
        // A whole month, or this month so far.
        if let month, calendar.isDate(from, inSameDayAs: month.start),
           let lastOfMonth, calendar.isDate(to, inSameDayAs: lastOfMonth) || calendar.isDate(to, inSameDayAs: today) {
            let parts = calendar.dateComponents([.month, .year], from: from)
            let sameYear = parts.year == calendar.component(.year, from: today)
            return "tháng \(parts.month ?? 1)" + (sameYear ? "" : "/\(parts.year ?? 0)")
        }
        if let year = calendar.dateInterval(of: .year, for: from), calendar.isDate(from, inSameDayAs: year.start),
           let last = calendar.date(byAdding: .day, value: -1, to: year.end),
           calendar.isDate(to, inSameDayAs: last) || calendar.isDate(to, inSameDayAs: today) {
            return "năm \(calendar.component(.year, from: from))"
        }
        return day(from) + " – " + day(to)
    }
}

/// The steps of the answer on its way, which the chat's "Đang nghĩ…" lists as they come.
@Observable
final class AssistantProgress {
    var steps: [ThinkingStep] = []
}

enum AssistantServices {
    /// The service the chat uses: the local LLM on the app's server when `MiluAPI.plist` says
    /// where it is (user choice 2026-11-12), the keyword assistant on the phone otherwise.
    @MainActor
    static func make(store: FinanceStore, app: AppFacts = AppFacts()) -> any AssistantService {
        if let api = MiluAPI.shared { return RemoteAssistant(api: api, store: store, app: app) }
        return MockAssistant(store: store)
    }
}

/// What can go wrong asking for an answer, in words for the chat.
enum AssistantServiceError: LocalizedError {
    case noConnection
    /// The connection dropped mid-way (Milu went to the background while it waited).
    case interrupted
    /// The phone is online, the server is not.
    case unavailable
    case server(String)

    var errorDescription: String? {
        switch self {
        case .noConnection: "Không có kết nối internet 📵 Bạn bật Wi-Fi hoặc 4G rồi hỏi lại Milu nha."
        case .interrupted: "Kết nối bị ngắt giữa chừng, bạn hỏi lại Milu nhé."
        case .unavailable: "Milu đang tạm nghỉ một chút, bạn thử lại sau ít phút nhé."
        case .server(let detail): "Milu chưa trả lời được (\(detail)). Bạn thử lại sau nhé."
        }
    }
}
