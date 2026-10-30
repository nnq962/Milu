import Foundation

/// Vay nợ: khoản vay, thu nợ / trả nợ, lãi, liên kết danh bạ.
extension FinanceStore {
    /// Also files the loan under the person its name names (see `link`); a person the app made who
    /// is left with no loan goes. A new loan (not from before the app) moves its principal out of
    /// or into its account; changing it undoes the old move first.
    func save(_ loan: Loan) {
        let old = loans.first { $0.id == loan.id }
        // Money on an archived account stays as it is: only who and when may change.
        if let old, readOnlyReason(old) != nil,
           old.principal != loan.principal || old.direction != loan.direction
            || old.movedAccountID != loan.movedAccountID || old.outstanding != loan.outstanding { return }
        persist {
            let loan = link(loan)
            if let old { moveMoney(of: old, sign: -1) }
            if let index = loans.firstIndex(where: { $0.id == loan.id }) {
                loans[index] = loan
            } else {
                loans.append(loan)
            }
            moveMoney(of: loan, sign: 1)
            database?.save(loan)
            if let previous = old?.contactID, previous != loan.contactID { removeIfUnused(previous) }
        }
    }

    /// Applies (1) or undoes (-1) a new loan's money on its account: lending takes it out,
    /// borrowing brings it in. A loan from before the app moves nothing.
    private func moveMoney(of loan: Loan, sign: Double) {
        guard let accountID = loan.movedAccountID else { return }
        adjustBalance(of: accountID, by: (loan.direction == .lent ? -loan.principal : loan.principal) * sign)
    }

    /// New loans whose money moved, newest first: rows of "Thu chi" (neither income nor spending)
    /// and of the account's history.
    var loanMoves: [Loan] {
        loans.filter { $0.movedAccountID != nil }.sorted { $0.date > $1.date }
    }

    func loanMoves(of account: Account) -> [Loan] {
        loanMoves.filter { $0.movedAccountID == account.id }
    }

    // MARK: - Thu nợ / Trả nợ

    /// Repayments that came into or left an account, newest first: rows of its history.
    func loanPayments(of account: Account) -> [LoanPayment] {
        loanPayments.filter { $0.accountID == account.id }
    }

    /// A loan's repayments, newest first.
    func payments(of loan: Loan) -> [LoanPayment] {
        loanPayments.filter { $0.loanID == loan.id }
    }

    /// Adds or changes a repayment: the old one is undone first. Its principal comes off what is
    /// left of the loan; principal and interest both come into the account (lent) or leave it
    /// (borrowed).
    func save(_ payment: LoanPayment) {
        // Money on an archived account stays as it is.
        if let old = loanPayments.first(where: { $0.id == payment.id }), readOnlyReason(old) != nil { return }
        guard account(id: payment.accountID)?.isArchived != true else { return }
        persist {
            if let index = loanPayments.firstIndex(where: { $0.id == payment.id }) {
                apply(loanPayments[index], sign: -1)
                loanPayments[index] = payment
            } else {
                loanPayments.append(payment)
            }
            loanPayments.sort { $0.date > $1.date }
            apply(payment, sign: 1)
            database?.save(payment)
        }
    }

    func delete(_ payment: LoanPayment) {
        persist {
            guard let saved = loanPayments.first(where: { $0.id == payment.id }), readOnlyReason(saved) == nil else { return }
            apply(saved, sign: -1)
            loanPayments.removeAll { $0.id == payment.id }
            database?.deleteLoanPayment(id: payment.id)
        }
    }

    /// Applies (1) or undoes (-1) a repayment on its loan and its account.
    /// What is left stays between 0 and the principal, whatever was typed on the loan since.
    private func apply(_ payment: LoanPayment, sign: Double) {
        guard let index = loans.firstIndex(where: { $0.id == payment.loanID }) else { return }
        let loan = loans[index]
        loans[index].outstanding = min(max(loan.outstanding - payment.principal * sign, 0), loan.principal)
        database?.save(loans[index])
        let lent = loan.direction == .lent
        adjustBalance(of: payment.accountID, by: (lent ? payment.total : -payment.total) * sign)
    }

    /// Why a loan's money cannot change: its account, or one of its repayments' accounts, is
    /// archived (as transactions and transfers there are frozen).
    func readOnlyReason(_ loan: Loan) -> String? {
        let ids = [loan.movedAccountID].compactMap { $0 } + payments(of: loan).map(\.accountID)
        return ids.contains { account(id: $0)?.isArchived == true } ? Self.archivedReason : nil
    }

    func readOnlyReason(_ payment: LoanPayment) -> String? {
        account(id: payment.accountID)?.isArchived == true ? Self.archivedReason : nil
    }

    /// When a loan was settled: its last repayment of principal (late interest does not move it),
    /// else the day it was made.
    func settledDate(of loan: Loan) -> Date {
        payments(of: loan).filter { $0.principal > 0 }.map(\.date).max() ?? loan.date
    }

