import SwiftUI

/// Home tab (redone 2026-11-02 after the user's references: blocks on a soft coloured ground): the
/// head on its ground (`OverviewHeader`: a greeting, the net worth and how it moved), then the
/// first steps, what Timi noticed, the calendar, this month and Timi Pro last;
/// Q, Timi's ✦ and the bell on the bar. One file per card in `Cards/`, with the sheets they open.
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
                    InsightsCard()
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
            .background { TabBackdrop() }
            .foregroundStyle(Palette.label)
            // The greeting heads the page, so the bar shows no title; it stays as the page's name
            // for the back button and VoiceOver.
            .navigationTitle("Tổng quan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .modifier(OverviewBar(profile: profileButton, greeting: greeting,
                                  assistant: assistantButton, bell: notificationButton))
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
        Button {
            isShowingSettings = true
        } label: {
            // The initial drawn as an image: the bar sets an image in a circle like the bell, but
            // text (even an icon-only label) in a pill. A template, tinted when shown: a colour
            // drawn into it stayed the light one at night, black on the dark glass.
            Image(size: CGSize(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)) { context in
                context.draw(Text("Q").font(TextRole.heading.font),
                             at: CGPoint(x: RowMetrics.toolbarGlyphFrame / 2, y: RowMetrics.toolbarGlyphFrame / 2))
            }
            .renderingMode(.template)
            .foregroundStyle(Palette.primary)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Hồ sơ của Quyet")
        .accessibilityHint("Mở cài đặt")
    }

    private var assistantButton: some View {
        Button {
            isShowingAssistant = true
        } label: {
            TimiIcon("hugeicons-ai-magic", size: RowMetrics.toolbarGlyph)
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.primary)
        .accessibilityLabel("Hỏi Timi")
        .accessibilityHint("Mở trợ lý AI")
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Greeting.salutation(at: .now))
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
            Text("Quyet")
                .textRole(.bodyStrong)
                .foregroundStyle(Palette.label)
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
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

/// The bar of Tổng quan. Plain buttons: the bar draws their glass circles, so they take part in
/// its push and pop. The avatar and the greeting on the leading side (the greeting in words on
/// the ground, not in a glass pill, user request 2026-11-02), Timi's ✦ and the bell on the
/// trailing one, a spacer giving each its own glass. Before iOS 26 there is no glass to share or
/// hide, so the items simply sit in the bar; before iOS 18 the hidden title is an empty middle.
private struct OverviewBar<Profile: View, Greeting: View, Assistant: View, Bell: View>: ViewModifier {
    /// The middle slot is centred between the leading avatar and the two trailing circles, and as
    /// wide as its content. Set to this width, its leading edge falls 16 after the avatar: twice
    /// the distance from that point to the centre of the room between the items.
    private static var greetingWidth: CGFloat {
        let margin = Spacing.l, circle = ControlHeight.regular, spacer = Spacing.s
        let leadingEnd = margin + circle
        let trailingStart = UIScreen.main.bounds.width - margin - 2 * circle - spacer
        let centre = (leadingEnd + trailingStart) / 2
        return max(2 * (centre - (leadingEnd + Spacing.l)), 0)
    }

    let profile: Profile
    let greeting: Greeting
    let assistant: Assistant
    let bell: Bell

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // The greeting in the middle slot stands in for the title, so the title is not removed:
            // removing it hid the middle slot too.
            content
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { profile }
                    // In the middle slot, pushed to its leading edge, so it sits by the avatar
                    // without being a leading item: as one, it morphed into the back button of the
                    // page pushed over Tổng quan and showed as a box beside ‹ (user report
                    // 2026-11-03). The middle fades with the title instead.
                    ToolbarItem(placement: .principal) {
                        greeting.frame(width: Self.greetingWidth, alignment: .leading)
                    }
                    .sharedBackgroundVisibility(.hidden)
                    ToolbarItem(placement: .topBarTrailing) { assistant }
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    ToolbarItem(placement: .topBarTrailing) { bell }
                }
        } else {
            content
                .toolbar {
                    ToolbarItem(placement: .principal) { Color.clear }
                    ToolbarItem(placement: .topBarLeading) {
                        HStack(spacing: Spacing.s) { profile; greeting }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: Spacing.m) { assistant; bell }
                    }
                }
        }
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
