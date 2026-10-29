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
                                         accountTransfers: store.accountTransfers(of: account))
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
    /// A row of the account's history: a transaction, money moved to or from a goal, or a transfer
    /// with another account.
    enum Activity: Identifiable, Hashable {
        case transaction(FinanceTransaction)
        case transfer(GoalTransfer)
        case accountTransfer(AccountTransfer)

        var id: UUID {
            switch self {
            case .transaction(let transaction): transaction.id
            case .transfer(let transfer): transfer.id
            case .accountTransfer(let transfer): transfer.id
            }
        }

        var date: Date {
            switch self {
            case .transaction(let transaction): transaction.date
            case .transfer(let transfer): transfer.date
            case .accountTransfer(let transfer): transfer.date
            }
        }
    }

    static func activity(transactions: [FinanceTransaction], transfers: [GoalTransfer] = [],
                         accountTransfers: [AccountTransfer] = []) -> [Activity] {
        (transactions.map(Activity.transaction) + transfers.map(Activity.transfer)
            + accountTransfers.map(Activity.accountTransfer))
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

    private var canEdit: Bool {
        guard isEditable else { return false }
        switch item {
        case .transaction(let transaction): return store.isEditable(transaction)
        case .transfer(let transfer): return store.isEditable(transfer)
        case .accountTransfer(let transfer): return store.readOnlyReason(transfer) == nil
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
        }
    }
}

/// A transfer between two accounts. From one of them: "Chuyển đến MoMo" (−) or "Nhận từ
/// Vietcombank" (+); on "Giao dịch": "Chuyển khoản", "Vietcombank → MoMo", without a sign.
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
        return ListRow(icon: "hugeicons-arrow-data-transfer-horizontal", title: title,
                       subtitle: viewedAccount == nil ? "\(from) → \(to)" : "Chuyển khoản",
                       trailingSubtitle: detail == .time
                           ? transfer.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
                           : TransactionListRow.dayMonth(transfer.date),
                       amount: transfer.amount, amountTone: tone, showsChevron: false)
    }
}

/// The form for a tapped history row: the transaction form, or the deposit/withdrawal sheet.
struct ActivityEditor: View {
    let item: AccountDetailView.Activity

    @Environment(FinanceStore.self) private var store

    var body: some View {
        switch item {
        case .transaction(let transaction):
            TransactionEditSheet(transaction: transaction)
        case .accountTransfer(let transfer):
            AddTransactionView(editingTransfer: transfer)
        case .transfer(let transfer):
            if let goal = store.goal(id: transfer.goalID) {
                GoalTransferSheet(editing: transfer, goal: goal)
            }
        }
    }
}
