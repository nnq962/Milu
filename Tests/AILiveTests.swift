import Foundation
import Testing
@testable import Milu

/// Milu AI tested as the chat uses it (user request 2026-11-18: "test con AI trên app của tôi để
/// cho nó chuyên nghiệp"). Each case of `docs/ai-tests/cases.json` is a new chat on the sample
/// data: what the user types goes to the live server through `RemoteAssistant`, the app's tools
/// run here, the words and cards are what the chat would show; "Lưu", "Huỷ" and the typed "ok"
/// work as the chat's do.
///
/// It talks to the server, so it runs only when asked:
///
///     TEST_RUNNER_MILU_LIVE=<report.json> [TEST_RUNNER_MILU_LIVE_ONLY=T,H01] xcodebuild test \
///         -only-testing:"MiluTests/AILiveTests"
///
/// `MILU_LIVE_ONLY` picks cases by id or group letter. The report is written after each case.
@MainActor
struct AILiveTests {
    @Test func milusAnswersAsTheChatShowsThem() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let out = environment["MILU_LIVE"] else { return }
        let api = try #require(MiluAPI.shared, "MiluAPI.plist is needed: the build has no server")
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let file = try JSONDecoder().decode(CaseFile.self,
                                            from: Data(contentsOf: source.appending(path: "docs/ai-tests/cases.json")))
        let only = environment["MILU_LIVE_ONLY"].map {
            Set($0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        }
        let cases = file.cases.filter { item in
            only.map { $0.contains(item.id) || $0.contains(String(item.id.prefix(1))) } ?? true
        }
        var results: [CaseResult] = []
        for item in cases {
            results.append(await run(item, api: api))
            try write(results, to: URL(fileURLWithPath: out))
        }
    }

    // MARK: A chat

    private func run(_ item: Case, api: MiluAPI) async -> CaseResult {
        let store = FinanceStore()
        // The sample data puts some of today's at 12:00 or 20:00, ahead of a morning run: "mấy khoản
        // vừa ghi" then found those first. Moved to the start of today, still today's.
        let today = Calendar.current.startOfDay(for: .now)
        store.transactions = store.transactions.map { transaction in
            var transaction = transaction
            if transaction.date > .now { transaction.date = today.addingTimeInterval(60) }
            // Made all at once, the sample's newest was recorded first: recorded as dated, so
            // "recent items" are the recent ones.
            transaction.createdAt = transaction.date
            return transaction
        }
        let assistant = RemoteAssistant(api: api, store: store)
        let start = store.transactions.count
        let accountsAtStart = store.accounts.count
        var messages: [ChatMessage] = []
        var turns: [TurnResult] = []
        for turn in item.turns {
            var result = TurnResult(say: turn.say, tap: turn.tap)
            var reply: AssistantReply?
            if let tap = turn.tap {
                result.text = press(tap, in: &messages, store: store)
            } else if let say = turn.say {
                if let said = typedShortcut(say, in: &messages, store: store) {
                    result.text = said
                    result.shortcut = true
                } else {
                    let tools = ToolsHeard()
                    let asked = Date.now
                    do {
                        let answer = try await assistant.reply(to: say, history: messages) { step in
                            if let tool = step.tool { tools.names.append(tool) }
                        }
                        reply = answer
                        result.text = answer.text
                        result.tools = tools.names
                        result.asks = answer.asksBack
                        result.refused = answer.refused.map(Self.refusalKind)
                        result.seconds = Date.now.timeIntervalSince(asked)
                        show(answer, after: say, in: &messages)
                    } catch {
                        result.error = (error as? LocalizedError)?.errorDescription ?? "\(error)"
                        messages.append(ChatMessage(role: .user, text: say))
                    }
                }
            }
            if let reply {
                result.card = reply.actions.compactMap { action -> TransactionDraft? in
                    if case .draft(let draft) = action { draft } else { nil }
                }.first.map { describe($0, in: store) }
                result.deleteCard = reply.actions.contains { if case .confirmDelete = $0 { true } else { false } }
                result.accountCard = reply.actions.compactMap { action -> AccountDraft? in
                    if case .accountDraft(let draft) = action { draft } else { nil }
                }.first.map(describe)
            }
            result.saved = store.transactions.count - start
            result.accountsAdded = store.accounts.count - accountsAtStart
            result.problems = check(turn.expect, result, store: store) + Self.general(result, modelSpoke: reply != nil)
            turns.append(result)
            // A turn that failed to reach Milu leaves the rest of the chat meaningless.
            if result.error != nil { break }
        }
        return CaseResult(id: item.id, title: item.title, turns: turns,
                          passed: turns.count == item.turns.count && turns.allSatisfy(\.problems.isEmpty))
    }

