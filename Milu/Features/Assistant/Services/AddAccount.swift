import Foundation

/// Makes a card of accounts to add ("thêm tài khoản Techcombank 5 triệu"), and adds nothing: the
/// user checks it and taps "Lưu", as for transactions (user request 2026-11-20). What is missing or
/// unsure is asked, never guessed: the kind of account, which bank or wallet, the balance, and
/// whether a name the user already has means a second account (user choices 2026-11-20).
struct AddAccount: AssistantTool {
    var turn = RecordTurn()

    let name = "add_account"
    let description = """
        Soạn thẻ thêm tài khoản mới (tiền mặt, ngân hàng, ví điện tử; thẻ tín dụng là ngân hàng số dư âm) để người dùng \
        bấm Lưu; CHƯA thêm gì. Gọi ngay khi người dùng muốn thêm, tạo một tài khoản, kể cả khi thiếu số dư hay tên, mọi \
        tài khoản của câu trong một lần. Sửa thẻ đang chờ thì gửi lại đủ tài khoản kèm replaces.
        """
    let parameters: JSONValue = [
        "type": "object",
        "properties": [
            "accounts": [
                "type": "array",
                "description": "Từng tài khoản người dùng muốn thêm",
                "items": [
                    "type": "object",
                    "properties": [
                        "type": ["type": "string", "enum": ["cash", "bank", "ewallet", "goal", "unclear"],
                                 "description": "goal: hũ tiết kiệm"],
                        "institution": ["type": "string", "description": "Ngân hàng hay ví người dùng nói: Techcombank, vcb, momo"],
                        "name": ["type": "string", "description": "Tên riêng người dùng đặt, nếu có"],
                        "balance": ["type": "integer", "description": "Số dư VND; bỏ trống nếu chưa nói"],
                        "balance_said": ["type": "string", "description": "Số dư đúng chữ người dùng nói"],
                        "negative": ["type": "boolean", "description": "true khi là số đang nợ"],
                        "same_name_ok": ["type": "boolean", "description": "true khi người dùng vẫn thêm dù trùng tên"],
                        "note": ["type": "string"],
                    ],
                ],
            ],
            "replaces": ["type": "string", "description": "Mã thẻ tài khoản cần sửa (từ [Thẻ tài khoản #k7f2]); chỉ mã, không accounts, là hiện lại thẻ"],
        ],
        "required": ["accounts"],
    ]

    /// Whether the model is given this tool for `question`: only when the chat is about accounts.
    /// Given always, it and its rules took the prompt to 7.445 of the model's 8.192 tokens, and
    /// long chats about spending came back empty (live test 2026-11-20).
    static func isNeeded(for question: String, history: [ChatMessage]) -> Bool {
        if history.contains(where: { $0.pendingAccountDraft != nil }) { return true }
        if history.last(where: { $0.role == .assistant })?.askedCall?.name == AddAccount().name { return true }
        let words = " " + question.searchKey.split { !$0.isLetter && !$0.isNumber }.joined(separator: " ") + " "
        // Not " vi " alone: "vì" reads the same without its marks.
        let about = [" tai khoan ", " tk ", " vi dien tu ", " them vi ", " tao vi ", " mo vi ", " ngan hang ", " tien mat ",
                     " bank ", " account "]
        // A bank named with a word of adding only: "chuyển 500k từ VCB sang MoMo" is a transfer, and
        // given add_account the model answered it in words (live test 2026-11-20).
        let adds = [" them ", " tao ", " mo "].contains(where: words.contains)
        // "mua áo 500k bằng thẻ tín dụng" pays with one (live test 2026-11-20): a card is added only.
        return about.contains(where: words.contains)
            || (adds && (AccountDraftBuilder.named(in: question) != nil || words.contains(" the tin dung ")))
    }

    func run(_ arguments: JSONValue, in store: FinanceStore) -> ToolOutput {
        AccountDraftBuilder(turn: turn, store: store).run(arguments)
    }
}

/// The checks behind `AddAccount`, account by account, adding nothing.
struct AccountDraftBuilder {
    let turn: RecordTurn
    let store: FinanceStore

    enum Outcome {
        case ready(AccountDraft.Row)
        case needs(DraftBuilder.Need)
        case refused(reason: String, howTo: String?)
    }

