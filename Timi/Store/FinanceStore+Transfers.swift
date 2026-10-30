import Foundation

/// Chuyển khoản giữa hai tài khoản, và phí chuyển khoản.
extension FinanceStore {
    func accountTransfer(id: AccountTransfer.ID) -> AccountTransfer? {
        accountTransfers.first { $0.id == id }
    }

    /// Transfers into or out of an account.
    func accountTransfers(of account: Account) -> [AccountTransfer] {
        accountTransfers.filter { $0.fromAccountID == account.id || $0.toAccountID == account.id }
    }

    /// Why a transfer cannot be changed; nil when it can. An archived account on either side
    /// freezes it, as its other history. A locked one does not: like a transaction on a locked
    /// account it can change, keeping that account on its side (`accepts(_:replacing:)`).
    func readOnlyReason(_ transfer: AccountTransfer) -> String? {
        let sides = [transfer.fromAccountID, transfer.toAccountID].compactMap { account(id: $0) }
        return sides.count < 2 || sides.contains(where: \.isArchived) ? Self.archivedReason : nil
    }

    /// Two different accounts, a positive amount and a fee of 0 or more. Each side is an unlocked
    /// account in use, or (when changing a transfer) the locked one it already had on that side.
    func accepts(_ transfer: AccountTransfer, replacing old: AccountTransfer? = nil) -> Bool {
        func fits(_ id: Account.ID, was oldID: Account.ID?) -> Bool {
            acceptsMoney(id) || (id == oldID && accounts.contains { $0.id == id })
        }
        return transfer.fromAccountID != transfer.toAccountID && transfer.amount > 0 && transfer.fee >= 0
            && fits(transfer.fromAccountID, was: old?.fromAccountID) && fits(transfer.toAccountID, was: old?.toAccountID)
    }

    /// Moves `amount` from one account to the other; a fee is spent from the source as well.
    func add(_ transfer: AccountTransfer) {
        persist {
            guard accepts(transfer) else { return }
            accountTransfers.append(transfer)
            accountTransfers.sort { $0.date > $1.date }
            apply(transfer, sign: 1)
            database?.save(transfer)
        }
    }

    /// Replaces a transfer: the old one is undone on both accounts, the new one applied.
    func update(_ transfer: AccountTransfer) {
        persist {
            guard let index = accountTransfers.firstIndex(where: { $0.id == transfer.id }),
                  readOnlyReason(accountTransfers[index]) == nil else { return }
            let old = accountTransfers[index]
            apply(old, sign: -1)
            guard accepts(transfer, replacing: old) else {
                apply(old, sign: 1)
                return
            }
            accountTransfers[index] = transfer
            accountTransfers.sort { $0.date > $1.date }
            apply(transfer, sign: 1)
            database?.save(transfer)
        }
    }

    func delete(_ transfer: AccountTransfer) {
        persist {
            guard accountTransfers.contains(where: { $0.id == transfer.id }), readOnlyReason(transfer) == nil else { return }
            accountTransfers.removeAll { $0.id == transfer.id }
            apply(transfer, sign: -1)
            database?.deleteTransaction(id: transfer.id)
        }
    }

    /// Applies (1) or undoes (-1) a transfer on both balances: the source pays the amount and
    /// the fee, the destination gets the amount.
    private func apply(_ transfer: AccountTransfer, sign: Double) {
        adjustBalance(of: transfer.fromAccountID, by: -(transfer.amount + transfer.fee) * sign)
        adjustBalance(of: transfer.toAccountID, by: transfer.amount * sign)
    }

    /// Fees were once a separate "Phí chuyển khoản" expense next to their transfer (user choice
    /// 2026-10-29: only the transfer is kept). Each such row goes; its transfer already holds the
    /// fee, and the source's balance already paid it, so nothing else moves.
    func foldFeeRows() {
        let feeIDs = Set(accountTransfers.filter { $0.fee > 0 }.map(\.feeID))
        let rows = transactions.filter { feeIDs.contains($0.id) }
        guard !rows.isEmpty else { return }
        persist {
            transactions.removeAll { feeIDs.contains($0.id) }
            for row in rows { database?.deleteTransaction(id: row.id) }
        }
    }

    /// Transactions once had a name of their own ("Bún chả"); they now show their category (user
    /// choice 2026-10-29). A name that says more than the category goes into the note, before
    /// what the note had, so nothing is lost; then the name is cleared.
    func moveTitlesToNotes() {
        let named = transactions.indices.filter { !transactions[$0].title.isEmpty }
        guard !named.isEmpty else { return }
        persist {
            for index in named {
                var transaction = transactions[index]
                if transaction.title != categoryName(transaction.categoryID) {
                    transaction.note = [transaction.title, transaction.note].filter { !$0.isEmpty }.joined(separator: "\n")
                }
                transaction.title = ""
                transactions[index] = transaction
                database?.save(transaction)
            }
        }
    }

    /// Transfer fees as the spending they are, for totals and reports only: a fee has no row of its
    /// own in any list (it shows on its transfer).
    func feeExpenses(inMonthOf date: Date) -> [FinanceTransaction] {
        feeExpenses(in: .month(of: date))
    }

    func feeExpenses(in interval: DateInterval) -> [FinanceTransaction] {
        accountTransfers
            .filter { $0.fee > 0 && interval.holds($0.date) }
            .map(\.feeExpense)
    }

    /// Dư nợ thẻ/tài khoản âm cộng các khoản đi vay.
    var totalDebt: Double {
        countedAccounts.filter { $0.balance < 0 }.reduce(0) { $0 - $1.balance } + totalBorrowed
    }
}
