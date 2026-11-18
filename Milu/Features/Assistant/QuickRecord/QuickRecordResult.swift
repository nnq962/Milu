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
