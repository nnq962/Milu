import SwiftUI

/// Home tab: greeting, then the overview cards (one file each in `Cards/`), with the sheets they open.
struct OverviewView: View {
    @Binding var selectedTab: AppTab
    @AppStorage("overview.monthlyBudget") private var monthlyBudget = SampleData.monthlyBudget
    @State private var isEditingBudget = false
    @State private var information: Information?
    @State private var isShowingDesignSystem = false
    @State private var selectedDay: CalendarDay?

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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greetingHeader
                    BalanceCard()
                    ProUpgradeCard {
                        information = Information(title: "Timi Pro · Sắp ra mắt", message: "Gói Pro đang được chuẩn bị. Hiện chưa mở đăng ký hoặc thanh toán; trợ lý trong app vẫn dùng dữ liệu giả lập.")
                    }
                    OnboardingCard()
                    MonthSummaryCard(monthlyBudget: monthlyBudget) { isEditingBudget = true }
                    AttentionCard()
                    MoneyCalendarCard { selectedDay = CalendarDay(date: $0) }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Palette.background)
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
            .sheet(isPresented: $isEditingBudget) { BudgetEditorSheet(monthlyBudget: $monthlyBudget) }
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
            .navigationDestination(isPresented: $isShowingDesignSystem) { DesignSystemView() }
        }
    }

    // Native navigation-bar items: iOS owns their glass and the scroll-edge backdrop.
    private var profileButton: some View {
        // The design system lives behind the avatar until there is a profile screen.
        Button {
            isShowingDesignSystem = true
        } label: {
            Text("Q")
                .textRole(.heading)
                .frame(width: 28, height: 28)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.ink)
        .accessibilityLabel("Hồ sơ của Quyet")
        .accessibilityHint("Mở thư viện UI")
    }

    private var notificationButton: some View {
        Button {
            information = Information(title: "Thông báo", message: "Bạn chưa có thông báo mới. Nhắc hạn thanh toán sẽ xuất hiện ở đây khi tính năng được bổ sung.")
        } label: {
            SolarIcon("solar-bell-linear", size: 20)
                .frame(width: 28, height: 28)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.ink)
        .accessibilityLabel("Thông báo")
    }

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.vietnam)).capitalizedFirstLetter)
                .textRole(.captionStrong).foregroundStyle(Palette.secondaryText)
            Text("\(greeting), Quyet")
                .textRole(.pageTitle)
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

extension View {
    /// White card used by every Overview card.
    func overviewCard() -> some View {
        self.padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(color: Palette.card, elevated: true)
    }
}

#Preview {
    OverviewView(selectedTab: .constant(.overview))
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .textRole(.body)
}
