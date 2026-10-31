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
        .background(Palette.background)
        .foregroundStyle(Palette.label)
        .navigationTitle(part.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewingLoan) { LoanDetailSheet(loanID: $0.id) }
    }

    /// What counts as money in hand: counted accounts above zero, largest first, drawn as on the
    /// tab Tài khoản (`AccountRow`; strict review 2026-10-31: a second style here).
    private var accounts: some View {
        let accounts = store.countedAccounts.filter { $0.balance > 0 }.sorted { $0.balance > $1.balance }
        return VStack(spacing: 0) {
            ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                NavigationLink(value: account.id) {
                    AccountRow(account: account)
                }
                .buttonStyle(.row)
                .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
            }
        }
        .listCard()
    }

    /// Drawn as on the tab Tài khoản (`GoalRow`, its ring 32, and the logo-column hairline;
    /// re-review 2026-10-31: `ListRow` with a 20 icon here).
    private var goals: some View {
        let goals = store.activeGoals.sorted { $0.saved > $1.saved }
        return VStack(spacing: 0) {
            ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                NavigationLink(value: GoalRoute(id: goal.id)) {
                    GoalRow(goal: goal)
                }
                .buttonStyle(.row)
                .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
            }
        }
        .listCard()
    }

    /// Loans still to be paid back, as on Vay nợ; tapping one opens its sheet.
    private var lent: some View {
        let loans = store.loans.filter { $0.direction == .lent && $0.outstanding > 0 }
        return LoanRowList(loans: loans) { viewingLoan = $0 }
    }
}
