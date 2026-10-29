import Foundation

/// Money moved between two of the user's accounts ("Chuyển khoản"): neither income nor spending,
/// so it stays out of totals and reports. A fee, when there is one, is a separate expense from the
/// source account ("Phí chuyển khoản", which does count), with an id made from the transfer's
/// (`feeID`), so the two always go together.
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

    /// The id of its fee expense: the transfer's id with the last byte flipped, so either one
    /// leads to the other without a stored link.
    var feeID: UUID { Self.flip(id) }

    /// The transfer a fee expense belongs to.
    static func id(ofFee feeID: UUID) -> UUID { flip(feeID) }

    private static func flip(_ id: UUID) -> UUID {
        var bytes = id.uuid
        bytes.15 ^= 0xFF
        return UUID(uuid: bytes)
    }

    /// The fee as the expense it is recorded as.
    func feeTransaction(toName: String) -> FinanceTransaction {
        FinanceTransaction(id: feeID, title: TransactionCategory.transferFee.title, amount: fee,
                           category: .transferFee, accountID: fromAccountID, date: date,
                           note: "Chuyển sang \(toName)")
    }
}
