import Foundation
import Testing
@testable import Milu

/// The tools the assistant's model is offered (`AssistantTools`), and what the server's
/// evaluation (milu-server/eval) reads of them.
@MainActor
struct AssistantToolsTests {
    @Test func toolNamesAreUniqueAndSnakeCase() {
        let names = AssistantTools.all.map(\.name)
        #expect(Set(names).count == names.count)
        #expect(names.allSatisfy { $0.wholeMatch(of: /[a-z]+(_[a-z]+)*/) != nil })
    }

    @Test func everyToolHasAnObjectSchema() {
        for tool in AssistantTools.all {
            #expect(tool.parameters["type"] == "object", "\(tool.name)")
        }
    }

    // MARK: get_app_info

    /// Every topic answers from the app's own pages: none of the entries it quotes went missing
    /// (renamed in `LegalDocument`), and each fits what the server passes on (8000 characters).
    @Test func everyAppTopicAnswersAndFits() {
        let store = FinanceStore()
        for topic in GetAppInfo.Topic.allCases {
            let output = GetAppInfo().run(["topic": .string(topic.rawValue)], in: store)
            let text = output.result.jsonString
            #expect(output.result["topic"]?.string == topic.rawValue)
            #expect(text.count > 120, "\(topic.rawValue)")
            #expect(text.count < 7_000, "\(topic.rawValue): \(text.count)")
            #expect(output.action == nil)
        }
        #expect(GetAppInfo.lines(LegalDocument.terms, "Lượt AI", "Milu Pro").count == 2)
        #expect(GetAppInfo.lines(LegalDocument.privacy, "Dữ liệu bạn ghi trong Milu", "Quyền của bạn",
                                 "Quyền truy cập trên iPhone").count == 3)
    }

    @Test func appQuotaSaysWhatIsLeft() {
        var facts = AppFacts()
        facts.weeklyLeft = 7
        facts.bonus = 5
        facts.bonusExpires = ToolDates.day("2026-11-19")
        facts.renewsOn = ToolDates.day("2026-11-16") ?? .now
        let now = GetAppInfo(facts: facts).run(["topic": "ai_quota"], in: FinanceStore()).result["now"]
        #expect(now?["weeklyLeft"] == 7)
        #expect(now?["bonusLeft"] == 5)
        #expect(now?["totalLeft"] == 12)
        #expect(now?["weekRenews"]?.string == "0 giờ thứ Hai 16/11")
        #expect(now?["bonusExpires"]?.string == "thứ Năm 19/11 lúc 0:00")
        let say = GetAppInfo(facts: facts).run(["topic": "ai_quota"], in: FinanceStore()).result["say"]?.string
        #expect(say == "Bạn còn 12 lượt hỏi: 7 lượt của tuần (làm mới lúc 0 giờ thứ Hai 16/11) và 5 lượt thưởng (hết hạn thứ Năm 19/11 lúc 0:00).")
        var none = facts
        none.weeklyLeft = 0
        none.bonus = 0
        let empty = GetAppInfo(facts: none).run(["topic": "ai_quota"], in: FinanceStore()).result["say"]?.string
        #expect(empty?.hasPrefix("Bạn đã hết lượt hỏi tuần này; lượt mới có lúc 0 giờ thứ Hai 16/11.") == true)
        facts.unlimited = true
        let debug = GetAppInfo(facts: facts).run(["topic": "ai_quota"], in: FinanceStore()).result["now"]
        #expect(debug?["unlimited"] == true)
    }

    @Test func proPricesOnlyWhenKnown() {
        var facts = AppFacts()
        let notOnSale = GetAppInfo(facts: facts).run(["topic": "pro"], in: FinanceStore()).result
        #expect(notOnSale["prices"] == nil)
        #expect(notOnSale["sale"] != nil)
        facts.monthlyPrice = "49.000đ"
        facts.yearlyPrice = "399.000đ"
        let onSale = GetAppInfo(facts: facts).run(["topic": "pro"], in: FinanceStore()).result
        #expect(onSale["prices"]?["yearly"]?.string == "399.000đ")
        #expect(onSale["sale"] == nil)
    }

    @Test func unknownAppTopicListsTheTopics() {
        let result = GetAppInfo().run(["topic": "weather"], in: FinanceStore()).result
        #expect(result["topics"] != nil)
    }

    /// Asking about the app takes no lượt, as recording and deleting; with anything else it does.
    @Test func appQuestionsAreFree() {
        #expect(!RemoteAssistant.counts([GetAppInfo().name]))
        #expect(!RemoteAssistant.counts([GetAppInfo().name, RecordTransaction().name]))
        #expect(RemoteAssistant.counts([GetAppInfo().name, SummarizeTransactions().name]))
        #expect(RemoteAssistant.counts([]))
    }

    /// With no lượt left (the question took none), asking about the app is still answered, and a
    /// question about spending is told when the lượt come back.
    @Test func appQuestionsAnsweredWithNoneLeft() {
        let aboutApp = RemoteAssistant.counts([GetAppInfo().name])
        let aboutMoney = RemoteAssistant.counts([SummarizeTransactions().name])
        #expect(AnswerCharge(paid: false, counts: aboutApp) == .free)
        #expect(AnswerCharge(paid: false, counts: aboutMoney) == .outOfQuestions)
        #expect(AnswerCharge(paid: true, counts: aboutApp) == .free)
        #expect(AnswerCharge(paid: true, counts: aboutMoney) == .paid)
        // And what it is told: none left, when they come back, what still works.
        var facts = AppFacts()
        facts.weeklyLeft = 0
        facts.renewsOn = ToolDates.day("2026-11-16") ?? .now
        let say = GetAppInfo(facts: facts).run(["topic": "ai_quota"], in: FinanceStore()).result["say"]?.string
        #expect(say?.contains("hỏi về app vẫn dùng được") == true)
    }

    @Test func appStepSaysTheTopic() {
        #expect(ThinkingStep.tool("get_app_info", arguments: ["topic": "privacy"]).done
                == "Đã xem chính sách quyền riêng tư")
        #expect(ThinkingStep.tool("get_app_info", arguments: ["topic": "ai_quota"]).running
                == "Đang xem lượt AI của bạn…")
    }

    /// With TEST_RUNNER_MILU_EXPORT=<path> set for `xcodebuild test`, writes the tools and the
    /// context the app sends (sample data, on 2026-11-12) for the server's evaluation.
    @Test func exportsWhatTheServerSees() throws {
        let store = FinanceStore()
        let day = ToolDates.day("2026-11-12") ?? .now
        let context = RemoteAssistant.context(for: store, on: day)
        #expect(!context.expenseCategories.isEmpty)
        guard let path = ProcessInfo.processInfo.environment["MILU_EXPORT"] else { return }
        struct Export: Encodable {
            var tools: [MiluAPI.ToolSpec]
            var context: MiluAPI.Context
            /// What get_app_info answers, each topic, for the answers' cases: the free plan with
            /// 3 of the week's lượt and 5 bonus left, Pro not on sale yet, iCloud on.
            var appInfo: [String: JSONValue]
        }
        var facts = AppFacts()
        facts.weeklyLeft = 3
        facts.bonus = 5
        facts.bonusExpires = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0,
                                                   of: ToolDates.day("2026-11-19") ?? .now)
        facts.renewsOn = ToolDates.day("2026-11-16") ?? .now
        facts.iCloud = .available
        facts.version = "1.0 (12)"
        let appInfo = Dictionary(uniqueKeysWithValues: GetAppInfo.Topic.allCases.map { topic in
            (topic.rawValue, GetAppInfo(facts: facts).run(["topic": .string(topic.rawValue)], in: store).result)
        })
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(Export(tools: AssistantTools.specs, context: context, appInfo: appInfo))
            .write(to: URL(fileURLWithPath: path))
    }
}
