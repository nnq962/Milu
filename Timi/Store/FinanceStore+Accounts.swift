import Foundation

/// Tài khoản: số dư, tổng tài sản, thêm, sửa, lưu trữ, xoá.
extension FinanceStore {
    /// Accounts that count towards totals and reports.
    var countedAccounts: [Account] {
        accounts.filter { !$0.isLocked }
    }

    var netWorth: Double {
        countedAccounts.reduce(0) { $0 + $1.balance } + totalLent - totalBorrowed + totalSaved
    }

    /// Số còn phải thu từ các khoản cho vay chưa tất toán.
    var totalLent: Double {
        loans.filter { $0.direction == .lent }.reduce(0) { $0 + $1.outstanding }
    }

    /// Số còn phải trả của các khoản đi vay (không gồm thẻ tín dụng).
    var totalBorrowed: Double {
        loans.filter { $0.direction == .borrowed }.reduce(0) { $0 + $1.outstanding }
    }

    /// What open goals hold (a closed goal is empty: its money was spent or taken out).
    var totalSaved: Double {
        savingsGoals.reduce(0) { $0 + $1.saved }
    }

    /// Số dư dương của các tài khoản cộng tiền trong hũ.
    var totalAssets: Double {
        countedAccounts.filter { $0.balance > 0 }.reduce(0) { $0 + $1.balance } + totalSaved
    }

    var paymentAccounts: [Account] {
        accounts.filter { AccountType.paymentTypes.contains($0.type) }
    }

    /// "Tổng số dư" của màn Tài khoản: tài khoản thanh toán và hũ, không gồm thẻ tín dụng.
    var paymentBalance: Double {
        paymentAccounts.filter { !$0.isLocked }.reduce(0) { $0 + $1.balance } + totalSaved
    }

    /// Payment accounts that are locked: kept out of `paymentBalance`.
    var lockedPaymentAccounts: [Account] {
        paymentAccounts.filter(\.isLocked)
    }

    /// Locked accounts: out of totals and out of reports.
    var lockedAccountIDs: Set<Account.ID> {
        Set((accounts + archivedAccounts).filter(\.isLocked).map(\.id))
    }

    /// Whether a transaction counts in totals, charts and the assistant.
    func isReportable(_ transaction: FinanceTransaction) -> Bool {
        !transaction.isAdjustment && !transaction.isExcluded && !lockedAccountIDs.contains(transaction.accountID)
    }

    /// Accounts money can be recorded on: every account but the locked ones.
    var usableAccounts: [Account] {
        accounts.filter { !$0.isLocked }
    }

    func accounts(of type: AccountType) -> [Account] {
        accounts.filter { $0.type == type }
    }

    func add(_ account: Account) {
        accounts.append(account)
        database?.save(account)
        lastCreated = Creation(kind: .account)
    }

    /// Saves the edited details and, when `balance` differs from the current one, records the
    /// difference as an "Điều chỉnh số dư" transaction (kept out of reports), so the history
    /// still adds up to the balance.
    func update(_ account: Account, balance: Double) {
        persist {
            guard let current = self.account(id: account.id) else { return }
            var edited = account
            edited.balance = current.balance
            replace(edited)
            let delta = balance - edited.balance
            guard abs(delta) >= 1 else { return }
            add(FinanceTransaction(amount: abs(delta),
                                   category: delta > 0 ? .adjustmentIn : .adjustmentOut,
                                   accountID: account.id, date: .now))
        }
    }

    /// Writes an account back wherever it lives (in use or archived).
    private func replace(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        } else if let index = archivedAccounts.firstIndex(where: { $0.id == account.id }) {
            archivedAccounts[index] = account
        }
        database?.save(account)
    }

    /// Whether anything was ever recorded on the account; such an account is archived, not deleted.
    /// Balance corrections alone ("Điều chỉnh số dư", a typo fixed after adding it) do not count
    /// (user choice 2026-10-29): the account can still be deleted, with them.
    func hasHistory(_ account: Account) -> Bool {
        transactions.contains { $0.accountID == account.id && !$0.isAdjustment }
            || goalTransfers.contains { $0.accountID == account.id }
            || accountTransfers.contains { $0.fromAccountID == account.id || $0.toAccountID == account.id }
            || loans.contains { $0.movedAccountID == account.id } || loanPayments.contains { $0.accountID == account.id }
    }

    /// Hides an account with history: out of lists, pickers and totals, history kept. What it
    /// holds simply stops counting (user choice 2026-10-29: no step to bring it to 0đ first).
    func archive(_ account: Account) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        var archived = accounts.remove(at: index)
        archived.archivedAt = .now
        archivedAccounts.insert(archived, at: 0)
        database?.save(archived)
    }

    /// Puts an archived account back at the end of the list.
    func unarchive(_ account: Account) {
        guard let index = archivedAccounts.firstIndex(where: { $0.id == account.id }) else { return }
        var restored = archivedAccounts.remove(at: index)
        restored.archivedAt = nil
        accounts.append(restored)
        persist {
            database?.save(restored)
            database?.moveToEnd(restored.id)
        }
    }

    /// Deletes an account that has no history (see `hasHistory`); one with history is archived
    /// instead, so no balance, report or goal history changes (user choice 2026-10-29).
    /// Its balance corrections go with it (nothing else is on it, see `hasHistory`).
    func delete(_ account: Account) {
        guard !hasHistory(account) else { return }
        persist {
            let corrections = transactions.filter { $0.accountID == account.id }
            transactions.removeAll { $0.accountID == account.id }
            for row in corrections { database?.deleteTransaction(id: row.id) }
            accounts.removeAll { $0.id == account.id }
            archivedAccounts.removeAll { $0.id == account.id }
            database?.deleteAccount(id: account.id)
        }
    }
}
