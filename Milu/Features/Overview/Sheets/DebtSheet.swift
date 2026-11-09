import SwiftUI

/// What makes up "Nợ" on Tổng quan: the total under the bar, then cards and accounts below zero
/// and the loans still to repay. Scrolls, so many loans are never cut off (sheet review
/// 2026-10-30), with group headings and list blocks like every other sheet.
struct DebtSheet: View {
    @Environment(FinanceStore.self) private var store
    @State private var viewingLoan: Loan?
    /// An account below zero opens its sheet as a loan here does (review 2026-11-08: tapping a
    /// card did nothing). Held here, not on the row, so paying it off does not close it.
    @State private var openAccount: OpenAccount?

    private struct OpenAccount: Identifiable { let id: UUID }

    var body: some View {
        // Most owed first, and the loans by urgency as on Vay nợ (review 2026-11-08).
        let accounts = store.countedAccounts.filter { $0.balance < 0 }.sorted { $0.balance < $1.balance }
        let loans = store.loans.filter { $0.direction == .borrowed && $0.outstanding > 0 }.byUrgency()
        SheetScaffold(title: "Nợ") {
            // The total as a `MoneyText` under the bar, red with its sign like the "Nợ" row that
            // opens this (re-review 2026-10-31: "Nợ 12tr" in ink, and "Nợ 0đ" with none).
            if store.totalDebt > 0 {
                MoneyText(amount: -store.totalDebt, size: .large, tone: .balance)
                    .frame(maxWidth: .infinity)
            }
            if accounts.isEmpty && loans.isEmpty {
                EmptyStateCard(title: "Không có khoản nợ",
                               message: "Thẻ âm và khoản đi vay sẽ hiện ở đây.",
                               picture: IconCatalog.emojiName("💳"))
            }
            // Accounts and loans as the rows of the pages Tổng quan opens (`AccountRow`, `LoanRowList`),
            // and a loan opens its sheet as on Vay nợ (strict review 2026-10-31).
            if !accounts.isEmpty {
                group("Thẻ và tài khoản âm") {
                    VStack(spacing: 0) {
                        ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                            Button { openAccount = OpenAccount(id: account.id) } label: {
                                // "−" in ink as the loans under it: red is kept for the total
                                // (review 2026-11-08: red rows above ink ones for the same debt).
                                AccountRow(account: account, amountTone: .outflow)
                            }
                            .buttonStyle(.row)
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
        .miluSheetStyle([.medium, .large])
        .sheet(item: $viewingLoan) { LoanDetailSheet(loanID: $0.id) }
        .sheet(item: $openAccount) { AccountDetailSheet(accountID: $0.id) }
    }

    private func group(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: title, style: .group)
            content()
        }
    }
}