    /// Principal repaid through the app ("Thu nợ" / "Trả nợ"), for the loan form's limits.
    func repaidPrincipal(of loan: Loan) -> Double {
        payments(of: loan).reduce(0) { $0 + $1.principal }
    }

    /// The day of a loan's first repayment: its own date cannot move past it.
    func firstPaymentDate(of loan: Loan) -> Date? {
        payments(of: loan).map(\.date).min()
    }

    /// Repayments whose loan is still there (a row of "Thu chi" opens the loan).
    var listedLoanPayments: [LoanPayment] {
        loanPayments.filter { payment in loans.contains { $0.id == payment.loanID } }
    }

    /// The month's loan interest as the income (lent) or spending (borrowed) reports count.
    func interestTransactions(inMonthOf date: Date) -> [FinanceTransaction] {
        interestTransactions(in: .month(of: date))
    }

    func interestTransactions(in interval: DateInterval) -> [FinanceTransaction] {
        loanPayments
            .filter { $0.interest > 0 && interval.holds($0.date) }
            .compactMap { payment in
                loan(id: payment.loanID).map { payment.interestTransaction(lent: $0.direction == .lent) }
            }
    }

    /// Whether interest is due this month: some is set and the loan began before this month (one
    /// lent today owes none yet).
    func owesInterest(_ loan: Loan, inMonthOf month: Date = .now) -> Bool {
        guard loan.monthlyInterestRate > 0, !loan.isSettled else { return false }
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        return loan.date < startOfMonth || loan.isExisting
    }

    /// Whether the interest of `month` was paid on this loan (any repayment with interest in it).
    func hasPaidInterest(_ loan: Loan, inMonthOf month: Date = .now) -> Bool {
        payments(of: loan).contains { $0.interest > 0 && Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    func loan(id: Loan.ID) -> Loan? {
        loans.first { $0.id == id }
    }

    /// Accounts a new loan can move money with: unlocked ones in use, plus the one it already has.
    /// The one kept may be archived (its history still names it), so changing something else does
    /// not move the money to another account.
    func loanAccountOptions(keeping kept: Account.ID?) -> [Account.ID] {
        accounts.filter { !$0.isLocked || $0.id == kept }.map(\.id)
            + archivedAccounts.filter { $0.id == kept }.map(\.id)
    }

    /// The loan with its person in "Danh bạ": its own while the name still matches, else the one
    /// with the name typed, else someone new ("Khác"), so every loan has a person. The name is
    /// written as the person's. Until the loan form picks from Danh bạ, the name is how it says who.
    private func link(_ loan: Loan) -> Loan {
        // As long as a name typed in Danh bạ may be; the loan form has no limit.
        let name = String(Contact.clean(loan.name).prefix(Contact.maxNameLength))
        guard !name.isEmpty else { return loan }
        var loan = loan
        let person: Contact
        if let own = loan.contactID.flatMap({ contact(id: $0) }), own.hasName(name) {
            person = own
        } else if let named = contact(named: name) {
            person = named
        } else {
            person = Contact(name: name, relationshipID: ContactRelationship.other.rawValue, isAutoCreated: true)
            contacts.append(person)
            database?.save(person)
        }
        loan.contactID = person.id
        loan.name = person.name
        return loan
    }

    /// Loans from before "Danh bạ" (V2) have only a name: each gets its person, once, at launch.
    func linkLoansToContacts() {
        let unlinked = loans.filter { loan in loan.contactID.flatMap { contact(id: $0) } == nil }
        guard !unlinked.isEmpty else { return }
        persist { for loan in unlinked { save(loan) } }
    }

    /// Also undoes its repayments on their accounts, as the loan's own money is.
    func delete(_ loan: Loan) {
        guard readOnlyReason(loan) == nil else { return }
        persist {
            for payment in payments(of: loan) {
                let lent = loan.direction == .lent
                adjustBalance(of: payment.accountID, by: lent ? -payment.total : payment.total)
                database?.deleteLoanPayment(id: payment.id)
            }
            loanPayments.removeAll { $0.loanID == loan.id }
            if let saved = self.loan(id: loan.id) { moveMoney(of: saved, sign: -1) }
            loans.removeAll { $0.id == loan.id }
            database?.deleteLoan(id: loan.id)
            if let person = loan.contactID { removeIfUnused(person) }
        }
    }

    /// A person the app made from a loan's name ("Minh Tran", fixed to "Minh Trần" on the loan)
    /// goes once no loan names them; someone the user added or edited stays.
    private func removeIfUnused(_ id: Contact.ID) {
        guard let person = contact(id: id), person.isAutoCreated, loans(of: person).isEmpty else { return }
        contacts.removeAll { $0.id == id }
        database?.deleteContact(id: id)
    }

    /// An account in use or archived (archived ones still name their history).
    func account(id: Account.ID) -> Account? {
        accounts.first { $0.id == id } ?? archivedAccounts.first { $0.id == id }
    }

    func accountTransactions(_ account: Account) -> [FinanceTransaction] {
        transactions.filter { $0.accountID == account.id }
    }
}
