import CoreText
import Foundation

/// Milu's answers from the local LLM on the app's server (`MiluAPI`), worked from the phone's
/// own data: the model asks for tools (`AssistantTools`), they run here, only their results go
/// back, and it answers from them (user choice 2026-11-12).
///
/// Without internet it says so (user choice 2026-11-12: no stand-in answers offline); the
/// keyword assistant answers only when no server is set at all (`AssistantServices`).
struct RemoteAssistant: AssistantService {
    let api: MiluAPI
    let store: FinanceStore
    /// The app's own facts, for questions about Milu itself (`GetAppInfo`).
    var app = AppFacts()

    /// Rounds of tools before giving up: a question takes one or two.
    private static let maxRounds = 5
    /// The chat so far the model reads: enough for "còn tháng trước?" after a question.
    private static let historyLength = 6

    func reply(to question: String, history: [ChatMessage],
               onStep: @escaping (ThinkingStep) -> Void) async throws -> AssistantReply {
        var messages = Self.history(history, store: store)
        messages.append(.user(question))
        let context = Self.context(for: store)
        var actions: [AssistantReply.Action] = []
        /// The tools run: a question that only recorded or deleted takes no lượt.
        var toolsRun = Set<String>()
        /// What `record_transaction` knows of the chat: the user's words, to check amounts, and the
        /// cards waiting for "Lưu", this answer's own as they come.
        var turn = RecordTurn(userWords: history.filter { $0.role == .user }.suffix(3).map(\.text) + [question],
                              open: history.compactMap(\.pendingDraft))
        /// A card was waiting before this question: an answer that says it changed must have changed it.
        let cardWaiting = !turn.open.isEmpty
        /// What Milu refused to record in this answer, and whether its last record call asked
        /// something back (then the model's question stands, the way by hand added to it).
        var refused: [RecordRefusal.Refused] = []
        var asksBack = false

        do {
            for _ in 0..<Self.maxRounds {
                let reply = try await api.chat(messages, tools: AssistantTools.specs, context: context)
                guard !reply.toolCalls.isEmpty else {
                    let text = Emoji.drawable(reply.content).trimmingCharacters(in: .whitespacesAndNewlines)
                    let answer = !refused.isEmpty && !asksBack
                        ? Self.refusedAnswer(refused, actions: actions)
                        : Self.withHowTo(Self.answerText(text, actions: actions, cardWaiting: cardWaiting, refused: !refused.isEmpty),
                                         refused.compactMap(\.howTo))
                    return AssistantReply(text: answer, actions: actions, counts: Self.counts(toolsRun))
                }
                messages.append(.assistant(reply.content, calls: reply.toolCalls))
                for call in reply.toolCalls {
                    // Said in the chat as it is done (a stopped answer says no more).
                    if !Task.isCancelled { onStep(ThinkingStep.tool(call.name, arguments: call.arguments)) }
                    let output = AssistantTools.named(call.name, app: app, turn: turn)?.run(call.arguments, in: store)
                        ?? .failure("Không có công cụ \(call.name)")
                    if let next = output.action { Self.add(next, to: &actions, turn: &turn) }
                    if call.name == RecordTransaction().name {
                        refused = Self.refused(in: output.result, adding: refused)
                        asksBack = output.result["status"] == "needsInfo"
                    }
                    toolsRun.insert(call.name)
                    messages.append(.tool(call.name, result: output.result))
                }
            }
            return AssistantReply(text: Self.emptyAnswer(actions.first), actions: actions, counts: Self.counts(toolsRun))
        } catch where !actions.isEmpty {
            // A card was made, or a transaction picked to delete, before the answer failed, a "too
            // many questions" too (audit 2026-11-15: that one hid the card): its card shows.
            // Not counted: the answer did not come, and recording and deleting are free (audit
            // round 2, 2026-11-15: a question that also read something kept its lượt).
            return AssistantReply(text: Self.emptyAnswer(actions.first), actions: actions, counts: false)
        } catch MiluAPI.Failure.busy {
            // The server's hourly limit is shared by everyone: busy, not "you asked too much" to
            // someone who asked once (audit round 3, 2026-11-16).
            throw AssistantServiceError.server("đang có nhiều người hỏi cùng lúc")
        } catch is CancellationError {
            throw CancellationError()
        } catch MiluAPI.Failure.offline {
            throw AssistantServiceError.noConnection
        } catch MiluAPI.Failure.interrupted {
            throw AssistantServiceError.interrupted
        } catch MiluAPI.Failure.unreachable {
            throw AssistantServiceError.unavailable
        } catch MiluAPI.Failure.unauthorized {
            throw AssistantServiceError.server("khoá kết nối không hợp lệ")
        } catch {
            throw AssistantServiceError.server("máy chủ trả lời lỗi")
        }
    }

