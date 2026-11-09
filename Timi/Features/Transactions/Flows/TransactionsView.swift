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
    @State private var isSearching = false
    /// Trợ lý AI from the ✦ on the bar.
    @State private var isShowingAssistant = false
    @State private var editingLoan: Loan?
    /// A row tapped to read it (then change or delete it from its sheet).
    @State private var editingItem: AccountDetailView.Activity?
    /// Whether the filter row has gone up past the scroll view's top. A yes or no, written only
    /// when it flips: its position, written every frame, rebuilt the whole page on every frame
    /// of a scroll (user report 2026-11-07).
    @State private var isPastFilter = false
    @State private var isShowingSettings = false
    /// Off the top of the page: the bar's soft edge shows (a yes or no, written on a flip).
    @State private var isScrolled = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroller in
                ScrollView {
                    // Milu's Giao dịch (Figma 317:6594, "Thu chi · Tất cả", 2026-11-07), laid out as
                    // Sổ ví: Than's sky with "Sổ giao dịch", the head of Tài khoản's height and
                    // shape, then "Thu chi ⌄" and "Báo cáo", the month with its figures, the
                    // filter and a card for each day. Spaced as Sổ ví (user report 2026-11-07): 24
                    // under the sky, 12 from a heading to its card, 28 between the parts.
                    VStack(alignment: .leading, spacing: 0) {
                        SkyHeader(overline: "Than ghi chép", title: "Sổ giao dịch",
                                  mascot: thanMascot, placement: .thanAtRest, sky: .than)
                        VStack(alignment: .leading, spacing: 0) {
                            sectionHead
                            figuresRow
                                .padding(.top, Spacing.m)
                                .padding(.bottom, Spacing.section - Spacing.m)
                            // The filter with the list it narrows: it leaves the totals as they
                            // are. A new month or segment: the list fades over to what it shows
                            // now. It keeps at least a screen's height, so a shorter one leaves
                            // the page where it is instead of snapping it up.
                            switch segment {
                            case .flows:
                                filterRow { TransactionFilterTabs(selection: $filter) }
                                listContainer {
                                    // Its own view: the page's scroll flags and a row tapped no
                                    // longer rebuild the month's list (review 2026-11-09).
                                    MonthFlowList(month: displayedMonth, filter: filter, editingItem: $editingItem)
                                        .equatable()
                                }
                            case .loans:
                                filterRow { SegmentPills(selection: $loanFilter, options: LoanFilter.allCases) { $0.title } }
                                listContainer { LoansContent(filter: loanFilter, today: today) { editingLoan = $0 } }
                            }
                        }
                        .padding(.horizontal, Spacing.page)
                        .padding(.top, Spacing.xxl)
                        .padding(.bottom, Spacing.xxl)
                    }
                    // A new month or segment fades over; a new filter shows its list at once, no
                    // animation (user request 2026-11-01: every animation tried felt jerky).
                    .animation(Motion.gentle(.smooth(duration: 0.3)), value: pageIdentity)
                }
                // Scrolled up, the page goes behind the bar's band, not under its buttons (review
                // 2026-11-07: "Sổ giao dịch" and "Thu chi" read through Q and Hỏi Milu).
                .topScrollEdgeIfAvailable(scrolled: isScrolled)
                .onScrolledFromTop { isScrolled = $0 }
                // Scrolled down into the list: a new filter glides back to the filter row, so what
                // it shows starts in view.
                .onChange(of: listIdentity) {
                    guard isPastFilter else { return }
                    withAnimation(Motion.gentle(.smooth(duration: 0.35))) { scroller.scrollTo(Self.filterAnchor, anchor: .top) }
                }
            }
            .pageBackground()
            .foregroundStyle(Palette.label)
            // The bar of Tài khoản: Q, opening Cài đặt, on the left, ✦ Hỏi Milu and search on the
            // right; no wordmark (user request 2026-11-07). The title stays for VoiceOver and the
            // back button.
            .modifier(HiddenTitleBar(title: "Giao dịch", leadingCircles: 1, trailingCircles: 2,
                                     trailingWidth: AssistantBarButton.width + Spacing.s + ControlHeight.regular) {
                // An empty slot, not EmptyView: with nothing there, iOS shows the title.
                Color.clear.frame(height: 1).accessibilityHidden(true)
            })
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                // Plain items: the bar draws their glass, which then takes part in push and pop.
                // The + beside the tab bar adds a transaction, or a loan while "Vay nợ" shows
                // (`AddTransactionContext.addsLoan`). The spacer gives each its own glass.
                ToolbarItem(placement: .topBarLeading) { ProfileBarButton { isShowingSettings = true } }
                ToolbarItem(placement: .topBarTrailing) { assistantButton }
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) { searchButton }
            }
            .sheet(isPresented: $isShowingSettings) { SettingsView() }
            .fullScreenCover(isPresented: $isShowingAssistant) {
                NavigationStack { AssistantView() }
                    .presentationBackground(Palette.background)
            }
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
            // 28 under the month card (the filter and the days are the next part), 12 over the
            // first day, as a heading over its card.
            .padding(.vertical, Spacing.m)
            .id(Self.filterAnchor)
            .onGeometryChange(for: Bool.self) { $0.frame(in: .scrollView).minY < 0 } action: { isPastFilter = $0 }
    }

    /// A new month or segment is another list: the old fades out over the new one in the same
    /// place, not stacked under it. A new filter just shows its rows.
    private func listContainer(@ViewBuilder _ list: () -> some View) -> some View {
        // Top-aligned without a ZStack: lining the list up by its top made the ZStack lay the whole
        // month out a second time on a tab's first frame (Instruments 2026-11-09).
        TopAlignedStack {
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

    /// A new day: the rows' "Hôm nay" moves on, and a page that showed the month just ended shows the new
    /// one (another month picked stays picked).
    private func followToday() {
        let now = Date.now
        guard !Calendar.current.isDate(now, inSameDayAs: today) else { return }
        if Calendar.current.isDate(displayedMonth, equalTo: today, toGranularity: .month) {
            displayedMonth = now
        }
        today = now
    }

    /// "Thu chi ⌄" as the section's heading, iOS's own menu opening from it to pick "Thu chi" or
    /// "Vay nợ", the one shown ticked (Figma 262:3298). As tall as its words, its tap 44 tall.
    /// "Báo cáo" is in the month card.
    private var sectionHead: some View {
        HStack(spacing: Spacing.s) {
            Menu {
                Picker("Trang", selection: $segment) {
                    ForEach(TransactionSegment.allCases) { Text($0.title).tag($0) }
                }
            } label: {
                HStack(spacing: IconSize.glyphGap) {
                    Text(segment.title)
                        .textRole(.heading)
                        .lineLimit(1)
                    // SF's ⌄, as the month's and the "›" of "Báo cáo" (user request 2026-11-07),
                    // larger with the heading.
                    Image(systemName: "chevron.down")
                        .font(.system(size: sectionChevron, weight: .semibold))
                        .accessibilityHidden(true)
                }
                .foregroundStyle(Palette.label)
                // Laid out as its words, as "Ví & ngân hàng" on Tài khoản; the tap reaches 44 tall.
                .contentShape(Rectangle().inset(by: -Spacing.s))
            }
            .tint(Palette.primary)
            .accessibilityLabel("Trang")
            .accessibilityValue(segment.title)
            .accessibilityHint("Chọn Thu chi hoặc Vay nợ")
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.s)
        }
    }

    @ScaledMetric(relativeTo: .title3) private var sectionChevron: CGFloat = IconSize.headingChevron
    @ScaledMetric(relativeTo: .subheadline) private var reportGlyph: CGFloat = IconSize.chevron

    private var searchButton: some View {
        Button { isSearching = true } label: {
            BarSymbol("magnifyingglass")
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel(segment == .flows ? "Tìm giao dịch" : "Tìm khoản vay")
    }

    /// ✦ Hỏi Milu, as on Tổng quan and Tài khoản.
    private var assistantButton: some View {
        AssistantBarButton { isShowingAssistant = true }
    }

    // MARK: - Thu chi

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

    /// Under the heading, 12 down, a card (user design 2026-11-07): on Thu chi the month, opening
    /// the wheels, and "Báo cáo" at its head, then what went out and came in that month side by
    /// side; on Vay nợ what is lent and owed.
    @ViewBuilder
    private var figuresRow: some View {
        switch segment {
        case .flows:
            VStack(alignment: .leading, spacing: Spacing.l) {
                // One above the other at the accessibility sizes, where side by side the two ran
                // past the card (review 2026-11-07).
                AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s, stackedSpacing: Spacing.m) {
                    MonthTitleButton(month: $displayedMonth)
                    Spacer(minLength: Spacing.s)
                    reportLink
                }
                MonthFlowFigures(month: displayedMonth)
                    .equatable()
            }
            .card()
        case .loans:
            LoansFigures()
                .card()
        }
    }

    /// "Báo cáo ›", in the link colour as the month beside it, to the month's report.
    private var reportLink: some View {
        NavigationLink {
            ReportView(period: ReportPeriod(.month, containing: displayedMonth))
        } label: {
            HStack(spacing: IconSize.glyphGap) {
                // 14, as "Tháng 11" at the other end of the row (HIG: one size for one row).
                Text("Báo cáo")
                    .textRole(.accessory)
                    .lineLimit(1)
                    .fixedSize()
                // SF's ›, as iOS ends a link to a page (user request 2026-11-07, over the chart).
                Image(systemName: "chevron.right")
                    .font(.system(size: reportGlyph, weight: .semibold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Palette.primary)
            .contentShape(Rectangle().inset(by: -Spacing.m))
        }
        .headerLinkButton()
        .accessibilityLabel("Báo cáo \(monthName.lowercased())")
    }

    /// "Tháng 9" this year, "Tháng 9/2025" another: the month in the empty list's words.
    private var monthName: String { MonthPickerButton.name(of: displayedMonth) }

    /// Than read from what is recorded, as Nâu on Tài khoản, the same every time the tab opens
    /// (user request 2026-11-07): curious before the first transaction or loan, at rest after.
    /// The swap hops in from the feet (`SkyHeader`).
    private var thanMascot: String {
        MonthFlowList.hasNothingRecorded(in: store) && store.loans.isEmpty ? "cun-than-dau-trang-to-mo" : "cun-than-dau-trang"
    }

}

/// What went out and came in in the month on "Thu chi" (Figma 317:6599). A view of its own, redrawn
/// only for another month or a change in the records, not when the page scrolls (review 2026-11-09).
struct MonthFlowFigures: View, Equatable {
    let month: Date
    @Environment(FinanceStore.self) private var store

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.month == rhs.month }

    var body: some View {
        let reported = store.reportableTransactions(inMonthOf: month)
        let spent = store.total(.expense, of: reported)
        let earned = store.total(.income, of: reported)
        let name = MonthPickerButton.name(of: month).lowercased()
        FigurePair(label: "Đã chi", amount: spent,
                   secondaryLabel: "Đã thu", secondaryAmount: earned,
                   secondaryTone: earned > 0 ? .income : .neutral,
                   accessibilityLabel: "Đã chi \(name), \(MoneyText.spoken(spent)). Đã thu \(MoneyText.spoken(earned))")
    }
}

/// The month's days on "Thu chi", each a card, or the empty card. A view of its own, compared by
/// month and filter: the page's scroll flags (`isScrolled`, `isPastFilter`) and a row tapped
/// rebuilt every row of the month before (review 2026-11-09). Records changed still redraw it.
struct MonthFlowList: View, Equatable {
    let month: Date
    let filter: TransactionFilter
    @Binding var editingItem: AccountDetailView.Activity?
    @Environment(FinanceStore.self) private var store

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.month == rhs.month && lhs.filter == rhs.filter }

    var body: some View {
        let groups = ActivityDayList.byDay(filteredItems)
        if groups.isEmpty {
            // The card alone: the + beside the tabs adds (user request 2026-11-07, no "Ghi khoản đầu
            // tiên" under it).
            EmptyStateCard(icon: filter == .transfer ? "hugeicons-arrow-data-transfer-horizontal" : "hugeicons-inbox",
                           title: emptyTitle, message: emptyMessage,
                           picture: filter == .transfer ? IconCatalog.emojiName("💸") : IconCatalog.emojiName("📝"))
                // As the parts of Tài khoản, both ways: the one leaving goes at once, the one coming
                // fades in, so the last day never shows through the empty card or the other way.
                .transition(.emptySwap)
        } else {
            // Tapping a row opens it to read, change or delete, as in an account's history. One
            // view, so the days leave and come as one (`.emptySwap`), not each with its own fade.
            // Lazy: the days under the fold are built as they scroll in, not the whole month on
            // the tab's first frame (Instruments 2026-11-09).
            LazyVStack(alignment: .leading, spacing: Spacing.section) {
                ActivityDayList(groups: groups, headingOutside: true) { editingItem = $0 }
            }
            .transition(.emptySwap)
        }
    }

    /// The month's rows a filter lists, each to its own (user choice 2026-10-29): "Chi" and "Thu"
    /// their transactions, "Chuyển khoản" the transfers between accounts and the money put into or
    /// taken from goals (review 2026-10-31: it said "chưa có chuyển khoản" with eight deposits that
    /// month), "Tất cả" all of them and the money of new loans (neither income nor spending). A
    /// transfer's fee stays with the transfer (its sheet), not on "Chi".
    private var filteredItems: [AccountDetailView.Activity] {
        let interval = DateInterval.month(of: month)
        let inMonth = { (date: Date) in interval.holds(date) }
        let transactions = filter == .transfer ? [] : store.transactions.filter { inMonth($0.date) && filter.matches($0) }
        let transfers = filter != .all && filter != .transfer ? [] : store.accountTransfers.filter { inMonth($0.date) }
        let goalTransfers = filter != .all && filter != .transfer ? [] : store.goalTransfers.filter { inMonth($0.date) }
        let loans = filter != .all ? [] : store.loanMoves.filter { inMonth($0.date) }
        let payments = filter != .all ? [] : store.listedLoanPayments.filter { inMonth($0.date) }
        return AccountDetailView.activity(transactions: transactions, transfers: goalTransfers,
                                          accountTransfers: transfers, loans: loans,
                                          loanPayments: payments)
    }

    /// "Tháng 9" this year, "Tháng 9/2025" another: the month in the empty list's words.
    private var monthName: String { MonthPickerButton.name(of: month) }

    /// Nothing at all on "Thu chi" yet, loans' money included: the first-run invitation.
    static func hasNothingRecorded(in store: FinanceStore) -> Bool {
        store.transactions.isEmpty && store.accountTransfers.isEmpty && store.goalTransfers.isEmpty
            && store.loanMoves.isEmpty
            && store.listedLoanPayments.isEmpty
    }

    /// The empty list in the words of its chip and month; the first-run invitation only when the
    /// app has nothing recorded yet.
    private var emptyTitle: String {
        if Self.hasNothingRecorded(in: store) { return "Chưa có giao dịch" }
        return switch filter {
        case .all: "\(monthName) chưa có giao dịch"
        case .income: "\(monthName) chưa có khoản thu"
        case .expense: "\(monthName) chưa có khoản chi"
        case .transfer: "\(monthName) chưa có chuyển khoản"
        }
    }

    /// One short line on what will show here, no button named (strict review 2026-10-31).
    private var emptyMessage: String {
        if Self.hasNothingRecorded(in: store) { return "Khoản thu chi bạn ghi sẽ hiện ở đây." }
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

/// Its pieces one over another, each at the top and the full width, as tall as the tallest. A
/// `ZStack(alignment: .top)` asks each piece where its top is, which for a long list means laying it
/// all out again; here each is measured once.
private struct TopAlignedStack: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)) }
        return CGSize(width: width ?? sizes.map(\.width).max() ?? 0, height: sizes.map(\.height).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            subview.place(at: bounds.origin, anchor: .topLeading,
                          proposal: ProposedViewSize(width: bounds.width, height: nil))
        }
    }
}
