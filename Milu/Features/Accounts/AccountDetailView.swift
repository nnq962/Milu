import SwiftUI

/// One payment account: its balance on top, then its transactions and goal deposits/withdrawals,
/// newest first. The pencil in the toolbar opens the account form, which also holds
/// "Xoá tài khoản" (as in iOS Contacts).
struct AccountDetailView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// Tells the + beside the tab bar which account to start on (absent in previews).
    let accountID: Account.ID
    /// ✕ on the left: the first screen of `AccountDetailSheet`.
    var showsClose = false
    @State private var isEditing = false
    /// Set by "Lưu trữ" / "Xoá" / "Khôi phục" in the edit form; the account goes once that form
    /// and this screen have closed.
    @State private var leave: AddAccountView.Leave?
    /// A history row tapped to change or delete it.
    @State private var editingItem: Activity?

    var body: some View {
        if let account = store.account(id: accountID) {
            let transactions = store.accountTransactions(account)
            let activity = Self.activity(transactions: transactions, transfers: store.transfers(of: account),
                                         accountTransfers: store.accountTransfers(of: account),
                                         loans: store.loanMoves(of: account),
                                         loanPayments: store.loanPayments(of: account))
            // The detail page of every sheet (`SheetPage`, review 2026-11-07): ✕ on the first
            // screen, the pencil, the sheets' margins.
            SheetPage(title: account.name, showsClose: showsClose, canEdit: true, onEdit: { isEditing = true }) {
                    SummaryCard(title: "Số dư", amount: account.balance, icon: account.iconName,
                                tone: account.isLocked || account.isArchived ? .muted : .balance) {
                        if let subtitle = Self.subtitle(for: account) {
                            Text(subtitle)
                                .textRole(.caption)
                                .foregroundStyle(Palette.secondaryLabel)
                                .padding(.top, Spacing.xs)
                                .accessibilityLabel(FormDateRow.spokenDays(in: subtitle))
                        }
                    }

                    if activity.isEmpty {
                        // Over its card, as the days once there are some (user request 2026-11-07).
                        OutsideHeaderSection(title: "Lịch sử") {
                            EmptyStateCard(title: "Chưa có giao dịch",
                                           message: "Giao dịch của tài khoản sẽ hiện ở đây.",
                                           picture: IconCatalog.emojiName("🧾"))
                        }
                    } else {
                        // One card a day with its totals, as on "Giao dịch" (review 2026-10-31: one
                        // long list here, by day there), the day's title over its card in the same
                        // words and size as there (user request 2026-11-07). `SheetPage` sets them 24 apart.
                        ActivityDayList(groups: ActivityDayList.byDay(activity), viewedAccount: account.id,
                                        headingOutside: true) { editingItem = $0 }
                    }
            }
            .sheet(isPresented: $isEditing, onDismiss: {
                guard let leave else { return }
                self.leave = nil
                // This sheet or page first, then the account out of its list (`AfterDismiss`).
                dismiss()
                let store = store
                AfterDismiss.run {
                    switch leave {
                    case .archive: store.archive(account)
                    case .delete: store.delete(account)
                    case .restore: store.unarchive(account)
                    }
                }
            }) {
                AddAccountView(account: account) { leave = $0 }
            }
            .sheet(item: $editingItem) { item in
                ActivityEditor(item: item)
            }
        } else {
            // In the sheet's own page, so ✕ is still there (review 2026-11-07).
            SheetPage(title: "Tài khoản", showsClose: showsClose, canEdit: false, onEdit: {}) {
                EmptyStateCard(title: "Không tìm thấy tài khoản",
                               message: "Tài khoản này có thể đã bị xoá.", picture: IconCatalog.emojiName("🧭"))
            }
        }
    }
}

