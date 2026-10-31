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
    /// The report circle grows with the text as the month capsule beside it does, so the two stay
    /// one height (strict review 2026-10-31).
    @ScaledMetric(relativeTo: .body) private var reportDiameter = ControlHeight.regular
    @ScaledMetric(relativeTo: .body) private var reportGlyph = RowMetrics.toolbarGlyph
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
                        ScaledSegmentedPicker(title: "Loại", selection: $segment,
                                              options: TransactionSegment.allCases) { $0.title }
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
            .foregroundStyle(Palette.label)
            // The visible title (`TabHeading`) shrinks to the middle of the bar as the page scrolls,
            // as on Tài khoản.
            .navigationTitle("Giao dịch")
            .modifier(TabHeading())
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                // A new transaction comes from the + beside the tab bar (every tab); a new loan from
                // the + here, shown on "Vay nợ" (user choice 2026-10-29).
                // The month is picked on the page, beside "Đã chi" (user choice 2026-10-30): out of
                // the bar, the title has room to shrink to the middle as on Tài khoản.
                // Search opens a screen of its own (TransactionSearchView).
                // Plain items: the bar draws their glass, which then takes part in push and pop
                // (glass drawn inside the item showed as a square mid-transition). The spacer
                // gives each its own glass rather than one shared pill.
                if segment == .loans {
                    ToolbarItem(placement: .topBarTrailing) { addLoanButton }
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) { searchButton }
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

    private var searchButton: some View {
        Button { isSearching = true } label: {
            TimiIcon("hugeicons-search-01", size: RowMetrics.toolbarGlyph)
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel(segment == .flows ? "Tìm giao dịch" : "Tìm khoản vay")
    }

    private var addLoanButton: some View {
        Button { isAddingLoan = true } label: {
            // The same + as on Tài khoản, at the bar's one glyph size (strict review 2026-10-31).
            TimiIcon("hugeicons-add-circle", size: RowMetrics.toolbarGlyph)
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
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

    /// The month in a white card right under the segments, balanced (user request 2026-10-30: a big
    /// spending figure over a small income line read lopsided). A top row of two controls the same
    /// height: the month as a capsule, and a circle opening the month's report, both flat fills. Under
    /// it what went out and what came in side by side at one size, as on Báo cáo. The limit shows
    /// only when it needs a look: from 80% used, orange, red once over.
    private var summaryCard: some View {
        let reported = store.reportableTransactions(inMonthOf: displayedMonth)
        let spent = reported.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        let earned = reported.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        return VStack(alignment: .leading, spacing: Spacing.l) {
            HStack {
                MonthMenu(month: $displayedMonth)
                Spacer(minLength: Spacing.s)
                // The month in detail: by group, against last month, per account.
                NavigationLink {
                    ReportView(period: ReportPeriod(.month, containing: displayedMonth))
                } label: {
                    TimiIcon("hugeicons-pie-chart", size: reportGlyph)
                        .foregroundStyle(Palette.primary)
                }
                // Flat, as the month beside it: glass inside the card trailed it on scroll.
                .flatCircleButton(diameter: reportDiameter)
                .accessibilityLabel("Báo cáo tháng")
            }
            HStack(alignment: .top, spacing: 0) {
                monthTotal("Đã chi", amount: spent, tone: spent > 0 ? .signedExpense : .plain)
                    .padding(.trailing, Spacing.l)
                    .overlay(alignment: .trailing) { VerticalDivider() }
                monthTotal("Đã thu", amount: earned, tone: earned > 0 ? .signedIncome : .plain)
                    .padding(.leading, Spacing.l)
            }
            let progress = BudgetProgress(limit: monthlyBudget, spent: spent)
            if monthlyBudget > 0, progress.isOver || progress.isNearing {
                BudgetStatusLine(level: .init(progress),
                                 text: progress.isOver ? "Vượt hạn mức \((-progress.left).vndCompact)"
                                     : "Đã dùng \(progress.ratio.percentText) hạn mức, còn \(progress.left.vndCompact)")
            }
        }
        .card()
    }

    /// One side of the month: its name and the amount, signed in the app's colours.
    private func monthTotal(_ title: String, amount: Double, tone: MoneyText.Tone) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryLabel)
            MoneyText(amount: amount, size: .large, tone: tone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
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

    /// "Tháng 9" this year, "Tháng 9/2025" another: the words of the month button and its menu.
    private var monthName: String { MonthMenu.name(of: displayedMonth) }

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

    /// One short line on what will show here, no button named (strict review 2026-10-31).
    private var emptyMessage: String {
        if hasNothingRecorded { return "Khoản thu chi bạn ghi sẽ hiện ở đây." }
        return switch filter {
        case .all: "Thu chi trong tháng sẽ hiện ở đây."
        case .income: "Khoản thu trong tháng sẽ hiện ở đây."
        case .expense: "Khoản chi trong tháng sẽ hiện ở đây."
        case .transfer: "Tiền chuyển giữa tài khoản sẽ hiện ở đây."
        }
    }
}

#Preview {
    TransactionsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
