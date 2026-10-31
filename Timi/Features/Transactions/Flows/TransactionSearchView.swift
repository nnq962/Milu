import SwiftUI

/// The search of "Giao dịch", on a screen of its own over everything (user choice 2026-10-29, as
/// banking apps do): its own field on top with ✕, then the filters as chips, then the recent
/// searches (nothing typed, no filter) or what matches, by day, in every month. The page behind
/// stays as it is. On "Vay nợ" it searches loans the same way: chips for the kind (Cho vay, Đi
/// vay), its own recent searches (user choice 2026-10-29).
struct TransactionSearchView: View {
    let segment: TransactionSegment

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var filter = TransactionSearchFilter()
    /// "Vay nợ": Tất cả, Cho vay or Đi vay.
    @State private var loanKind: LoanFilter = .all
    @State private var isFiltering = false
    /// A result tapped to read or change it.
    @State private var openedItem: AccountDetailView.Activity?
    @State private var editingLoan: Loan?
    @FocusState private var isFieldFocused: Bool
    /// The last searches, one per line (`remember`); "Vay nợ" keeps its own.
    @AppStorage private var historyText: String

    init(segment: TransactionSegment) {
        self.segment = segment
        _historyText = AppStorage(wrappedValue: "",
                                  segment == .flows ? "transactions.searchHistory" : "loans.searchHistory")
    }

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.s)
                .padding(.bottom, Spacing.m)
            ScrollView {
                // Lazy: "Chi, Mọi lúc" can list every expense ever recorded.
                LazyVStack(alignment: .leading, spacing: Spacing.section) {
                    filterChips
                    Group {
                        switch segment {
                        case .flows: flowsResults
                        case .loans: loansResults
                        }
                    }
                    .transition(.opacity)
                }
                .padding(.horizontal, Spacing.page)
                .padding(.bottom, Spacing.xxl)
                .animation(.smooth(duration: 0.25), value: filter)
                .animation(.smooth(duration: 0.25), value: loanKind)
                .animation(.smooth(duration: 0.2), value: trimmedQuery.isEmpty)
            }
            .scrollDismissesKeyboard(.immediately)
            // No bar above it: iOS 26's soft top edge drew a light band behind the chips.
            .scrollEdgeEffectHidden(true, for: .all)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.label)
        // The keyboard comes up once the screen has slid in: started during the slide, it took
        // frames from it and the slide caught near its end (as TimiAmountField waits too).
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            isFieldFocused = true
        }
        .sheet(item: $openedItem) { ActivityEditor(item: $0) }
        .sheet(item: $editingLoan) { LoanDetailSheet(loanID: $0.id) }
        .sheet(isPresented: $isFiltering) {
            switch segment {
            case .flows: TransactionFilterSheet(filter: $filter)
            case .loans: LoanFilterSheet(kind: $loanKind)
            }
        }
        // Opening a result means the search was the right one: keep it.
        .onChange(of: openedItem) { _, item in if item != nil { remember(query) } }
        .onChange(of: editingLoan) { _, loan in if loan != nil { remember(query) } }
    }

    // MARK: - Ô tìm

    private var searchBar: some View {
        HStack(spacing: Spacing.s) {
            SearchField(prompt: segment == .flows ? "Tìm giao dịch" : "Tìm khoản vay", text: $query,
                        isFocused: $isFieldFocused) {
                remember(query)
            }
            Button { dismiss() } label: {
                TimiIcon("hugeicons-cancel-01", size: RowMetrics.toolbarGlyph)
                    .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
            }
            .nativeCircleButton(diameter: ControlHeight.regular)
            .tint(Palette.label)
            .accessibilityLabel("Đóng tìm kiếm")
        }
    }

    // MARK: - Kết quả

    @ViewBuilder
    private var flowsResults: some View {
        if trimmedQuery.isEmpty && !filter.isActive {
            recentSearches
        } else {
            let matcher = filter.matcher(in: store)
            let groups = ActivityDayList.byDay(matches(matcher))
            if groups.isEmpty {
                EmptyStateCard(icon: "hugeicons-search-01", title: "Không tìm thấy", message: emptyMessage)
            } else {
                ActivityDayList(groups: groups) { openedItem = $0 }
            }
        }
    }

    @ViewBuilder
    private var loansResults: some View {
        if trimmedQuery.isEmpty && loanKind == .all {
            recentSearches
        } else {
            LoansContent(filter: loanKind, searchText: query, isSearching: true) { editingLoan = $0 }
        }
    }

    // MARK: - Bộ lọc

    /// "Bộ lọc" (filled with a count when something is on), one chip per thing that is on (× drops
    /// it), then quick picks for what is not set yet, so the button never stands alone.
    private var filterChips: some View {
        // Scroll only when the chips overflow: a horizontal ScrollView behind glass draws a lighter
        // band across the row on iOS 26 (as ChipRow does).
        ViewThatFits(in: .horizontal) {
            chipStack.frame(maxWidth: .infinity, alignment: .leading)
            ScrollView(.horizontal) {
                chipStack.padding(.horizontal, Spacing.page)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectHidden(true, for: .all)
            .padding(.horizontal, -Spacing.page)
        }
    }

    private var chipStack: some View {
        let count = segment == .flows ? filter.activeCount : (loanKind == .all ? 0 : 1)
        return HStack(spacing: Spacing.s) {
            TagChip(title: count > 0 ? "Bộ lọc · \(count)" : "Bộ lọc",
                    icon: "hugeicons-filter-horizontal", isProminent: count > 0) { isFiltering = true }
                .accessibilityLabel(count > 0 ? "Bộ lọc, đang bật \(count)" : "Bộ lọc")

            ForEach(activeChips) { chip in
                TagChip(title: chip.title, hint: "Mở bộ lọc", action: { isFiltering = true }) {
                    withAnimation(.smooth(duration: 0.25)) { chip.clear() }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            ForEach(quickPicks, id: \.title) { pick in
                TagChip(title: pick.title, isSuggestion: true) {
                    Haptics.selection()
                    withAnimation(.smooth(duration: 0.25)) { pick.apply() }
                }
                .accessibilityHint("Thêm vào bộ lọc")
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }

    /// One thing that is on: the chip opens "Bộ lọc", × drops it.
    private struct ActiveChip: Identifiable {
        let id: String
        let title: String
        let clear: () -> Void
    }

    private var activeChips: [ActiveChip] {
        switch segment {
        case .flows:
            filter.chips(in: store).map { chip in
                ActiveChip(id: "\(chip.part)", title: chip.title) { filter.clear(chip.part) }
            }
        case .loans:
            loanKind == .all ? [] : [ActiveChip(id: "kind", title: loanKind.title) { loanKind = .all }]
        }
    }

    private struct QuickPick {
        let title: String
        let apply: () -> Void
    }

    /// What is not set yet, one tap to turn on: on "Thu chi" the kinds while none is chosen and
    /// "Tháng này" while no period is; on "Vay nợ" the two kinds while neither is.
    private var quickPicks: [QuickPick] {
        var picks: [QuickPick] = []
        switch segment {
        case .flows:
            if filter.kind == .all {
                // In the order of the chips on Thu chi and of "Loại" in Bộ lọc (strict review 2026-10-31).
                picks += [TransactionFilter.income, .expense, .transfer].map { kind in
                    QuickPick(title: kind.title) { filter.setKind(kind, groupsOf: store) }
                }
            }
            if filter.period == .all {
                picks.append(QuickPick(title: TransactionSearchFilter.Period.thisMonth.title) {
                    filter.period = .thisMonth
                })
            }
        case .loans:
            if loanKind == .all {
                picks += [LoanFilter.lent, .borrowed].map { kind in QuickPick(title: kind.title) { loanKind = kind } }
            }
        }
        return picks
    }

    /// What matches the words and the filters, in every month: a transaction by its category,
    /// group, note or account; a transfer by either account, its note, "chuyển khoản" (and "phí"
    /// when it has a fee); a new loan's money by its person, kind and account. Every word has to be
    /// found, in any order, accents aside ("momo cafe").
    /// No words: everything the filters let through.
    private func matches(_ matcher: TransactionSearchFilter.Matcher) -> [AccountDetailView.Activity] {
        let words = trimmedQuery.searchKey.split(separator: " ")
        func found(in text: String) -> Bool {
            guard !words.isEmpty else { return true }
            let key = text.searchKey
            return words.allSatisfy { key.contains($0) }
        }
        // Looked up once per search, not once per transaction.
        let categories = Dictionary(store.categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let names = Dictionary((store.accounts + store.archivedAccounts).map { ($0.id, $0.name) },
                               uniquingKeysWith: { first, _ in first })
            .merging(store.savingsGoals.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let transactions = store.transactions.filter { transaction in
            guard matcher.matches(transaction) else { return false }
            let item = categories[transaction.categoryID]
            let group = item?.parentID.flatMap { categories[$0]?.name } ?? ""
            let name = item?.name ?? store.categoryName(transaction.categoryID)
            return found(in: "\(name) \(group) \(transaction.note) \(names[transaction.accountID] ?? "")")
        }
        let transfers = store.accountTransfers.filter { transfer in
            guard matcher.matches(transfer) else { return false }
            let sides = [transfer.fromAccountID, transfer.toAccountID].compactMap { names[$0] }
            let fee = transfer.fee > 0 ? "phí" : ""
            return found(in: "chuyển khoản \(fee) \(sides.joined(separator: " ")) \(transfer.note)")
        }
        let loans = store.loanMoves.filter { loan in
            guard matcher.matches(loan) else { return false }
            return found(in: "\(loan.direction.title) khoản vay \(loan.name) \(loan.movedAccountID.flatMap { names[$0] } ?? "")")
        }
        let payments = store.loanPayments.filter { payment in
            guard let loan = store.loan(id: payment.loanID), matcher.matches(payment) else { return false }
            let kind = loan.direction == .lent ? "thu nợ" : "trả nợ"
            let interest = payment.interest > 0 ? (loan.direction == .lent ? "lãi cho vay" : "lãi đi vay") : ""
            return found(in: "\(kind) \(interest) khoản vay \(loan.name) \(names[payment.accountID] ?? "")")
        }
        return AccountDetailView.activity(transactions: transactions, accountTransfers: transfers, loans: loans,
                                          loanPayments: payments)
    }

    /// Says what left nothing: the words, the filters, or both.
    private var emptyMessage: String {
        if trimmedQuery.isEmpty { return "Không có giao dịch nào khớp với bộ lọc." }
        let words = "“\(trimmedQuery)”"
        return filter.isActive ? "Không có giao dịch nào khớp với \(words) và bộ lọc."
            : "Không có giao dịch nào khớp với \(words)."
    }

    // MARK: - Lịch sử tìm kiếm

    /// The last searches, newest first: tap one to search it again, × to forget it, "Xoá" to
    /// forget all (user request 2026-10-29).
    @ViewBuilder
    private var recentSearches: some View {
        let history = self.history
        if history.isEmpty {
            // One short line, no button named (strict review 2026-10-31).
            Text(segment == .flows ? "Tìm theo hạng mục, ghi chú hoặc tài khoản."
                 : "Tìm theo tên người vay hoặc cho vay.")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
                .padding(.horizontal, RowMetrics.horizontal)
        } else {
            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                // A full page's heading, as the days of the results (strict review 2026-10-31).
                SectionHeader(title: "Tìm kiếm gần đây") {
                    Button { withAnimation(.smooth(duration: 0.25)) { historyText = "" } } label: {
                        HeaderLink(title: "Xoá")
                    }
                    .headerLinkButton()
                    .accessibilityLabel("Xoá lịch sử tìm kiếm")
                }
                VStack(spacing: 0) {
                    ForEach(Array(history.enumerated()), id: \.element) { index, item in
                        HStack(spacing: 0) {
                            Button {
                                query = item
                                remember(item)
                            } label: {
                                FormRowLabel(title: item, icon: "hugeicons-clock-01")
                                    .padding(.vertical, RowMetrics.vertical)
                                    .frame(maxWidth: .infinity, minHeight: RowMetrics.minHeight, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            // × on the card's 16 edge, under "Xoá", with a 44 target that grows to
                            // the left and fills the row's height: the row stays 52, as every row
                            // (strict review 2026-10-31: 64 tall, × 31 in).
                            Button { forget(item) } label: {
                                TimiIcon("hugeicons-cancel-01", size: RowMetrics.inlineGlyph)
                                    .foregroundStyle(Palette.secondaryLabel)
                                    .frame(minWidth: ControlHeight.regular, maxHeight: .infinity, alignment: .trailing)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Xoá “\(item)” khỏi lịch sử")
                        }
                        .padding(.horizontal, RowMetrics.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                        .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                    }
                }
                .listCard()
            }
        }
    }

    /// Kept as lines, newest first, at most `historyLimit`.
    private var history: [String] {
        historyText.split(separator: "\n").map(String.init)
    }

    private static let historyLimit = 8

    /// Saves a search, newest first; one that differs only in case or accents ("an sang", "Ăn
    /// sáng") replaces the older one.
    private func remember(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let rest = history.filter { $0.searchKey != clean.searchKey }
        historyText = ([clean] + rest).prefix(Self.historyLimit).joined(separator: "\n")
    }

    private func forget(_ text: String) {
        withAnimation(.smooth(duration: 0.25)) {
            historyText = history.filter { $0 != text }.joined(separator: "\n")
        }
    }
}