extension AccountDetailView {
    /// A row of the account's history: a transaction, money moved to or from a goal, a transfer
    /// with another account, or the money of a new loan (lent from it, borrowed into it).
    enum Activity: Identifiable, Hashable {
        case transaction(FinanceTransaction)
        case transfer(GoalTransfer)
        case accountTransfer(AccountTransfer)
        case loan(Loan)
        case loanPayment(LoanPayment)

        var id: UUID {
            switch self {
            case .transaction(let transaction): transaction.id
            case .transfer(let transfer): transfer.id
            case .accountTransfer(let transfer): transfer.id
            case .loan(let loan): loan.id
            case .loanPayment(let payment): payment.id
            }
        }

        var date: Date {
            switch self {
            case .transaction(let transaction): transaction.date
            case .transfer(let transfer): transfer.date
            case .accountTransfer(let transfer): transfer.date
            case .loan(let loan): loan.date
            case .loanPayment(let payment): payment.date
            }
        }
    }

    static func activity(transactions: [FinanceTransaction], transfers: [GoalTransfer] = [],
                         accountTransfers: [AccountTransfer] = [], loans: [Loan] = [],
                         loanPayments: [LoanPayment] = []) -> [Activity] {
        (transactions.map(Activity.transaction) + transfers.map(Activity.transfer)
            + accountTransfers.map(Activity.accountTransfer) + loans.map(Activity.loan)
            + loanPayments.map(Activity.loanPayment))
            .sorted { $0.date > $1.date }
    }

    /// The line under the balance, the same for every kind of account: when tracking started, or
    /// that it is archived (and when, as on "Tài khoản đã lưu trữ") or locked. Short words, the
    /// app's one short date (re-review 2026-10-31: explaining sentences and "01/10/2026").
    static func subtitle(for account: Account) -> String? {
        if account.isArchived {
            return ["Đã lưu trữ", account.archivedAt?.shortDay].compactMap { $0 }.joined(separator: " ")
        }
        return account.isLocked ? "Đã khoá" : "Từ ngày \(account.openedAt.shortDay)"
    }
}

/// An account opened from a list: a sheet sliding up, as a transaction opens, so the tab bar is
/// not left showing under it (user choice 2026-11-01, over pushing a page). ✕ or a swipe down
/// closes it.
struct AccountDetailSheet: View {
    let accountID: Account.ID

    var body: some View {
        NavigationStack {
            AccountDetailView(accountID: accountID, showsClose: true)
        }
        .miluSheetStyle()
    }
}

/// A row that opens its account in `AccountDetailSheet`: every list of accounts (Tài khoản, the
/// archived ones, Tài sản ròng, Báo cáo) opens it the same way.
struct AccountSheetLink<Label: View>: View {
    let accountID: Account.ID
    @ViewBuilder var label: Label

    @State private var isOpen = false

    var body: some View {
        Button { isOpen = true } label: { label }
            .sheet(isPresented: $isOpen) { AccountDetailSheet(accountID: accountID) }
    }
}

#Preview {
    AccountDetailSheet(accountID: SampleData.vietcombank.id)
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}

/// One history row; tapping it opens `ActivityEditor`, unless `isEditable` is false (a closed
/// goal's history is read-only) or the goal it moved money with was deleted.
struct ActivityRow: View {
    let item: AccountDetailView.Activity
    let side: GoalTransferRow.Side
    var isEditable = true
    /// The account whose history this is: a transfer reads "Chuyển đến …" or "Nhận từ …" from it;
    /// nil on "Giao dịch", where it reads "Từ … → …".
    var viewedAccount: Account.ID? = nil
    /// What goes under the amount: the day (an account's history) or the time (grouped by day).
    var detail: TransactionListRow.Detail = .day
    let onEdit: (AccountDetailView.Activity) -> Void

    @Environment(FinanceStore.self) private var store

