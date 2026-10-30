import SwiftUI

/// Home tab: greeting, then the overview cards (one file each in `Cards/`), with the sheets they open.
struct OverviewView: View {
    @Binding var selectedTab: AppTab
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @State private var isShowingBudget = false
    @State private var isShowingReport = false
    @State private var information: Information?
    @State private var isShowingSettings = false
    /// Tài sản ròng and what it opens go by value (pushing a value onto a page opened with
    /// `isPresented` popped straight back).
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
                VStack(alignment: .leading, spacing: Spacing.section) {
                    greetingHeader
                    // One solid teal lead card, then the rest; the Pro offer goes last.
                    HeroCard { path.append(NetWorthRoute()) }
                    OnboardingCard(selectedTab: $selectedTab)
                    AttentionCard()
                    MonthSummaryCard(monthlyBudget: monthlyBudget, onOpenReport: { isShowingReport = true },
                                     onOpenBudget: { isShowingBudget = true })
                    MoneyCalendarCard { selectedDay = CalendarDay(date: $0) }
                    ProUpgradeCard {
                        information = Information(title: "Timi Pro · Sắp ra mắt", message: "Gói Pro đang được chuẩn bị. Hiện chưa mở đăng ký hoặc thanh toán; trợ lý trong app vẫn dùng dữ liệu giả lập.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(alignment: .top) {
                // Two faint colour blobs, as in the user's Sleek theme (2026-10-30); the amber one
                // went in the UI review, amber is kept for the few things that ask for attention.
                ZStack {
                    Palette.background
                    Circle().fill(Palette.primary.opacity(0.10)).frame(width: 260).blur(radius: 80)
                        .offset(x: -150, y: -60)
                    Circle().fill(Palette.sky.opacity(0.14)).frame(width: 260).blur(radius: 80)
                        .offset(x: 170, y: 260)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
            }
            .foregroundStyle(Palette.ink)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
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
            // The whole Hạn mức chi tiêu page, not only the amount (user choice 2026-10-30).
            .navigationDestination(isPresented: $isShowingBudget) { BudgetView() }
            .navigationDestination(isPresented: $isShowingReport) { ReportView() }
            .navigationDestination(for: NetWorthRoute.self) { _ in NetWorthView() }
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
        .tint(Palette.primary)
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
        .tint(Palette.primary)
        .accessibilityLabel("Thông báo")
    }

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.vietnam)).capitalizedFirstLetter)
                .textRole(.captionStrong).foregroundStyle(Palette.secondaryText)
            // Large, on two lines (user choice 2026-10-30).
            Text("\(greeting),\nQuyet")
                .textRole(.display)
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

#Preview {
    OverviewView(selectedTab: .constant(.overview))
        .environment(FinanceStore())
        .environment(AIQuota())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
