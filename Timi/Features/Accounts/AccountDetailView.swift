import SwiftUI

/// One payment account: its balance on top, then its transactions and goal deposits/withdrawals,
/// newest first. The pencil in the toolbar opens the account form, which also holds
/// "Xoá tài khoản" (as in iOS Contacts).
struct AccountDetailView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let accountID: Account.ID
    @State private var isEditing = false
    /// Set by "Lưu trữ" / "Xoá" in the edit form; the account goes once that form has closed.
    @State private var leave: AddAccountView.Leave?
    /// A history row tapped to change or delete it.
    @State private var editingItem: Activity?

    var body: some View {
        if let account = store.account(id: accountID) {
            let transactions = store.accountTransactions(account)
            let activity = Self.activity(transactions: transactions, transfers: store.transfers(of: account))
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
                                    ActivityRow(item: item, side: .account, isEditable: true) { editingItem = $0 }
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
    /// A row of the account's history: a transaction or money moved to or from a goal.
    enum Activity: Identifiable, Hashable {
        case transaction(FinanceTransaction)
        case transfer(GoalTransfer)

        var id: UUID {
            switch self {
            case .transaction(let transaction): transaction.id
            case .transfer(let transfer): transfer.id
            }
        }

        var date: Date {
            switch self {
            case .transaction(let transaction): transaction.date
            case .transfer(let transfer): transfer.date
            }
        }
    }

    static func activity(transactions: [FinanceTransaction], transfers: [GoalTransfer]) -> [Activity] {
        (transactions.map(Activity.transaction) + transfers.map(Activity.transfer))
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
    let onEdit: (AccountDetailView.Activity) -> Void

    @Environment(FinanceStore.self) private var store

    private var canEdit: Bool {
        guard isEditable else { return false }
        switch item {
        case .transaction(let transaction): return store.isEditable(transaction)
        case .transfer(let transfer): return store.isEditable(transfer)
        }
    }

    var body: some View {
        let row = Group {
            switch item {
            case .transaction(let transaction):
                TransactionListRow(transaction: transaction, detail: .day)
            case .transfer(let transfer):
                GoalTransferRow(transfer: transfer, side: side)
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
        }
    }
}

/// The form for a tapped history row: the transaction form, or the deposit/withdrawal sheet.
struct ActivityEditor: View {
    let item: AccountDetailView.Activity

    @Environment(FinanceStore.self) private var store

    var body: some View {
        switch item {
        case .transaction(let transaction):
            AddTransactionView(editing: transaction)
        case .transfer(let transfer):
            if let goal = store.goal(id: transfer.goalID) {
                GoalTransferSheet(editing: transfer, goal: goal)
            }
        }
    }
}
