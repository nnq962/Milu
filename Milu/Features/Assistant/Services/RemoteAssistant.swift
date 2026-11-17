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

        do {
            for _ in 0..<Self.maxRounds {
                let reply = try await api.chat(messages, tools: AssistantTools.specs, context: context)
                guard !reply.toolCalls.isEmpty else {
                    let text = Emoji.drawable(reply.content).trimmingCharacters(in: .whitespacesAndNewlines)
                    return AssistantReply(text: Self.answerText(text, actions: actions), actions: actions,
                                          counts: Self.counts(toolsRun))
                }
                messages.append(.assistant(reply.content, calls: reply.toolCalls))
                for call in reply.toolCalls {
                    // Said in the chat as it is done (a stopped answer says no more).
                    if !Task.isCancelled { onStep(ThinkingStep.tool(call.name, arguments: call.arguments)) }
                    let output = AssistantTools.named(call.name, app: app, turn: turn)?.run(call.arguments, in: store)
                        ?? .failure("Không có công cụ \(call.name)")
                    if let next = output.action { Self.add(next, to: &actions, turn: &turn) }
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

    /// The model's words, unless it said a card was recorded: nothing is until "Lưu", and "đã ghi"
    /// over a card waiting for it would have the user leave it unsaved.
    static func answerText(_ text: String, actions: [AssistantReply.Action]) -> String {
        guard !text.isEmpty else { return emptyAnswer(actions.first) }
        let hasDraft = actions.contains { if case .draft = $0 { true } else { false } }
        guard hasDraft else { return text }
        let words = " " + text.searchKey.split { !$0.isLetter && !$0.isNumber }.joined(separator: " ") + " "
        let saysSaved = [" da ghi ", " da luu ", " ghi xong ", " luu xong ", " da them ", " ghi lai roi ", " ghi roi "]
            .contains { words.contains($0) } && !words.contains(" ghi chu ")
        return saysSaved ? draftReady : text
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

    /// The chat so far as the model reads it: the last few messages, a card's state said under
    /// the words it came with (`[Thẻ #k7f2 · đang chờ Lưu · 1) chi 60.000đ · Ăn trưa …]`), so
    /// "à không, 50k thôi" means that card. A card still waiting from further back comes first.
    /// None of it is shown in the chat.
    static func history(_ history: [ChatMessage], store: FinanceStore) -> [MiluAPI.ChatMessage] {
        let recent = Array(history.suffix(historyLength))
        var messages: [MiluAPI.ChatMessage] = []
        let recentIDs = Set(recent.map(\.id))
        if let waiting = history.last(where: { $0.pendingDraft != nil }), !recentIDs.contains(waiting.id),
           let note = cardNote(waiting.card, store: store) {
            messages.append(.assistant(note))
        }
        for message in recent where message.role != .notice {
            let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let note = cardNote(message.card, store: store)
            let full = [text, note].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: "\n")
            guard !full.isEmpty else { continue }
            messages.append(message.role == .user ? .user(full) : .assistant(full))
        }
        return messages
    }

    /// A card as the model is told of it.
    static func cardNote(_ card: ChatMessage.Card?, store: FinanceStore) -> String? {
        switch card {
        case .draft(let draft):
            let state = switch draft.state {
            case .pending: "đang chờ người dùng bấm Lưu, chưa ghi"
            case .saved: "đã lưu"
            case .cancelled: "đã huỷ, không ghi gì"
            case .replaced: "đã thay bằng thẻ mới"
            }
            let rows = draft.liveRows.enumerated().map { index, row in
                let transaction = row.transaction
                var parts = ["\(index + 1)) \(transaction.kind == .income ? "thu" : "chi") \(transaction.amount.vnd)"]
                parts.append(DraftChecks.categoryText(of: row, in: store))
                parts.append(store.account(id: transaction.accountID)?.name ?? "")
                parts.append(ToolDates.text(transaction.date) + " " + DraftChecks.time(transaction.date))
                if !transaction.note.isEmpty { parts.append("ghi chú: \(transaction.note)") }
                return parts.joined(separator: " · ")
            }
            return "[Thẻ #\(draft.ref) · \(state) · " + rows.joined(separator: " · ") + "]"
        case .recorded(let transaction, let removed):
            return "[Đã ghi \(transaction.amount.vnd)\(removed ? ", rồi đã xoá" : "")]"
        case .confirmDelete(let transaction, let state):
            let said = switch state {
            case .pending: "chờ xác nhận xoá"
            case .deleted: "đã xoá"
            case .cancelled: "đã giữ lại"
            }
            return "[Khoản \(transaction.amount.vnd) \(said)]"
        case nil:
            return nil
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
