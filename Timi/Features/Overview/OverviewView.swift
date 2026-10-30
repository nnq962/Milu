import SwiftUI

/// Home tab: a moss band with the greeting and the net worth card over its edge, then shortcuts
/// and plain sections (one file each in `Cards/`), with the sheets they open.
struct OverviewView: View {
    /// How far the net worth card reaches up into the moss band.
    private static let cardOverlap: CGFloat = 72

    @State private var information: Information?
    @State private var isShowingSettings = false
    /// Every page Tổng quan opens goes by value: Tài sản ròng and its parts, Trợ lý AI.
    @State private var path = NavigationPath()
    @State private var selectedDay: CalendarDay?
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
            // The bar is moss like the band under it, with light status-bar text.
            .toolbarBackground(Palette.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) {
                        profileButton.nativeCircleButton(diameter: 44)
                    }
                    .sharedBackgroundVisibility(.hidden)
                    ToolbarItem(placement: .topBarTrailing) {
                        notificationButton.nativeCircleButton(diameter: 44)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) { profileButton }
                    ToolbarItem(placement: .topBarTrailing) { notificationButton }
                }
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
            Text("Q")
                .textRole(.heading)
                .frame(width: 28, height: 28)
        }
        .buttonBorderShape(.circle)
        // Deep moss on the pale glass: white on it was too faint (UI review 2026-10-30).
        .foregroundStyle(Palette.primary)
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
        .foregroundStyle(Palette.primary)
        .accessibilityLabel("Thông báo")
    }

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.vietnam)).capitalizedFirstLetter)
                .textRole(.captionStrong).foregroundStyle(.white.opacity(0.75))
            Text("\(greeting), Quyet")
                .textRole(.pageTitle)
                .foregroundStyle(.white)
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
