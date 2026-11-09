import Observation

/// What the + beside the tab bar knows about the screen behind it: the account being viewed, so
/// "Thêm giao dịch" starts on it (set by `AccountDetailView` while it shows), and whether "Vay
/// nợ" is on screen, where it adds a loan instead: one + there, not one on the bar and one beside
/// the tabs doing two things (review 2026-11-03).
@Observable
final class AddTransactionContext {
    var accountID: Account.ID?
    var addsLoan = false
}
