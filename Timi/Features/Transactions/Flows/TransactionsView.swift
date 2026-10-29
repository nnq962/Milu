import SwiftUI

enum TransactionSegment: String, CaseIterable, Identifiable {
    case flows, loans

    var id: Self { self }

    var title: String {
        switch self {
        case .flows: "Thu chi"
        case .loans: "Vay nợ"
        }
    }
}

struct TransactionsView: View {
    @Environment(FinanceStore.self) private var store
    @AppStorage("overview.monthlyBudget") private var monthlyBudget = SampleData.monthlyBudget
    @State private var segment: TransactionSegment = .flows
    @State private var filter: TransactionFilter = .all
    @State private var loanFilter: LoanFilter = .all
    @State private var displayedMonth = Date.now
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isAddingLoan = false
    @State private var editingLoan: Loan?
    /// A row tapped to change or delete it.
    @State private var editingItem: AccountDetailView.Activity?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Loại", selection: $segment) {
                        ForEach(TransactionSegment.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)

                    switch segment {
                    case .flows:
                        summaryCard
                        FilterChips(selection: $filter)
                        flowList
                    case .loans:
                        LoansContent(filter: $loanFilter, searchText: searchText) { editingLoan = $0 }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            // The title names the back button of pushed screens; the leading heading is the visible title.
            .navigationTitle("Giao dịch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) { HiddenToolbarTitle() }
                // A new transaction comes from the + beside the tab bar (every tab); a new loan from
                // the + here, shown on "Vay nợ" (user choice 2026-10-29).
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) { heading }
                        .sharedBackgroundVisibility(.hidden)
                    if segment == .loans {
                        ToolbarItem(placement: .topBarTrailing) {
                            addLoanButton.nativeCircleButton(diameter: 44)
                        }
                        .sharedBackgroundVisibility(.hidden)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        searchButton.nativeCircleButton(diameter: 44)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) { heading }
                    if segment == .loans {
                        ToolbarItem(placement: .topBarTrailing) { addLoanButton }
                    }
                    ToolbarItem(placement: .topBarTrailing) { searchButton }
                }
            }
            .modifier(OnDemandSearch(text: $searchText, isPresented: $isSearching,
                                     prompt: segment == .flows ? "Tìm giao dịch" : "Tìm khoản vay"))
            .navigationDestination(for: Account.ID.self) { AccountDetailView(accountID: $0) }
            .sheet(item: $editingItem) { ActivityEditor(item: $0) }
            .sheet(isPresented: $isAddingLoan) { LoanEditorView(loan: nil) }
            .sheet(item: $editingLoan) { LoanEditorView(loan: $0) }
        }
    }

    private var heading: some View {
        Text("Giao dịch")
            .textRole(.pageTitle)
            .foregroundStyle(Palette.ink)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
    }

    private var searchButton: some View {
        Button { isSearching = true } label: {
            TimiIcon("hugeicons-search-01", size: 20)
                .frame(width: 28, height: 28)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.ink)
        .accessibilityLabel(segment == .flows ? "Tìm giao dịch" : "Tìm khoản vay")
    }

    private var addLoanButton: some View {
        Button { isAddingLoan = true } label: {
            TimiIcon("hugeicons-add-01", size: 20)
                .frame(width: 28, height: 28)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.ink)
        .accessibilityLabel("Thêm khoản vay")
    }

    // MARK: - Thu chi

    private var monthTransactions: [FinanceTransaction] {
        store.monthlyTransactions(for: displayedMonth)
    }

    private var summaryCard: some View {
        let reported = store.reportableTransactions(inMonthOf: displayedMonth)
        let expenses = reported.filter { $0.kind == .expense }
        let incomes = reported.filter { $0.kind == .income }
        let spent = expenses.reduce(0) { $0 + $1.amount }
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                MonthMenu(month: $displayedMonth)
            }
            HStack(spacing: 0) {
                // The count is of rows in the list: a transfer fee adds to the sum, not the count.
                flowTotal("Đã chi · \(expenses.filter { $0.categoryID != TransactionCategory.transferFee.rawValue }.count)",
                          amount: spent)
                    .padding(.trailing, 16)
                    .overlay(alignment: .trailing) { Palette.border.frame(width: 1) }
                flowTotal("Đã thu · \(incomes.count)", amount: incomes.reduce(0) { $0 + $1.amount })
                    .padding(.leading, 16)
            }
            .padding(.top, 20)
            DailySpendingChart(month: displayedMonth, totals: Dictionary(grouping: expenses) { Calendar.current.component(.day, from: $0.date) }
                .mapValues { $0.reduce(0) { $0 + $1.amount } })
                .padding(.top, 20)
            if monthlyBudget > 0 {
                budgetRow(spent: spent)
                    .padding(.top, 16)
                    .overlay(alignment: .top) { Palette.border.frame(height: 1) }
                    .padding(.top, 16)
            }
        }
        .sleekCard(radius: CardCorners.extraLarge)
    }

    private func flowTotal(_ title: String, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryText)
            // Exact line height + minimumScaleFactor shrinks text unexpectedly on iOS; use min-height.
            Text(amount.vnd)
                .textRole(.amountLarge)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                .frame(minHeight: 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func budgetRow(spent: Double) -> some View {
        let ratio = spent / monthlyBudget
        let over = spent > monthlyBudget
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Đã dùng \(ratio.percentText) hạn mức tổng")
                    .textRole(.body)
                Spacer(minLength: 8)
                Text(over ? "vượt \((spent - monthlyBudget).vndCompact)" : "còn \((monthlyBudget - spent).vndCompact)")
                    .textRole(.captionStrong)
                    .foregroundStyle(over ? Palette.red : Palette.secondaryText)
                    .monospacedDigit()
            }
            // Same colors as the Overview limit bar: green within budget, red when over.
            ProgressBar(value: ratio, color: ProgressBar.budgetColor(ratio))
        }
        .accessibilityElement(children: .combine)
    }

    /// The month's transactions and transfers between accounts that match the chip and the search.
    private var filteredItems: [AccountDetailView.Activity] {
        let transactions = filter == .transfer ? [] : monthTransactions.filter { transaction in
            filter.matches(transaction)
                && (searchText.isEmpty
                    || transaction.note.localizedCaseInsensitiveContains(searchText)
                    || store.categoryName(transaction.categoryID).localizedCaseInsensitiveContains(searchText))
        }
        let transfers = filter != .all && filter != .transfer ? [] : store.accountTransfers.filter { transfer in
            Calendar.current.isDate(transfer.date, equalTo: displayedMonth, toGranularity: .month)
                && (searchText.isEmpty
                    || [transfer.fromAccountID, transfer.toAccountID].contains { store.account(id: $0)?.name.localizedCaseInsensitiveContains(searchText) == true }
                    || "chuyển khoản".localizedCaseInsensitiveContains(searchText)
                    || transfer.note.localizedCaseInsensitiveContains(searchText))
        }
        return AccountDetailView.activity(transactions: transactions, accountTransfers: transfers)
    }

    /// Gom theo ngày, ngày mới nhất lên đầu.
    private var itemsByDay: [(day: Date, items: [AccountDetailView.Activity])] {
        let groups = Dictionary(grouping: filteredItems) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in (day, groups[day] ?? []) }
    }

    @ViewBuilder
    private var flowList: some View {
        let groups = itemsByDay
        if groups.isEmpty {
            EmptyStateCard(icon: filter == .transfer ? "hugeicons-arrow-data-transfer-horizontal" : "hugeicons-inbox",
                           title: emptyTitle, message: emptyMessage)
        } else {
            ForEach(groups, id: \.day) { group in
                VStack(alignment: .leading, spacing: Spacing.headerGap) {
                    SectionHeader(title: group.day.transactionDayTitle) {
                        // A transfer's fee is spending of that day too.
                        DayTotals(items: group.items.compactMap {
                            switch $0 {
                            case .transaction(let transaction): transaction
                            case .accountTransfer(let transfer) where transfer.fee > 0: transfer.feeExpense
                            default: nil
                            }
                        })
                    }
                    VStack(spacing: 0) {
                        // Tapping a row opens it to change or delete, as in an account's history.
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                            ActivityRow(item: item, side: .account, detail: .time) { editingItem = $0 }
                                .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                        }
                    }
                    .cardSurface(color: Palette.card, elevated: true)
                }
            }
        }
    }

    private var emptyTitle: String {
        if !searchText.isEmpty { return "Không tìm thấy" }
        return filter == .transfer ? "Chưa có giao dịch chuyển khoản" : "Chưa có giao dịch"
    }

    private var emptyMessage: String {
        if !searchText.isEmpty { return "Không có giao dịch nào khớp với “\(searchText)” trong tháng này." }
        if filter == .transfer { return "Chuyển tiền giữa hai tài khoản bằng nút + cạnh thanh tab." }
        return "Thêm giao dịch đầu tiên để bắt đầu theo dõi."
    }
}

#Preview {
    TransactionsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