    /// Whether the question takes a lượt: not when every tool it ran only recorded, deleted or
    /// told of the app itself (its lượt, Milu Pro, privacy: asked too when none are left).
    static func counts(_ tools: Set<String>) -> Bool {
        var tools = tools
        // A delete needs the transaction's ref, which only list_transactions gives: finding it is
        // part of deleting (audit 2026-11-15: every delete took a lượt, and with none left could not
        // be done, against the Terms).
        if tools.contains(DeleteTransaction().name) { tools.remove(ListTransactions().name) }
        return tools.isEmpty || !tools.isSubset(of: [RecordTransaction().name, DeleteTransaction().name, GetAppInfo().name])
    }

    static func emptyAnswer(_ action: AssistantReply.Action?) -> String {
        switch action {
        case .draft: draftReady
        case .confirmDelete: "Khoản cần xoá ở bên dưới, bạn bấm xác nhận nhé:"
        case nil: "Mình chưa trả lời được câu này. Bạn hỏi lại theo cách khác nhé."
        }
    }

    /// Said over a card waiting for "Lưu".
    static let draftReady = "Milu soạn xong rồi, bạn kiểm tra rồi bấm **Lưu** nhé:"

    /// Said when the model claimed a card waiting for "Lưu" was changed, and nothing changed it.
    static let cardUnchanged = "Thẻ ở trên chưa đổi gì đâu. Bạn bấm vào dòng trên thẻ để sửa, hoặc nói lại rõ hơn (ví dụ: “đổi thành 50k”) nhé."

