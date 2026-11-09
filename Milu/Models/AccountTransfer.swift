import Foundation

/// Money moved between two of the user's accounts ("Chuyển khoản"): neither income nor spending,
/// so the amount stays out of totals and reports. A fee is paid by the source on top of the amount
/// and counts as spending ("Phí chuyển khoản" in reports, `feeExpense`), though it has no row of
/// its own (user choice 2026-10-29).
struct AccountTransfer: Identifiable, Hashable {
    var id = UUID()
    var fromAccountID: Account.ID
    var toAccountID: Account.ID
    /// Always > 0: what reaches `toAccountID`.
    var amount: Double
    /// 0 when free; otherwise spent from `fromAccountID` on top of `amount`.
    var fee: Double = 0
    var date: Date
    var note: String = ""

    /// The id of its fee as an expense: the transfer's id with the last byte flipped. Fees were
    /// once saved as their own row under this id; `FinanceStore` removes those.
    var feeID: UUID { Self.flip(id) }

    private static func flip(_ id: UUID) -> UUID {
        var bytes = id.uuid
        bytes.15 ^= 0xFF
        return UUID(uuid: bytes)
    }

    /// The fee as the spending reports count, never saved nor listed.
    var feeExpense: FinanceTransaction {
        FinanceTransaction(id: feeID, title: TransactionCategory.transferFee.title, amount: fee,
                           category: .transferFee, accountID: fromAccountID, date: date)
    }

    /// What leaves the source: the amount and the fee.
    var totalOut: Double { amount + fee }
}
