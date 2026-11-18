import Foundation

/// Transactions Milu has made ready from the chat, waiting on a card for the user's "Lưu": nothing
/// is saved before the user has seen every field (user choice 2026-11-17). Several said in one
/// sentence wait on one card and are saved together ("Lưu cả 3").
///
/// Kept in the saved chats, so it reads leniently: a field it does not know yet, or one gone, takes
/// its default, and one card that cannot be read never takes the chat with it (`ChatMessage`).
struct TransactionDraft: Equatable, Codable, Identifiable {
    var id = UUID()
    var rows: [Row]
    var state: State = .pending
    /// Why the last "Lưu" saved nothing, said on the card.
    var problem: String? = nil
    /// The card this one was made to replace ("à không, 50k thôi"): marked so once this one shows.
    var replacing: UUID? = nil

    enum State: String, Codable {
        /// On the card, waiting for "Lưu" or "Huỷ".
        case pending
        case saved
        case cancelled
        /// A newer card took its place.
        case replaced
    }

    struct Row: Equatable, Codable, Identifiable {
        /// Its id is the one it is saved with, made as the card is: saving twice adds it once.
        var transaction: FinanceTransaction
        /// An item to create on "Lưu", under a group the user has: the transaction has no category
        /// until then ("" as its id).
        var newItem: NewItem? = nil
        /// The account was not said: Milu took the last one used, and says so on the card.
        var accountChosenByApp = false
        /// A transaction like it is saved already that day: told, not stopped.
        var warning: String? = nil
        /// Why it cannot be saved as it is (its account locked since, its item hidden).
        var problem: String? = nil
        /// Deleted from the card after it was saved.
        var removed = false

        var id: UUID { transaction.id }

        init(transaction: FinanceTransaction, newItem: NewItem? = nil, accountChosenByApp: Bool = false,
             warning: String? = nil) {
            self.transaction = transaction
            self.newItem = newItem
            self.accountChosenByApp = accountChosenByApp
            self.warning = warning
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            transaction = try values.decode(FinanceTransaction.self, forKey: .transaction)
            newItem = try? values.decodeIfPresent(NewItem.self, forKey: .newItem)
            accountChosenByApp = (try? values.decodeIfPresent(Bool.self, forKey: .accountChosenByApp)) ?? false
            warning = try? values.decodeIfPresent(String.self, forKey: .warning)
            problem = try? values.decodeIfPresent(String.self, forKey: .problem)
            removed = (try? values.decodeIfPresent(Bool.self, forKey: .removed)) ?? false
        }

        private enum CodingKeys: String, CodingKey {
            case transaction, newItem, accountChosenByApp, warning, problem, removed
        }
    }

    /// An item "Lưu" creates: "Học tiếng Nhật" in "Học tập".
    struct NewItem: Equatable, Codable {
        var name: String
        var groupID: String
    }

    init(rows: [Row], replacing: UUID? = nil) {
        self.rows = rows
        self.replacing = replacing
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? values.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        rows = (try? values.decodeIfPresent([Row].self, forKey: .rows)) ?? []
        // A state a newer build wrote reads as done with, never as one to save.
        let state = (try? values.decodeIfPresent(String.self, forKey: .state)) ?? ""
        self.state = State(rawValue: state) ?? .cancelled
        problem = try? values.decodeIfPresent(String.self, forKey: .problem)
        replacing = try? values.decodeIfPresent(UUID.self, forKey: .replacing)
    }

    private enum CodingKeys: String, CodingKey {
        case id, rows, state, problem, replacing
    }

    /// The short handle the model is told, to replace this card: "k7f2".
    var ref: String { String(id.uuidString.prefix(4)).lowercased() }

    var isPending: Bool { state == .pending }

    /// The rows still on the card.
    var liveRows: [Row] { rows.filter { !$0.removed } }

    func row(_ id: UUID) -> Row? { rows.first { $0.id == id } }

    /// The card with one row changed (an edit in its form), its warning worked out again.
    func replacingRow(_ row: Row) -> TransactionDraft {
        var draft = self
        if let index = draft.rows.firstIndex(where: { $0.id == row.id }) { draft.rows[index] = row }
        draft.problem = nil
        return draft
    }

    /// The card without one row ("Bỏ khoản này"); an empty card is cancelled.
    func removingRow(_ id: UUID) -> TransactionDraft {
        var draft = self
        draft.rows.removeAll { $0.id == id }
        draft.problem = nil
        if draft.rows.isEmpty { draft.state = .cancelled }
        return draft
    }
}
