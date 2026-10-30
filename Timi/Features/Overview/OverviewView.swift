import SwiftUI

/// Home tab: a moss band with the greeting and the net worth card over its edge, then shortcuts
/// and plain sections (one file each in `Cards/`), with the sheets they open.
struct OverviewView: View {
    /// How far the net worth card reaches up into the moss band.
    private static let cardOverlap: CGFloat = 72
    /// How far the page scrolls before the band's foot passes under the status bar.
    private static let bandScrollAway: CGFloat = 200
    /// Q and the bell on their pale glass over the band: the primary colour, or ink when a light
    /// one is being tried (`AccentTrial`), as primary on primary disappeared.
    private static var bandGlyph: Color { AccentTrial.shared.choice.isLight ? Palette.ink : Palette.primary }

    @State private var information: Information?
    @State private var isShowingSettings = false
    /// Every page Tổng quan opens goes by value: Tài sản ròng and its parts, Trợ lý AI.
    @State private var path = NavigationPath()
    @State private var selectedDay: CalendarDay?
    /// The moss band has scrolled up out from under the bar: the status bar goes back to dark text.
    @State private var isPastBand = false
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
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // A wallet-app layout (user request 2026-10-30: fewer cards): a moss band with
                    // the greeting, the one floating card over its edge, then shortcuts and plain
                    // sections straight on the page.
                    greetingHeader
                        .padding(.horizontal, Spacing.page)
                        .padding(.top, Spacing.xs)
                        .padding(.bottom, Spacing.xxl + Self.cardOverlap)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(alignment: .bottom) {
                            // Reaches far up so pulling the page down shows moss, not a gap.
                            UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32, style: .continuous)
                                .fill(Palette.primary)
                                .padding(.top, -1000)
                        }
                    HeroCard { path.append(NetWorthRoute()) }
                        .padding(.horizontal, Spacing.page)
                        .padding(.top, -Self.cardOverlap)
                    // More air than other pages: with no cards, space is what keeps sections apart.
                    VStack(alignment: .leading, spacing: Spacing.xxxl + Spacing.xs) {
                        QuickActions { path.append(AssistantRoute()) }
                        OnboardingCard { path.append(AssistantRoute()) }
                        AttentionCard()
                        MoneyCalendarCard { selectedDay = CalendarDay(date: $0) }
                        ProUpgradeCard {
                            information = Information(title: "Timi Pro · Sắp ra mắt", message: "Gói Pro đang được chuẩn bị. Hiện chưa mở đăng ký hoặc thanh toán; trợ lý trong app vẫn dùng dữ liệu giả lập.")
                        }
                    }
                    .padding(.horizontal, Spacing.page)
                    .padding(.top, Spacing.xxl)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .modifier(ClearBarOverBand(isPastBand: $isPastBand, scrollAway: Self.bandScrollAway))
            // Plain buttons: the bar draws their glass circles, so they take part in its push and pop
            // (Q turns into the back button). A glass button drawn inside the item did not, and
            // showed as a square mid-transition (user report 2026-10-30).
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { profileButton }
                ToolbarItem(placement: .topBarTrailing) { notificationButton }
            }
            // Here, not on the card: the card goes away as its last step is done.
            .onChange(of: OnboardingCard.completedSteps(store, askedAI: hasAskedAI), initial: true) { _, steps in
                steps.forEach(quota.claim)
            }
            .navigationDestination(for: NetWorthRoute.self) { _ in NetWorthView() }
            .navigationDestination(for: AssistantRoute.self) { _ in AssistantView() }
            .navigationDestination(for: NetWorthPart.self) { NetWorthPartView(part: $0) }
            .navigationDestination(for: Account.ID.self) { AccountDetailView(accountID: $0) }
            .navigationDestination(for: GoalRoute.self) { GoalDetailView(goalID: $0.id) }
            .sheet(item: $information) { info in
                NavigationStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(info.title).textRole(.heading)
                        Text(info.message).textRole(.body).foregroundStyle(Palette.secondaryText)
                        Spacer()
                    }
                    .padding(24)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Đóng") { information = nil } } }
                }
                .presentationDetents([.medium])
            }
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
            Image(size: CGSize(width: 28, height: 28)) { context in
                context.draw(Text("Q").font(TextRole.heading.font).foregroundStyle(Self.bandGlyph),
                             at: CGPoint(x: 14, y: 14))
            }
        }
        .buttonBorderShape(.circle)
        // Deep moss on the pale glass: white on it was too faint (UI review 2026-10-30).
        .foregroundStyle(Self.bandGlyph)
        .accessibilityLabel("Hồ sơ của Quyet")
        .accessibilityHint("Mở cài đặt")
    }

    private var notificationButton: some View {
        Button {
            information = Information(title: "Thông báo", message: "Bạn chưa có thông báo mới. Nhắc hạn thanh toán sẽ xuất hiện ở đây khi tính năng được bổ sung.")
        } label: {
            TimiIcon("hugeicons-notification-01", size: 20)
                .frame(width: 28, height: 28)
        }
        .buttonBorderShape(.circle)
        .foregroundStyle(Self.bandGlyph)
        .accessibilityLabel("Thông báo")
    }

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.vietnam)).capitalizedFirstLetter)
                .textRole(.captionStrong).foregroundStyle(Palette.onPrimary.opacity(0.75))
            Text("\(greeting), Quyet")
                .textRole(.pageTitle)
                .foregroundStyle(Palette.onPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Chào buổi sáng"
        case 12..<18: "Chào buổi chiều"
        default: "Chào buổi tối"
        }
    }
}

/// The bar draws no colour of its own: the band scrolls away under it and iOS lays its scroll-edge
/// effect over the page, as Liquid Glass bars should (HIG review 2026-10-30: a solid moss bar cut
/// the page off with a hard edge). Status-bar text is light on the band, dark once the cream page
/// is under it. iOS 17 cannot follow the scroll, so it keeps the moss bar with light text.
private struct ClearBarOverBand: ViewModifier {
    @Binding var isPastBand: Bool
    let scrollAway: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top > scrollAway
                } action: { _, isPast in
                    isPastBand = isPast
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                // Dark status-bar text over a light band being tried too.
                .toolbarColorScheme(isPastBand || AccentTrial.shared.choice.isLight ? .light : .dark, for: .navigationBar)
                .modifier(TopEdgeEffectOnlyPastBand(isPastBand: isPastBand))
        } else {
            content
                .toolbarBackground(Palette.primary, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

/// With light status-bar text the scroll-edge effect turns dark and laid a grey smear over the
/// white card passing under it, so it shows only once the cream page is under the bar.
private struct TopEdgeEffectOnlyPastBand: ViewModifier {
    let isPastBand: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectHidden(!isPastBand, for: .top)
        } else {
            content
        }
    }
}

/// Pushes Trợ lý AI from Tổng quan (the last shortcut, or "Hỏi AI một câu hỏi").
struct AssistantRoute: Hashable {}

#Preview {
    OverviewView()
        .environment(FinanceStore())
        .environment(AIQuota())
        .environment(AssistantChats())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
