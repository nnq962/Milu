import SwiftUI

/// One payment account: its balance on top, then its transactions, newest first.
struct AccountDetailView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let accountID: Account.ID

    @State private var isConfirmingDelete = false

    var body: some View {
        if let account = store.account(id: accountID) {
            let transactions = store.accountTransactions(account)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    VStack(spacing: Spacing.s) {
                        if let institution = account.institution {
                            InstitutionLogo(image: institution.logoImage, size: 56)
                        } else {
                            IconCircle(icon: account.type.icon)
                        }
                        MoneyText(amount: account.balance, size: .display, tone: .negativeRed)
                        Text("\(account.type.title) · \(account.detail)")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .sleekCard()

                    SectionHeader(title: "Giao dịch")
                    if transactions.isEmpty {
                        EmptyStateCard(icon: "solar-inbox-linear", title: "Chưa có giao dịch",
                                       message: "Giao dịch ghi vào tài khoản này sẽ hiện ở đây.")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                                TransactionListRow(transaction: transaction, detail: .day)
                                    .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                            }
                        }
                        .sleekCard(padding: 0)
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
                    Menu {
                        Button(role: .destructive) { isConfirmingDelete = true } label: {
                            Label("Xoá tài khoản", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("Tuỳ chọn tài khoản")
                }
            }
            .confirmationDialog("Xoá tài khoản “\(account.name)”?", isPresented: $isConfirmingDelete,
                                titleVisibility: .visible) {
                Button("Xoá tài khoản", role: .destructive) {
                    Haptics.warning()
                    dismiss()
                    store.delete(account)
                }
            } message: {
                Text(AccountsView.deleteMessage(transactionCount: transactions.count))
            }
        } else {
            ContentUnavailableView("Không tìm thấy tài khoản", image: "solar-danger-triangle-linear")
        }
    }
}

#Preview {
    NavigationStack {
        AccountDetailView(accountID: SampleData.vietcombank.id)
    }
    .environment(FinanceStore())
    .environment(\.locale, .vietnam)
}
