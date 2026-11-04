import SwiftUI

/// Home tab (redone 2026-11-02 after the user's references: blocks on a soft coloured ground): the
/// head on its ground (`OverviewHeader`: the net worth and how it moved), then the
/// first steps, the calendar, this month and Timi Pro last;
/// Q, Timi's ✦ and the bell on the bar, no greeting (user request 2026-11-04). One file per card
/// in `Cards/`, with the sheets they open.
struct OverviewView: View {
    /// "Cần chú ý" on the page; off for now (user request 2026-10-30).
    private static let showsAttention = false

    @State private var information: Information?
    @State private var isShowingSettings = false
    /// Trợ lý AI, over everything from the ✦ on the bar.
    @State private var isShowingAssistant = false
    /// Every page Tổng quan opens goes by value: Tài sản ròng and its parts, Báo cáo.
    @State private var path = NavigationPath()
    @State private var selectedDay: CalendarDay?
    /// The month Lịch thu chi shows.
    @State private var calendarMonth = Date.now
    /// What a first step's button opens (`OnboardingCard`).
    @State private var adding: AddTransactionView.Mode?
    @State private var isAddingAccount = false
    @State private var isAddingLoan = false
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
                    OverviewHeader {
                        path.append(NetWorthRoute())
                    }
                    OnboardingCard { step in
                        switch step {
                        case .account: isAddingAccount = true
                        case .transaction: adding = .expense
                        case .loan: isAddingLoan = true
                        case .askAI: isShowingAssistant = true
                        }
                    }
                    HeaderCard(title: "Lịch thu chi", inset: Spacing.card, radius: CardCorners.large) {
                        // The month as plain words, as every control on a heading's row.
                        MonthPickerButton(month: $calendarMonth, compact: true)
                    } content: {
                        MoneyCalendarCard(displayedMonth: $calendarMonth) { selectedDay = CalendarDay(date: $0) }
                            .card()
                    }
                    HeaderCard(title: "Tháng này", inset: Spacing.card, radius: CardCorners.large) {
                        Button { path.append(ReportRoute(month: month)) } label: {
                            HeaderLink(title: "Báo cáo", opensPage: true)
                        }
                        .headerLinkButton()
                    } content: {
                        MonthCard(month: month) { path.append(ReportRoute(month: month)) }
                    }
                    // Hidden for now, as if nothing needed a look (user request 2026-10-30). Set
                    // `showsAttention` back to true to bring it back.
                    if Self.showsAttention { AttentionCard() }
                    // Last, at the foot of the page (user request 2026-10-31).
                    ProUpgradeCard {
                        information = Information(title: TimiProNote.title, message: TimiProNote.message)
                    }
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.xxl)
            }
            // The plain page, as every tab: the light of lime behind the head went (user request
            // 2026-11-03).
            .background(Palette.background)
            .foregroundStyle(Palette.label)
            // No title and no greeting on the bar (user request 2026-11-04), as on Tài khoản: Q on
            // the left, ✦ and the bell on the right. The title stays for the back button and VoiceOver.
            .modifier(HiddenTitleBar(title: "Tổng quan", leadingCircles: 1, trailingCircles: 2) { Color.clear.frame(height: 1) })
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                // Plain buttons: the bar draws their glass, which then takes part in push and pop.
                // The spacer gives ✦ and the bell each its own glass.
                ToolbarItem(placement: .topBarLeading) { profileButton }
                ToolbarItem(placement: .topBarTrailing) { assistantButton }
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) { notificationButton }
            }
            // Here, not on the card: the card goes away as its last step is done.
            .onChange(of: OnboardingCard.completedSteps(store, askedAI: hasAskedAI), initial: true) { _, steps in
                steps.forEach(quota.claim)
            }
            .navigationDestination(for: NetWorthRoute.self) { _ in NetWorthView() }
            .fullScreenCover(isPresented: $isShowingAssistant) {
                NavigationStack { AssistantView() }
                    .presentationBackground(Palette.background)
            }
            .navigationDestination(for: ReportRoute.self) { ReportView(period: ReportPeriod(.month, containing: $0.month)) }
            .navigationDestination(for: NetWorthPart.self) { NetWorthPartView(part: $0) }
            .sheet(item: $information) { NoteSheet(title: $0.title, message: $0.message) }
            .sheet(item: $selectedDay) { DayTransactionsSheet(date: $0.date) }
            .sheet(item: $adding) { AddTransactionView(mode: $0) }
            .sheet(isPresented: $isAddingAccount) { AddAccountView(type: .bank) }
            .sheet(isPresented: $isAddingLoan) { LoanEditorView(loan: nil) }
            .sheet(isPresented: $isShowingSettings) { SettingsView() }
        }
    }

    // Native navigation-bar items: iOS owns their glass and the scroll-edge backdrop.
    private var profileButton: some View {
        ProfileBarButton { isShowingSettings = true }
    }

    private var assistantButton: some View {
        AssistantBarButton { isShowingAssistant = true }
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

/// Pushes Báo cáo for a month from Tổng quan ("Tháng này").
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