    static let goalRefusal = RecordRefusal.Kind(
        reason: "Milu chưa tạo được hũ tiết kiệm: tính năng này chưa có, Milu sẽ cập nhật sau nha.",
        ways: ["Tài khoản → nút + ở góc trên → Hũ tiết kiệm."])

    func run(_ arguments: JSONValue) -> ToolOutput {
        var inputs = Self.items(arguments)
        // Beside a new one, an account just added from this chat's card was copied from the chat:
        // left out ("thêm ví zalopay" after "BIDV lương" was saved asked about both, Simulator
        // 2026-11-20). Alone, it is asked for again, and asked about as a name taken.
        let added = turn.addedAccounts.compactMap { store.account(id: $0)?.name.searchKey }
        let fresh = inputs.filter { !added.contains(Self.saidName(of: $0).searchKey) }
        if !fresh.isEmpty, fresh.count < inputs.count { inputs = fresh }
        var ref = (arguments["replaces"]?.string ?? "").lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        // The code of a card since replaced, one card of accounts still waiting: that one is meant
        // (live test 2026-11-20: changed twice, the model sent the first card's code, and was told
        // it was saved).
        if !ref.isEmpty, !turn.openAccounts.contains(where: { $0.ref == ref }), turn.openAccounts.count == 1,
           let waiting = turn.openAccounts.first {
            ref = waiting.ref
        }
        if inputs.isEmpty, !ref.isEmpty { return showAgain(ref) }
        guard !inputs.isEmpty else {
            return .failure("Không có tài khoản nào để thêm. Hỏi người dùng muốn thêm tài khoản nào, số dư bao nhiêu; chưa thêm gì")
        }
        var replacing: AccountDraft?
        if let card = turn.openAccounts.last(where: { $0.ref == ref }) {
            replacing = card
        } else if !ref.isEmpty, turn.seenAccounts.contains(ref) {
            return Self.notWaiting(ref)
        }
        var rows: [AccountDraft.Row] = []
        var needs: [JSONValue] = []
        var refused: [JSONValue] = []
        for (index, input) in inputs.enumerated() {
            switch resolve(input, beside: rows, replacing: replacing, alone: inputs.count == 1) {
            case .ready(let row):
                rows.append(row)
            case .needs(let need):
                var item: [String: JSONValue] = ["index": .number(Double(index + 1)), "missing": .string(need.missing),
                                                 "ask": .string(need.ask)]
                if !need.options.isEmpty { item["options"] = .array(need.options.map(JSONValue.string)) }
                let about = Self.about(input)
                if !about.isEmpty { item["about"] = .string(about) }
                needs.append(.object(item))
            case .refused(let reason, let howTo):
                var item: [String: JSONValue] = ["index": .number(Double(index + 1)), "reason": .string(reason)]
                if let howTo { item["howTo"] = .string(howTo) }
                refused.append(.object(item))
            }
        }
        if !needs.isEmpty {
            var result: [String: JSONValue] = [
                "ok": true, "status": "needsInfo", "items": .array(needs),
                "say": .string("Hỏi người dùng đúng câu ask của từng tài khoản, rồi gọi lại add_account với đủ mọi tài khoản"
                    + (replacing == nil ? "" : " và replaces như lần này") + ". Chưa soạn, chưa thêm gì: không nói đã soạn hay đã thêm."),
            ]
            if !refused.isEmpty { result["rejected"] = .array(refused) }
            return ToolOutput(result: .object(result))
        }
        guard !rows.isEmpty else {
            return ToolOutput(result: [
                "ok": false, "status": "rejected", "items": .array(refused),
                "say": "Không thêm gì, không soạn gì. Nói thật là Milu chưa làm được (reason), rồi chép nguyên văn cách làm tay (howTo); không hỏi thêm gì.",
            ])
        }
        let draft = AccountDraft(rows: rows, replacing: replacing?.id)
        var result: [String: JSONValue] = [
            "ok": true, "status": "draft", "card": .string(draft.ref),
            "rows": .array(rows.enumerated().map { describe($0.element, number: $0.offset + 1) }),
            "say": .string("Đã soạn, CHƯA thêm gì. Nói ngắn gọn: người dùng kiểm tra tài khoản Milu soạn rồi bấm Lưu; không nói đã thêm, không gọi là thẻ, không nói mã."
                + (refused.isEmpty ? "" : " Nói thêm cái nào chưa làm được, lý do, rồi chép nguyên văn cách làm tay (howTo).")),
        ]
        if !refused.isEmpty { result["rejected"] = .array(refused) }
        return ToolOutput(result: .object(result), action: .accountDraft(draft))
    }

