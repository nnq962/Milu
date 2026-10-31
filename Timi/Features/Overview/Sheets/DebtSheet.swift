import SwiftUI

/// What makes up "Nợ" on Tổng quan: the total under the bar, then cards and accounts below zero
/// and the loans still to repay. Scrolls, so many loans are never cut off (sheet review
/// 2026-10-30), with group headings and list blocks like every other sheet.
struct DebtSheet: View {
    @Environment(FinanceStore.self) private var store
    @State private var viewingLoan: Loan?

    var body: some View {
        let accounts = store.countedAccounts.filter { $0.balance < 0 }
        let loans = store.loans.filter { $0.direction == .borrowed && $0.outstanding > 0 }
        SheetScaffold(title: "Nợ") {
            // The total as a `MoneyText` under the bar, red with its sign like the "Nợ" row that
            // opens this (re-review 2026-10-31: "Nợ 12tr" in ink, and "Nợ 0đ" with none).
            if store.totalDebt > 0 {
                MoneyText(amount: -store.totalDebt, size: .large, tone: .negativeRed)
                    .frame(maxWidth: .infinity)
            }
            if accounts.isEmpty && loans.isEmpty {
                EmptyStateCard(icon: "hugeicons-credit-card", title: "Không có khoản nợ",
                               message: "Thẻ âm và khoản đi vay sẽ hiện ở đây.")
            }
            // Accounts and loans drawn as on their own pages (`AccountRow`, `LoanRowList`),
            // and a loan opens its sheet as on Vay nợ (strict review 2026-10-31).
            if !accounts.isEmpty {
                group("Thẻ, tài khoản âm") {
                    VStack(spacing: 0) {
                        ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                            AccountRow(account: account, showsChevron: false)
                                .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                        }
                    }
                    .listCard()
                }
            }
            if !loans.isEmpty {
                group("Đi vay") {
                    LoanRowList(loans: loans) { viewingLoan = $0 }
                }
            }
        }
        .timiSheetStyle([.medium, .large])
        .sheet(item: $viewingLoan) { LoanDetailSheet(loanID: $0.id) }
    }

    private func group(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: title, style: .group)
            content()
        }
    }
}
