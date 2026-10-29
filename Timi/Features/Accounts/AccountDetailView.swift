import SwiftUI

/// One payment account: its balance on top, then its transactions and goal deposits/withdrawals,
/// newest first. The pencil in the toolbar opens the account form, which also holds
/// "Xoá tài khoản" (as in iOS Contacts).
struct AccountDetailView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// Tells the + beside the tab bar which account to start on (absent in previews).
    @Environment(AddTransactionContext.self) private var addContext: AddTransactionContext?
    let accountID: Account.ID
    @State private var isEditing = false
    /// Set by "Lưu trữ" / "Xoá" in the edit form; the account goes once that form has closed.
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
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    SummaryCard(label: "Số dư", amount: account.balance, icon: account.iconName,
                                tone: account.isLocked || account.isArchived ? .muted : .negativeRed) {
                        if let subtitle = Self.subtitle(for: account) {
                            Text(subtitle)
                                .textRole(.caption)
                                .foregroundStyle(Palette.secondaryText)
                                .padding(.top, Spacing.xs)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Lịch sử")
                        if activity.isEmpty {
                            EmptyStateCard(icon: "hugeicons-inbox", title: "Chưa có giao dịch",
                                           message: "Giao dịch ghi vào tài khoản này sẽ hiện ở đây.")
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(activity.enumerated()), id: \.element.id) { index, item in
                                    ActivityRow(item: item, side: .account, viewedAccount: account.id) { editingItem = $0 }
                                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                                }
                            }
                            .listCard()
                        }
                    }
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            .navigationTitle(account.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditToolbarButton { isEditing = true }
                }
            }
            .sheet(isPresented: $isEditing, onDismiss: {
                guard let leave else { return }
                dismiss()
                switch leave {
                case .archive: store.archive(account)
                case .delete: store.delete(account)
                }
            }) {
                AddAccountView(account: account) { leave = $0 }
            }
            .sheet(item: $editingItem) { item in
                ActivityEditor(item: item)
            }
            // Also on switching tabs: the + on another tab does not start on this account.
            .onAppear { addContext?.accountID = accountID }
            .onDisappear { if addContext?.accountID == accountID { addContext?.accountID = nil } }
        } else {
            EmptyStateCard(icon: "hugeicons-alert-02", title: "Không tìm thấy tài khoản",
                           message: "Tài khoản này có thể đã bị xoá.")
                .padding(Spacing.page)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(Palette.background)
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

    /// The line under the balance, the same for every kind of account: when tracking started.
    static func subtitle(for account: Account) -> String? {
        let since = "Từ ngày " + account.openedAt.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(.vietnam))
        if account.isArchived { return "Đã lưu trữ · không tính vào tổng số dư" }
        return account.isLocked ? "Đã khoá · không tính vào tổng và báo cáo" : since
    }
}

#Preview {
    NavigationStack {
        AccountDetailView(accountID: SampleData.vietcombank.id)
    }
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
                GoalTransferRow(transfer: transfer, side: side)
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
                .alert("Không sửa được", isPresented: $isExplaining) {
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
            tone = .plain
        default:
            title = outgoing ? "Chuyển đến \(to)" : "Nhận từ \(from)"
            tone = outgoing ? .signedExpense : .signedIncome
        }
        let fee = transfer.fee > 0 ? transfer.fee.vnd : nil
        let subtitle: String
        switch viewedAccount {
        case nil: subtitle = "\(from) → \(to)"
        case transfer.fromAccountID?: subtitle = fee.map { "Gồm phí \($0)" } ?? "Chuyển khoản"
        default: subtitle = "Chuyển khoản"
        }
        return ListRow(icon: "hugeicons-arrow-data-transfer-horizontal", title: title,
                       subtitle: subtitle,
                       trailingSubtitle: detail == .time
                           ? transfer.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
                           : TransactionListRow.dayMonth(transfer.date),
                       amount: outgoing ? transfer.totalOut : transfer.amount, amountTone: tone, showsChevron: false)
    }
}

/// The money of a new loan (user choice 2026-10-29): neither income nor spending, so no red.
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
        ListRow(icon: lent ? "hugeicons-hand-coins" : "hugeicons-money-receive-02", title: title,
                subtitle: subtitle,
                trailingSubtitle: detail == .time
                    ? loan.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
                    : TransactionListRow.dayMonth(loan.date),
                amount: lent ? -loan.principal : loan.principal, amountTone: lent ? .plain : .signedIncome,
                showsChevron: false)
    }
}

/// A loan's repayment (user choice 2026-10-29): money in when a loan given is repaid, out when
/// one taken is; neither income nor spending, though its interest counts as one. On "Giao dịch":
/// "Thu nợ", "Minh Trần · Vietcombank"; in an account's history: "Thu nợ Minh Trần", "Gốc 5tr · Lãi 375k".
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
        let parts = [payment.principal > 0 ? "Gốc \(payment.principal.vndCompact)" : nil,
                     payment.interest > 0 ? "Lãi \(payment.interest.vndCompact)" : nil].compactMap { $0 }
        ListRow(icon: lent ? "hugeicons-money-receive-02" : "hugeicons-money-send-02",
                title: viewedAccount == nil ? kind : "\(kind) \(name)",
                subtitle: viewedAccount == nil ? "\(name) · \(account)" : parts.joined(separator: " · "),
                trailingSubtitle: detail == .time
                    ? payment.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
                    : TransactionListRow.dayMonth(payment.date),
                amount: lent ? payment.total : -payment.total, amountTone: lent ? .signedIncome : .plain,
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