    /// The card waiting under `ref` shown again at the foot of the chat, as it is.
    func showAgain(_ ref: String) -> ToolOutput {
        guard let card = turn.openAccounts.last(where: { $0.ref == ref }), !card.rows.isEmpty else {
            return Self.notWaiting(ref)
        }
        let draft = AccountDraft(rows: card.rows, replacing: card.id)
        return ToolOutput(result: [
            "ok": true, "status": "draft", "card": .string(draft.ref),
            "rows": .array(draft.rows.enumerated().map { describe($0.element, number: $0.offset + 1) }),
            "say": "Đã hiện lại ở cuối chat, CHƯA thêm gì. Nói ngắn: tài khoản ở bên dưới, người dùng kiểm tra rồi bấm Lưu; không gọi là thẻ, không nói mã.",
        ], action: .accountDraft(draft))
    }

    static func notWaiting(_ ref: String) -> ToolOutput {
        ToolOutput(result: [
            "ok": false, "status": "rejected",
            "reason": .string("Thẻ tài khoản #\(ref) không còn chờ Lưu: đã lưu, đã huỷ hoặc đã thay."),
            "howTo": "Tài khoản đã thêm thì sửa ở tab Tài khoản → chọn tài khoản → bút chì ở góc trên.",
            "say": "Chưa soạn gì. Muốn thêm tài khoản khác thì gọi lại add_account, không gửi replaces. Không nói tên công cụ hay mã thẻ với người dùng.",
        ])
    }

    /// The items the model sent: `accounts`, one at the top, or the list as a JSON string.
    static func items(_ arguments: JSONValue) -> [JSONValue] {
        func objects(_ items: [JSONValue]) -> [JSONValue] { items.filter { if case .object = $0 { true } else { false } } }
        switch arguments["accounts"] {
        case .array(let items): return objects(items)
        case .string(let text):
            if let data = text.data(using: .utf8), let decoded = try? JSONDecoder().decode(JSONValue.self, from: data),
               case .array(let items) = decoded { return objects(items) }
            return []
        case .object: return arguments["accounts"].map { [$0] } ?? []
        default:
            let fields = ["type", "institution", "name", "balance", "balance_said"]
            return fields.contains(where: { arguments[$0] != nil }) ? [arguments] : []
        }
    }

    /// A yes to the question about a name taken ("thêm tài khoản mới", "ok", "có"): the call that
    /// asked, made again with `same_name_ok`, its card Milu's answer. Nil for any other words.
    @MainActor
    static func answer(_ said: String, to asked: ChatMessage.AskedCall, history: [ChatMessage],
                       store: FinanceStore) -> AssistantReply? {
        guard asked.name == AddAccount().name, case .array(let items)? = asked.result["items"],
              items.contains(where: { $0["missing"] == "duplicate" }),
              items.allSatisfy({ $0["missing"] == "duplicate" }) else { return nil }
        let words = " " + said.searchKey.split { !$0.isLetter && !$0.isNumber }.joined(separator: " ") + " "
        let yes = [" them moi ", " tai khoan moi ", " them nua ", " van them ", " them di ", " them luon "]
        guard yes.contains(where: words.contains) || DraftShortcut.match(said) == .save else { return nil }
        guard case .array(let accounts)? = asked.arguments["accounts"] else { return nil }
        let marked: [JSONValue] = accounts.map { account in
            guard case .object(var fields) = account else { return account }
            fields["same_name_ok"] = true
            return .object(fields)
        }
        var arguments: [String: JSONValue] = ["accounts": .array(marked)]
        if case .object(let original) = asked.arguments, let ref = original["replaces"] { arguments["replaces"] = ref }
        let turn = RecordTurn(userWords: history.filter { $0.role == .user }.suffix(3).map(\.text) + [said],
                              openAccounts: history.compactMap(\.pendingAccountDraft))
        let output = AddAccount(turn: turn).run(.object(arguments), in: store)
        guard case .accountDraft(let draft) = output.action else { return nil }
        return AssistantReply(text: RemoteAssistant.draftReady, actions: [.accountDraft(draft)], counts: false)
    }

