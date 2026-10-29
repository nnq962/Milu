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

/// The lead card of "Vay nợ" (user choice 2026-10-29): "Chênh lệch", what is lent minus what is
/// owed; a bar splitting the two (green lent, red owed); then the two sides in short ("80tr · 2
/// người"), each with its bar color as a dot. Loans with people only: a credit card's debt stays
/// on Tài khoản.
struct LoansSummaryCard: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let active = store.loans.filter { !$0.isSettled }
        let lenders = active.filter { $0.direction == .lent }.count
        let debts = active.filter { $0.direction == .borrowed }.count
        let lent = store.totalLent
        let owed = store.totalBorrowed
        // The same `SummaryCard` as "Tổng số dư" on Tài khoản.
        SummaryCard(label: "Chênh lệch", amount: lent - owed, tone: .plain) {
            SplitBar(lent: lent, owed: owed)
                .padding(.top, Spacing.m)
            HStack(spacing: Spacing.m) {
                tile("Cho vay", amount: lent, detail: "\(lenders) người", dot: Palette.green,
                     color: Palette.ink, background: Palette.incomeTile)
                // Red only while something is owed.
                tile("Đang nợ", amount: owed, detail: "\(debts) khoản", dot: Palette.red,
                     color: owed > 0 ? Palette.red : Palette.ink, background: Palette.muted)
            }
            .padding(.top, Spacing.m)
        }
    }

    private func tile(_ title: String, amount: Double, detail: String, dot: Color, color: Color,
                      background: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                Circle().fill(dot).frame(width: 8, height: 8)
                Text(title)
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryText)
            }
            (Text(amount.vndCompact).foregroundStyle(color)
                + Text(" · \(detail)").foregroundStyle(Palette.secondaryText))
                .textRole(.bodyStrong)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .cardSurface(radius: CardCorners.flow, color: background)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(amount.vnd), \(detail)")
    }
}

/// How lent and owed split, side by side on one bar (user request 2026-10-29). A side with
/// money keeps a sliver even when tiny; nothing at all is one grey bar.
private struct SplitBar: View {
    let lent: Double
    let owed: Double

    private static let height: CGFloat = 8
    private static let gap: CGFloat = 3
    /// The thinnest a side with money is drawn, so a small debt still shows.
    private static let sliver: CGFloat = 8

    var body: some View {
        let total = lent + owed
        GeometryReader { geometry in
            let width = geometry.size.width
            if total <= 0 {
                Capsule().fill(Palette.fill2)
            } else if lent <= 0 || owed <= 0 {
                Capsule().fill(lent > 0 ? Palette.green : Palette.red)
            } else {
                let room = width - Self.gap
                let lentWidth = min(max(room * lent / total, Self.sliver), room - Self.sliver)
                HStack(spacing: Self.gap) {
                    Capsule().fill(Palette.green).frame(width: lentWidth)
                    Capsule().fill(Palette.red)
                }
            }
        }
        .frame(height: Self.height)
        .animation(.smooth(duration: 0.3), value: lent)
        .animation(.smooth(duration: 0.3), value: owed)
        .accessibilityElement()
        .accessibilityLabel(total > 0
            ? "Cho vay \((lent / total).percentText), đang nợ \((owed / total).percentText)"
            : "Chưa có khoản vay")
    }
}

/// "Vay nợ" of the Transactions screen: loans with people (a credit card's debt stays on Tài
/// khoản, user choice 2026-10-29). On the page, the sections of the chip picked; in search, every
/// section with a match for the words and the kind (`filter`: Tất cả, Cho vay or Đi vay).
struct LoansContent: View {
    @Environment(FinanceStore.self) private var store
    var filter: LoanFilter = .all
    var searchText = ""
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

    private var lentLoans: [Loan] { shownLoans.filter { !$0.isSettled && $0.direction == .lent } }
    private var borrowedLoans: [Loan] { shownLoans.filter { !$0.isSettled && $0.direction == .borrowed } }
    private var settledLoans: [Loan] { shownLoans.filter(\.isSettled) }

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
            switch filter {
            case .all:
                lentSection
                borrowedSection
            case .lent:
                lentSection
            case .borrowed:
                borrowedSection
            }
            settledEntry
        }
    }

    /// The way into the loans repaid in full, at the bottom on every chip, once there is one.
    @ViewBuilder
    private var settledEntry: some View {
        let count = store.loans.count(where: \.isSettled)
        if count > 0 {
            NavigationLink(value: SettledLoansRoute()) {
                NavigationRowLabel(title: "Khoản vay đã tất toán", icon: "hugeicons-checkmark-badge-01",
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

    private var lentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader(title: "Cho vay") { remainingLabel(lentLoans.reduce(0) { $0 + $1.outstanding }) }
                .padding(.bottom, Spacing.headerGap - Spacing.m)
            if lentLoans.isEmpty {
                EmptyStateCard(icon: "hugeicons-hand-coins", title: "Chưa có khoản cho vay",
                               message: "Nhấn + để ghi lại số tiền bạn cho người khác vay.")
            }
            ForEach(lentLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.card)
            }
        }
    }

    private var borrowedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader(title: "Đi vay") { remainingLabel(borrowedLoans.reduce(0) { $0 + $1.outstanding }) }
                .padding(.bottom, Spacing.headerGap - Spacing.m)
            if borrowedLoans.isEmpty {
                EmptyStateCard(icon: "hugeicons-money-receive-02", title: "Chưa có khoản đi vay",
                               message: "Khoản bạn vay của người khác sẽ hiện ở đây.")
            }
            ForEach(borrowedLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.card)
            }
        }
    }

    /// Search only: the page keeps these behind `settledEntry`.
    private var settledSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader(title: "Đã tất toán")
                .padding(.bottom, Spacing.headerGap - Spacing.m)
            ForEach(settledLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.card)
            }
        }
    }

    private func remainingLabel(_ amount: Double) -> some View {
        Text("Còn \(amount.vndCompact)")
            .textRole(.captionStrong)
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
    }
}

/// "Khoản vay đã tất toán": loans repaid in full, newest first, as on the page; tapping one opens
/// its form (to read, reopen by changing what is left, or delete). Laid out as "Hũ đã hoàn thành".
struct SettledLoansView: View {
    @Environment(FinanceStore.self) private var store
    @State private var editingLoan: Loan?

    var body: some View {
        let loans = store.loans.filter(\.isSettled).sorted { $0.date > $1.date }
        ScrollView {
            if loans.isEmpty {
                // Reopening the last one empties this list while the screen is open.
                EmptyStateCard(icon: "hugeicons-checkmark-badge-01", title: "Chưa có khoản nào tất toán",
                               message: "Khoản vay đã thu hoặc trả đủ sẽ nằm ở đây.")
            } else {
                VStack(spacing: Spacing.m) {
                    ForEach(loans) { loan in
                        Button { editingLoan = loan } label: { LoanCard(loan: loan) }
                            .buttonStyle(.card)
                    }
                }
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Khoản vay đã tất toán")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingLoan) { LoanEditorView(loan: $0) }
    }
}

#Preview("Sửa khoản vay") {
    LoanEditorView(loan: SampleData.loans[0])
        .environment(FinanceStore())
}
