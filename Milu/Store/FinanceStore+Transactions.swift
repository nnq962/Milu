import Foundation

/// Thêm, sửa, xoá giao dịch, và các hàm dùng chung để ghi số dư.
extension FinanceStore {
    func add(_ transaction: FinanceTransaction) {
        persist {
            // Not onto an archived account or a closed or deleted goal (a balance adjustment on a
            // locked account is fine: it is the user's own correction).
            if let account = account(id: transaction.accountID) {
                guard !account.isArchived else { return }
            } else {
                guard goal(id: transaction.accountID).map({ !$0.isClosed }) == true else { return }
            }
            transactions.append(transaction)
            transactions.sort { $0.date > $1.date }
            adjustBalance(of: transaction.accountID, by: transaction.signedAmount)
            database?.save(transaction)
            // A balance correction, a fee or interest is the app's own entry, not one recorded.
            if transaction.systemCategory?.isSystem != true { lastCreated = Creation(kind: .transaction) }
        }
    }

    /// Thay một giao dịch đã có và cập nhật lại số dư của tài khoản cũ lẫn mới.
    func update(_ transaction: FinanceTransaction) {
        persist {
            guard let index = transactions.firstIndex(where: { $0.id == transaction.id }),
                  isEditable(transactions[index]), accepts(transaction, replacing: transactions[index])
            else { return }
            let old = transactions[index]
            adjustBalance(of: old.accountID, by: -old.signedAmount)
            transactions[index] = transaction
            transactions.sort { $0.date > $1.date }
            adjustBalance(of: transaction.accountID, by: transaction.signedAmount)
            database?.save(transaction)
        }
    }

    func transaction(id: FinanceTransaction.ID) -> FinanceTransaction? {
        transactions.first { $0.id == id }
    }

    func delete(_ transaction: FinanceTransaction) {
        persist {
            // Chat cards can ask twice; only reverse the balance for a transaction that still exists.
            guard transactions.contains(where: { $0.id == transaction.id }), isEditable(transaction) else { return }
            transactions.removeAll { $0.id == transaction.id }
            adjustBalance(of: transaction.accountID, by: -transaction.signedAmount)
            database?.deleteTransaction(id: transaction.id)
        }
    }

    /// Moves an account's balance, or a goal's saved amount when the money was spent from a goal.
    func adjustBalance(of accountID: Account.ID, by delta: Double) {
        if let index = accounts.firstIndex(where: { $0.id == accountID }) {
            accounts[index].balance += delta
            database?.save(accounts[index])
        } else if let index = archivedAccounts.firstIndex(where: { $0.id == accountID }) {
            archivedAccounts[index].balance += delta
            database?.save(archivedAccounts[index])
        } else if let index = savingsGoals.firstIndex(where: { $0.id == accountID }) {
            savingsGoals[index].saved += delta
            database?.save(savingsGoals[index])
        }
    }

    /// One save for the whole of `body` (see `FinanceDatabase.batch`).
    func persist(_ body: () -> Void) {
        if let database { database.batch(body) } else { body() }
    }
}
