import Foundation

/// What the quick sheet ("Thêm bằng AI") shows for Milu's answer to a sentence to record (user
/// design 2026-11-17): a card waiting for "Lưu", a question back with answers to tap, what Milu
/// cannot record yet with the form to do it by hand, or that the sentence was no record at all.
enum QuickRecordResult: Equatable {
    /// A card waiting for "Lưu"; `note`, the app's words over it when part of the sentence was
    /// refused.
    case card(TransactionDraft, note: String?)
    /// Asked something back (an amount, an item it is unsure of), and answers to tap.
    case asking(String, choices: [String])
    /// Not recorded, in the app's words, and the form to do it by hand when there is one.
    case refused(String, form: QuickRecordForm?)
    /// No transaction to record (a question): the chat is the place for it. The model's words are
    /// not shown: given the record tool alone, it has no figures to answer from.
    case notRecord

    static func of(_ reply: AssistantReply, said: String) -> QuickRecordResult {
        let card = reply.actions.compactMap { action -> TransactionDraft? in
            if case .draft(let draft) = action { draft } else { nil }
        }.last
        if let card {
            return .card(card, note: reply.refused.isEmpty ? nil : RecordRefusal.message(reply.refused))
        }
        if !reply.refused.isEmpty {
            let form = QuickRecordForm.of(reply.refused, said: said)
            // With the form's button under it, the way by hand ("Nút + → …") said nothing more.
            let message = if let form, reply.refused.count == 1 { form.message } else { RecordRefusal.message(reply.refused) }
            return .refused(message, form: form)
        }
        // The tool's own short question, over the model's longer one.
        if reply.asksBack { return .asking(reply.asked ?? reply.text, choices: reply.choices) }
        return .notRecord
    }
}

/// Words said under a card waiting for "Lưu", to change it (user request 2026-11-19: once the
/// card showed, a wrong amount meant its form or the whole sentence again). The card stays over
/// them; what Milu answers does one of three things to it.
enum QuickRecordFix: Equatable {
    /// A new card in its place.
    case changed
    /// A question first, the card still over it until the answer.
    case asked
    /// Not changed: the card back as it was, and why under it.
    case unchanged(String)

    /// `before`, the card the words were said under.
    static func of(_ result: QuickRecordResult, refused: [RecordRefusal.Refused],
                   before: TransactionDraft? = nil) -> QuickRecordFix {
        switch result {
        // The same card again (Simulator 2026-11-19: "sửa giúp mình cái đó" came back as it was,
        // and the sheet seemed not to have heard): nothing to change was understood.
        case .card(let draft, _) where before.map { sameRows(draft, $0) } ?? false: .unchanged(notUnderstood)
        case .card: .changed
        case .asking: .asked
        // The card still there to save, no form's button beside it: the way by hand is said.
        case .refused: .unchanged(RecordRefusal.message(refused))
        // Words Milu made no record of ("sửa giúp mình", a question): the card is the same.
        case .notRecord: .unchanged(notUnderstood)
        }
    }

    static let notUnderstood = "Milu chưa hiểu cần sửa gì. Bạn hãy nói rõ khoản nào và sửa thành gì."

    /// Whether two cards hold the same transactions, whatever their ids: the kind, amount, item,
    /// account and note of each, and its moment within a few minutes (one said with no time is
    /// made at the moment the card is, again on a card sent back as it was).
    static func sameRows(_ one: TransactionDraft, _ other: TransactionDraft) -> Bool {
        let rows = one.liveRows, others = other.liveRows
        guard rows.count == others.count else { return false }
        return zip(rows, others).allSatisfy { row, other in
            let a = row.transaction, b = other.transaction
            return a.kind == b.kind && a.amount == b.amount && a.categoryID == b.categoryID
                && a.accountID == b.accountID && a.note == b.note && row.newItem == other.newItem
                && abs(a.date.timeIntervalSince(b.date)) < 10 * 60
        }
    }

    /// The exchange with the card `id` waiting no more: a newer one took its place, so Milu reads
    /// one card to change, not two (and in the chat's words, "đã thay bằng bản mới").
    static func replacing(_ id: UUID, in history: [ChatMessage]) -> [ChatMessage] {
        history.map { message in
            guard var draft = message.pendingDraft, draft.id == id else { return message }
            draft.state = .replaced
            var message = message
            message.card = .draft(draft)
            return message
        }
    }

    /// The exchange with the card as it now is: a row changed in its form, or taken off it, or
    /// why it could not be saved.
    static func updating(_ draft: TransactionDraft, in history: [ChatMessage]) -> [ChatMessage] {
        history.map { message in
            guard case .draft(let old) = message.card, old.id == draft.id else { return message }
            var message = message
            message.card = .draft(draft)
            return message
        }
    }
}

/// The manual form for what Milu could not record, the amount said already in it (user choice
/// 2026-11-17). None for a goal (which one is the user's to pick on its page) or a repayment (it
/// goes on a loan already there).
enum QuickRecordForm: Hashable {
    case transfer(amount: Double?)
    case loan(LoanDirection, amount: Double?)

    var title: String {
        switch self {
        // Plain words, not the English "form" (user review 2026-11-18).
        case .transfer: "Ghi chuyển khoản thủ công"
        case .loan: "Ghi khoản vay thủ công"
        }
    }

    /// Over its button, what Milu cannot record and that the button does it, in a line: the
    /// chat's "…: tính năng này chưa có." read cold over a button that answers it (user review
    /// 2026-11-18).
    var message: String {
        switch self {
        case .transfer: "Milu chưa hỗ trợ ghi chuyển khoản, rút tiền hoặc nạp ví. Bạn có thể ghi thủ công."
        case .loan: "Milu chưa hỗ trợ ghi khoản vay. Bạn có thể ghi thủ công."
        }
    }

    static func of(_ refused: [RecordRefusal.Refused], said: String) -> QuickRecordForm? {
        let amount = SaidAmount.parse(said)
        let tokens = said.searchKey.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        let words = " " + tokens.joined(separator: " ") + " "
        func has(_ phrases: [String]) -> Bool { phrases.contains { words.contains(" \($0) ") } }
        for item in refused {
            if item.reason == RecordRefusal.transfer.reason { return .transfer(amount: amount) }
            if item.reason == RecordRefusal.loan.reason {
                if has(["tra no", "thu no", "tra lai", "tra tien", "tra bot", "tra het"]) { return nil }
                // "cho (Tuấn) mượn", "cho vay": lent; "vay", "mượn (của)": borrowed; neither: lent,
                // the form's own first side.
                guard let verb = tokens.firstIndex(where: { $0 == "vay" || $0 == "muon" }) else {
                    return .loan(.lent, amount: amount)
                }
                let lent = tokens[..<verb].contains("cho")
                return .loan(lent ? .lent : .borrowed, amount: amount)
            }
        }
        return nil
    }
}

/// What opens once the quick sheet has gone: a form to do by hand what Milu could not, or the
/// chat with the sentence in its field.
enum QuickRecordNext: Hashable {
    case form(QuickRecordForm)
    case chat(String)
}