    /// The name an item gives, as it would be on the card: its own, else its bank's short name.
    static func saidName(of input: JSONValue) -> String {
        let name = Category.cleanName(input["name"]?.string ?? "")
        if !name.isEmpty, case .found(let institution) = institution(withoutTypeWords(name)), isOnly(institution, withoutTypeWords(name)) {
            return institution.shortName
        }
        if !name.isEmpty { return name }
        let said = withoutTypeWords(Category.cleanName(input["institution"]?.string ?? ""))
        if case .found(let institution) = institution(said) { return institution.shortName }
        return said
    }

    /// The account asked about, short: "MoMo", "Techcombank 5.000.000đ".
    static func about(_ input: JSONValue) -> String {
        let name = Category.cleanName(input["name"]?.string ?? "")
        let institution = Category.cleanName(input["institution"]?.string ?? "")
        let shown = name.isEmpty ? institution : name
        let balance = input["balance"]?.number.map { abs($0.rounded()).vnd }
        return [shown.isEmpty ? nil : shown.capitalizedFirstLetter, balance].compactMap { $0 }.joined(separator: " ")
    }

    /// The question back in the app's own words, for the chat to say as Milu's answer: one ask
    /// alone as it is; several, one line each under a lead.
    static func question(in result: JSONValue) -> String? {
        guard result["status"] == "needsInfo", case .array(let items)? = result["items"] else { return nil }
        var asks: [(about: String, ask: String)] = []
        for item in items {
            guard let ask = item["ask"]?.string, !ask.isEmpty, !asks.contains(where: { $0.ask == ask }) else { continue }
            asks.append((item["about"]?.string ?? "", ask))
        }
        guard let first = asks.first else { return nil }
        guard asks.count > 1 else { return first.ask }
        return (["Milu cần hỏi thêm \(asks.count) chỗ trước khi soạn nè 👀"] + asks.map { "• \($0.ask)" })
            .joined(separator: "\n")
    }

    // MARK: - One account

    enum TypeWord { case cash, bank, eWallet, goal, unclear, unknown }

    static func typeWord(_ text: String?) -> TypeWord {
        let key = (text ?? "").searchKey.trimmingCharacters(in: .whitespaces)
        switch key {
        case "cash", "tien mat": return .cash
        case "bank", "ngan hang", "tai khoan ngan hang", "credit", "credit card", "the tin dung": return .bank
        case "ewallet", "e-wallet", "e wallet", "wallet", "vi", "vi dien tu": return .eWallet
        case "goal", "saving", "savings", "hu", "hu tiet kiem", "tiet kiem": return .goal
        case "", "unclear", "unknown": return .unclear
        default: return .unknown
        }
    }

