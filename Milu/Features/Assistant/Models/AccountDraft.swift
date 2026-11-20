import Foundation

/// Accounts Milu has made ready from the chat ("thêm tài khoản Techcombank 5 triệu"), waiting on a
/// card for the user's "Lưu", as transactions do (`TransactionDraft`): nothing is added before the
/// user has seen it (user request 2026-11-20). Several said in one sentence wait on one card and
/// are added together ("Lưu cả 2").
///
/// Kept in the saved chats, so it reads leniently, as `TransactionDraft` does.
struct AccountDraft: Equatable, Codable, Identifiable {
    var id = UUID()
    var rows: [Row]
    var state: TransactionDraft.State = .pending
    /// Why the last "Lưu" added nothing, said on the card.
    var problem: String? = nil
    /// The card this one was made to replace ("sửa số dư thành 3 triệu").
    var replacing: UUID? = nil

    struct Row: Equatable, Codable, Identifiable {
        /// Added as it is on "Lưu", with this id: adding twice adds it once.
        var account: Account
        /// What Milu chose that the user did not say: "Vietcombank là ngân hàng, Milu để loại Ngân
        /// hàng". Said under the rows, grey.
        var notice: String? = nil
        /// To look at before "Lưu" (a balance read otherwise than said): yellow.
        var warning: String? = nil
        /// Why it cannot be added as it is (a name taken since): red.
        var problem: String? = nil

        var id: UUID { account.id }

        init(account: Account, notice: String? = nil, warning: String? = nil) {
            self.account = account
            self.notice = notice
            self.warning = warning
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            account = try values.decode(Account.self, forKey: .account)
            notice = try? values.decodeIfPresent(String.self, forKey: .notice)
            warning = try? values.decodeIfPresent(String.self, forKey: .warning)
            problem = try? values.decodeIfPresent(String.self, forKey: .problem)
        }

        private enum CodingKeys: String, CodingKey { case account, notice, warning, problem }
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
        self.state = TransactionDraft.State(rawValue: state) ?? .cancelled
        problem = try? values.decodeIfPresent(String.self, forKey: .problem)
        replacing = try? values.decodeIfPresent(UUID.self, forKey: .replacing)
    }

    private enum CodingKeys: String, CodingKey { case id, rows, state, problem, replacing }

    /// The short handle the model is told, to change this card: "k7f2".
    var ref: String { String(id.uuidString.prefix(4)).lowercased() }

    var isPending: Bool { state == .pending }

    func row(_ id: UUID) -> Row? { rows.first { $0.id == id } }

    /// The card with one row changed in its form.
    func replacingRow(_ row: Row) -> AccountDraft {
        var draft = self
        if let index = draft.rows.firstIndex(where: { $0.id == row.id }) { draft.rows[index] = row }
        draft.problem = nil
        return draft
    }
}
