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
                ArchivedAccountsList()
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Tài khoản đã lưu trữ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
        }
    }
}

/// The archived accounts as rows on one card, each opening its account over the list; with a
/// `title`, under that heading (the "Lưu trữ & hoàn thành" sheet holds this and the closed goals).
struct ArchivedAccountsList: View {
    var title: String? = nil

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let accounts = store.archivedAccounts
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let title {
                Text(title)
                    .textRole(.title)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(spacing: 0) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    // Slides over the list inside the same sheet, ‹ back to it (user choice
                    // 2026-11-01: one sheet, not one on top of another).
                    NavigationLink { AccountDetailView(accountID: account.id) } label: {
                        AccountRow(account: account,
                                   subtitle: account.archivedAt.map { "Đã lưu trữ \($0.shortDay)" },
                                   isMuted: true, usesWalletMark: true)
                    }
                    .buttonStyle(.row)
                    .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                }
            }
            .listCard()
        }
    }
}

/// The row at the foot of Tài khoản, with archived accounts only: the list in a sheet, as an account opens (user choice 2026-11-01).
struct ArchivedAccountsSheet: View {
    var body: some View {
        NavigationStack { ArchivedAccountsView() }
            .timiSheetStyle()
    }
}
