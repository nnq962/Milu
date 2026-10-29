import Observation

/// What the + beside the tab bar knows about the screen behind it: the account being viewed, so
/// "Thêm giao dịch" starts on it. Set by `AccountDetailView` while it shows.
@Observable
final class AddTransactionContext {
    var accountID: Account.ID?
}