    /// "Lưu" or "Huỷ" on the card still waiting, as its buttons do.
    private func press(_ tap: String, in messages: inout [ChatMessage], store: FinanceStore) -> String {
        if let row = messages.lastIndex(where: \.waitsForSave), var accounts = messages[row].pendingAccountDraft {
            if tap == "save" {
                accounts = AccountDraftSaver.save(accounts, in: store)
                messages[row].card = .accountDraft(accounts)
                return accounts.state == .saved ? "(bấm Lưu: đã thêm)" : "(bấm Lưu: chưa lưu được, \(accounts.problem ?? ""))"
            }
            accounts.state = .cancelled
            messages[row].card = .accountDraft(accounts)
            return "(bấm Huỷ)"
        }
        guard let row = messages.lastIndex(where: { $0.pendingDraft != nil }),
              var draft = messages[row].pendingDraft else { return "(không có thẻ chờ Lưu để bấm)" }
        if tap == "save" {
            draft = DraftSaver.save(draft, in: store)
            messages[row].card = .draft(draft)
            return draft.state == .saved ? "(bấm Lưu: đã lưu)" : "(bấm Lưu: chưa lưu được, \(draft.problem ?? ""))"
        }
        draft.state = .cancelled
        messages[row].card = .draft(draft)
        return "(bấm Huỷ)"
    }

    /// "ok", "huỷ" typed over a card waiting for "Lưu": the chat's own shortcut (`AssistantView`).
    private func typedShortcut(_ said: String, in messages: inout [ChatMessage], store: FinanceStore) -> String? {
        guard let answer = DraftShortcut.match(said),
              let last = messages.last(where: { $0.role == .assistant }), last.waitsForSave else { return nil }
        if let row = messages.firstIndex(where: { $0.id == last.id }), var accounts = messages[row].pendingAccountDraft {
            messages.append(ChatMessage(role: .user, text: said))
            let reply: String
            switch answer {
            case .save:
                accounts = AccountDraftSaver.save(accounts, in: store)
                reply = accounts.state == .saved
                    ? accounts.rows.count > 1 ? "Đã thêm \(accounts.rows.count) tài khoản." : "Đã thêm tài khoản."
                    : "Chưa lưu được, bạn xem tài khoản ở trên nhé."
            case .cancel:
                accounts.state = .cancelled
                reply = "Đã huỷ, Milu chưa thêm gì."
            }
            messages[row].card = .accountDraft(accounts)
            messages.append(ChatMessage(role: .assistant, text: reply, isLocal: true))
            return reply
        }
        guard last.pendingDraft != nil,
              let row = messages.firstIndex(where: { $0.id == last.id }),
              var draft = messages[row].pendingDraft else { return nil }
        messages.append(ChatMessage(role: .user, text: said))
        let reply: String
        switch answer {
        case .save:
            draft = DraftSaver.save(draft, in: store)
            reply = draft.state == .saved
                ? draft.liveRows.count > 1 ? "Đã lưu \(draft.liveRows.count) khoản." : "Đã lưu."
                : "Chưa lưu được, bạn xem các khoản ở trên nhé."
        case .cancel:
            draft.state = .cancelled
            reply = "Đã huỷ, Milu chưa ghi gì."
        }
        messages[row].card = .draft(draft)
        messages.append(ChatMessage(role: .assistant, text: reply, isLocal: true))
        return reply
    }