    /// `beside`: the rows already made from this sentence, whose names are taken too.
    /// `replacing`: the card being changed, whose names (one Milu numbered) are kept.
    /// `alone`: the only account of the sentence, whose kind may be read from the user's words.
    func resolve(_ input: JSONValue, beside rows: [AccountDraft.Row] = [], replacing: AccountDraft? = nil,
                 alone: Bool = true) -> Outcome {
        let said = turn.userWords.last ?? ""
        let saysCredit = said.searchKey.contains("tin dung") || said.searchKey.contains("credit")
        var type: AccountType?
        switch Self.typeWord(input["type"]?.string) {
        case .cash: type = .cash
        case .bank: type = .bank
        case .eWallet: type = .eWallet
        case .goal: return .refused(reason: Self.goalRefusal.reason, howTo: Self.goalRefusal.howTo)
        case .unclear, .unknown: type = nil
        }
        var institutionText = Self.withoutTypeWords(Category.cleanName(input["institution"]?.string ?? ""))
        var name = String(Category.cleanName(input["name"]?.string ?? "").prefix(60))
        // A kind sent as a name ("tiền mặt"): the kind, no name.
        for text in [institutionText, name] where type == nil {
            if case let word = Self.typeWord(text), [.cash, .bank, .eWallet].contains(word) {
                type = word == .cash ? .cash : word == .bank ? .bank : .eWallet
            }
        }
        if Self.typeWord(institutionText) != .unknown { institutionText = "" }
        if Self.typeWord(name) != .unknown { name = "" }
        // "thêm tài khoản mới" said to the question about a name taken: "Mới" is no name (live test
        // 2026-11-20).
        let fillers: Set<String> = ["moi", "khac", "nua", "moi nua", "khac nua", "tai khoan moi", "tai khoan khac"]
        if fillers.contains(Self.withoutTypeWords(name).searchKey) || fillers.contains(name.searchKey) { name = "" }
        // The kind the user said, the model leaving it out ("thêm tiền mặt 200k", live test
        // 2026-11-20): for one account alone, the words being the user's.
        if type == nil, alone {
            let words = " " + said.searchKey.split { !$0.isLetter && !$0.isNumber }.joined(separator: " ") + " "
            if words.contains(" tien mat ") { type = .cash }
            else if words.contains(" ngan hang ") { type = .bank }
            else if words.contains(" vi dien tu ") { type = .eWallet }
        }

        // Which bank or wallet: the one named, or one in the name ("Techcombank lương").
        var institution: Institution?
        var notFound: (said: String, close: [Institution])?
        for text in [institutionText, Self.withoutTypeWords(name)] where !text.isEmpty {
            switch Self.institution(text) {
            case .found(let found): institution = found
            case .ambiguous(let close): notFound = notFound ?? (text, close)
            case .none: notFound = notFound ?? (text, [])
            }
            if institution != nil { break }
        }
        // Said to the model alone, as a name: a name of its own when it is more than the bank's.
        if let institution, Self.isOnly(institution, Self.withoutTypeWords(name)) { name = "" }

        var notices: [String] = []
        if let institution {
            let kind: AccountType = institution.kind == .bank ? .bank : .eWallet
            if let type, type != kind {
                notices.append("\(institution.shortName) là \(kind == .bank ? "ngân hàng" : "ví điện tử"), Milu để loại \(kind.title).")
            }
            type = kind
        } else if type == .cash {
            // Cash with a bank's name not found ("tiền mặt ABC"): a name, nothing more.
            notFound = nil
            if name.isEmpty, !institutionText.isEmpty { name = institutionText }
        }

        guard let type else {
            if let notFound, !notFound.close.isEmpty {
                return .needs(DraftBuilder.Need(
                    missing: "institution",
                    ask: "“\(notFound.said)” là \(Self.listed(notFound.close.map(\.shortName))) hay tài khoản nào khác nè? 🧐",
                    options: notFound.close.map(\.shortName)))
            }
            let named = name.isEmpty ? (notFound?.said ?? "") : name
            let what = named.isEmpty ? "Tài khoản này" : "“\(named.capitalizedFirstLetter)”"
            return .needs(DraftBuilder.Need(
                missing: "type",
                ask: "\(what) là tiền mặt, tài khoản ngân hàng hay ví điện tử nè? Ngân hàng hay ví thì nói tên luôn nha (ví dụ: Vietcombank, MoMo) 🤔",
                options: ["Tiền mặt", "Ngân hàng", "Ví điện tử"]))
        }
        if type != .cash, institution == nil {
            let word = type == .eWallet ? "ví điện tử" : "ngân hàng"
            if let notFound {
                if !notFound.close.isEmpty {
                    return .needs(DraftBuilder.Need(
                        missing: "institution",
                        ask: "“\(notFound.said)” là \(Self.listed(notFound.close.map(\.shortName))) nè? 🧐",
                        options: notFound.close.map(\.shortName)))
                }
                return .needs(DraftBuilder.Need(
                    missing: "institution",
                    ask: "Milu không thấy \(word) “\(notFound.said)” trong danh sách 🧐 Bạn nói lại tên \(word) giúp Milu nha (ví dụ: \(type == .eWallet ? "MoMo, ZaloPay, ShopeePay" : "Vietcombank, Techcombank, MB Bank")).",
                    options: []))
            }
            let named = name.isEmpty ? "" : " “\(name)”"
            return .needs(DraftBuilder.Need(
                missing: "institution",
                ask: type == .eWallet
                    ? "Ví\(named) là ví điện tử nào nè? (ví dụ: MoMo, ZaloPay, ShopeePay) 🤔"
                    : "Tài khoản\(named) ở ngân hàng nào nè? (ví dụ: Vietcombank, Techcombank, MB Bank) 🤔",
                options: []))
        }
        if name.isEmpty { name = institution?.shortName ?? "Tiền mặt" }

        // The same name as one the user has: asked first (user choice 2026-11-20); once the user
        // said to add it all the same, numbered ("Techcombank 2").
        let sameOK: Bool = if case .bool(true)? = input["same_name_ok"] { true } else { false }
        let kept = replacing?.rows.first { row in
            row.account.name.searchKey.hasPrefix(name.searchKey + " ")
                && Int(row.account.name.searchKey.dropFirst(name.searchKey.count + 1)) != nil
                && row.account.institutionID == institution?.id
        }
        if let kept {
            name = kept.account.name
        } else if let twin = taken(name, beside: rows) {
            if sameOK || twin.inCard {
                let numbered = numbered(name, beside: rows)
                notices.append("Đã có “\(name)”, Milu đặt tên “\(numbered)”.")
                name = numbered
            } else if let account = twin.account {
                let path = account.isArchived
                    ? "Còn muốn dùng lại tài khoản cũ thì vào Tài khoản → Tài khoản đã lưu trữ → \(account.name) → bút chì → Khôi phục tài khoản nha."
                    : "Còn muốn sửa số dư tài khoản cũ thì vào Tài khoản → \(account.name) → bút chì ở góc trên nha."
                let held = account.isArchived ? "đã lưu trữ" : account.balance.vnd
                return .needs(DraftBuilder.Need(
                    missing: "duplicate",
                    ask: "Bạn có tài khoản “\(account.name)” (\(held)) rồi nè 👀 Thêm một tài khoản \(name) nữa không? \(path)",
                    options: ["Thêm tài khoản mới"]))
            }
        }

        // By its name, else by its bank, else the card's only row ("đổi tên thành BIDV lương").
        let previous = replacing.flatMap { card -> AccountDraft.Row? in
            if let named = card.rows.first(where: { $0.account.name.searchKey == name.searchKey }) { return named }
            let sameBank = card.rows.filter { $0.account.institutionID != nil && $0.account.institutionID == institution?.id }
            if sameBank.count == 1, !rows.contains(where: { $0.id == sameBank[0].id }) { return sameBank[0] }
            return card.rows.count == 1 && rows.isEmpty ? card.rows[0] : nil
        }
        // Balance: said, and the one the user said.
        let balanceSaid = input["balance_said"]?.string ?? ""
        let negative: Bool = if case .bool(true)? = input["negative"] { true } else { saysCredit && type == .bank }
        // Changing a card ("đổi tên thành BIDV lương"), what is not said again stays as it was.
        let keptBalance: Double? = previous.map { $0.account.balance }
        guard let raw = input["balance"]?.number ?? (balanceSaid.isEmpty ? nil : SaidAmount.parse(balanceSaid)) ?? keptBalance,
              raw.isFinite else {
            return .needs(DraftBuilder.Need(
                missing: "balance",
                ask: negative
                    ? "“\(name)” đang nợ bao nhiêu nè? 💳"
                    : "“\(name)” đang có bao nhiêu tiền nè? Chưa có đồng nào thì nói “0đ” nha 💸",
                options: []))
        }
        let amount = abs(raw.rounded())
        guard amount <= MiluAmountField.maxAmount else {
            return .refused(reason: "Số dư quá lớn: Milu ghi tối đa \(MiluAmountField.maxAmount.vnd).", howTo: nil)
        }
        var warning: String?
        let heard = SaidAmount.all(in: turn.userWords.joined(separator: " "))
            .union(replacing.map { Set($0.rows.map { abs($0.account.balance) }) } ?? [])
        if !balanceSaid.isEmpty, let read = SaidAmount.parse(balanceSaid), read != amount {
            warning = "\(name): bạn nói “\(balanceSaid)” (\(read.vnd)), Milu để \(amount.vnd). Kiểm tra lại số dư nhé."
        } else if amount > 0, !turn.userWords.isEmpty, !heard.isEmpty, !heard.contains(amount) {
            warning = "\(name): Milu không thấy \(amount.vnd) trong lời bạn. Kiểm tra lại số dư nhé."
        }
        let balance = (negative || raw < 0) && amount > 0 ? -amount : amount
        if balance < 0, saysCredit { notices.append("Số dư âm của \(name) là số bạn đang nợ.") }

        // A card made again keeps its rows' ids, so the form's edits and the chat's card match.
        var account = Account(name: name, type: type, balance: balance,
                              detail: String(Category.cleanName(input["note"]?.string ?? "").prefix(200)),
                              institutionID: institution?.id, openedAt: turn.now)
        if let previous {
            account.id = previous.account.id
            account.openedAt = previous.account.openedAt
            account.isLocked = previous.account.isLocked
            if account.detail.isEmpty { account.detail = previous.account.detail }
        }
        if DraftBuilder.note(account.detail).isEmpty { account.detail = "" }
        return .ready(AccountDraft.Row(account: account, notice: notices.isEmpty ? nil : notices.joined(separator: " "),
                                       warning: warning))
    }

