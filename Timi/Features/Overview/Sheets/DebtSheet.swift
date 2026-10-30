import SwiftUI

/// What makes up "Nợ" on Tổng quan: cards and accounts below zero, then the loans still to repay.
struct DebtSheet: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let accounts = store.countedAccounts.filter { $0.balance < 0 }
        let loans = store.loans.filter { $0.direction == .borrowed && $0.outstanding > 0 }
        VStack(alignment: .leading, spacing: Spacing.l) {
            SheetHeader(title: "Nợ \(store.totalDebt.vndCompact)")
            if accounts.isEmpty && loans.isEmpty {
                EmptyStateCard(icon: "hugeicons-credit-card", title: "Không có khoản nợ",
                               message: "Không thẻ nào âm và không có khoản đi vay nào.")
            }
            if !accounts.isEmpty {
                group("Thẻ, tài khoản âm") {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        ListRow(icon: account.iconName, title: account.name, amount: account.balance,
                                showsChevron: false)
                            .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
            }
            if !loans.isEmpty {
                group("Đi vay") {
                    ForEach(Array(loans.enumerated()), id: \.element.id) { index, loan in
                        ListRow(icon: "hugeicons-user", title: loan.name, amount: -loan.outstanding,
                                showsChevron: false)
                            .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.l)
        .timiFittedSheet()
    }

    private func group(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryText)
            VStack(spacing: 0, content: rows)
                .sleekCard(padding: 0)
        }
    }
}
