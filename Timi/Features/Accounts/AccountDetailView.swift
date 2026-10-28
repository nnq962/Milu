import SwiftUI

/// One payment account: its balance on top, then its transactions and goal deposits/withdrawals,
/// newest first. The pencil in the toolbar opens the account form, which also holds
/// "Xoá tài khoản" (as in iOS Contacts).
struct AccountDetailView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let accountID: Account.ID
    @State private var isEditing = false
    /// Set by "Xoá tài khoản" in the edit form; the account goes once that form has closed.
    @State private var deletesOnDismiss = false

    var body: some View {
        if let account = store.account(id: accountID) {
            let transactions = store.accountTransactions(account)
            let activity = Self.activity(transactions: transactions, transfers: store.transfers(of: account))
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    VStack(spacing: Spacing.s) {
                        RowIcon(name: account.iconName, size: RowMetrics.featureIcon)
                        MoneyText(amount: account.balance, size: .display, tone: .negativeRed)
                        if let subtitle = Self.subtitle(for: account) {
                            Text(subtitle)
                                .textRole(.caption)
                                .foregroundStyle(Palette.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .sleekCard()

                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Giao dịch")
                        if activity.isEmpty {
                            EmptyStateCard(icon: "hugeicons-inbox", title: "Chưa có giao dịch",
                                           message: "Giao dịch ghi vào tài khoản này sẽ hiện ở đây.")
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(activity.enumerated()), id: \.element.id) { index, item in
                                    Group {
                                        switch item {
                                        case .transaction(let transaction):
                                            TransactionListRow(transaction: transaction, detail: .day)
                                        case .transfer(let transfer):
                                            GoalTransferRow(transfer: transfer, side: .account)
                                        }
                                    }
                                    .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                                }
                            }
                            .sleekCard(padding: 0)
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
                guard deletesOnDismiss else { return }
                dismiss()
                store.delete(account)
            }) {
                AddAccountView(account: account) { deletesOnDismiss = true }
            }
        } else {
            ContentUnavailableView("Không tìm thấy tài khoản", image: "hugeicons-alert-02")
        }
    }
}

extension AccountDetailView {
    /// A row of the account's history: a transaction or money moved to or from a goal.
    enum Activity: Identifiable {
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
        "Từ ngày " + account.openedAt.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(.vietnam))
    }
}

#Preview {
    NavigationStack {
        AccountDetailView(accountID: SampleData.vietcombank.id)
    }
    .environment(FinanceStore())
    .environment(\.locale, .vietnam)
}
