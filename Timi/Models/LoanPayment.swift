import Foundation

/// One repayment of a loan ("Thu nợ" when lent, "Trả nợ" when borrowed, user choice 2026-10-29):
/// the part of the principal it pays off and the interest, apart. Both move `accountID`'s
/// balance (in when lent, out when borrowed). The principal is neither income nor spending; the
/// interest is income on a loan given and spending on one taken ("Lãi cho vay" / "Lãi đi vay"),
/// counted in reports through `interestTransaction` though it has no row of its own.
struct LoanPayment: Identifiable, Hashable {
    var id = UUID()
    var loanID: Loan.ID
    /// Pays off this much of what is left; 0 when only interest was paid.
    var principal: Double
    var interest: Double = 0
    var accountID: Account.ID
    var date: Date

    var total: Double { principal + interest }

    /// The id of its interest as a transaction: its own with the last byte flipped (as a transfer's
    /// fee).
    var interestID: UUID {
        var bytes = id.uuid
        bytes.15 ^= 0xFF
        return UUID(uuid: bytes)
    }

    /// The interest as the income or spending reports count, never saved nor listed.
    func interestTransaction(lent: Bool) -> FinanceTransaction {
        let category: TransactionCategory = lent ? .loanInterestIncome : .loanInterestExpense
        return FinanceTransaction(id: interestID, title: category.title, amount: interest, category: category,
                                  accountID: accountID, date: date)
    }
}