    /// The model's words, but never a card's code ("#adb0", only for the model), and never a claim
    /// the words cannot keep: "đã ghi" over a card waiting for "Lưu" (nothing is saved until then,
    /// and the user would leave it), or "đã cập nhật thẻ" when no new card came (Simulator,
    /// 2026-11-17: said with the card still at 60k, after "50k thôi").
    /// Over a card, one short sentence of the model's (user choice 2026-11-17: it wrote lines of
    /// bullets saying again what the card shows); all of it when something was refused, as that
    /// is said there.
    static func answerText(_ text: String, actions: [AssistantReply.Action], cardWaiting: Bool = false,
                           refused: Bool = false) -> String {
        let text = text.replacing(/\s?\*{0,2}#[0-9a-f]{4}\b\*{0,2}/, with: "")
        guard !text.isEmpty else { return emptyAnswer(actions.first) }
        let hasDraft = actions.contains { if case .draft = $0 { true } else { false } }
        let words = " " + text.searchKey.split { !$0.isLetter && !$0.isNumber }.joined(separator: " ") + " "
        if hasDraft {
            let saysSaved = [" da ghi ", " da luu ", " ghi xong ", " luu xong ", " da them ", " ghi lai roi ", " ghi roi "]
                .contains { words.contains($0) } && !words.contains(" ghi chu ")
            if saysSaved { return draftReady }
            return refused ? text : firstSentence(text)
        }
        guard cardWaiting, actions.isEmpty else { return text }
        let saysChanged = [" da cap nhat ", " da duoc cap nhat ", " da sua ", " da duoc sua ", " da doi ", " da duoc doi ",
                           " cap nhat roi ", " sua roi ", " doi roi ", " da ghi ", " da luu "]
            .contains { words.contains($0) }
        return saysChanged ? cardUnchanged : text
    }

    /// The answer's first sentence, from its first line that is not a bullet: "Milu soạn xong rồi
    /// nè 🫠. Bạn kiểm tra…" is "Milu soạn xong rồi nè 🫠.". A sentence ends at ".", "!", "?" or
    /// "…", or at an emoji, before a space and a capital ("rồi nha 🧋 Bạn kiểm tra…", 2026-11-17).
    static func firstSentence(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        guard let line = lines.first(where: { !$0.isEmpty && !$0.hasPrefix("•") }) else { return text }
        let characters = Array(line)
        for index in characters.indices.dropLast(2) {
            let character = characters[index]
            let ends = ".!?…".contains(character) || isEmoji(character)
            guard ends, characters[index + 1].isWhitespace else { continue }
            // The next word: past the spaces, and past a run of emoji ("nè 🫠 😏 Bạn").
            var next = index + 1
            while next < characters.count, characters[next].isWhitespace || isEmoji(characters[next]) { next += 1 }
            guard next < characters.count, characters[next].isUppercase || characters[next] == "*" else { continue }
            let kept = String(characters[...index]).trimmingCharacters(in: .whitespaces)
            // An emoji at the end keeps the ones right after it ("nè 🫠😏").
            return kept
        }
        return line
    }

    private static func isEmoji(_ character: Character) -> Bool {
        character.unicodeScalars.contains { $0.properties.isEmojiPresentation || ($0.properties.isEmoji && $0.value > 0x2000) }
    }

    /// What a record result refused, new ones after `known`.
    static func refused(in result: JSONValue, adding known: [RecordRefusal.Refused]) -> [RecordRefusal.Refused] {
        var found = known
        let items: [JSONValue] = switch (result["items"], result["rejected"]) {
        case (_, .array(let items)?): items
        case (.array(let items)?, _) where result["status"] == "rejected": items
        default: []
        }
        for item in items {
            guard let reason = item["reason"]?.string, !reason.isEmpty else { continue }
            let howTo = item["howTo"]?.string.flatMap { $0.isEmpty ? nil : $0 }
            let refusal = RecordRefusal.Refused(reason: reason, howTo: howTo)
            if !found.contains(refusal) { found.append(refusal) }
        }
        return found
    }

    /// An answer that refused something, in the app's own words (user request 2026-11-17: the
    /// model said "Milu bị từ chối rồi nè", as if Milu were the one turned down): what Milu cannot
    /// record yet and the way by hand; then, when the rest made a card, that it waits for "Lưu",
    /// last, right over the card.
    static func refusedAnswer(_ refused: [RecordRefusal.Refused], actions: [AssistantReply.Action]) -> String {
        let message = RecordRefusal.message(refused)
        let hasDraft = actions.contains { if case .draft = $0 { true } else { false } }
        return hasDraft ? message + "\n\n" + restReady : message
    }

    /// Over the card of what was not refused.
    static let restReady = "Phần còn lại Milu soạn xong rồi, bạn kiểm tra rồi bấm **Lưu** nhé:"

    /// The answer with each way by hand it left out added at its end: told in the model's own words
    /// it was lost half the time ("rút 2tr": "Milu cần bạn làm thủ công", and no path; eval
    /// 2026-11-17). Said is where its path ends ("Chuyển khoản" of "nút + → Thêm giao dịch →
    /// Chuyển khoản").
    static func withHowTo(_ text: String, _ howTos: [String]) -> String {
        let said = text.searchKey
        let missing = howTos.filter { howTo in
            let firstWay = howTo.components(separatedBy: ".").first ?? howTo
            let end = (firstWay.components(separatedBy: "→").last ?? firstWay)
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            return !end.isEmpty && !said.contains(end.searchKey)
        }
        guard !missing.isEmpty else { return text }
        return ([text] + missing.map { "• \($0)" }).joined(separator: "\n")
    }

    /// A card into the answer's: one that replaces another made in this answer takes its place;
    /// the record tool's next call sees it as waiting.
    static func add(_ action: AssistantReply.Action, to actions: inout [AssistantReply.Action], turn: inout RecordTurn) {
        guard case .draft(var draft) = action else {
            actions.append(action)
            return
        }
        if let replaced = draft.replacing {
            // The card it replaces waits no more.
            turn.open.removeAll { $0.id == replaced }
            // One of this same answer: the newer card stands for it, and for the one it replaced.
            if let index = actions.firstIndex(where: { if case .draft(let earlier) = $0 { earlier.id == replaced } else { false } }),
               case .draft(let earlier) = actions[index] {
                draft.replacing = earlier.replacing
                actions.remove(at: index)
            }
        }
        turn.open.append(draft)
        actions.append(.draft(draft))
    }

    /// The chat so far as the model reads it: the last few messages, each card as the tool call
    /// that made it and its result, before Milu's words (`cardExchange`), so "à không, 50k thôi"
    /// means that card. A card still waiting from further back comes first. Said as a note in
    /// Milu's own words, the model copied the note into its answers (Simulator, 2026-11-17).
    static func history(_ history: [ChatMessage], store: FinanceStore) -> [MiluAPI.ChatMessage] {
        let recent = Array(history.suffix(historyLength))
        var messages: [MiluAPI.ChatMessage] = []
        let recentIDs = Set(recent.map(\.id))
        if let waiting = history.last(where: { $0.pendingDraft != nil }), !recentIDs.contains(waiting.id) {
            messages += cardExchange(waiting.card, store: store)
        }
        for message in recent where message.role != .notice {
            let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if message.role == .user {
                if !text.isEmpty { messages.append(.user(text)) }
                continue
            }
            messages += cardExchange(message.card, store: store)
            if !text.isEmpty { messages.append(.assistant(text)) }
        }
        return messages
    }

    /// A card as the call that made it and the result it gave, as now: "[Thẻ #k7f2 · đang chờ …]"
    /// in the result for one waiting (the server looks for it), the rows as they are on the card.
    static func cardExchange(_ card: ChatMessage.Card?, store: FinanceStore) -> [MiluAPI.ChatMessage] {
        let builder = DraftBuilder(turn: RecordTurn(), store: store)
        func exchange(_ name: String, id: String, arguments: JSONValue, result: JSONValue) -> [MiluAPI.ChatMessage] {
            [.assistant("", calls: [MiluAPI.ToolCall(id: id, name: name, arguments: arguments)]), .tool(name, result: result)]
        }
        switch card {
        case .draft(let draft):
            let rows = draft.liveRows
            let state = switch draft.state {
            case .pending: "đang chờ người dùng bấm Lưu, chưa ghi; đổi gì thì gọi record_transaction với replaces"
            case .saved: "đã lưu, người dùng bấm Xem trên thẻ để sửa"
            case .cancelled: "đã huỷ, không ghi gì"
            case .replaced: "đã thay bằng thẻ mới"
            }
            let items: [JSONValue] = rows.map { row in
                let transaction = row.transaction
                var item: [String: JSONValue] = [
                    "kind": .string(transaction.kind.rawValue), "amount": ToolMoney.value(transaction.amount),
                    "category": .string(row.newItem?.name ?? store.categoryName(transaction.categoryID)),
                    "date": .string(ToolDates.text(transaction.date)),
                ]
                if !row.accountChosenByApp, let account = store.account(id: transaction.accountID) {
                    item["account"] = .string(account.name)
                }
                if !transaction.note.isEmpty { item["note"] = .string(transaction.note) }
                return .object(item)
            }
            return exchange(RecordTransaction().name, id: "card-\(draft.ref)", arguments: ["transactions": .array(items)],
                            result: ["ok": true, "status": "draft", "card": .string(draft.ref),
                                     "note": .string("[Thẻ #\(draft.ref) · \(state)]"),
                                     "rows": .array(rows.enumerated().map { builder.describe($0.element, number: $0.offset + 1) })])
        case .recorded(let transaction, let removed):
            return exchange(RecordTransaction().name, id: "rec-\(ToolTransactions.ref(transaction))",
                            arguments: ["kind": .string(transaction.kind.rawValue), "amount": ToolMoney.value(transaction.amount)],
                            result: ["ok": true, "recorded": ToolTransactions.describe(transaction, in: store),
                                     "removed": .bool(removed)])
        case .confirmDelete(let transaction, let state):
            let said = switch state {
            case .pending: "chờ người dùng bấm xác nhận xoá"
            case .deleted: "đã xoá"
            case .cancelled: "người dùng giữ lại, không xoá"
            }
            return exchange(DeleteTransaction().name, id: "del-\(ToolTransactions.ref(transaction))",
                            arguments: ["ref": .string(ToolTransactions.ref(transaction))],
                            result: ["ok": true, "state": .string(said),
                                     "transaction": ToolTransactions.describe(transaction, in: store)])
        case nil:
            return []
        }
    }

    /// The day and the names the model may use: categories (groups and their items) and accounts.
    /// Also what the server's evaluation reads (`AssistantToolsTests`).
    static func context(for store: FinanceStore, on day: Date = .now) -> MiluAPI.Context {
        func names(_ kind: TransactionKind) -> [String] {
            store.groups(kind).flatMap { group in [group.name] + store.items(of: group).map(\.name) }
        }
        let profileName = UserDefaults.standard.string(forKey: StorageKey.profileName)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return MiluAPI.Context(
            today: ToolDates.text(day),
            userName: profileName?.isEmpty == false ? profileName : nil,
            expenseCategories: names(.expense),
            incomeCategories: names(.income),
            accounts: store.accounts.map(\.name)
        )
    }
}

/// Emoji in an answer (user choice 2026-11-12: Milu answers with them), less any this iPhone has
/// no picture for: a newer one than its emoji font showed as a "?" box (Simulator, 2026-11-12).
enum Emoji {
    private static let font = CTFontCreateWithName("AppleColorEmoji" as CFString, 17, nil)

    static func drawable(_ text: String) -> String {
        String(text.filter(isDrawable))
    }

    private static func isDrawable(_ character: Character) -> Bool {
        // Only pictographs are checked: digits, © and the like are drawn by the text's own font.
        let pictographs = character.unicodeScalars.filter { $0.properties.isEmojiPresentation || $0.value >= 0x1F000 }
        guard !pictographs.isEmpty else { return true }
        return pictographs.allSatisfy { scalar in
            let units = Array(String(scalar).utf16)
            var glyphs = [CGGlyph](repeating: 0, count: units.count)
            return CTFontGetGlyphsForCharacters(font, units, &glyphs, units.count)
        }
    }
}
