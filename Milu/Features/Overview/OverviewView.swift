import SwiftUI

/// Home tab: under Milu's hill, sections each with its heading on the page (2026-11-08): the first
/// steps while any is left (`OnboardingCard`, a row to swipe), Tài sản ròng (`OverviewHeader`),
/// Chi tiêu (`SpendingTiles`), Tuần này (`WeekCard`), Hũ và khoản vay (`SavingTiles`), Milu Pro;
/// Q, "✨ Hỏi Milu" and the bell on the bar, no greeting (user request 2026-11-04). One file per card
/// in `Cards/`, with the sheets they open.
struct OverviewView: View {
    /// "Cần chú ý" on the page; off for now (user request 2026-10-30).
    private static let showsAttention = false

    @State private var information: Information?
    @State private var isShowingPaywall = false
    @AppStorage(StorageKey.debugPro) private var debugPro = false
    @State private var isShowingSettings = false
    /// Trợ lý AI, over everything from the ✦ on the bar.
    @State private var isShowingAssistant = false
    /// Every page Tổng quan opens goes by value: Tài sản ròng and its parts, Báo cáo.
    @State private var path = NavigationPath()
    @State private var selectedDay: CalendarDay?
    /// What a first step's button opens (`OnboardingCard`).
    @State private var adding: AddTransactionView.Mode?
    @State private var isAddingAccount = false
    @State private var isAddingLoan = false
    @State private var isAddingGoal = false
    /// A recurring payment that fell due, being recorded ("Sắp tới" → "Ghi").
    @State private var confirmingRecurring: RecurringOccurrence?
    /// Off the top: the bar shows its soft edge; at the top the hill runs on under it.
    @State private var isScrolled = false
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = 0.0

    /// Milu's face for the month so far (trial 2026-11-09): sleepy late with nothing written
    /// today, sad past the month's limit, worried near it, all smiles well under it.
    private var miluLook: MiluHero.Look {
        let now = Date.now
        let calendar = Calendar.current
        if calendar.component(.hour, from: now) >= 20,
           !store.transactions.contains(where: { calendar.isDateInToday($0.date) }) {
            return .buonNgu
        }
        guard let share = budgetShare(at: now) else { return .macDinh }
        if share > 1 { return .buon }
        if share >= 0.8 { return .loLang }
        return share < 0.6 ? .cuoiTitMat : .macDinh
    }

    /// What was spent this month against the limit as it stands today (the month's limit spread
    /// over its days); nil with no limit.
    private func budgetShare(at now: Date) -> Double? {
        guard monthlyBudget > 0 else { return nil }
        let month = DateInterval.month(of: now)
        let calendar = Calendar.current
        let days = Double(calendar.range(of: .day, in: .month, for: now)?.count ?? 30)
        let day = Double(calendar.component(.day, from: now))
        let spent = store.total(.expense, in: month)
        if spent > monthlyBudget { return spent / monthlyBudget }
        return spent / (monthlyBudget * day / days)
    }