    /// Whether a tap opens it. Transactions and transfers open their view sheet even when they
    /// cannot change (it says why, without the pencil); a goal deposit or withdrawal opens its form,
    /// so only when it can change.
    private var canEdit: Bool {
        switch item {
        case .transaction, .accountTransfer, .loan, .loanPayment: return true
        case .transfer(let transfer): return isEditable && store.isEditable(transfer)
        }
    }

    var body: some View {
        let row = Group {
            switch item {
            case .transaction(let transaction):
                TransactionListRow(transaction: transaction, detail: detail)
            case .transfer(let transfer):
                GoalTransferRow(transfer: transfer, side: side, detail: detail)
            case .accountTransfer(let transfer):
                AccountTransferRow(transfer: transfer, viewedAccount: viewedAccount, detail: detail)
            case .loan(let loan):
                LoanMoveRow(loan: loan, viewedAccount: viewedAccount, detail: detail)
            case .loanPayment(let payment):
                LoanPaymentRow(payment: payment, viewedAccount: viewedAccount, detail: detail)
            }
        }
        if canEdit {
            Button { onEdit(item) } label: { row }
                .buttonStyle(.row)
        } else if let reason = readOnlyReason {
            // Read-only history still answers a tap: it says why and what to do.
            Button { isExplaining = true } label: { row }
                .buttonStyle(.row)
                .systemAlert("Không sửa được", isPresented: $isExplaining) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(reason)
                }
        } else {
            row
        }
    }

    @State private var isExplaining = false

    private var readOnlyReason: String? {
        switch item {
        case .transaction(let transaction): store.readOnlyReason(transaction)
        case .transfer(let transfer): store.readOnlyReason(transfer)
        case .accountTransfer(let transfer): store.readOnlyReason(transfer)
        case .loan, .loanPayment: nil
        }
    }
}

/// A transfer between two accounts. From one of them: "Chuyển đến MoMo" (− the amount and its fee,
/// "Gồm phí 5.000đ", so the figure adds up) or "Nhận từ Vietcombank" (+ the amount); on "Giao
/// dịch": "Chuyển khoản", "Vietcombank → MoMo", without a sign (the fee is in its view sheet).
struct AccountTransferRow: View {
    let transfer: AccountTransfer
    var viewedAccount: Account.ID? = nil
    var detail: TransactionListRow.Detail = .day

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let from = store.account(id: transfer.fromAccountID)?.name ?? "Tài khoản đã xoá"
        let to = store.account(id: transfer.toAccountID)?.name ?? "Tài khoản đã xoá"
        let outgoing = viewedAccount == transfer.fromAccountID
        let title: String
        let tone: MoneyText.Tone
        switch viewedAccount {
        case nil:
            title = "Chuyển khoản"
            tone = .transfer
        default:
            title = outgoing ? "Chuyển đến \(to)" : "Nhận từ \(from)"
            // Money out in ink, as a spending is ("B+"; review 2026-11-06).
            tone = outgoing ? .outflow : .signedIncome
        }
        // Whole, as every amount (Milu: no "tr"/"k"): "Gốc 5.000.000đ · Lãi 375.000đ".
        let fee = transfer.fee > 0 ? transfer.fee.vnd : nil
        let subtitle: String
        switch viewedAccount {
        case nil: subtitle = "\(from) → \(to)"
        case transfer.fromAccountID?: subtitle = fee.map { "Gồm phí \($0)" } ?? "Chuyển khoản"
        default: subtitle = "Chuyển khoản"
        }
        // Fluent pictures for money moves too, as every row of a day (review 2026-11-07).
        return ListRow(icon: IconCatalog.emojiName("💸"), title: title,
                       subtitle: subtitle,
                       trailingSubtitle: detail == .time
                           ? transfer.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
                           : transfer.date.shortDay,
                       amount: outgoing ? transfer.totalOut : transfer.amount, amountTone: tone, showsChevron: false)
    }
}