    /// The answer into the chat as `AssistantView` puts it: a card it replaces waits no more; the
    /// first card under the answer, each other under a line of its own.
    private func show(_ reply: AssistantReply, after question: String, in messages: inout [ChatMessage]) {
        messages.append(ChatMessage(role: .user, text: question))
        let cards: [ChatMessage.Card] = reply.actions.map { action in
            switch action {
            case .draft(let draft): .draft(draft)
            case .confirmDelete(let transaction): .confirmDelete(transaction, state: .pending)
            case .accountDraft(let draft): .accountDraft(draft)
            }
        }
        for case .accountDraft(let draft) in reply.actions {
            guard let replaced = draft.replacing,
                  let row = messages.firstIndex(where: { $0.pendingAccountDraft?.id == replaced }),
                  var old = messages[row].pendingAccountDraft else { continue }
            old.state = .replaced
            messages[row].card = .accountDraft(old)
        }
        for case .draft(let draft) in reply.actions {
            guard let replaced = draft.replacing,
                  let row = messages.firstIndex(where: { $0.pendingDraft?.id == replaced }),
                  var old = messages[row].pendingDraft else { continue }
            old.state = .replaced
            messages[row].card = .draft(old)
        }
        messages.append(ChatMessage(role: .assistant, text: reply.text, card: cards.first, askedCall: reply.askedCall))
        for card in cards.dropFirst() {
            messages.append(ChatMessage(role: .assistant, text: "Và các khoản này, bấm Lưu nếu đúng:", card: card))
        }
    }

    private func describe(_ draft: TransactionDraft, in store: FinanceStore) -> CardSeen {
        CardSeen(replaces: draft.replacing != nil, rows: draft.liveRows.map { row in
            let transaction = row.transaction
            return RowSeen(kind: transaction.kind.rawValue, amount: transaction.amount,
                           category: row.newItem?.name ?? store.category(id: transaction.categoryID)?.name ?? "",
                           isNew: row.newItem != nil,
                           account: store.account(id: transaction.accountID)?.name ?? "",
                           date: ToolDates.text(transaction.date),
                           note: [transaction.title, transaction.note].filter { !$0.isEmpty }.joined(separator: " · "),
                           warning: row.warning, accountChosen: row.accountChosenByApp)
        })
    }

    private func describe(_ draft: AccountDraft) -> AccountCardSeen {
        AccountCardSeen(replaces: draft.replacing != nil, rows: draft.rows.map { row in
            AccountRowSeen(name: row.account.name, type: AccountDraftBuilder.typeName(row.account.type),
                           balance: row.account.balance, institution: row.account.institution?.shortName ?? "",
                           notice: row.notice, warning: row.warning)
        })
    }

    private static func refusalKind(_ refused: RecordRefusal.Refused) -> String {
        switch refused.reason {
        case RecordRefusal.transfer.reason: "transfer"
        case RecordRefusal.loan.reason: "loan"
        case RecordRefusal.goal.reason: "goal"
        default: refused.reason
        }
    }

    // MARK: Checks

