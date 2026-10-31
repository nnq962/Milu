import SwiftUI

/// Home tab (HIG pass 2026-10-31): the native title and bar every tab has, then sections of one
/// white card each: the net worth, the shortcuts, this month, the groups that took most, the
/// first steps, and the calendar. Liquid Glass stays on the bar, the tab bar and the + beside it,
/// as the HIG keeps it for the controls layer; content sits on solid surfaces. One file per card
/// in `Cards/`, with the sheets they open.
struct OverviewView: View {
    /// "Cần chú ý" on the page; off for now (user request 2026-10-30).
    private static let showsAttention = false

    @State private var information: Information?
    @State private var isShowingSettings = false
    /// Every page Tổng quan opens goes by value: Tài sản ròng and its parts, Trợ lý AI, Báo cáo.
    @State private var path = NavigationPath()
    @State private var selectedDay: CalendarDay?
    /// The month Lịch thu chi shows.
    @State private var calendarMonth = Date.now
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota
    @AppStorage(StorageKey.askedAI) private var hasAskedAI = false

    private struct Information: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    private struct CalendarDay: Identifiable {
        let date: Date
        var id: Date { date }
    }

    var body: some View {
        let month = Date.now
        NavigationStack(path: $path) {
            ScrollView {
                // Sections 28 apart, as on every tab; a heading 8 above its card.
                VStack(alignment: .leading, spacing: Spacing.section) {
                    HeroCard { path.append(NetWorthRoute()) }
                    QuickActions { path.append(AssistantRoute()) }
                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Tháng này") {
                            Button { path.append(ReportRoute(month: month)) } label: {
                                HeaderLink(title: "Báo cáo", opensPage: true)
                            }
                            .headerLinkButton()
                        }
                        MonthCard(month: month) { path.append(ReportRoute(month: month)) }
                    }
                    if !store.expensesByCategory(inMonthOf: month).isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.headerGap) {
                            SectionHeader(title: "Chi nhiều nhất")
                            TopCategoriesCard(month: month) { path.append(ReportRoute(month: month)) }
                        }
                    }
                    OnboardingCard { path.append(AssistantRoute()) }
                    // Hidden for now, as if nothing needed a look (user request 2026-10-30). Set
                    // `showsAttention` back to true to bring it back.
                    if Self.showsAttention { AttentionCard() }
                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Lịch thu chi") {
                            // The month menu as plain words, as every control on a heading's row.
                            MonthMenu(month: $calendarMonth, compact: true)
                                .headerLinkButton()
                        }
                        MoneyCalendarCard(displayedMonth: $calendarMonth) { selectedDay = CalendarDay(date: $0) }
                            .card()
                    }
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.label)
            .navigationTitle("Tổng quan")
            .modifier(TabHeading())
            .toolbar(.visible, for: .navigationBar)
            // Plain buttons: the bar draws their glass circles, so they take part in its push and
            // pop.
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { profileButton }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) { notificationButton }
            }
            // Here, not on the card: the card goes away as its last step is done.
            .onChange(of: OnboardingCard.completedSteps(store, askedAI: hasAskedAI), initial: true) { _, steps in
                steps.forEach(quota.claim)
            }
            .navigationDestination(for: NetWorthRoute.self) { _ in NetWorthView() }
            .navigationDestination(for: AssistantRoute.self) { _ in AssistantView() }
            .navigationDestination(for: ReportRoute.self) { ReportView(period: ReportPeriod(.month, containing: $0.month)) }
            .navigationDestination(for: NetWorthPart.self) { NetWorthPartView(part: $0) }
            .navigationDestination(for: Account.ID.self) { AccountDetailView(accountID: $0) }
            .navigationDestination(for: GoalRoute.self) { GoalDetailView(goalID: $0.id) }
            .sheet(item: $information) { NoteSheet(title: $0.title, message: $0.message) }
            .sheet(item: $selectedDay) { DayTransactionsSheet(date: $0.date) }
            .sheet(isPresented: $isShowingSettings) { SettingsView() }
        }
    }

    // Native navigation-bar items: iOS owns their glass and the scroll-edge backdrop.
    private var profileButton: some View {
        Button {
            isShowingSettings = true
        } label: {
            // The initial drawn as an image: the bar sets an image in a circle like the bell, but
            // text (even an icon-only label) in a pill.
            Image(size: CGSize(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)) { context in
                context.draw(Text("Q").font(TextRole.heading.font).foregroundStyle(Palette.primary),
                             at: CGPoint(x: RowMetrics.toolbarGlyphFrame / 2, y: RowMetrics.toolbarGlyphFrame / 2))
            }
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Hồ sơ của Quyet")
        .accessibilityHint("Mở cài đặt")
    }

    private var notificationButton: some View {
        Button {
            information = Information(title: "Thông báo", message: "Bạn chưa có thông báo mới. Nhắc hạn thanh toán sẽ xuất hiện ở đây khi tính năng được bổ sung.")
        } label: {
            TimiIcon("hugeicons-notification-01", size: RowMetrics.toolbarGlyph)
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Thông báo")
    }
}

/// Pushes Trợ lý AI from Tổng quan (the last shortcut, or "Hỏi AI một câu hỏi").
struct AssistantRoute: Hashable {}

/// Pushes Báo cáo for a month from Tổng quan ("Tháng này", "Chi nhiều nhất").
struct ReportRoute: Hashable {
    let month: Date
}

#Preview {
    OverviewView()
        .environment(FinanceStore())
        .environment(AIQuota())
        .environment(AssistantChats())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