/// The money of a new loan (user choice 2026-10-29): neither income nor spending, though it
/// leaves or reaches an account, so it reads as money out (ink "-", as a spending) or in ("+") like any other
/// (strict review 2026-10-31: lent money was ink with a "-").
/// On "Giao dịch": "Cho vay", "Minh Trần · Vietcombank", −75.000.000đ; in an account's history:
/// "Cho Minh Trần vay" or "Vay của Lan", "Khoản vay".
struct LoanMoveRow: View {
    let loan: Loan
    var viewedAccount: Account.ID? = nil
    var detail: TransactionListRow.Detail = .day

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let lent = loan.direction == .lent
        let account = loan.movedAccountID.flatMap { store.account(id: $0)?.name } ?? "Tài khoản đã xoá"
        let title = viewedAccount == nil ? loan.direction.title : lent ? "Cho \(loan.name) vay" : "Vay của \(loan.name)"
        let subtitle = viewedAccount == nil ? "\(loan.name) · \(account)" : "Khoản vay"
        ListRow(icon: lent ? IconCatalog.emojiName("🤝") : IconCatalog.emojiName("💵"), title: title,
                subtitle: subtitle,
                trailingSubtitle: detail == .time
                    ? loan.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
                    : loan.date.shortDay,
                amount: loan.principal, amountTone: lent ? .outflow : .signedIncome,
                showsChevron: false)
    }
}

/// A loan's repayment (user choice 2026-10-29): money in when a loan given is repaid, out when
/// one taken is; neither income nor spending, though its interest counts as one. On "Giao dịch":
/// "Thu nợ", "Minh Trần · Vietcombank"; in an account's history: "Thu nợ Minh Trần", "Gốc 5.000.000đ · Lãi 375.000đ".
struct LoanPaymentRow: View {
    let payment: LoanPayment
    var viewedAccount: Account.ID? = nil
    var detail: TransactionListRow.Detail = .day

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let loan = store.loan(id: payment.loanID)
        let lent = loan?.direction != .borrowed
        let name = loan?.name ?? "Khoản vay đã xoá"
        let kind = lent ? "Thu nợ" : "Trả nợ"
        let account = store.account(id: payment.accountID)?.name ?? "Tài khoản đã xoá"
        let parts = [payment.principal > 0 ? "Gốc \(payment.principal.vnd)" : nil,
                     payment.interest > 0 ? "Lãi \(payment.interest.vnd)" : nil].compactMap { $0 }
        ListRow(icon: lent ? IconCatalog.emojiName("💰") : IconCatalog.emojiName("🪙"),
                title: viewedAccount == nil ? kind : "\(kind) \(name)",
                subtitle: viewedAccount == nil ? "\(name) · \(account)" : parts.joined(separator: " · "),
                trailingSubtitle: detail == .time
                    ? payment.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
                    : payment.date.shortDay,
                // Money out in ink with "-" (as a spending, "B+"; review 2026-11-06), in with "+".
                amount: payment.total, amountTone: lent ? .signedIncome : .outflow,
                showsChevron: false)
    }
}

/// What opens for a tapped history row: a transaction's or a transfer's details (their pencil
/// opens the form), the deposit/withdrawal sheet, or the loan a loan's money or repayment is of.
struct ActivityEditor: View {
    let item: AccountDetailView.Activity

    @Environment(FinanceStore.self) private var store

    var body: some View {
        switch item {
        case .transaction(let transaction):
            TransactionDetailSheet(transactionID: transaction.id)
        case .accountTransfer(let transfer):
            TransferDetailSheet(transferID: transfer.id)
        case .transfer(let transfer):
            if let goal = store.goal(id: transfer.goalID) {
                GoalTransferSheet(editing: transfer, goal: goal)
            }
        // Both a loan's money and its repayments open the loan (history, then the form).
        case .loan(let loan):
            LoanDetailSheet(loanID: loan.id)
        case .loanPayment(let payment):
            LoanDetailSheet(loanID: payment.loanID)
        }
    }
}
