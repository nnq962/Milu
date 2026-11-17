import Foundation

/// "Lưu" on a card of transactions (`TransactionDraft`): everything checked again, since the card
/// may have waited (an account locked or archived since, an item hidden), then all saved, or none
/// with why on the rows that cannot be (user choice 2026-11-17).
enum DraftSaver {
    /// Why each row could not be saved now, by its transaction's id; empty when all can.
    static func problems(of draft: TransactionDraft, in store: FinanceStore, now: Date = .now) -> [UUID: String] {
        var problems: [UUID: String] = [:]
        let calendar = Calendar.current
        for row in draft.liveRows where store.transaction(id: row.id) == nil {
            let transaction = row.transaction
            // `account(id:)` finds archived ones too: they are asked about first.
            if let account = store.account(id: transaction.accountID) {
                if account.isArchived {
                    problems[row.id] = "Tài khoản “\(account.name)” đã lưu trữ: chọn tài khoản khác."
                } else if account.isLocked {
                    problems[row.id] = "Tài khoản “\(account.name)” đang khoá: chọn tài khoản khác."
                }
            } else {
                problems[row.id] = "Tài khoản này không còn: chọn tài khoản khác."
            }
            if let item = row.newItem {
                let group = store.category(id: item.groupID)
                if group == nil || group?.isHidden == true || group?.kind != transaction.kind {
                    problems[row.id] = problems[row.id] ?? "Nhóm của mục mới không còn: chọn hạng mục khác."
                } else if let twin = store.item(named: item.name, inGroup: item.groupID), twin.isHidden {
                    problems[row.id] = problems[row.id] ?? "“\(twin.name)” đang ẩn: chọn hạng mục khác."
                }
            } else if !store.pickableItems(transaction.kind).contains(where: { $0.id == transaction.categoryID }) {
                problems[row.id] = problems[row.id] ?? "Hạng mục “\(store.categoryName(transaction.categoryID))” đã ẩn hoặc đã xoá: chọn mục khác."
            }
            if transaction.amount < 1 || transaction.amount > MiluAmountField.maxAmount {
                problems[row.id] = problems[row.id] ?? "Số tiền không hợp lệ."
            }
            if calendar.startOfDay(for: transaction.date) > calendar.startOfDay(for: now) {
                problems[row.id] = problems[row.id] ?? "Ngày này chưa tới."
            }
        }
        return problems
    }

    /// Saves every row of the card that is not saved yet, making its new items first, and gives
    /// back the card as it now is: saved, or unchanged with why on the rows that stopped it. Safe
    /// to call twice: a row already saved is not added again.
    static func save(_ draft: TransactionDraft, in store: FinanceStore, defaults: UserDefaults = .standard,
                     now: Date = .now) -> TransactionDraft {
        guard draft.isPending else { return draft }
        var draft = draft
        let problems = problems(of: draft, in: store, now: now)
        for index in draft.rows.indices { draft.rows[index].problem = problems[draft.rows[index].id] }
        guard problems.isEmpty else {
            draft.problem = problems.count == 1 && draft.liveRows.count == 1
                ? "Chưa lưu được." : "Chưa lưu được: \(problems.count) khoản cần sửa."
            return draft
        }
        /// Added by this "Lưu", taken out again if any other could not be.
        var added: [FinanceTransaction] = []
        store.persist {
            // One item per name and group, however many rows go under it.
            var made: [String: String] = [:]
            for index in draft.rows.indices where !draft.rows[index].removed {
                guard let item = draft.rows[index].newItem else { continue }
                let key = "\(item.groupID)/\(item.name.searchKey)"
                if made[key] == nil {
                    if let existing = store.item(named: item.name, inGroup: item.groupID) {
                        made[key] = existing.id
                    } else if let group = store.category(id: item.groupID) {
                        let category = Category(id: UUID().uuidString, kind: group.kind, parentID: group.id,
                                                name: Category.cleanName(item.name), icon: group.icon)
                        store.save(category)
                        made[key] = category.id
                    }
                }
                if let id = made[key] {
                    draft.rows[index].transaction.categoryID = id
                    draft.rows[index].newItem = nil
                }
            }
            for row in draft.liveRows where store.transaction(id: row.id) == nil {
                store.add(row.transaction)
                if store.transaction(id: row.id) != nil { added.append(row.transaction) }
            }
        }
        // Said, never assumed: the store may keep one out. Then none stays: all or nothing.
        let missing = draft.liveRows.filter { store.transaction(id: $0.id) == nil }
        guard missing.isEmpty else {
            store.persist { for transaction in added { store.delete(transaction) } }
            for index in draft.rows.indices where missing.contains(where: { $0.id == draft.rows[index].id }) {
                draft.rows[index].problem = "Chưa lưu được khoản này."
            }
            draft.problem = "Có khoản chưa lưu được."
            return draft
        }
        if let last = draft.liveRows.last?.transaction.accountID {
            defaults.set(last.uuidString, forKey: StorageKey.lastAccountID)
        }
        draft.state = .saved
        draft.problem = nil
        return draft
    }
}

/// "ok", "lưu đi", "huỷ" typed under a card waiting for "Lưu": saved or dropped by the app itself,
/// with no question to the model and no lượt (user choice 2026-11-17). Only the whole message,
/// short: "ok nhưng đổi sang Momo" goes to Milu.
enum DraftShortcut {
    enum Answer { case save, cancel }

    static func match(_ text: String) -> Answer? {
        let key = text.searchKey.split { !$0.isLetter && !$0.isNumber }.joined(separator: " ")
        let save: Set<String> = ["ok", "oke", "okay", "okie", "oki", "luu", "luu di", "luu nhe", "luu nha", "luu lai",
                                 "dung roi", "dung", "chuan", "chot", "u", "uh", "um", "vang", "da", "co", "yes",
                                 "luu giup", "luu giup minh", "ok luu", "ok luu di", "dong y"]
        let cancel: Set<String> = ["huy", "huy di", "khong luu", "thoi", "bo di", "bo qua", "khong", "no", "cancel",
                                   "thoi khoi", "khong can"]
        if save.contains(key) { return .save }
        if cancel.contains(key) { return .cancel }
        return nil
    }
}