    private func check(_ expect: Expect?, _ seen: TurnResult, store: FinanceStore) -> [String] {
        guard let expect else { return [] }
        if let options = expect.anyOf, !options.isEmpty {
            let tries = options.map { check($0, seen, store: store) }
            if tries.contains(where: \.isEmpty) { return check(expect.without(anyOf: true), seen, store: store) }
            return ["không đạt cách nào: " + tries.map { $0.joined(separator: "; ") }.joined(separator: " | ")]
                + check(expect.without(anyOf: true), seen, store: store)
        }
        var problems: [String] = []
        if let error = seen.error { return ["lỗi gọi máy chủ: \(error)"] }
        let text = Self.key(seen.text)
        if let card = expect.card {
            if let seenCard = seen.card { problems += check(card, seenCard) } else { problems.append("không có thẻ") }
        }
        if expect.noCard == true, seen.card != nil { problems.append("có thẻ (không được có)") }
        if let card = expect.accountCard {
            if let seenCard = seen.accountCard { problems += check(card, seenCard) } else { problems.append("không có thẻ tài khoản") }
        }
        if expect.noAccountCard == true, seen.accountCard != nil { problems.append("có thẻ tài khoản (không được có)") }
        if let added = expect.accountsAdded, added != seen.accountsAdded {
            problems.append("đã thêm \(seen.accountsAdded) tài khoản (cần \(added))")
        }
        if let asks = expect.asks, asks != seen.asks { problems.append(asks ? "không hỏi lại" : "hỏi lại (không cần)") }
        for kind in expect.refused ?? [] where !seen.refused.contains(kind) { problems.append("không từ chối \(kind)") }
        if let tools = expect.tool, !tools.contains(where: seen.tools.contains) {
            problems.append("không gọi \(tools.joined(separator: "/")) (đã gọi: \(seen.tools.joined(separator: ", ")))")
        }
        if expect.noTool == true, !seen.tools.isEmpty { problems.append("gọi công cụ \(seen.tools.joined(separator: ", "))") }
        if let delete = expect.deleteCard, delete != seen.deleteCard {
            problems.append(delete ? "không có thẻ xác nhận xoá" : "có thẻ xoá")
        }
        for group in expect.has ?? [] where !group.contains(where: { text.contains(Self.key($0)) }) {
            problems.append("thiếu “\(group.joined(separator: "” hoặc “"))”")
        }
        for word in expect.not ?? [] where text.contains(Self.key(word)) { problems.append("có “\(word)”") }
        for word in expect.once ?? [] where text.components(separatedBy: Self.key(word)).count > 2 {
            problems.append("“\(word)” lặp lại")
        }
        if let saved = expect.saved, saved != seen.saved { problems.append("đã lưu \(seen.saved) khoản (cần \(saved))") }
        if let name = expect.newItemSaved,
           !(store.pickableItems(.expense) + store.pickableItems(.income)).contains(where: { $0.name.searchKey == name.searchKey }) {
            problems.append("chưa tạo mục “\(name)”")
        }
        return problems
    }

    private func check(_ expect: CardExpect, _ card: CardSeen) -> [String] {
        var problems: [String] = []
        let rows = card.rows
        if let count = expect.rows, count != rows.count { problems.append("thẻ \(rows.count) khoản (cần \(count))") }
        if let amounts = expect.amounts, amounts.sorted() != rows.map(\.amount).sorted() {
            problems.append("số tiền \(rows.map { Int($0.amount) }) (cần \(amounts.map { Int($0) }))")
        }
        for amount in expect.amountsInclude ?? [] where !rows.contains(where: { $0.amount == amount }) {
            problems.append("thẻ không có \(Int(amount))")
        }
        guard let first = rows.first else { return problems + ["thẻ trống"] }
        if let names = expect.category, !names.contains(where: { $0.searchKey == first.category.searchKey }) {
            problems.append("hạng mục “\(first.category)” (cần \(names.joined(separator: "/")))")
        }
        if let names = expect.notCategory, rows.contains(where: { row in names.contains { $0.searchKey == row.category.searchKey } }) {
            problems.append("hạng mục “\(first.category)” (không được là \(names.joined(separator: "/")))")
        }
        if let name = expect.newItem, !(first.isNew && first.category.searchKey == name.searchKey) {
            problems.append("không đề xuất mục mới “\(name)” (thẻ: \(first.category)\(first.isNew ? ", mới" : ""))")
        }
        for name in expect.newItems ?? [] where !rows.contains(where: { $0.isNew && $0.category.searchKey == name.searchKey }) {
            problems.append("không có mục mới “\(name)”")
        }
        if let names = expect.account, !names.contains(where: { $0.searchKey == first.account.searchKey }) {
            problems.append("tài khoản “\(first.account)” (cần \(names.joined(separator: "/")))")
        }
        if let kind = expect.kind, kind != first.kind { problems.append("loại \(first.kind) (cần \(kind))") }
        if let day = expect.date, let wanted = Self.day(day), first.date != ToolDates.text(wanted) {
            problems.append("ngày \(first.date) (cần \(ToolDates.text(wanted)))")
        }
        if let note = expect.note, !rows.contains(where: { Self.key($0.note).contains(Self.key(note)) }) {
            problems.append("ghi chú không có “\(note)”")
        }
        if let warned = expect.warning, warned != rows.contains(where: { $0.warning != nil }) {
            problems.append(warned ? "không cảnh báo" : "có cảnh báo (không cần)")
        }
        if let chosen = expect.accountChosen, chosen != first.accountChosen {
            problems.append(chosen ? "không ghi Milu tự chọn tài khoản" : "ghi Milu tự chọn tài khoản")
        }
        if let replaces = expect.replaces, replaces != card.replaces {
            problems.append(replaces ? "thẻ mới không thay thẻ cũ" : "thay thẻ cũ (không cần)")
        }
        return problems
    }

