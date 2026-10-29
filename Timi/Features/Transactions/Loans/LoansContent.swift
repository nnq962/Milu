import SwiftUI

enum LoanFilter: String, CaseIterable, Identifiable {
    case all, lent, borrowed, settled

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Tất cả"
        case .lent: "Cho vay"
        case .borrowed: "Đi vay"
        case .settled: "Đã tất toán"
        }
    }

    /// What the search's "Bộ lọc" picks from: the kind only (search shows every state).
    static let kinds: [LoanFilter] = [.all, .lent, .borrowed]

    /// The side a kind keeps; nil for "Tất cả" (and "Đã tất toán", which is a state).
    var direction: LoanDirection? {
        switch self {
        case .lent: .lent
        case .borrowed: .borrowed
        case .all, .settled: nil
        }
    }
}

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
            case .settled:
                settledSection
            }
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

    private var settledSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader(title: "Đã tất toán")
                .padding(.bottom, Spacing.headerGap - Spacing.m)
            if settledLoans.isEmpty {
                EmptyStateCard(icon: "hugeicons-checkmark-circle-02", title: "Chưa có khoản nào tất toán",
                               message: "Khoản vay đã thu hoặc trả đủ sẽ được lưu ở đây.")
            }
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

#Preview("Sửa khoản vay") {
    LoanEditorView(loan: SampleData.loans[0])
        .environment(FinanceStore())
}
