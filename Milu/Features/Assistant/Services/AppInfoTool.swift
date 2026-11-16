import Foundation

/// What Trợ lý AI may say of the app itself, read when the question is asked (user request
/// 2026-11-15: "hỏi các thông tin về app: chính sách quyền riêng tư, lượt AI…"): the user's lượt
/// as they were before it (a question about the app takes none, so that is what is left after),
/// the plan, the lock, iCloud. The rules come from the pages the app already shows
/// (`LegalDocument`, `FAQView`), so Milu never says other than they do.
struct AppFacts {
    /// A Debug build: no lượt counted (`AIQuota.unlimitedInDebug`).
    var unlimited = false
    var isPro = false
    var weeklyAllowance = AIQuota.weeklyFree
    var weeklyLeft = AIQuota.weeklyFree
    var bonus = 0
    var bonusExpires: Date?
    var renewsOn = Date.now
    /// "Gói năm", "Gói tháng", when one is owned.
    var proPlan: String?
    var proEnds: Date?
    var proRenews = true
    /// From the App Store; nil until the plans load, or while Pro is not on sale.
    var monthlyPrice: String?
    var yearlyPrice: String?
    var lockOn = false
    var lockDelay: String?
    var biometry = "Face ID"
    var iCloud: CloudSyncMonitor.AccountState?
    var version = "1.0"

    /// Now, from what the app holds.
    @MainActor
    static func current(quota: AIQuota, sync: CloudSyncMonitor?) -> AppFacts {
        let pro = ProStore.shared
        let defaults = UserDefaults.standard
        let isPro = pro.isPro || MiluPlan.isPro
        let info = Bundle.main.infoDictionary
        return AppFacts(
            unlimited: quota.isUnlimited,
            isPro: isPro,
            weeklyAllowance: quota.weeklyAllowance,
            weeklyLeft: quota.weeklyLeft,
            bonus: quota.bonus,
            bonusExpires: quota.bonusExpires,
            renewsOn: quota.renewsOn,
            proPlan: pro.ownedPlan?.title,
            proEnds: pro.expiresAt,
            proRenews: pro.renews,
            monthlyPrice: pro.price(.monthly),
            yearlyPrice: pro.price(.yearly),
            // The switch alone: it locks whatever the plan (`AppLock.isOn`).
            lockOn: defaults.bool(forKey: StorageKey.appLock),
            lockDelay: AppLock.Delay(rawValue: defaults.integer(forKey: StorageKey.appLockDelay))?.title,
            biometry: AppLock.biometryName,
            iCloud: sync?.account,
            version: "\(info?["CFBundleShortVersionString"] as? String ?? "1.0") (\(info?["CFBundleVersion"] as? String ?? "1"))"
        )
    }
}

/// Questions about Milu itself: lượt AI, Milu Pro, privacy, data and iCloud, the lock, the
/// terms, where things are, support. Answered from `AppFacts` and the app's own pages, and,
/// like recording, it takes no lượt (`RemoteAssistant.counts`): someone out of lượt can still
/// ask when they come back.
struct GetAppInfo: AssistantTool {
    var facts = AppFacts()

    enum Topic: String, CaseIterable {
        case aiQuota = "ai_quota"
        case pro
        case privacy
        case data
        case security
        case terms
        case features
        case support
    }

