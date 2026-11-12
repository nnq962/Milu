import Foundation

/// How far the history has moved each account's and goal's balance from where it opened, the same
/// moves `FinanceStore.adjustBalance` makes as things are recorded:
/// - a transaction: in for income, out for spending, on its account (or the goal it was spent from);
/// - a transfer: the amount and its fee out of the source, the amount into the destination;
/// - money into or out of a goal: one side up by what the other goes down;
/// - a new loan (not one from before the app): lent money out of its account, borrowed money in;
/// - a repayment: principal and interest into the account (lent) or out of it (borrowed).
///
/// Balance = opening + this. Stored balances cannot be trusted once two devices write the same
/// account through iCloud (the last write wins and the other's money is lost), so every load works
/// them out again from the history, which syncs row by row (user choice 2026-11-12).
enum BalanceLedger {
    static func movements(transactions: [FinanceTransaction], accountTransfers: [AccountTransfer],
                          goalTransfers: [GoalTransfer], loans: [Loan],
                          loanPayments: [LoanPayment]) -> [UUID: Double] {
        var moved: [UUID: Double] = [:]
        for transaction in transactions {
            moved[transaction.accountID, default: 0] += transaction.signedAmount
        }
        for transfer in accountTransfers {
            moved[transfer.fromAccountID, default: 0] -= transfer.amount + transfer.fee
            moved[transfer.toAccountID, default: 0] += transfer.amount
        }
        for transfer in goalTransfers {
            moved[transfer.goalID, default: 0] += transfer.goalDelta
            moved[transfer.accountID, default: 0] -= transfer.goalDelta
        }
        let lent = Dictionary(loans.map { ($0.id, $0.direction == .lent) }, uniquingKeysWith: { first, _ in first })
        for loan in loans {
            guard let accountID = loan.movedAccountID else { continue }
            moved[accountID, default: 0] += loan.direction == .lent ? -loan.principal : loan.principal
        }
        for payment in loanPayments {
            // A repayment of a loan that is gone moved nothing (`FinanceStore.apply(_:sign:)`).
            guard let isLent = lent[payment.loanID] else { continue }
            moved[payment.accountID, default: 0] += isLent ? payment.total : -payment.total
        }
        return moved
    }
}