    private func check(_ expect: AccountCardExpect, _ card: AccountCardSeen) -> [String] {
        var problems: [String] = []
        let rows = card.rows
        if let count = expect.rows, count != rows.count { problems.append("thẻ \(rows.count) tài khoản (cần \(count))") }
        for (index, names) in (expect.names ?? []).enumerated() {
            guard index < rows.count else { break }
            if !names.contains(where: { $0.searchKey == rows[index].name.searchKey }) {
                problems.append("tên “\(rows[index].name)” (cần \(names.joined(separator: "/")))")
            }
        }
        for (index, type) in (expect.types ?? []).enumerated() where index < rows.count && rows[index].type != type {
            problems.append("loại \(rows[index].type) (cần \(type))")
        }
        if let balances = expect.balances, balances != rows.map(\.balance) {
            problems.append("số dư \(rows.map { Int($0.balance) }) (cần \(balances.map { Int($0) }))")
        }
        for (index, name) in (expect.institutions ?? []).enumerated() where index < rows.count
            && rows[index].institution.searchKey != name.searchKey {
            problems.append("ngân hàng “\(rows[index].institution)” (cần \(name))")
        }
        if let noticed = expect.notice, noticed != rows.contains(where: { $0.notice != nil }) {
            problems.append(noticed ? "không ghi chú Milu đã chọn gì" : "có ghi chú (không cần)")
        }
        if let warned = expect.warning, warned != rows.contains(where: { $0.warning != nil }) {
            problems.append(warned ? "không cảnh báo" : "có cảnh báo (không cần)")
        }
        if let replaces = expect.replaces, replaces != card.replaces {
            problems.append(replaces ? "thẻ mới không thay thẻ cũ" : "thay thẻ cũ (không cần)")
        }
        return problems
    }

