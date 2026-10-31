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
                               message: "Tài khoản bạn thôi dùng sẽ hiện ở đây.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        // The one account row of the app, as on the tab (strict review 2026-10-31:
                        // here the icon went untiled and the balance in full).
                        NavigationLink(value: account.id) {
                            AccountRow(account: account,
                                       subtitle: account.archivedAt.map { "Đã lưu trữ \($0.shortDay)" },
                                       isMuted: true)
                        }
                            .buttonStyle(.row)
                            .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                    }
                }
                .listCard()
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .background(Palette.background)
        .foregroundStyle(Palette.label)
        .navigationTitle("Tài khoản đã lưu trữ")
        .navigationBarTitleDisplayMode(.inline)
    }
}
