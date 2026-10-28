import Foundation

/// Money moved between a payment account and a savings goal ("Nạp tiền" / "Rút tiền" on the
/// goal). It changes both balances and nothing else: not income or spending, so it never counts in
/// reports. Stored as a transfer row (`fromAccountID` → `toAccountID`).
struct GoalTransfer: Identifiable, Hashable {
    enum Direction: String, Identifiable {
        /// From the account into the goal.
        case deposit
        /// From the goal back to the account.
        case withdrawal

        var id: Self { self }
    }

    var id = UUID()
    var goalID: SavingsGoal.ID
    var accountID: Account.ID
    var direction: Direction
    /// Always > 0; the direction says which way it went.
    var amount: Double
    var date: Date
    var note: String = ""

    /// What it does to the goal: + for a deposit, − for a withdrawal.
    var goalDelta: Double { direction == .deposit ? amount : -amount }
}