    /// The account, or the row of this card, already holding `name`.
    private func taken(_ name: String, beside rows: [AccountDraft.Row]) -> (account: Account?, inCard: Bool)? {
        let key = name.searchKey
        if rows.contains(where: { $0.account.name.searchKey == key }) { return (nil, true) }
        if let account = (store.accounts + store.archivedAccounts).first(where: { $0.name.searchKey == key }) {
            return (account, false)
        }
        return nil
    }

    /// "Techcombank 2", or the next number free.
    private func numbered(_ name: String, beside rows: [AccountDraft.Row]) -> String {
        var number = 2
        while taken("\(name) \(number)", beside: rows) != nil { number += 1 }
        return "\(name) \(number)"
    }

    // MARK: - Banks and wallets

    enum InstitutionMatch: Equatable {
        case found(Institution)
        case ambiguous([Institution])
        case none
    }

    /// The bank or wallet `text` names: its short name, id or keyword exactly ("vcb", "momo"); or
    /// the one the catalogue's search puts first when no other starts the same; or one named inside
    /// it ("Techcombank lương"). A few to pick when unsure, none when nothing is close.
    static func institution(_ text: String) -> InstitutionMatch {
        let key = compact(text)
        guard !key.isEmpty else { return .none }
        let exact = Institution.all.filter { names(of: $0).contains(key) }
        if exact.count == 1 { return .found(exact[0]) }
        if exact.count > 1 { return .ambiguous(Array(exact.prefix(3))) }
        let found = Institution.search(text, in: Institution.all)
        let starting = found.filter { compact($0.shortName).hasPrefix(key) }
        if starting.count == 1 { return .found(starting[0]) }
        if let inside = named(in: text) { return .found(inside) }
        if starting.count > 1 { return .ambiguous(Array(starting.prefix(3))) }
        return found.isEmpty ? .none : .ambiguous(Array(found.prefix(3)))
    }

