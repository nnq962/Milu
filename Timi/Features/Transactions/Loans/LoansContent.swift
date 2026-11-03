import SwiftUI

/// The kind a chip or the search's "Bộ lọc" keeps. Settled loans have no chip: they sit behind
/// "Khoản vay đã tất toán" at the bottom of the page (user choice 2026-10-29, as "Hũ đã hoàn thành").
enum LoanFilter: String, CaseIterable, Identifiable {
    case all, lent, borrowed

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Tất cả"
        case .lent: "Cho vay"
        case .borrowed: "Đi vay"
        }
    }

    /// The side a kind keeps; nil for "Tất cả".
    var direction: LoanDirection? {
        switch self {
        case .lent: .lent
        case .borrowed: .borrowed
        case .all: nil
        }
    }
}

/// Opens "Khoản vay đã tất toán".
struct SettledLoansRoute: Hashable {}

/// The head of "Vay nợ": what others owe you and what you owe, side by side at one size, with how
/// many people under each, in a card as the head of Thu chi beside it (user request 2026-11-03,
/// after a day on the bare page read loose). Loans with people only: a credit card's debt stays
/// on Tài khoản.
struct LoansSummaryHead: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let active = store.loans.filter { !$0.isSettled }
        // People, not loans: two open loans to Minh Trần are one person.
        let lenders = Set(active.filter { $0.direction == .lent }.map { $0.contactID?.uuidString ?? $0.name }).count
        let debts = Set(active.filter { $0.direction == .borrowed }.map { $0.contactID?.uuidString ?? $0.name }).count
        let owed = store.totalBorrowed
        let lentWho = Self.who(lenders)
        let owedWho = Self.who(debts)
        // "Đi vay", the chip's and the section's word, not "Đang nợ"; red with "-" while
        // something is owed, as on its rows (strict review 2026-10-31). VoiceOver gets the words on
        // screen, "Không có ai" included.
        SplitTotals(items: [
            .init("Cho vay", amount: store.totalLent, accessibilityLabel: "Cho vay \(store.totalLent.vnd), \(lentWho)"),
            .init("Đi vay", amount: owed, tone: owed > 0 ? .signedExpense : .neutral,
                  accessibilityLabel: "Đi vay \(owed > 0 ? "-" : "")\(owed.vnd), \(owedWho)"),
        ]) { item in
            Text(item.title == "Cho vay" ? lentWho : owedWho)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
        }
        .card()
    }

    private static func who(_ people: Int) -> String {
        people == 0 ? "Không có ai" : "\(people) người"
    }
}

/// "Vay nợ" of the Transactions screen: loans with people (a credit card's debt stays on Tài
/// khoản, user choice 2026-10-29). On the page, the sections of the chip picked; in search, every
/// section with a match for the words and the kind (`filter`: Tất cả, Cho vay or Đi vay).
struct LoansContent: View {
    @Environment(FinanceStore.self) private var store
    var filter: LoanFilter = .all
    var searchText = ""
    /// The day the badges and the order are for; the page moves it on overnight.
    var today = Date.now
    var isSearching = false
    let onEdit: (Loan) -> Void

    private var trimmedSearch: String { searchText.trimmingCharacters(in: .whitespaces) }

    /// Every word found in the name, accents and stray spaces aside ("chi lan" finds "Chị Lan"),
    /// as the search of "Thu chi" does.
    private func matchesSearch(_ name: String) -> Bool {
        let words = searchText.searchKey.split(separator: " ")
        guard !words.isEmpty else { return true }
        let key = name.searchKey
        return words.allSatisfy { key.contains($0) }
    }

    /// The side the search keeps; the page keeps both and picks sections instead.
    private var direction: LoanDirection? { isSearching ? filter.direction : nil }

    private var shownLoans: [Loan] {
        store.loans.filter { loan in
            matchesSearch(loan.name) && (direction == nil || loan.direction == direction)
        }
    }

    /// Most urgent first: overdue, then the nearest deadline (user request 2026-10-29).
    private var lentLoans: [Loan] { shownLoans.filter { !$0.isSettled && $0.direction == .lent }.byUrgency(today: today) }
    private var borrowedLoans: [Loan] { shownLoans.filter { !$0.isSettled && $0.direction == .borrowed }.byUrgency(today: today) }
    /// The most recently settled first, as on "Khoản vay đã tất toán".
    private var settledLoans: [Loan] {
        shownLoans.filter(\.isSettled).sorted { store.settledDate(of: $0) > store.settledDate(of: $1) }
    }

    var body: some View {
        if isSearching {
            // Only the sections with a match: their empty cards are for a first visit (one even
            // points at a + the search does not have). Nothing at all: one "Không tìm thấy".
            if lentLoans.isEmpty && borrowedLoans.isEmpty && settledLoans.isEmpty {
                EmptyStateCard(icon: "hugeicons-search-01", title: "Không tìm thấy", message: emptyMessage)
            } else {
                if !lentLoans.isEmpty { lentSection }
                if !borrowedLoans.isEmpty { borrowedSection }
                if !settledLoans.isEmpty { settledSection }
            }
        } else {
            if filter != .borrowed { lentSection }
            if filter != .lent { borrowedSection }
            settledEntry
        }
    }

