import SwiftUI

/// The search of "Giao dịch", on a screen of its own over everything (user choice 2026-10-29, as
/// banking apps do): iOS's own search field under the bar (`.searchable`, user request 2026-11-07,
/// over a field drawn by the app), ✕ on the left, "Bộ lọc" on the right, the filters that are on as
/// chips, then the recent searches (nothing typed, no filter) or what matches, by day, in every
/// month. The page behind stays as it is. On "Vay nợ" it searches loans the same way: the kind
/// (Cho vay, Đi vay) as its filter, its own recent searches (user choice 2026-10-29).
struct TransactionSearchView: View {
    let segment: TransactionSegment

    @Environment(FinanceStore.self) private var store
    @State private var query = ""
    /// Each text searched in, folded once ("Cà phê" → "ca phe") and kept for the next letters.
    @State private var keys = SearchKeys()
    /// Whether the search field is active (keyboard up); a recent search tapped lowers it.
    @State private var isSearchActive = false
    @State private var filter = TransactionSearchFilter()
    /// "Vay nợ": Tất cả, Cho vay or Đi vay.
    @State private var loanKind: LoanFilter = .all
    @State private var isFiltering = false
    /// The ×s of the recent searches grow with the text, no more than 1.6 times, as a chip's ×
    /// (review 2026-11-07).
    @ScaledMetric(relativeTo: .body) private var removeGlyph = RowMetrics.linkChevron
    /// A result tapped to read or change it.
    @State private var openedItem: AccountDetailView.Activity?
    @State private var editingLoan: Loan?
    /// The last searches, one per line (`remember`); "Vay nợ" keeps its own.
    @AppStorage private var historyText: String