    /// A bank or wallet named as whole words inside `text`, the longest name first.
    static func named(in text: String) -> Institution? {
        let words = text.searchKey.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        var best: (institution: Institution, length: Int)?
        for institution in Institution.all {
            let names = ([institution.shortName, institution.id] + institution.keywords)
                .map { $0.searchKey.split { !$0.isLetter && !$0.isNumber }.map(String.init) }
                .filter { !$0.isEmpty }
            for name in names where words.indices.contains(where: { words[$0...].starts(with: name) }) {
                let length = name.joined().count
                // "a chau" is one keyword, two letters a word: short ones only as a whole name.
                guard length >= 3 else { continue }
                if length > best?.length ?? 0 { best = (institution, length) }
            }
        }
        return best?.institution
    }

    /// Whether `text` says only the bank's name ("techcombank", "vcb"), nothing of its own.
    static func isOnly(_ institution: Institution, _ text: String) -> Bool {
        text.isEmpty || names(of: institution).contains(compact(text))
    }

    private static func names(of institution: Institution) -> Set<String> {
        Set(([institution.shortName, institution.id] + institution.keywords).map(compact))
    }

    private static func compact(_ text: String) -> String {
        text.searchKey.filter { $0.isLetter || $0.isNumber }
    }

    /// The words of a kind of account in front of a name: "tài khoản Techcombank" is "Techcombank",
    /// "ví momo" is "momo".
    static func withoutTypeWords(_ text: String) -> String {
        var words = text.split(separator: " ").map(String.init)
        let leads: [[String]] = [["tai", "khoan", "ngan", "hang"], ["tai", "khoan"], ["ngan", "hang"], ["vi", "dien", "tu"],
                                 ["the", "tin", "dung"], ["the", "ngan", "hang"], ["the"], ["vi"], ["tk"], ["bank"]]
        var changed = true
        while changed, !words.isEmpty {
            changed = false
            for lead in leads where words.count > lead.count && words.prefix(lead.count).map(\.searchKey) == lead {
                words.removeFirst(lead.count)
                changed = true
                break
            }
        }
        return words.joined(separator: " ")
    }

    private static func listed(_ names: [String]) -> String {
        names.count < 2 ? names.joined() : names.dropLast().joined(separator: ", ") + " hay " + (names.last ?? "")
    }