    /// The way into the loans repaid in full, at the bottom on every chip, once there is one.
    @ViewBuilder
    private var settledEntry: some View {
        let count = store.loans.count(where: \.isSettled)
        if count > 0 {
            NavigationLink(value: SettledLoansRoute()) {
                NavigationRowContent(title: "Khoản vay đã tất toán", icon: "hugeicons-checkmark-badge-01",
                                   value: "\(count)", spokenValue: "\(count) khoản")
            }
            .buttonStyle(.row)
            .listCard()
        }
    }

    /// Says what left nothing: the words, the kind, or both.
    private var emptyMessage: String {
        if trimmedSearch.isEmpty { return "Không có khoản vay nào khớp với bộ lọc." }
        let words = "“\(trimmedSearch)”"
        return filter == .all ? "Không có khoản vay nào khớp với \(words)."
            : "Không có khoản vay nào khớp với \(words) và bộ lọc."
    }

    // MARK: - Cho vay / Đi vay / Đã tất toán

    /// "Tất cả" on the page shows both sides under the card that already totals them: no "Còn …"
    /// beside the headings, which said the card's figure again (review 2026-10-31). A chip of one
    /// side, or search, keeps it.
    private var isOverview: Bool { filter == .all && !isSearching }

    private var lentSection: some View {
        HeaderCard(title: "Cho vay") {
            // What is left beside the heading once there is a loan: no "Còn 0đ" over the empty card.
            if !lentLoans.isEmpty && !isOverview {
                remainingLabel(lentLoans.reduce(0) { $0 + $1.outstanding }, tone: .neutral)
            }
        } content: {
            if lentLoans.isEmpty {
                // One short sentence, no button named (strict review 2026-10-31).
                // 3D pictures in the empty states of Vay nợ, as on Tài khoản (user request 2026-11-03).
                EmptyStateCard(icon: "hugeicons-hand-coins", title: "Chưa có ai vay",
                               message: "Khoản cho vay sẽ hiện ở đây.", picture: "fluent-handshake")
            }
            if !lentLoans.isEmpty {
                LoanRowList(loans: lentLoans, today: today, onOpen: onEdit)
            }
        }
    }

    private var borrowedSection: some View {
        HeaderCard(title: "Đi vay") {
            if !borrowedLoans.isEmpty && !isOverview {
                remainingLabel(borrowedLoans.reduce(0) { $0 + $1.outstanding }, tone: .signedExpense)
            }
        } content: {
            if borrowedLoans.isEmpty {
                // The same card on every chip (user choice 2026-10-31, after a single line on "Tất cả").
                EmptyStateCard(icon: "hugeicons-money-receive-02", title: "Chưa vay ai",
                               message: "Khoản đi vay sẽ hiện ở đây.", picture: "fluent-money")
            }
            if !borrowedLoans.isEmpty {
                LoanRowList(loans: borrowedLoans, today: today, onOpen: onEdit)
            }
        }
    }

    /// Search only: the page keeps these behind `settledEntry`.
    private var settledSection: some View {
        HeaderCard(title: "Đã tất toán") {
            LoanRowList(loans: settledLoans, today: today, onOpen: onEdit)
        }
    }

    /// "Còn 45tr" beside a heading: the amount by `MoneyText(.caption)` as a day's totals on Thu chi,
    /// in its rows' colour (re-review 2026-10-31: grey text there, MoneyText here).
    private func remainingLabel(_ amount: Double, tone: MoneyText.Tone) -> some View {
        HStack(spacing: Spacing.xs) {
            Text("Còn")
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryLabel)
            MoneyText(amount: amount, size: .caption, tone: tone)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Còn \(tone == .signedExpense ? "nợ " : "")\(amount.vnd)")
    }
}

/// "Khoản vay đã tất toán": loans repaid in full, the most recently settled first; tapping one opens
/// its sheet (history, then the form). Laid out as "Hũ đã hoàn thành".
struct SettledLoansView: View {
    @Environment(FinanceStore.self) private var store
    @State private var editingLoan: Loan?

    var body: some View {
        let loans = store.loans.filter(\.isSettled).sorted { store.settledDate(of: $0) > store.settledDate(of: $1) }
        ScrollView {
            if loans.isEmpty {
                // Reopening the last one empties this list while the screen is open.
                EmptyStateCard(icon: "hugeicons-checkmark-badge-01", title: "Chưa có khoản nào tất toán",
                               message: "Khoản vay đã thu hoặc trả đủ sẽ nằm ở đây.", picture: "fluent-goal")
            } else {
                LoanRowList(loans: loans) { editingLoan = $0 }
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .background(Palette.background)
        .foregroundStyle(Palette.label)
        .navigationTitle("Khoản vay đã tất toán")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingLoan) { LoanDetailSheet(loanID: $0.id) }
    }
}

#Preview("Sửa khoản vay") {
    LoanEditorView(loan: SampleData.loans[0])
        .environment(FinanceStore())
}