    let name = "get_app_info"
    let description = """
        Thông tin về chính app Milu. BẮT BUỘC gọi cho mọi câu hỏi về app, không tự trả lời theo trí nhớ: \
        lượt hỏi AI (còn bao nhiêu, khi nào có lại, cách tính, hỏi Milu có tốn phí không), Milu Pro (giá, quyền lợi, mua, huỷ), \
        quyền riêng tư (dữ liệu gửi đi đâu, AI có lưu hay đọc dữ liệu không), dữ liệu và iCloud (lưu ở đâu, \
        sao lưu, đổi máy, xoá dữ liệu), khoá Face ID, điều khoản sử dụng, tính năng nằm ở đâu, liên hệ hỗ trợ, phiên bản.
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "topic": [
                "type": "string",
                "enum": .array(Topic.allCases.map { .string($0.rawValue) }),
                "description": """
                    ai_quota: lượt hỏi AI, hỏi Milu có mất phí không; pro: gói Milu Pro; privacy: chính sách quyền riêng tư, dữ liệu gửi lên máy chủ, AI; \
                    data: dữ liệu lưu ở đâu, iCloud, sao lưu, đổi máy, xoá dữ liệu; security: khoá Face ID, quyền micro; \
                    terms: điều khoản sử dụng; features: tính năng và chỗ tìm trong app; support: liên hệ, góp ý, phiên bản
                    """,
            ],
        ],
        "required": ["topic"],
    ]

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        let topic = arguments["topic"]?.string.flatMap { Topic(rawValue: $0.lowercased()) }
        guard let topic else {
            return ToolOutput(result: [
                "topics": .array(Topic.allCases.map { .string($0.rawValue) }),
                "note": "Gọi lại với một topic trong danh sách",
            ])
        }
        var result = content(topic)
        result["topic"] = .string(topic.rawValue)
        return ToolOutput(result: .object(result))
    }

    // MARK: - Topics

    private func content(_ topic: Topic) -> [String: JSONValue] {
        switch topic {
        case .aiQuota:
            return [
                "say": .string(quotaSummary),
                "now": quotaNow,
                "rules": .array(Self.lines(LegalDocument.terms, "Lượt AI")
                    + [.string("Milu Pro có \(AIQuota.weeklyPro) lượt mỗi tuần thay cho \(AIQuota.weeklyFree)."),
                       "Hỏi Milu về chính app (lượt AI, Milu Pro, quyền riêng tư…) cũng không tốn lượt."]),
                "where": "Cài đặt → Hạn mức AI. Mở Cài đặt bằng ảnh đại diện ở góc trên bên trái.",
            ]
        case .pro:
            var result: [String: JSONValue] = [
                "now": proNow,
                "benefits": [
                    .string("Trợ lý AI \(AIQuota.weeklyPro) lượt mỗi tuần (gói miễn phí \(AIQuota.weeklyFree))"),
                    .string("Khoá Milu bằng \(facts.biometry)"),
                    "Xuất báo cáo PDF và Excel (sắp có)",
                ],
                "where": "Cài đặt → Nâng cấp Milu Pro (dưới Hạn mức AI). Trên trang đó có Khôi phục và Mã ưu đãi.",
                "cancel": "Huỷ bất cứ lúc nào trong Cài đặt của iPhone → Apple ID → Đăng ký; gói tự gia hạn đến khi huỷ.",
            ]
            if let monthly = facts.monthlyPrice, let yearly = facts.yearlyPrice {
                result["prices"] = ["monthly": .string(monthly), "yearly": .string(yearly)]
            } else {
                result["sale"] = .array(Self.lines(LegalDocument.terms, "Milu Pro"))
            }
            return result
        case .privacy:
            return [
                "policy": .array(LegalDocument.privacy.entries.map(Self.line)),
                "updated": .string(LegalDocument.privacy.updated),
                "where": "Cài đặt → Về Milu → Chính sách quyền riêng tư",
            ]
        case .data:
            return [
                "iCloudNow": .string(iCloudNow),
                "facts": .array(Self.lines(LegalDocument.privacy, "Dữ liệu bạn ghi trong Milu", "Quyền của bạn")),
                "eraseAll": .string("""
                    Xoá hết trong app: Cài đặt → kéo xuống cuối → "Xoá toàn bộ dữ liệu" (hỏi lại hai lần). Xoá cả \
                    trong iCloud và trên các thiết bị khác dùng chung Apple ID, không lấy lại được.
                    """),
                "where": "Trạng thái đồng bộ: Cài đặt → Sao lưu & đồng bộ → Đồng bộ iCloud.",
            ]
        case .security:
            return [
                "lockNow": .string(lockNow),
                "lock": .string("""
                    Khoá bằng \(facts.biometry) là tính năng Milu Pro: Milu mở sau khi \(facts.biometry) \
                    hoặc mật mã iPhone xác nhận, mỗi lần mở app và khi quay lại sau thời gian chọn ở "Khoá lại" \
                    (ngay lập tức, sau 1 phút, sau 5 phút). Khi app không ở trước, nội dung được che nên màn chuyển \
                    app không lộ số dư. Bật ở Cài đặt → Bảo mật.
                    """),
                "permissions": .array(Self.lines(LegalDocument.privacy, "Quyền truy cập trên iPhone")),
            ]
        case .terms:
            return [
                "terms": .array(LegalDocument.terms.entries.map(Self.line)),
                "updated": .string(LegalDocument.terms.updated),
                "where": "Cài đặt → Về Milu → Điều khoản sử dụng",
            ]
        case .features:
            return [
                "tabs": [
                    "Tổng quan: số dư, tài sản ròng, thu chi trong tháng, hạn mức, lịch thu chi, báo cáo",
                    // No credit card kind to pick: one is a bank account with a balance below
                    // zero (audit round 3, 2026-11-16: Milu sent users to add a card).
                    "Tài khoản: tiền mặt, ngân hàng, ví điện tử, hũ tiết kiệm (thẻ tín dụng thì thêm như tài khoản ngân hàng, số dư âm)",
                    "Giao dịch: các khoản thu chi và khoản vay",
                    "Nút + ở thanh dưới: thêm giao dịch (hoặc khoản vay)",
                    "✨ Hỏi Milu ở góc trên bên phải: trợ lý AI, gõ hoặc chạm micro để nói",
                    "Ảnh đại diện ở góc trên bên trái: Cài đặt",
                ],
                "settings": [
                    "Hạn mức AI, Nâng cấp Milu Pro",
                    "Quản lý tài chính: Hạn mức chi tiêu, Hạng mục, Giao dịch định kỳ, Danh bạ, Báo cáo",
                    "Sao lưu & đồng bộ: Đồng bộ iCloud",
                    .string("Bảo mật: Khoá bằng \(facts.biometry) (Pro)"),
                    "Giao diện: Hệ thống, Sáng, Tối",
                    "Thông báo: Nhắc ghi chi tiêu, Cảnh báo hạn mức, Nhắc khoản định kỳ",
                    "Hỗ trợ: Câu hỏi thường gặp, Góp ý và hỗ trợ",
                    "Về Milu: Chính sách quyền riêng tư, Điều khoản sử dụng, Giấy phép mã nguồn mở",
                ],
                "faq": .array(FAQView.entries.map(Self.line)),
            ]
        case .support:
            return [
                "email": .string(LegalDocument.supportEmail),
                "version": .string("Milu \(facts.version)"),
                "where": "Cài đặt → Hỗ trợ: Câu hỏi thường gặp, Góp ý và hỗ trợ (gửi thư). Phiên bản ở cuối Cài đặt.",
            ]
        }
    }

    /// What is left, in one sentence to say: the model gave the week's count alone, not the
    /// bonus beside it (eval 2026-11-15).
    private var quotaSummary: String {
        if facts.unlimited { return "Bản thử nghiệm này không giới hạn lượt hỏi." }
        let renews = "0 giờ \(Self.day(facts.renewsOn))"
        let bonus = facts.bonus > 0
            ? " và \(facts.bonus) lượt thưởng" + (facts.bonusExpires.map { " (hết hạn \(Self.dayAndTime($0)))" } ?? "")
            : ""
        if facts.weeklyLeft + facts.bonus == 0 {
            return "Bạn đã hết lượt hỏi tuần này; lượt mới có lúc \(renews). Ghi, xoá giao dịch và hỏi về app vẫn dùng được."
        }
        if facts.bonus == 0 {
            return "Bạn còn \(facts.weeklyLeft) lượt hỏi tuần này, làm mới lúc \(renews)."
        }
        return "Bạn còn \(facts.weeklyLeft + facts.bonus) lượt hỏi: \(facts.weeklyLeft) lượt của tuần (làm mới lúc \(renews))\(bonus)."
    }

    private var quotaNow: JSONValue {
        if facts.unlimited {
            return ["unlimited": true, "note": "Bản thử nghiệm của nhà phát triển: không giới hạn lượt"]
        }
        var now: [String: JSONValue] = [
            "plan": .string(facts.isPro ? "Milu Pro" : "Miễn phí"),
            "weeklyAllowance": .number(Double(facts.weeklyAllowance)),
            "weeklyLeft": .number(Double(facts.weeklyLeft)),
            "totalLeft": .number(Double(facts.weeklyLeft + facts.bonus)),
            "weekRenews": .string("0 giờ \(Self.day(facts.renewsOn))"),
        ]
        if facts.bonus > 0 {
            now["bonusLeft"] = .number(Double(facts.bonus))
            now["bonusExpires"] = facts.bonusExpires.map { .string(Self.dayAndTime($0)) } ?? .null
        }
        return .object(now)
    }

    private var proNow: JSONValue {
        guard facts.isPro else { return ["plan": "Miễn phí", "owned": false] }
        var now: [String: JSONValue] = ["plan": "Milu Pro", "owned": true]
        if let plan = facts.proPlan { now["kind"] = .string(plan) }
        if let ends = facts.proEnds {
            now[facts.proRenews ? "renews" : "endsCancelled"] = .string(Self.day(ends))
        }
        return .object(now)
    }

    private var iCloudNow: String {
        switch facts.iCloud {
        case .available: "iCloud đang bật: dữ liệu được đồng bộ vào iCloud của bạn"
        case .signedOut: "iCloud đang tắt cho Milu (hoặc iPhone chưa đăng nhập iCloud): dữ liệu chỉ ở trên máy này"
        case .restricted, .unavailable: "iCloud trên iPhone này chưa dùng được: dữ liệu chỉ ở trên máy này"
        case .checking, nil: "Đang kiểm tra iCloud"
        }
    }

    private var lockNow: String {
        guard facts.isPro else { return "Đang tắt (cần Milu Pro)" }
        guard facts.lockOn else { return "Đang tắt" }
        return "Đang bật" + (facts.lockDelay.map { ", khoá lại: \($0.lowercased())" } ?? "")
    }

    // MARK: - Words

    /// An entry of a page as one line: its title, then its paragraphs.
    private static func line(_ entry: ReadingEntry) -> JSONValue {
        .string("\(entry.title): " + entry.paragraphs.joined(separator: " "))
    }

    /// The entries of `document` with these titles, as lines.
    static func lines(_ document: LegalDocument, _ titles: String...) -> [JSONValue] {
        titles.compactMap { title in document.entries.first { $0.title == title }.map(line) }
    }

    private static let weekdays = ["Chủ nhật", "thứ Hai", "thứ Ba", "thứ Tư", "thứ Năm", "thứ Sáu", "thứ Bảy"]

    /// "thứ Hai 16/11".
    static func day(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.weekday, .day, .month], from: date)
        return "\(weekdays[(parts.weekday ?? 1) - 1]) \(parts.day ?? 1)/\(parts.month ?? 1)"
    }

    /// "thứ Năm 19/11 lúc 14:30".
    static func dayAndTime(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return day(date) + String(format: " lúc %d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }
}