    // MARK: - For the model

    func describe(_ row: AccountDraft.Row, number: Int) -> JSONValue {
        let account = row.account
        var item: [String: JSONValue] = [
            "row": .number(Double(number)),
            "type": .string(Self.typeName(account.type)),
            "name": .string(account.name),
            "balance": ToolMoney.value(account.balance),
            "balanceText": .string(account.balance < 0 ? "−" + abs(account.balance).vnd : account.balance.vnd),
        ]
        if let institution = account.institution { item["institution"] = .string(institution.shortName) }
        if !account.detail.isEmpty { item["note"] = .string(account.detail) }
        if let notice = row.notice { item["notice"] = .string(notice) }
        if let warning = row.warning { item["warning"] = .string(warning) }
        return .object(item)
    }

    /// The type as the tool takes it.
    static func typeName(_ type: AccountType) -> String {
        switch type {
        case .cash: "cash"
        case .bank, .credit: "bank"
        case .eWallet: "ewallet"
        }
    }

    /// A card's rows as the call that would make them again (`RemoteAssistant.cardExchange`).
    static func arguments(of draft: AccountDraft) -> JSONValue {
        .array(draft.rows.map { row in
            let account = row.account
            var item: [String: JSONValue] = [
                "type": .string(typeName(account.type)),
                "name": .string(account.name),
                "balance": ToolMoney.value(abs(account.balance)),
            ]
            if account.balance < 0 { item["negative"] = true }
            if let institution = account.institution { item["institution"] = .string(institution.shortName) }
            if !account.detail.isEmpty { item["note"] = .string(account.detail) }
            return .object(item)
        })
    }
}

/// "Lưu" on a card of accounts: everything checked again, then all added, or none with why on the
/// rows that cannot be.
enum AccountDraftSaver {
    static func problems(of draft: AccountDraft, in store: FinanceStore) -> [UUID: String] {
        var problems: [UUID: String] = [:]
        var names: [String: UUID] = [:]
        for row in draft.rows where store.account(id: row.id) == nil {
            let account = row.account
            let name = account.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                problems[row.id] = "Tên tài khoản đang trống."
            } else if let twin = (store.accounts + store.archivedAccounts).first(where: { $0.name.searchKey == name.searchKey }) {
                problems[row.id] = "Đã có tài khoản “\(twin.name)”: đổi tên khác nhé."
            } else if names[name.searchKey] != nil {
                problems[row.id] = "Trùng tên với tài khoản khác trên đây."
            }
            names[name.searchKey] = row.id
            if account.type != .cash, account.institution == nil {
                problems[row.id] = problems[row.id] ?? (account.type == .eWallet ? "Chưa chọn ví điện tử." : "Chưa chọn ngân hàng.")
            }
            if abs(account.balance) > MiluAmountField.maxAmount {
                problems[row.id] = problems[row.id] ?? "Số dư không hợp lệ."
            }
        }
        return problems
    }

    /// Adds every account of the card not added yet, and gives back the card as it now is. Safe to
    /// call twice.
    static func save(_ draft: AccountDraft, in store: FinanceStore) -> AccountDraft {
        guard draft.isPending else { return draft }
        var draft = draft
        let problems = problems(of: draft, in: store)
        for index in draft.rows.indices { draft.rows[index].problem = problems[draft.rows[index].id] }
        guard problems.isEmpty else {
            draft.problem = problems.count == 1 && draft.rows.count == 1
                ? "Chưa lưu được." : "Chưa lưu được: \(problems.count) tài khoản cần sửa."
            return draft
        }
        var added: [Account] = []
        store.persist {
            for row in draft.rows where store.account(id: row.id) == nil {
                var account = row.account
                account.name = account.name.trimmingCharacters(in: .whitespacesAndNewlines)
                store.add(account)
                if store.account(id: row.id) != nil { added.append(account) }
            }
        }
        let missing = draft.rows.filter { store.account(id: $0.id) == nil }
        guard missing.isEmpty else {
            store.persist { for account in added { store.delete(account) } }
            for index in draft.rows.indices where missing.contains(where: { $0.id == draft.rows[index].id }) {
                draft.rows[index].problem = "Chưa lưu được tài khoản này."
            }
            draft.problem = "Có tài khoản chưa lưu được."
            return draft
        }
        draft.state = .saved
        draft.problem = nil
        return draft
    }
}
