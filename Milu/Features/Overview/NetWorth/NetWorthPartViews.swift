import SwiftUI

/// Pushes "Tài sản ròng" itself.
struct NetWorthRoute: Hashable {}

/// The parts of "Tài sản ròng", each pushed from its row so the page slides in and ‹ comes back
/// (user choice 2026-10-30: switching tab from there felt abrupt). Tổng quan's stack holds every
/// route of these pages, by value.
enum NetWorthPart: Hashable {
    case accounts, goals, lent

    var title: String {
        switch self {
        case .accounts: "Tài khoản"
        case .goals: "Hũ tiết kiệm"
        case .lent: "Cho vay"
        }
    }
}

struct NetWorthPartView: View {
    let part: NetWorthPart

    @Environment(FinanceStore.self) private var store
    @State private var viewingLoan: Loan?
    /// The account or goal open in its sheet, held by the page, not the row: a row that leaves
    /// the list while open (an account down to 0, a goal emptied with "Rút hết") took its sheet
    /// with it mid-use (review 2026-11-08).
    @State private var openAccount: Opened?
    @State private var openGoal: Opened?

    private struct Opened: Identifiable { let id: UUID }

    var body: some View {
        ScrollView {
            switch part {
            case .accounts: accounts
            case .goals: goals
            case .lent: lent
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle(part.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewingLoan) { LoanDetailSheet(loanID: $0.id) }
        .sheet(item: $openAccount) { AccountDetailSheet(accountID: $0.id) }
        .sheet(item: $openGoal) { GoalDetailSheet(goalID: $0.id) }
    }

    /// What counts as money in hand: counted accounts above zero, largest first, as `AccountRow`
    /// (the list row of the pages Tổng quan opens; the tab Tài khoản has its own `WalletRow`).
    private var accounts: some View {
        let accounts = store.countedAccounts.filter { $0.balance > 0 }.sorted { $0.balance > $1.balance }
        return Group {
            if accounts.isEmpty {
                empty(title: "Không còn tài khoản có tiền", message: "Tài khoản có số dư sẽ hiện ở đây.", emoji: "🏦")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        Button { openAccount = Opened(id: account.id) } label: {
                            AccountRow(account: account)
                        }
                        .buttonStyle(.row)
                        .separatorAbove(index > 0, order: index) { RowDivider(column: .logo) }
                    }
                }
                .listCard()
            }
        }
    }

    /// The goals saving, most saved first, as `GoalRow` (its ring 32 and the logo-column hairline;
    /// the tab Tài khoản shows them as jars, `GoalJar`).
    private var goals: some View {
        let goals = store.activeGoals.sorted { $0.saved > $1.saved }
        return Group {
            if goals.isEmpty {
                empty(title: "Chưa có hũ nào", message: "Hũ tiết kiệm đang để dành sẽ hiện ở đây.", emoji: "🐷")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                        Button { openGoal = Opened(id: goal.id) } label: {
                            GoalRow(goal: goal)
                        }
                        .buttonStyle(.row)
                        .separatorAbove(index > 0, order: index) { RowDivider(column: .logo) }
                    }
                }
                .listCard()
            }
        }
    }

    /// Loans still to be paid back, as on Vay nợ; tapping one opens its sheet.
    private var lent: some View {
        let loans = store.loans.filter { $0.direction == .lent && $0.outstanding > 0 }.byUrgency()
        return Group {
            if loans.isEmpty {
                empty(title: "Không còn khoản cho vay", message: "Khoản cho vay chưa thu hết sẽ hiện ở đây.", emoji: "🤝")
            } else {
                LoanRowList(loans: loans) { viewingLoan = $0 }
            }
        }
    }

    /// What a part shows once its last item is gone while the page is open (review 2026-11-08: a
    /// bare title).
    private func empty(title: String, message: String, emoji: String) -> some View {
        EmptyStateCard(title: title, message: message, picture: IconCatalog.emojiName(emoji))
    }
}
