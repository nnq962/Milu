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
    /// The tools the model is given, by name; all when nil. The quick sheet gives the record tool
    /// alone (user choice 2026-11-17: "Thêm bằng AI" only records).
    var onlyTools: Set<String>? = nil

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
                              open: history.compactMap(\.pendingDraft),
                              seen: Set(history.compactMap { message in
                                  if case .draft(let draft) = message.card { draft.ref } else { nil }
                              }))
        /// A card was waiting before this question: an answer that says it changed must have changed it.
        let cardWaiting = !turn.open.isEmpty
        /// What Milu refused to record in this answer, and whether its last record call asked
        /// something back (then the model's question stands, the way by hand added to it).
        var refused: [RecordRefusal.Refused] = []
        var asksBack = false
        /// What the record tool suggested to its last question, for the quick sheet's chips, and the
        /// question in its own words.
        var choices: [String] = []
        var asked: [String] = []
        /// Its question with answers to pick, as the chat says it (`choiceQuestion`), over the model's.
        var chatAsk: String?

        do {
            for _ in 0..<Self.maxRounds {
                let reply = try await api.chat(messages, tools: AssistantTools.specs(only: onlyTools), context: context)
                guard !reply.toolCalls.isEmpty else {
                    let text = Emoji.drawable(reply.content).trimmingCharacters(in: .whitespacesAndNewlines)
                    let answer = !refused.isEmpty && !asksBack
                        ? Self.refusedAnswer(refused, actions: actions)
                        : Self.withHowTo(chatAsk ?? Self.answerText(text, actions: actions, cardWaiting: cardWaiting,
                                                                    refused: !refused.isEmpty,
                                                                    asked: asksBack && !asked.isEmpty ? asked.joined(separator: " ") : nil,
                                                                    items: Self.itemNames(store),
                                                                    cardItems: Self.cardItems(actions, store: store),
                                                                    accounts: store.accounts.map(\.name)),
                                         refused.compactMap(\.howTo))
                    var result = AssistantReply(text: answer, actions: actions, counts: Self.counts(toolsRun))
                    result.refused = refused
                    result.asksBack = asksBack
                    result.choices = asksBack ? choices : []
                    result.asked = asksBack && !asked.isEmpty ? asked.joined(separator: " ") : nil
                    return result
                }
                messages.append(.assistant(reply.content, calls: reply.toolCalls))
                for call in reply.toolCalls {
                    // Said in the chat as it is done (a stopped answer says no more).
                    if !Task.isCancelled {
                        var step = ThinkingStep.tool(call.name, arguments: call.arguments)
                        step.tool = call.name
                        onStep(step)
                    }
                    let allowed = onlyTools?.contains(call.name) ?? true
                    let output = (allowed ? AssistantTools.named(call.name, app: app, turn: turn) : nil)?.run(call.arguments, in: store)
                        ?? .failure("Không có công cụ \(call.name)")
                    if let next = output.action { Self.add(next, to: &actions, turn: &turn) }
                    if call.name == RecordTransaction().name {
                        refused = Self.refused(in: output.result, adding: refused)
                        asksBack = output.result["status"] == "needsInfo"
                        choices = Self.choices(in: output.result)
                        asked = Self.questions(in: output.result)
                        chatAsk = Self.choiceQuestion(in: output.result)
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
    static let cardUnchanged = "Các khoản ở trên chưa đổi gì đâu. Bạn bấm vào khoản cần sửa, hoặc nói lại rõ hơn (ví dụ: “đổi thành 50k”) nhé."

    /// The model's words, but never a card's code ("#adb0", only for the model), and never a claim
    /// the words cannot keep: "đã ghi" over a card waiting for "Lưu" (nothing is saved until then,
    /// and the user would leave it), or "đã cập nhật thẻ" when no new card came (Simulator,
    /// 2026-11-17: said with the card still at 60k, after "50k thôi").
    /// Over a card, one short sentence of the model's (user choice 2026-11-17: it wrote lines of
    /// bullets saying again what the card shows); all of it when something was refused, as that
    /// is said there.
    /// Asking back (`asked`, the record tool's own question), with no card made: words of a card
    /// ("Trà sữa 20.000đ Milu soạn sẵn rồi nè", for "ăn vặt 20k"; or the tool's "Chưa soạn thẻ"
    /// said out) give way to that question (iPhone and eval, 2026-11-18).
    ///
    /// Over a card, words of another item or sum than the card's give way to `draftReady` too: the
    /// model copied its prompt's example, "Trà sữa 45.000đ Milu soạn sẵn rồi nè" over a Taxi card
    /// (eval 2026-11-18). `items` are all the user's item names, `cardItems` the card's.
    static func answerText(_ text: String, actions: [AssistantReply.Action], cardWaiting: Bool = false,
                           refused: Bool = false, asked: String? = nil, items: [String] = [],
                           cardItems: [String] = [], accounts: [String] = []) -> String {
        let text = withoutOpener(text.replacing(/\s?\*{0,2}#[0-9a-f]{4}\b\*{0,2}/, with: ""))
        guard !text.isEmpty else { return asked ?? emptyAnswer(actions.first) }
        let hasDraft = actions.contains { if case .draft = $0 { true } else { false } }
        let words = " " + text.searchKey.split { !$0.isLetter && !$0.isNumber }.joined(separator: " ") + " "
        if !hasDraft, let asked, words.contains(" soan ") { return asked }
        if hasDraft {
            let saysSaved = [" da ghi ", " da luu ", " ghi xong ", " luu xong ", " da them ", " ghi lai roi ", " ghi roi "]
                .contains { words.contains($0) } && !words.contains(" ghi chu ")
            if saysSaved { return draftReady }
            let said = refused ? text : firstSentence(text)
            if !refused, saysOtherThan(actions, items: items, cardItems: cardItems, in: said)
                || saysCard(said, accounts: accounts) {
                return draftReady
            }
            return said
        }
        // Over a delete waiting for its yes, the app's own line: the model's read as done, "Xong rồi
        // nè 🗑️", "Gỡ được khoản cà phê rồi nha" (live test 2026-11-18), one way of saying it after
        // another.
        if let delete = actions.first(where: { if case .confirmDelete = $0 { true } else { false } }) {
            return emptyAnswer(delete)
        }
        guard cardWaiting, actions.isEmpty else { return text }
        let saysChanged = [" da cap nhat ", " da duoc cap nhat ", " da sua ", " da duoc sua ", " da doi ", " da duoc doi ",
                           " cap nhat roi ", " sua roi ", " doi roi ", " da ghi ", " da luu "]
            .contains { words.contains($0) }
        return saysChanged ? cardUnchanged : text
    }

    /// Without "Ủa" or "Ê" first (user choice 2026-11-18: the prompt kept them out most times, not
    /// always: "Ủa, có 1 giao dịch cà phê hôm nay nè").
    static func withoutOpener(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).precomposedStringWithCanonicalMapping
        guard let opener = trimmed.prefixMatch(of: /(?i)(?:ủa|ê)(?:\s*[,!.…]+\s*|\s+)/) else { return text }
        let rest = trimmed[opener.range.upperBound...]
        guard let first = rest.first else { return text }
        return first.uppercased() + rest.dropFirst()
    }

    /// "Soạn thẻ xong rồi nè": "thẻ" is no word the user knows here (user 2026-11-18: "user sẽ
    /// thắc mắc ủa thẻ là cái gì?"), unless it is a credit card or an account's own name.
    static func saysCard(_ text: String, accounts: [String]) -> Bool {
        var said = text.lowercased().precomposedStringWithCanonicalMapping
        for name in accounts { said = said.replacingOccurrences(of: name.lowercased(), with: " ") }
        said = said.replacingOccurrences(of: "thẻ tín dụng", with: " ")
        return said.split { !$0.isLetter }.contains("thẻ")
    }

    /// Whether words over a card name an item or a sum that is not on it.
    static func saysOtherThan(_ actions: [AssistantReply.Action], items: [String], cardItems: [String],
                              in text: String) -> Bool {
        let rows = actions.flatMap { action -> [TransactionDraft.Row] in
            if case .draft(let draft) = action { draft.liveRows } else { [] }
        }
        guard !rows.isEmpty else { return false }
        func plain(_ text: String) -> String {
            " " + text.searchKey.split { !$0.isLetter && !$0.isNumber }.joined(separator: " ") + " "
        }
        let words = plain(text)
        let onCard = Set(cardItems.map(plain))
        if items.contains(where: { words.contains(plain($0)) && !onCard.contains(plain($0)) }) { return true }
        // Sums as the model writes them, "45.000đ": each must be one of the card's, or their total.
        let amounts = Set(rows.map(\.transaction.amount) + [rows.map(\.transaction.amount).reduce(0, +)])
        for match in text.matches(of: /(\d{1,3}(?:\.\d{3})+|\d+)\s*(?:đ|₫)/) {
            if let value = Double(match.output.1.replacingOccurrences(of: ".", with: "")), !amounts.contains(value) {
                return true
            }
        }
        return false
    }

    /// The names of the items the user picks from, to tell when words name one.
    static func itemNames(_ store: FinanceStore) -> [String] {
        // "Khác" is also a word ("tài khoản khác"), not only an item.
        (store.pickableItems(.expense) + store.pickableItems(.income)).map(\.name).filter { $0.searchKey != "khac" }
    }

    /// The items on the answer's cards, by name: an item the user has, or one to make on "Lưu".
    static func cardItems(_ actions: [AssistantReply.Action], store: FinanceStore) -> [String] {
        actions.flatMap { action -> [String] in
            guard case .draft(let draft) = action else { return [] }
            return draft.liveRows.compactMap { $0.newItem?.name ?? store.category(id: $0.transaction.categoryID)?.name }
        }
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

    /// The answers a record result suggests to what it asks: items to pick, options (chi or thu,
    /// a group, an account), and making the item it proposes; a few, each once.
    static func choices(in result: JSONValue) -> [String] {
        guard result["status"] == "needsInfo", case .array(let items)? = result["items"] else { return [] }
        var found: [String] = []
        for item in items {
            let offered = (item["suggestions"]?.strings ?? []) + (item["options"]?.strings ?? [])
            let made = item["canCreate"]?["name"]?.string.flatMap { $0.isEmpty ? nil : "Tạo mục “\($0)”" }
            for choice in offered + [made].compactMap({ $0 }) where !found.contains(choice) { found.append(choice) }
        }
        return Array(found.prefix(6))
    }

    /// A question back that has answers to pick, as the chat says it, in the app's words (user
    /// request 2026-11-18: "user làm sao mà nhớ được họ đang có những hạng mục nào"; the chat has no
    /// chips, and the model's words left the items out, or said a card was made):
    ///
    ///     Khoản “ăn vặt” 20.000đ này xếp vô mục nào trong nhóm “Ăn uống” nè? 🤔
    ///     • Chọn mục có sẵn: Ăn sáng, Ăn trưa, Ăn tối, Cà phê, Trà sữa, Đi chợ
    ///     • Hoặc tạo mục mới “Ăn vặt” trong nhóm “Ăn uống” luôn cho tiện ✨
    ///
    ///     Bạn chọn xong nhắn Milu một tiếng nha 😉
    ///
    /// Several asked the same ("trà đá 5k … ăn vặt 70k" in one sentence): one question for all,
    /// the list once (user 2026-11-18: "sao nó lại response giống hệt nhau thế"), with how to
    /// answer for each:
    ///
    ///     Có 2 khoản Milu chưa biết xếp vô mục nào nè: **Trà đá 5.000đ** và **Ăn vặt 70.000đ** 👀
    ///     • Chọn mục có sẵn: Ăn sáng, Ăn trưa, Ăn tối, Cà phê, Trà sữa, Đi chợ
    ///     • Hoặc tạo mục mới “Trà đá”, “Ăn vặt” trong nhóm “Ăn uống” luôn cho tiện ✨
    ///
    ///     Bạn nhắn Milu từng khoản nha, kiểu: “trà đá vào Ăn sáng, ăn vặt tạo mới” 😉
    ///
    /// In Milu's own young, playful voice (user 2026-11-18: the plain list read "cộc lốc"), the
    /// emoji and the last line one of a few (`variant`), so asking twice does not read the same;
    /// never "thẻ", a word the user does not know here (user 2026-11-18).
    /// Nil when nothing is offered to pick ("bao nhiêu tiền?"): the model's words stand.
    static func choiceQuestion(in result: JSONValue, variant: Int = Int.random(in: 0..<3)) -> String? {
        guard result["status"] == "needsInfo", case .array(let items)? = result["items"] else { return nil }
        struct Asked {
            var question: String
            var category: Bool
            var picks: [String]
            var newName: String?
            var groups: [String]
            var about: String
        }
        let asked: [Asked] = items.compactMap { item in
            guard let ask = item["ask"]?.string, !ask.isEmpty else { return nil }
            let question = ask.components(separatedBy: CategoryResolver.offerLead).first ?? ask
            // Options the question says already ("khoản chi hay khoản thu?") are not said again.
            let picks = ((item["suggestions"]?.strings ?? []) + (item["options"]?.strings ?? []))
                .filter { !question.searchKey.contains($0.searchKey) }
            let name = item["canCreate"]?["name"]?.string.flatMap { $0.isEmpty ? nil : $0 }
            return Asked(question: question, category: item["missing"]?.string == "category", picks: picks,
                         newName: name, groups: item["canCreate"]?["groups"]?.strings ?? [],
                         about: item["about"]?.string ?? "")
        }
        guard asked.contains(where: { !$0.picks.isEmpty || $0.newName != nil }) else { return nil }
        let look = ["🤔", "👀", "🧐"][variant % 3]
        func offer(_ names: [String], groups: [String]) -> String {
            "• Hoặc tạo mục mới " + names.map { "“\($0)”" }.joined(separator: ", ")
                + (groups.count == 1 ? " trong nhóm “\(groups[0])”" : "") + " luôn cho tiện ✨"
        }
        func listed(_ names: [String]) -> String {
            names.count < 2 ? names.joined() : names.dropLast().joined(separator: ", ") + " và " + (names.last ?? "")
        }
        var blocks: [String] = []
        var together: [Asked] = []
        var done = Set<Int>()
        for (index, one) in asked.enumerated() where !done.contains(index) {
            // The others asking for an item: asked with it, their lists made one (user 2026-11-18:
            // with lists not the same, the same question was said twice, word for word).
            let same = asked.indices.filter { other in
                !done.contains(other) && one.category && asked[other].category && !asked[other].about.isEmpty
            }
            if same.count > 1, !one.about.isEmpty {
                done.formUnion(same)
                let group = same.map { asked[$0] }
                var lines = ["Có \(group.count) khoản Milu chưa biết xếp vô mục nào nè: "
                             + listed(group.map { "**\($0.about)**" }) + " \(look)"]
                var picks: [String] = []
                for pick in group.flatMap(\.picks) where !picks.contains(pick) { picks.append(pick) }
                together = group.map { var each = $0; each.picks = Self.withoutSharedGroup(each.picks); return each }
                if !picks.isEmpty { lines.append("• Chọn mục có sẵn: \(Self.withoutSharedGroup(picks).joined(separator: ", "))") }
                let names = group.compactMap(\.newName)
                let homes = Set(group.flatMap(\.groups))
                if !names.isEmpty { lines.append(offer(names, groups: homes.count == 1 ? Array(homes) : [])) }
                blocks.append(lines.joined(separator: "\n"))
                continue
            }
            done.insert(index)
            var lines = [one.question]
            if !one.picks.isEmpty {
                let picks = one.category ? Self.withoutSharedGroup(one.picks) : one.picks
                lines.append("• \(one.category ? "Chọn mục có sẵn" : "Chọn"): \(picks.joined(separator: ", "))")
            }
            if let name = one.newName { lines.append(offer([name], groups: one.groups)) }
            if lines.count > 1 { lines[0] += " \(look)" }
            blocks.append(lines.joined(separator: "\n"))
        }
        // The name of what was asked about, its sum left out: "Trà đá 5.000đ" is "trà đá".
        func named(_ one: Asked) -> String {
            one.about.split(separator: " ").prefix { Double($0.filter(\.isNumber)) == nil }
                .joined(separator: " ").lowercased()
        }
        let last: String
        if together.count > 1 {
            // How to answer for each, in their own names: the first made new when it can be, the
            // next to an item there is.
            let (first, second) = (named(together[0]), named(together[1]))
            let firstTo = together[0].newName != nil ? "tạo mới" : together[0].picks.first.map { "vào \($0)" } ?? ""
            let secondTo = together[1].picks.first.map { "vào \($0)" } ?? (together[1].newName != nil ? "tạo mới" : "")
            last = first.isEmpty || second.isEmpty || firstTo.isEmpty || secondTo.isEmpty
                ? "Bạn nhắn Milu từng khoản xếp vô đâu nha 😉"
                : "Bạn nhắn Milu từng khoản nha, kiểu: “\(first) \(firstTo), \(second) \(secondTo)” 😉"
        } else {
            last = ["Bạn chọn xong nhắn Milu một tiếng nha 😉", "Chốt cái nào thì nhắn Milu nè 🚀",
                    "Nhắn Milu lựa chọn của bạn nha, phần còn lại để Milu lo 💪"][variant % 3]
        }
        return (blocks + [last]).joined(separator: "\n\n")
    }

    /// Items to pick, without the group they all share: "Trà sữa (Ăn uống), Cà phê (Ăn uống)" is
    /// "Trà sữa, Cà phê" (iPhone 2026-11-18). Groups that differ are kept, to tell items apart.
    static func withoutSharedGroup(_ picks: [String]) -> [String] {
        func group(_ pick: String) -> String? {
            guard pick.hasSuffix(")"), let open = pick.range(of: " (", options: .backwards) else { return nil }
            return String(pick[open.upperBound...].dropLast())
        }
        let groups = Set(picks.map(group))
        guard groups.count == 1, let only = groups.first, only != nil else { return picks }
        return picks.map { pick in
            pick.range(of: " (", options: .backwards).map { String(pick[..<$0.lowerBound]) } ?? pick
        }
    }

    /// What a record result asks, item by item, each once.
    static func questions(in result: JSONValue) -> [String] {
        guard result["status"] == "needsInfo", case .array(let items)? = result["items"] else { return [] }
        var found: [String] = []
        for item in items {
            if let ask = item["ask"]?.string, !ask.isEmpty, !found.contains(ask) { found.append(ask) }
        }
        return found
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
        turn.seen.insert(draft.ref)
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
            case .saved: "đã lưu, người dùng bấm Xem để sửa"
            case .cancelled: "đã huỷ, không ghi gì"
            case .replaced: "đã thay bằng bản mới"
            }
            let items: [JSONValue] = rows.map { row in
                let transaction = row.transaction
                var item: [String: JSONValue] = [
                    "kind": .string(transaction.kind.rawValue), "amount": ToolMoney.value(transaction.amount),
                    "date": .string(ToolDates.text(transaction.date)),
                ]
                // An item to make on "Lưu" as the model asks for one, so it sends it back so
                // (iPhone 2026-11-18: told as "category": "Trà đá", sent back so, it was asked again).
                if let new = row.newItem {
                    item["new_category"] = ["name": .string(new.name), "group": .string(store.categoryName(new.groupID))]
                } else {
                    item["category"] = .string(store.categoryName(transaction.categoryID))
                }
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