    /// What every answer of Milu's must keep to: no "Ủa"/"Ê" first (user choice 2026-11-18), no
    /// card code or note meant for the model, never empty.
    private static func general(_ seen: TurnResult, modelSpoke: Bool) -> [String] {
        guard modelSpoke else { return [] }
        var problems: [String] = []
        let text = seen.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { problems.append("câu trả lời trống") }
        let first = key(text).split(separator: " ").first.map(String.init) ?? ""
        if first == "ua" || first == "e" { problems.append("mở đầu bằng “\(text.prefix(3))”") }
        if text.contains(/#[0-9a-z]{4}\b/) { problems.append("lộ mã thẻ") }
        if let tool = text.firstMatch(of: /\b[a-z]+_[a-z_]+\b/) { problems.append("lộ tên công cụ “\(tool.output)”") }
        if key(text).contains("nhac tu he thong") || text.contains("{\"") { problems.append("lộ lời nhắc hệ thống") }
        // "Thẻ" is no word the user knows here (user 2026-11-18), but for a credit card's.
        let words = text.lowercased().replacingOccurrences(of: "thẻ tín dụng", with: " ")
            .replacingOccurrences(of: "thẻ vpbank visa", with: " ")
        if words.split(whereSeparator: { !$0.isLetter }).contains("thẻ") { problems.append("nói “thẻ” với người dùng") }
        return problems
    }

    private static func key(_ text: String) -> String {
        text.searchKey.split { !$0.isLetter && !$0.isNumber && $0 != "." }.joined(separator: " ")
    }

    private static func day(_ text: String) -> Date? {
        let today = Calendar.current.startOfDay(for: .now)
        switch text {
        case "today": return today
        case "yesterday": return Calendar.current.date(byAdding: .day, value: -1, to: today)
        default:
            if let back = Int(text) { return Calendar.current.date(byAdding: .day, value: back, to: today) }
            return ToolDates.day(text)
        }
    }

    private func write(_ results: [CaseResult], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(Report(date: ToolDates.text(.now), passed: results.filter(\.passed).count,
                                  total: results.count, cases: results)).write(to: url)
    }

    // MARK: The file and the report

    private final class ToolsHeard { var names: [String] = [] }

    private struct CaseFile: Decodable { let cases: [Case] }

    private struct Case: Decodable {
        let id: String
        let title: String
        let turns: [Turn]
    }

    private struct Turn: Decodable {
        var say: String?
        var tap: String?
        var expect: Expect?
    }

    private struct Expect: Decodable {
        var card: CardExpect?
        var noCard: Bool?
        var asks: Bool?
        var refused: [String]?
        var tool: [String]?
        var noTool: Bool?
        var deleteCard: Bool?
        var has: [[String]]?
        var not: [String]?
        /// Said at most once: one question for several transactions, not one each.
        var once: [String]?
        var saved: Int?
        var newItemSaved: String?
        /// A card of accounts waiting for "Lưu" (`add_account`).
        var accountCard: AccountCardExpect?
        var noAccountCard: Bool?
        /// Accounts added since the case began.
        var accountsAdded: Int?
        var anyOf: [Expect]?

        func without(anyOf _: Bool) -> Expect {
            var copy = self
            copy.anyOf = nil
            return copy
        }
    }

    private struct CardExpect: Decodable {
        var rows: Int?
        var amounts: [Double]?
        var amountsInclude: [Double]?
        var category: [String]?
        var notCategory: [String]?
        var newItem: String?
        /// Every one new on the card, on any row.
        var newItems: [String]?
        var account: [String]?
        var kind: String?
        var date: String?
        var note: String?
        var warning: Bool?
        var accountChosen: Bool?
        var replaces: Bool?
    }

    private struct AccountCardExpect: Decodable {
        var rows: Int?
        /// Each row's name, by order: one of these.
        var names: [[String]]?
        var types: [String]?
        var balances: [Double]?
        var institutions: [String]?
        var notice: Bool?
        var warning: Bool?
        var replaces: Bool?
    }

    private struct AccountCardSeen: Encodable {
        let replaces: Bool
        let rows: [AccountRowSeen]
    }

    private struct AccountRowSeen: Encodable {
        let name: String
        let type: String
        let balance: Double
        let institution: String
        let notice: String?
        let warning: String?
    }

    private struct Report: Encodable {
        let date: String
        let passed: Int
        let total: Int
        let cases: [CaseResult]
    }

    private struct CaseResult: Encodable {
        let id: String
        let title: String
        let turns: [TurnResult]
        let passed: Bool
    }

    private struct TurnResult: Encodable {
        var say: String?
        var tap: String?
        var text = ""
        var shortcut = false
        var tools: [String] = []
        var asks = false
        var refused: [String] = []
        var card: CardSeen?
        var deleteCard = false
        var accountCard: AccountCardSeen?
        var accountsAdded = 0
        var saved = 0
        var seconds: Double?
        var error: String?
        var problems: [String] = []
    }

    private struct CardSeen: Encodable {
        let replaces: Bool
        let rows: [RowSeen]
    }

    private struct RowSeen: Encodable {
        let kind: String
        let amount: Double
        let category: String
        let isNew: Bool
        let account: String
        let date: String
        let note: String
        let warning: String?
        let accountChosen: Bool
    }
}
