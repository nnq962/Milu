import Combine
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
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @State private var segment: TransactionSegment = .flows
    @State private var filter: TransactionFilter = .all
    @State private var loanFilter: LoanFilter = .all
    @State private var displayedMonth = Date.now
    /// The day the page was last drawn for: left open overnight, it moves on (`followToday`).
    @State private var today = Date.now
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSearching = false
    @State private var isAddingLoan = false
    @State private var editingLoan: Loan?
    /// A row tapped to read it (then change or delete it from its sheet).
    @State private var editingItem: AccountDetailView.Activity?
    /// The visible height of the page: the list keeps at least that, so a short filter does not
    /// pull the page back up.
    @State private var viewportHeight: CGFloat = 0
    /// Where the chip row is on screen: below the bar means the user has scrolled past it.
    @State private var chipsTop: CGFloat = 0

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroller in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.section) {
                        Picker("Loại", selection: $segment) {
                            ForEach(TransactionSegment.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.large)

                        // Both segments: the card, the chips, then the list. A new chip or month:
                        // the list fades over to what it shows now. It keeps at least a screen's
                        // height, so a shorter one leaves the page where it is instead of snapping
                        // it up.
                        switch segment {
                        case .flows:
                            summaryCard
                            chipsRow { FilterChips(selection: $filter) }
                            listContainer { flowList }
                        case .loans:
                            LoansSummaryCard()
                            chipsRow { ChipRow(options: LoanFilter.allCases, selection: $loanFilter) { $0.title } }
                            listContainer { LoansContent(filter: loanFilter, today: today) { editingLoan = $0 } }
                        }
                    }
                    .animation(.smooth(duration: 0.3), value: listIdentity)
                    .padding(.horizontal, Spacing.page)
                    .padding(.top, Spacing.l)
                    .padding(.bottom, Spacing.xxl)
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewportHeight = $0 }
                // Scrolled down into the list: a new chip glides back to the chips, so what it
                // shows starts in view.
                .onChange(of: listIdentity) {
                    guard chipsTop < 0 else { return }
                    withAnimation(.smooth(duration: 0.35)) { scroller.scrollTo(Self.chipsAnchor, anchor: .top) }
                }
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
                // The month is picked here, beside search (user choice 2026-10-29), on "Thu chi".
                // Search opens a screen of its own (TransactionSearchView).
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) { heading }
                        .sharedBackgroundVisibility(.hidden)
                    // One item, so the month (or the loan +) sits 8pt from search, not the bar's wider
                    // gap between separate items.
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: Spacing.s) {
                            if segment == .flows {
                                MonthMenu(month: $displayedMonth)
                            } else {
                                addLoanButton.nativeCircleButton(diameter: ControlHeight.regular)
                            }
                            searchButton.nativeCircleButton(diameter: ControlHeight.regular)
                        }
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) { heading }
                    if segment == .flows {
                        ToolbarItem(placement: .topBarTrailing) { MonthMenu(month: $displayedMonth) }
                    }
                    if segment == .loans {
                        ToolbarItem(placement: .topBarTrailing) { addLoanButton }
                    }
                    ToolbarItem(placement: .topBarTrailing) { searchButton }
                }
            }
            .fullScreenCover(isPresented: $isSearching) {
                TransactionSearchView(segment: segment)
            }
            .sheet(item: $editingItem) { ActivityEditor(item: $0) }
            .sheet(isPresented: $isAddingLoan) { LoanEditorView(loan: nil) }
            // A loan opens to read first; its pencil opens the form (user request 2026-10-29).
            .sheet(item: $editingLoan) { LoanDetailSheet(loanID: $0.id, today: today) }
            .navigationDestination(for: SettledLoansRoute.self) { _ in SettledLoansView() }
        }
        // Posted off the main thread; the page changes on the main one.
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            followToday()
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { followToday() } }
    }

    private static let chipsAnchor = "chips"

    /// The chip row, where a new chip scrolls back to.
    private func chipsRow(@ViewBuilder _ chips: () -> some View) -> some View {
        chips()
            .id(Self.chipsAnchor)
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView).minY } action: { chipsTop = $0 }
    }

    private func listContainer(@ViewBuilder _ list: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.section) { list() }
            .id(listIdentity)
            .transition(.opacity.combined(with: .offset(y: 12)))
            .frame(minHeight: viewportHeight, alignment: .top)
    }

    /// A new day: the chart lights it, and a page that showed the month just ended shows the new
    /// one (another month picked stays picked).
    private func followToday() {
        let now = Date.now
        guard !Calendar.current.isDate(now, inSameDayAs: today) else { return }
        if Calendar.current.isDate(displayedMonth, equalTo: today, toGranularity: .month) {
            displayedMonth = now
        }
        today = now
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
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.ink)
        .accessibilityLabel(segment == .flows ? "Tìm giao dịch" : "Tìm khoản vay")
    }

    private var addLoanButton: some View {
        Button { isAddingLoan = true } label: {
            TimiIcon("hugeicons-add-01", size: 20)
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.ink)
        .accessibilityLabel("Thêm khoản vay")
    }

    // MARK: - Thu chi

    private var monthTransactions: [FinanceTransaction] {
        store.monthlyTransactions(for: displayedMonth)
    }

    /// What the list shows: a new chip, month or segment redraws it with a fade.
    private var listIdentity: String {
        if segment == .loans { return "loans-\(loanFilter.rawValue)" }
        let parts = Calendar.current.dateComponents([.year, .month], from: displayedMonth)
        return "\(filter.rawValue)-\(parts.year ?? 0)-\(parts.month ?? 0)"
    }

    /// The two totals, a shorter chart and the budget on one line with its bar (user choice
    /// 2026-10-29), then "Xem báo cáo"; the month is picked in the toolbar.
    private var summaryCard: some View {
        let reported = store.reportableTransactions(inMonthOf: displayedMonth)
        let expenses = reported.filter { $0.kind == .expense }
        let incomes = reported.filter { $0.kind == .income }
        let spent = expenses.reduce(0) { $0 + $1.amount }
        // The counts are of the rows the "Chi" and "Thu" chips list (those not counted in the sum too).
        let listed = monthTransactions
        return VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: 0) {
                flowTotal("Đã chi", count: listed.count(where: TransactionFilter.expense.matches), amount: spent)
                    .padding(.trailing, Spacing.l)
                    .overlay(alignment: .trailing) { Palette.border.frame(width: 1) }
                flowTotal("Đã thu", count: listed.count(where: TransactionFilter.income.matches),
                          amount: incomes.reduce(0) { $0 + $1.amount })
                    .padding(.leading, Spacing.l)
            }
            DailySpendingChart(month: displayedMonth,
                               totals: Dictionary(grouping: expenses) { Calendar.current.component(.day, from: $0.date) }
                                   .mapValues { $0.reduce(0) { $0 + $1.amount } },
                               today: today, height: 44)
            if monthlyBudget > 0 {
                budgetRow(spent: spent)
                    .padding(.top, Spacing.m)
                    .overlay(alignment: .top) { Palette.border.frame(height: 1) }
            }
            // The month in detail: by group, against last month, per account (user choice 2026-10-30).
            NavigationLink {
                ReportView(period: ReportPeriod(.month, containing: displayedMonth))
            } label: {
                HStack(spacing: Spacing.s) {
                    TimiIcon("hugeicons-pie-chart", size: 18)
                    Text("Xem báo cáo")
                        .textRole(.captionStrong)
                    Spacer(minLength: Spacing.s)
                    TimiIcon("hugeicons-arrow-right-01", size: 16)
                        .foregroundStyle(Palette.secondary)
                }
                .foregroundStyle(Palette.ink)
                .frame(minHeight: ControlHeight.small)
                .contentShape(Rectangle())
            }
            .buttonStyle(.automatic)
            .padding(.top, Spacing.s)
            .overlay(alignment: .top) { Palette.border.frame(height: 1) }
        }
        .sleekCard(padding: Spacing.l, radius: CardCorners.extraLarge)
    }

    private func flowTotal(_ title: String, count: Int, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("\(title) · \(count)")
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryText)
            // Exact line height + minimumScaleFactor shrinks text unexpectedly on iOS; use min-height.
            Text(amount.vnd)
                .textRole(.amountLarge)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                .frame(minHeight: 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Read as words: "Đã chi 14.128.000 đồng, 22 giao dịch", not the "·" and a bare number.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(amount.vnd), \(count) giao dịch")
    }

    private func budgetRow(spent: Double) -> some View {
        let ratio = spent / monthlyBudget
        let over = spent > monthlyBudget
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text("Đã dùng \(ratio.percentText) hạn mức")
                    .textRole(.caption)
                Spacer(minLength: Spacing.s)
                Text(over ? "vượt \((spent - monthlyBudget).vndCompact)" : "còn \((monthlyBudget - spent).vndCompact)")
                    .textRole(.captionStrong)
                    .foregroundStyle(over ? Palette.red : Palette.secondaryText)
                    .monospacedDigit()
            }
            // Same colors as the Overview limit bar: green within budget, red when over.
            ProgressBar(value: ratio, color: ProgressBar.budgetColor(ratio))
        }
        // In full: "Đã dùng 85% hạn mức, còn 2.100.000 đ", not "còn 2,1tr".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Đã dùng \(ratio.percentText) hạn mức, "
            + (over ? "vượt \((spent - monthlyBudget).vnd)" : "còn \((monthlyBudget - spent).vnd)"))
    }

    /// The month's rows a chip lists, each to its own (user choice 2026-10-29): "Chi" and "Thu"
    /// their transactions, "Chuyển khoản" the transfers between accounts, "Tất cả" all of them and
    /// the money of new loans (neither income nor spending). A transfer's fee stays with the
    /// transfer (its sheet), not on "Chi".
    private var filteredItems: [AccountDetailView.Activity] {
        let inMonth = { (date: Date) in Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month) }
        let transactions = filter == .transfer ? [] : monthTransactions.filter(filter.matches)
        let transfers = filter != .all && filter != .transfer ? [] : store.accountTransfers.filter { inMonth($0.date) }
        let loans = filter != .all ? [] : store.loanMoves.filter { inMonth($0.date) }
        let payments = filter != .all ? [] : store.listedLoanPayments.filter { inMonth($0.date) }
        return AccountDetailView.activity(transactions: transactions, accountTransfers: transfers, loans: loans,
                                          loanPayments: payments)
    }

    @ViewBuilder
    private var flowList: some View {
        let groups = ActivityDayList.byDay(filteredItems)
        if groups.isEmpty {
            EmptyStateCard(icon: filter == .transfer ? "hugeicons-arrow-data-transfer-horizontal" : "hugeicons-inbox",
                           title: emptyTitle, message: emptyMessage)
        } else {
            // Tapping a row opens it to read, change or delete, as in an account's history.
            ActivityDayList(groups: groups) { editingItem = $0 }
        }
    }

    /// "Tháng 9" this year, "Tháng 9/2025" another.
    private var monthName: String {
        let calendar = Calendar.current
        let number = calendar.component(.month, from: displayedMonth)
        let sameYear = calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .year)
        return sameYear ? "Tháng \(number)" : "Tháng \(number)/\(calendar.component(.year, from: displayedMonth))"
    }

    /// Nothing at all on "Thu chi" yet, loans' money included: the first-run invitation.
    private var hasNothingRecorded: Bool {
        store.transactions.isEmpty && store.accountTransfers.isEmpty && store.loanMoves.isEmpty
            && store.listedLoanPayments.isEmpty
    }

    /// The empty list in the words of its chip and month; the first-run invitation only when the
    /// app has nothing recorded yet.
    private var emptyTitle: String {
        if hasNothingRecorded { return "Chưa có giao dịch" }
        return switch filter {
        case .all: "\(monthName) chưa có giao dịch"
        case .income: "\(monthName) chưa có khoản thu"
        case .expense: "\(monthName) chưa có khoản chi"
        case .transfer: "\(monthName) chưa có chuyển khoản"
        }
    }

    private var emptyMessage: String {
        if hasNothingRecorded {
            return "Thêm giao dịch đầu tiên bằng nút + cạnh thanh tab."
        }
        if filter == .transfer { return "Chuyển tiền giữa hai tài khoản bằng nút + cạnh thanh tab." }
        return "Chọn tháng khác ở nút tháng, hoặc thêm bằng nút + cạnh thanh tab."
    }
}

#Preview {
    TransactionsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
