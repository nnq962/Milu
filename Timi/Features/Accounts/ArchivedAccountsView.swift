import SwiftUI

/// "Tài khoản đã lưu trữ": accounts with history the user stopped using, the most recently
/// archived first. Out of totals; tapping one opens it, where the pencil offers "Khôi phục".
struct ArchivedAccountsView: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let accounts = store.archivedAccounts
        ScrollView {
            if accounts.isEmpty {
                EmptyStateCard(icon: "hugeicons-archive-02", title: "Chưa lưu trữ tài khoản nào",
                               message: "Tài khoản đã có giao dịch mà bạn thôi dùng sẽ nằm ở đây.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        NavigationLink(value: account.id) {
                            ListRow(icon: account.iconName, title: account.name,
                                    subtitle: account.archivedAt.map { "Đã lưu trữ \(TransactionListRow.dayMonth($0))" },
                                    amount: account.balance, amountTone: .muted)
                        }
                        .buttonStyle(.row)
                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .listCard()
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Tài khoản đã lưu trữ")
        .navigationBarTitleDisplayMode(.inline)
    }
}
