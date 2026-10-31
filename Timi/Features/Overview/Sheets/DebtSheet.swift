import SwiftUI

/// What makes up "Nợ" on Tổng quan: cards and accounts below zero, then the loans still to repay.
/// Scrolls, so many loans are never cut off (sheet review 2026-10-30), with group headings and
/// list blocks like every other sheet.
struct DebtSheet: View {
    @Environment(FinanceStore.self) private var store
    @State private var viewingLoan: Loan?

    var body: some View {
        let accounts = store.countedAccounts.filter { $0.balance < 0 }
        let loans = store.loans.filter { $0.direction == .borrowed && $0.outstanding > 0 }
        VStack(alignment: .leading, spacing: Spacing.l) {
            // Just "Nợ": the total as a `MoneyText` under it, red with its sign like the "Nợ" row
            // that opens this (re-review 2026-10-31: "Nợ 12tr" in ink, and "Nợ 0đ" with none).
            VStack(spacing: Spacing.xs) {
                SheetHeader(title: "Nợ")
                if store.totalDebt > 0 {
                    MoneyText(amount: -store.totalDebt, size: .large, tone: .negativeRed)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Spacing.page)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
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
            }
            // Margins inside the scroll view, so the list cards' shadow is not cut at the sides
            // (re-review 2026-10-31).
            .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
            .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
            .scrollBounceBehavior(.basedOnSize)
        }
        .foregroundStyle(Palette.label)
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