    private var miluGreeting: String {
        switch miluLook {
        case .buonNgu: "Hôm nay chưa ghi gì nè…"
        case .buon: "Lố hạn mức rồi…"
        case .loLang: "Sắp chạm hạn mức đó!"
        case .cuoiTitMat: "Tháng này ổn áp ghê!"
        default: "Chào bạn!"
        }
    }

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
        NavigationStack(path: $path) {
            ScrollView {
                // Milu's hill of three dogs (Figma 272:727, user request 2026-11-07): "Cả nhà Milu"
                // over Vàng, Than and Nâu, the same head as Tài khoản and Giao dịch; the blocks 24
                // under it.
                VStack(alignment: .leading, spacing: 0) {
                    SkyHeader(overline: "Milu đồng hành", milu: miluLook, greeting: miluGreeting,
                              sky: .meadow)
                    // Sections 28 apart, as on every tab, each with its heading on the page 8
                    // above its card (user request 2026-11-08: the headings out of the cards).
                    VStack(alignment: .leading, spacing: Spacing.section) {
                        // First while steps are left, so a new user sees what to do before the
                        // empty figures (user request 2026-11-08: a friendlier first run).
                        OnboardingCard { step in
                            switch step {
                            case .account: isAddingAccount = true
                            case .transaction: adding = .expense
                            case .loan: isAddingLoan = true
                            case .askAI: isShowingAssistant = true
                            }
                        }
                        OverviewHeader(onOpenNetWorth: { path.append(NetWorthRoute()) },
                                       onAddAccount: { isAddingAccount = true })
                        SpendingTiles(onOpenReport: { path.append(ReportRoute(month: .now)) },
                                      onOpenToday: { selectedDay = CalendarDay(date: .now) },
                                      onOpenBudget: { path.append(BudgetRoute()) })
                        // Rent, salary, subscriptions that fell due or come this week (user
                        // request 2026-11-12); nothing shows while there are none.
                        UpcomingRecurringCard { confirmingRecurring = $0 }
                        WeekCard(onOpenCalendar: { path.append(CalendarRoute()) },
                                 onSelectDay: { selectedDay = CalendarDay(date: $0) })
                        SavingTiles(onAddGoal: { isAddingGoal = true },
                                    onAddLoan: { isAddingLoan = true })
                        // Hidden for now, as if nothing needed a look (user request 2026-10-30). Set
                        // `showsAttention` back to true to bring it back.
                        if Self.showsAttention { AttentionCard() }
                        // Last, at the foot of the page (user request 2026-10-31).
                        // Gone once Pro is owned: nothing left to sell.
                        if !(ProStore.shared.isPro || debugPro) {
                            ProUpgradeCard { isShowingPaywall = true }
                        }
                    }
                    // The first steps fade away and the page closes up smoothly once the last is
                    // done, rather than everything under them jumping up (review 2026-11-08).
                    .animation(Motion.gentle(.smooth),
                               value: OnboardingCard.isFinished(quota))
                    .padding(.horizontal, Spacing.page)
                    .padding(.top, Spacing.xxl)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .topScrollEdgeIfAvailable(scrolled: isScrolled)
            .onScrolledFromTop { isScrolled = $0 }
            // The plain page, as every tab: the light of lime behind the head went (user request
            // 2026-11-03).
            .pageBackground()
            .foregroundStyle(Palette.label)
            // No title and no greeting on the bar (user request 2026-11-04), as on Tài khoản: Q on
            // the left, ✦ and the bell on the right. The title stays for the back button and VoiceOver.
            // As Tài khoản and Giao dịch: the "Hỏi Milu" pill's width given, the empty slot hidden
            // from VoiceOver (review 2026-11-08).
            .modifier(HiddenTitleBar(title: "Tổng quan", leadingCircles: 1, trailingCircles: 2,
                                     trailingWidth: AssistantBarButton.width + Spacing.s + ControlHeight.regular) {
                Color.clear.frame(height: 1).accessibilityHidden(true)
            })
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
            .navigationDestination(for: NetWorthRoute.self) { _ in NetWorthView() }
            .fullScreenCover(isPresented: $isShowingAssistant) {
                NavigationStack { AssistantView() }
                    .presentationBackground(Palette.background)
            }
            .navigationDestination(for: ReportRoute.self) { ReportView(period: ReportPeriod(.month, containing: $0.month)) }
            .navigationDestination(for: NetWorthPart.self) { NetWorthPartView(part: $0) }
            .navigationDestination(for: CalendarRoute.self) { _ in MoneyCalendarPage() }
            .navigationDestination(for: BudgetRoute.self) { _ in BudgetView() }
            .sheet(item: $confirmingRecurring) { RecurringConfirmSheet(occurrence: $0) }
            .sheet(isPresented: $isShowingPaywall) { PaywallView() }
            .sheet(item: $information) { NoteSheet(title: $0.title, message: $0.message) }
            .sheet(item: $selectedDay) { DayTransactionsSheet(date: $0.date) }
            .sheet(item: $adding) { AddTransactionView(mode: $0) }
            .sheet(isPresented: $isAddingAccount) { AddAccountView(type: .bank) }
            .sheet(isPresented: $isAddingLoan) { LoanEditorView(loan: nil) }
            .sheet(isPresented: $isAddingGoal) { GoalEditorView(goal: nil) }
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
            BarSymbol("bell")
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Thông báo")
    }
}

/// Pushes Hạn mức chi tiêu from Tổng quan ("Còn tiêu được" with no limit set).
struct BudgetRoute: Hashable {}

/// Pushes Báo cáo for a month from Tổng quan ("Tháng này").
struct ReportRoute: Hashable {
    let month: Date
}

#Preview {
    OverviewView()
        .environment(FinanceStore())
        .environment(AIQuota())
        .environment(CloudSyncMonitor())
        .environment(AssistantChats(saving: false))
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
