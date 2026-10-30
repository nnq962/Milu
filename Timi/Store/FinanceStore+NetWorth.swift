import Foundation

/// Tài sản ròng over time, for the growth chart on Tổng quan and the "Tài sản ròng" page.
///
/// Nothing is stored per day: a past value is today's net worth with every later money in and out
/// taken back (transactions, adjustments and excluded ones too since they moved a balance,
/// transfer fees, loan interest). Moves between the user's own accounts, savings goals and loans
/// leave it as it was. Accounts and loans count as if they had always been there, so adding a
/// wallet with money in it does not show as growth.
extension FinanceStore {
    /// Net worth at the end of each of the last `months` months, oldest first; the last point is
    /// now.
    func netWorthHistory(months: Int = 6, now: Date = .now) -> [NetWorthPoint] {
        let calendar = Calendar.current
        let thisMonth = DateInterval.month(of: now).start
        return (0..<months).reversed().compactMap { back in
            guard let start = calendar.date(byAdding: .month, value: -back, to: thisMonth) else { return nil }
            if back == 0 { return NetWorthPoint(month: start, value: netWorth) }
            guard let end = calendar.date(byAdding: .month, value: 1, to: start) else { return nil }
            return NetWorthPoint(month: start, value: netWorth - netWorthChange(since: end))
        }
    }

    /// Money in less money out on counted accounts from `date` on.
    func netWorthChange(since date: Date) -> Double {
        let after = DateInterval(start: date, end: .distantFuture)
        let locked = lockedAccountIDs
        return (transactions.filter { after.holds($0.date) } + feeExpenses(in: after) + interestTransactions(in: after))
            .filter { !locked.contains($0.accountID) }
            .reduce(0) { $0 + ($1.kind == .income ? $1.amount : -$1.amount) }
    }
}

struct NetWorthPoint: Identifiable, Hashable {
    /// The first day of the month the value closes.
    let month: Date
    let value: Double

    var id: Date { month }
}
