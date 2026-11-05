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
    @Environment(AddTransactionContext.self) private var addContext: AddTransactionContext?
    @State private var segment: TransactionSegment = .flows
    @State private var filter: TransactionFilter = .all
    @State private var loanFilter: LoanFilter = .all
    @State private var displayedMonth = Date.now
    /// The day the page was last drawn for: left open overnight, it moves on (`followToday`).
    @State private var today = Date.now
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSearching = false
    /// Trợ lý AI from the ✦ on the bar, and the first transaction from the empty list's button.
    @State private var isShowingAssistant = false
    @State private var isAddingFirst = false
    @State private var editingLoan: Loan?
    /// A row tapped to read it (then change or delete it from its sheet).
    @State private var editingItem: AccountDetailView.Activity?
    /// Where the filter row is on screen: above the scroll view's top means the user has scrolled
    /// past it.
    @State private var filterTop: CGFloat = 0

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroller in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.section) {
                        // The head's card first: "Thu chi · Vay nợ" went up into the bar, in the
                        // title's place (user pick "B" 2026-11-04).
                        switch segment {
                        case .flows: summaryHead
                        case .loans: LoansSummaryHead()
                        }

                        // Then the filter words with the list they narrow, not with the head: they
                        // leave the totals as they are, and "Thu" under "Đã chi" read as broken
                        // (review 2026-11-03). A new filter or month: the list fades over to what
                        // it shows now. It keeps at least a screen's height, so a shorter one
                        // leaves the page where it is instead of snapping it up.
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            switch segment {
                            case .flows:
                                filterRow { TransactionFilterTabs(selection: $filter) }
                                listContainer { flowList }
                            case .loans:
                                filterRow { TextTabs(selection: $loanFilter, options: LoanFilter.allCases) { $0.title } }
                                listContainer { LoansContent(filter: loanFilter, today: today) { editingLoan = $0 } }
                            }
                        }
                    }
                    // A new month or segment fades over; a new filter shows its list at once, no
                    // animation (user request 2026-11-01: every animation tried felt jerky).
                    .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: pageIdentity)
                    .padding(.horizontal, Spacing.page)
                    .padding(.top, Spacing.l)
                    .padding(.bottom, Spacing.xxl)
                }
                // Scrolled down into the list: a new filter glides back to the filter row, so what
                // it shows starts in view.
                .onChange(of: listIdentity) {
                    guard filterTop < 0 else { return }
                    withAnimation(.smooth(duration: 0.35)) { scroller.scrollTo(Self.filterAnchor, anchor: .top) }
                }
            }
            // The plain page colour, as on Tài khoản (user report 2026-11-03: the ground read muddy).
            .pageBackground()
            .foregroundStyle(Palette.label)
            // No title on the bar (user pick "B" 2026-11-04): "Thu chi · Vay nợ" on its left, words
            // rather than a segmented control (user pick "B" 2026-11-03). The title stays for
            // VoiceOver and the back button.
            .modifier(HiddenTitleBar(title: "Giao dịch", leadingCircles: 0, trailingCircles: 2) { Color.clear.frame(height: 1) })
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { pageMenu }
                // The + beside the tab bar adds a transaction, or a loan while "Vay nợ" shows
                // (`AddTransactionContext.addsLoan`): no + of its own on the bar, which made two +
                // doing two things side by side and moved ✦ and search on each switch (review
                // 2026-11-03). The month is picked on the page; search opens a screen of its own
                // (TransactionSearchView).
                // Plain items: the bar draws their glass, which then takes part in push and pop
                // (glass drawn inside the item showed as a square mid-transition). The spacer
                // gives each its own glass rather than one shared pill.
                ToolbarItem(placement: .topBarTrailing) { assistantButton }
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) { searchButton }
            }
            .fullScreenCover(isPresented: $isShowingAssistant) {
                NavigationStack { AssistantView() }
                    .presentationBackground(Palette.background)
            }
            .sheet(isPresented: $isAddingFirst) { AddTransactionView() }
            .fullScreenCover(isPresented: $isSearching) {
                TransactionSearchView(segment: segment)
            }
            .sheet(item: $editingItem) { ActivityEditor(item: $0) }
            // A loan opens to read first; its pencil opens the form (user request 2026-10-29).
            .sheet(item: $editingLoan) { LoanDetailSheet(loanID: $0.id, today: today) }
            .navigationDestination(for: SettledLoansRoute.self) { _ in SettledLoansView() }
        }
        // Posted off the main thread; the page changes on the main one.
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            followToday()
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { followToday() } }
        // The + beside the tabs adds a loan while "Vay nợ" is what shows.
        .onAppear { addContext?.addsLoan = segment == .loans }
        .onChange(of: segment) { _, new in addContext?.addsLoan = new == .loans }
        .onDisappear { addContext?.addsLoan = false }
    }

    private static let filterAnchor = "filter"

    /// The filter row, where a new filter scrolls back to.
    private func filterRow(@ViewBuilder _ filter: () -> some View) -> some View {
        filter()
            .id(Self.filterAnchor)
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView).minY } action: { filterTop = $0 }
    }

    /// A new month or segment is another list: the old fades out over the new one in the same
    /// place, not stacked under it. A new filter just shows its rows.
    private func listContainer(@ViewBuilder _ list: () -> some View) -> some View {
        ZStack(alignment: .top) {
            // At least the visible height, so a short filter does not pull the page back up. By
            // layout, not a measured height kept in state: a keyboard in a sheet over this page
            // changed that height, and redrawing here rebuilt the form in the sheet, which lost its
            // focus and its edits (user report 2026-11-01).
            Color.clear.containerRelativeFrame(.vertical)
            VStack(alignment: .leading, spacing: Spacing.section) { list() }
                .id(pageIdentity)
                .transition(.opacity)
        }
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

    /// The page shown, in the bar's glass on the left: tapped, iOS's own menu opens from it to
    /// pick "Thu chi" or "Vay nợ", the one shown ticked (user request 2026-11-04, in place of a
    /// segmented control).
    private var pageMenu: some View {
        Menu {
            Picker("Trang", selection: $segment) {
                ForEach(TransactionSegment.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                // Regular words, as iOS's own glass buttons (user request 2026-11-04).
                // Nunito SemiBold 15, as "Hỏi Milu" beside it (user pick 2026-11-05).
                Text(segment.title)
                    .font(Typography.font(.subheadline, size: 15, weight: .semibold))
                TimiIcon("hugeicons-arrow-down-01", size: RowMetrics.linkChevron)
            }
            .foregroundStyle(Palette.primary)
        }
        .tint(Palette.primary)
        .accessibilityLabel("Trang")
        .accessibilityValue(segment.title)
        .accessibilityHint("Chọn Thu chi hoặc Vay nợ")
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

    /// ✦ Hỏi Timi, as on Tổng quan and Tài khoản.
    private var assistantButton: some View {
        AssistantBarButton { isShowingAssistant = true }
    }

    // MARK: - Thu chi

    private var monthTransactions: [FinanceTransaction] {
        store.monthlyTransactions(for: displayedMonth)
    }

    /// The list as a whole: a new month or segment is another list, faded over.
    private var pageIdentity: String {
        if segment == .loans { return "loans" }
        let parts = Calendar.current.dateComponents([.year, .month], from: displayedMonth)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)"
    }

    /// What the list shows, filter included: what the page animates and scrolls back to the filter for.
    private var listIdentity: String {
        if segment == .loans { return "loans-\(loanFilter.rawValue)" }
        let parts = Calendar.current.dateComponents([.year, .month], from: displayedMonth)
        return "\(filter.rawValue)-\(parts.year ?? 0)-\(parts.month ?? 0)"
    }

    /// The head of "Thu chi", in a card as "Cho vay | Đi vay" beside it (user request 2026-11-03:
    /// on the bare page both read loose): "Đã chi tháng 11 ⌄", which picks the month, and "Báo cáo
    /// ›" to the month's report on one line, what went out in large type, and the month's spending
    /// day by day under it ("B+", 2026-11-03). No more words ("too many words", 2026-11-03: income
    /// is under "Thu", the limit on Tổng quan).
    private var summaryHead: some View {
        let reported = store.reportableTransactions(inMonthOf: displayedMonth)
        let spent = reported.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            // "Báo cáo ›" goes under the month at the largest text sizes, where on one line the
            // two pushed the page past the screen (review 2026-11-03).
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    monthButton
                    Spacer(minLength: Spacing.s)
                    reportLink
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    monthButton
                    reportLink
                }
            }
            // Ink, not red: the figure of the page, read every day (red is for a line of money out).
            // VoiceOver hears what it is, which the month button above carries on screen.
            MoneyText(amount: spent, size: .display, tone: .neutral)
                .accessibilityLabel("Đã chi \(monthName.lowercased()), \(MoneyText.spoken(spent))")
            DailySpendBars(month: displayedMonth, today: today)
                .padding(.top, Spacing.m)
        }
        .card()
    }

    private var monthButton: some View {
        MonthPickerButton(month: $displayedMonth, lead: "Đã chi")
    }

    private var reportLink: some View {
        NavigationLink {
            ReportView(period: ReportPeriod(.month, containing: displayedMonth))
        } label: {
            HeaderLink(title: "Báo cáo", opensPage: true)
        }
        .headerLinkButton()
    }

    /// The month's rows a filter lists, each to its own (user choice 2026-10-29): "Chi" and "Thu"
    /// their transactions, "Chuyển khoản" the transfers between accounts and the money put into or
    /// taken from goals (review 2026-10-31: it said "chưa có chuyển khoản" with eight deposits that
    /// month), "Tất cả" all of them and the money of new loans (neither income nor spending). A
    /// transfer's fee stays with the transfer (its sheet), not on "Chi".
    private var filteredItems: [AccountDetailView.Activity] {
        let inMonth = { (date: Date) in Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month) }
        let transactions = filter == .transfer ? [] : monthTransactions.filter(filter.matches)
        let transfers = filter != .all && filter != .transfer ? [] : store.accountTransfers.filter { inMonth($0.date) }
        let goalTransfers = filter != .all && filter != .transfer ? [] : store.goalTransfers.filter { inMonth($0.date) }
        let loans = filter != .all ? [] : store.loanMoves.filter { inMonth($0.date) }
        let payments = filter != .all ? [] : store.listedLoanPayments.filter { inMonth($0.date) }
        return AccountDetailView.activity(transactions: transactions, transfers: goalTransfers,
                                          accountTransfers: transfers, loans: loans,
                                          loanPayments: payments)
    }

    @ViewBuilder
    private var flowList: some View {
        let groups = ActivityDayList.byDay(filteredItems)
        if groups.isEmpty {
            VStack(spacing: Spacing.l) {
                EmptyStateCard(icon: filter == .transfer ? "hugeicons-arrow-data-transfer-horizontal" : "hugeicons-inbox",
                               title: emptyTitle, message: emptyMessage,
                               picture: filter == .transfer ? IconCatalog.emojiName("💵") : IconCatalog.emojiName("📝"))
                // Before anything is recorded, the way to start, under the card (2026-11-03).
                if hasNothingRecorded {
                    TimiButton("Ghi khoản đầu tiên", icon: "hugeicons-add-01", role: .primary, fullWidth: true) {
                        isAddingFirst = true
                    }
                }
            }
        } else {
            // Tapping a row opens it to read, change or delete, as in an account's history.
            ActivityDayList(groups: groups) { editingItem = $0 }
        }
    }

    /// "Tháng 9" this year, "Tháng 9/2025" another: the month in the empty list's words.
    private var monthName: String { MonthPickerButton.name(of: displayedMonth) }

    /// Nothing at all on "Thu chi" yet, loans' money included: the first-run invitation.
    private var hasNothingRecorded: Bool {
        store.transactions.isEmpty && store.accountTransfers.isEmpty && store.goalTransfers.isEmpty
            && store.loanMoves.isEmpty
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
        case .transfer: "Tiền chuyển giữa tài khoản và nạp, rút hũ sẽ hiện ở đây."
        }
    }
}

#Preview {
    TransactionsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