    init(segment: TransactionSegment) {
        self.segment = segment
        _historyText = AppStorage(wrappedValue: "",
                                  segment == .flows ? "transactions.searchHistory" : "loans.searchHistory")
    }

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
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
                .padding(.top, Spacing.s)
                .padding(.bottom, Spacing.xxl)
                .animation(Motion.gentle(.smooth(duration: 0.25)), value: filter)
                .animation(Motion.gentle(.smooth(duration: 0.25)), value: loanKind)
                .animation(Motion.gentle(.smooth(duration: 0.2)), value: trimmedQuery.isEmpty)
            }
            .scrollDismissesKeyboard(.immediately)
            .pageBackground()
            .foregroundStyle(Palette.label)
            .navigationTitle(segment == .flows ? "Tìm giao dịch" : "Tìm khoản vay")
            .navigationBarTitleDisplayMode(.inline)
            // iOS's own field, always shown under the bar; "Tìm" on the keyboard keeps the words.
            // No keyboard on opening, as Mail and Settings: an active field takes the whole bar on
            // iOS 26, hiding ✕ and "Bộ lọc" (Simulator 2026-11-07); a tap on the field starts typing.
            .searchable(text: $query, isPresented: $isSearchActive,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: segment == .flows ? "Hạng mục, ghi chú, tài khoản" : "Tên người vay hoặc cho vay")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onSubmit(of: .search) { remember(query) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
                ToolbarItem(placement: .topBarTrailing) { filterButton }
            }
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

    // MARK: - Kết quả

    @ViewBuilder
    private var flowsResults: some View {
        if trimmedQuery.isEmpty && !filter.isActive {
            recentSearches
        } else {
            let matcher = filter.matcher(in: store)
            let groups = ActivityDayList.byDay(matches(matcher))
            if groups.isEmpty {
                EmptyStateCard(icon: "hugeicons-search-01", title: "Không tìm thấy", message: emptyMessage,
                               picture: IconCatalog.emojiName("🧭"))
            } else {
                // The day's title over its card, as on Giao dịch (review 2026-11-07).
                ActivityDayList(groups: groups, headingOutside: true) { openedItem = $0 }
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

    private var activeCount: Int { segment == .flows ? filter.activeCount : (loanKind == .all ? 0 : 1) }

    /// "Bộ lọc" on the bar: SF's filter lines in the bar's glass, tinted while something is on,
    /// as in Mail (user request 2026-11-07, with the native search field).
    private var filterButton: some View {
        let count = activeCount
        return Button { isFiltering = true } label: {
            BarSymbol(FilterGlyph.name(isActive: count > 0))
        }
        .filterBarButtonStyle(isActive: count > 0)
        .accessibilityLabel(count > 0 ? "Bộ lọc, đang bật \(count)" : "Bộ lọc")
    }

    /// One chip per thing that is on (× drops it, a tap opens "Bộ lọc"); nothing while nothing is.
    /// They wrap rather than scroll: in a scrolling row iOS holds a touch to see whether it
    /// scrolls, so the chips' press showed late (user report 2026-10-31).
    @ViewBuilder
    private var filterChips: some View {
        if !activeChips.isEmpty {
            FlowLayout(spacing: Spacing.s) {
                ForEach(activeChips) { chip in
                    TagChip(title: chip.title, hint: "Mở bộ lọc", spokenTitle: chip.spoken,
                            action: { isFiltering = true }) {
                        withAnimation(Motion.gentle(.smooth(duration: 0.25))) { chip.clear() }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
    }

    /// One thing that is on: the chip opens "Bộ lọc", × drops it.
    private struct ActiveChip: Identifiable {
        let id: String
        let title: String
        var spoken: String? = nil
        let clear: () -> Void
    }

    private var activeChips: [ActiveChip] {
        switch segment {
        case .flows:
            filter.chips(in: store).map { chip in
                ActiveChip(id: "\(chip.part)", title: chip.title, spoken: chip.spoken) { filter.clear(chip.part) }
            }
        case .loans:
            loanKind == .all ? [] : [ActiveChip(id: "kind", title: loanKind.title) { loanKind = .all }]
        }
    }

    /// What matches the words and the filters, in every month: a transaction by its category,
    /// group, note or account; a transfer by either account, its note, "chuyển khoản" (and "phí"
    /// when it has a fee); money into or out of a goal by the goal, the account, "nạp/rút hũ"; a
    /// new loan's money by its person, kind and account; a repayment by "thu/trả nợ", "lãi", the
    /// person and the account. Every word has to be found, in any order, accents aside ("momo cafe").
    /// No words: everything the filters let through.
    private func matches(_ matcher: TransactionSearchFilter.Matcher) -> [AccountDetailView.Activity] {
        let words = trimmedQuery.searchKey.split(separator: " ")
        let keys = keys
        func found(in text: String) -> Bool {
            guard !words.isEmpty else { return true }
            let key = keys.key(for: text)
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
        let goalTransfers = store.goalTransfers.filter { transfer in
            guard matcher.matches(transfer) else { return false }
            let kind = transfer.direction == .deposit ? "nạp vào hũ" : "rút từ hũ"
            return found(in: "\(kind) chuyển khoản \(names[transfer.goalID] ?? "") \(names[transfer.accountID] ?? "") \(transfer.note)")
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
        return AccountDetailView.activity(transactions: transactions, transfers: goalTransfers,
                                          accountTransfers: transfers, loans: loans, loanPayments: payments)
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
            // Over its card, as the days of the results below it (review 2026-11-07).
            OutsideHeaderSection(title: "Tìm kiếm gần đây") {
                Button { withAnimation(Motion.gentle(.smooth(duration: 0.25))) { historyText = "" } } label: {
                    HeaderLink(title: "Xoá")
                }
                .headerLinkButton()
                .accessibilityLabel("Xoá lịch sử tìm kiếm")
            } content: {
                VStack(spacing: 0) {
                    ForEach(Array(history.enumerated()), id: \.element) { index, item in
                        HStack(spacing: 0) {
                            Button {
                                remember(item)
                                // The keyboard down first, then the words: lowering an active
                                // field is its "Huỷ", which empties it (review 2026-11-07).
                                if isSearchActive {
                                    isSearchActive = false
                                    Task { @MainActor in query = item }
                                } else {
                                    query = item
                                }
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
                                // SF's ✕, as every ✕ of the app (review 2026-11-07).
                                Image(systemName: "xmark")
                                    .font(.system(size: RowMetrics.capped(removeGlyph, base: RowMetrics.linkChevron) * IconSize.removeScale,
                                                  weight: .semibold))
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
        withAnimation(Motion.gentle(.smooth(duration: 0.25))) {
            historyText = history.filter { $0 != text }.joined(separator: "\n")
        }
    }
}

/// Texts folded for search, kept while the search screen is open: folding thousands of notes and
/// names again on every letter made typing lag (review 2026-11-09). A class, so filling it while
/// drawing changes nothing SwiftUI watches.
final class SearchKeys {
    private var cache: [String: String] = [:]

    func key(for text: String) -> String {
        if let key = cache[text] { return key }
        let key = text.searchKey
        cache[text] = key
        return key
    }
}
