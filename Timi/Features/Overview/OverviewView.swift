import SwiftUI

struct OverviewView: View {
    @Environment(FinanceStore.self) private var store
    @Binding var selectedTab: AppTab
    @AppStorage("overview.monthlyBudget") private var monthlyBudget = SampleData.monthlyBudget
    @State private var isEditingBudget = false
    @State private var budgetInput = ""
    @State private var information: Information?
    @State private var isShowingDesignSystem = false
    @State private var displayedMonth = Date.now
    @State private var selectedDay: CalendarDay?
    @ScaledMetric(relativeTo: .caption2) private var calendarDayHeight = 52

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
                    balanceCard
                    promotions
                    monthSummary
                    attentionCard
                    calendarCard

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
            .sheet(isPresented: $isEditingBudget) { budgetEditor }
            .sheet(item: $information) { info in
                NavigationStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(info.title).font(Typography.font(.title2, size: 22, weight: .semibold))
                        Text(info.message).font(Typography.body).foregroundStyle(Palette.secondaryText)
                        Spacer()
                    }
                    .padding(24)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Đóng") { information = nil } } }
                }
                .presentationDetents([.medium])
            }
            .sheet(item: $selectedDay) { day in dayDetails(day.date) }
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
                .font(Typography.font(.title3, size: 20, weight: .semibold))
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
                .font(Typography.font(.caption, size: 12, weight: .medium)).foregroundStyle(Palette.secondaryText)
                .designLineHeight(16, relativeTo: .caption)
            Text("\(greeting), Quyet")
                .font(Typography.font(.title2, size: 24, weight: .semibold))
                .designLineHeight(32, relativeTo: .title2)
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

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tổng tài sản").font(Typography.font(.caption, size: 12, weight: .medium)).foregroundStyle(Palette.secondaryText)
                    .designLineHeight(16, relativeTo: .caption)
                Text(store.netWorth.vnd)
                    .font(Typography.font(.largeTitle, size: 34, weight: .heavy))
                    .designLineHeight(42.5, relativeTo: .largeTitle)
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            }
            HStack(spacing: 8) {
                balanceStat("Số dư", value: store.totalAssets.vndCompact, icon: "solar-wallet-linear")
                balanceStat("Cho vay", value: store.totalLent.vndCompact, icon: "solar-hand-money-linear")
                balanceStat("Nợ", value: (-store.totalDebt).vndCompact, icon: "solar-card-linear", color: Palette.red)
            }
        }
        .overviewCard()
        .accessibilityElement(children: .contain)
    }

    private func balanceStat(_ title: String, value: String, icon: String, color: Color = Palette.ink) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SolarIcon(icon, size: 16)
                .accessibilityHidden(true)
                .frame(width: 28, height: 28)
                .background(Palette.card, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Typography.font(.caption, size: 11, weight: .medium)).foregroundStyle(Palette.secondaryText)
                    .designLineHeight(16.5, relativeTo: .caption)
                Text(value)
                    .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                    .foregroundStyle(color).monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                    .frame(minHeight: 20)
            }
        }
        .accessibilityElement(children: .combine)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .cardSurface(radius: CardCorners.inset, color: Palette.balanceTile)
    }

    private var promotions: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    SolarIcon("solar-crown-bold", size: 20)
                        .foregroundStyle(Palette.ink)
                        .frame(width: 40, height: 40)
                        .background(Palette.lime, in: RoundedRectangle(cornerRadius: CardCorners.icon, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nâng cấp Timi Pro")
                            .font(Typography.font(.callout, size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Nhận 300 lượt AI mỗi tháng, xuất báo cáo và đồng bộ trên mọi thiết bị.")
                            .font(Typography.font(.caption, size: 12))
                            .foregroundStyle(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Button {
                    information = Information(title: "Timi Pro · Sắp ra mắt", message: "Gói Pro đang được chuẩn bị. Hiện chưa mở đăng ký hoặc thanh toán; trợ lý trong app vẫn dùng dữ liệu giả lập.")
                } label: {
                    Text("Nâng cấp ngay")
                        .font(Typography.font(.caption, size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .frame(maxWidth: .infinity, minHeight: 24)
                }
                .nativeGlassButton(tint: Palette.lime)
                .buttonBorderShape(.capsule)
                .controlSize(.regular)
                .tint(Palette.lime)
                .foregroundStyle(Palette.ink)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                Color.clear
                    .cardSurface(color: Color(red: 17/255, green: 24/255, blue: 39/255))
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(Palette.lime.opacity(0.25))
                            .frame(width: 144, height: 144)
                            .blur(radius: 40)
                            .offset(x: 40, y: -40)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            onboardingCard
        }
    }

    private var onboardingCard: some View {
        let hasAccount = !store.accounts.isEmpty
        let hasTransaction = !store.transactions.isEmpty
        let hasLoan = !store.loans.isEmpty
        let completed = [hasAccount, hasTransaction, hasLoan].filter { $0 }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Làm quen với Timi")
                        .font(Typography.font(.callout, size: 16, weight: .semibold))
                    Text("Hoàn thành để nhận thêm lượt AI")
                        .font(Typography.font(.caption, size: 11))
                        .foregroundStyle(Palette.secondaryText)
                }
                Spacer()
                Text("\(completed)/4")
                    .font(Typography.font(.caption, size: 11, weight: .semibold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Palette.lime, in: Capsule())
            }
            GeometryReader { geometry in
                Capsule().fill(Palette.muted)
                    .overlay(alignment: .leading) {
                        Capsule().fill(Palette.lime)
                            .frame(width: geometry.size.width * Double(completed) / 4)
                    }
            }
            .frame(height: 8)
            .padding(.top, 4)
            VStack(spacing: 8) {
                onboardingRow("Thêm ví đầu tiên", completed: hasAccount)
                onboardingRow("Ghi một khoản thu chi", completed: hasTransaction)
                onboardingRow("Ghi một khoản cho vay", completed: hasLoan)
                onboardingRow("Hỏi AI một câu hỏi", completed: false)
            }
            .accessibilityElement(children: .contain)
        }
        .overviewCard()
    }

    private func onboardingRow(_ title: String, completed: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                if completed {
                    Circle().fill(Palette.ink)
                    SolarIcon("solar-check-read-linear", size: 12).foregroundStyle(.white)
                } else {
                    Circle().strokeBorder(Palette.border, lineWidth: 2)
                }
            }
            .frame(width: 20, height: 20)
            Text(title)
                .font(Typography.font(.caption, size: 12, weight: completed ? .regular : .medium))
                .foregroundStyle(completed ? Palette.secondaryText : Palette.ink)
            Spacer(minLength: 4)
            Text("+5")
                .font(Typography.font(.caption2, size: 10, weight: .semibold))
                .foregroundStyle(completed ? Palette.secondaryText : Palette.ink)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(completed ? Palette.muted : Palette.lime.opacity(0.4), in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), +5")
        .accessibilityValue(completed ? "Đã hoàn thành" : "Chưa hoàn thành")
    }

    private var monthSummary: some View {
        let expense = store.total(.expense)
        let ratio = monthlyBudget > 0 ? expense / monthlyBudget : 0
        let calendar = Calendar.current
        let month = calendar.component(.month, from: .now)
        let daysLeft = (calendar.range(of: .day, in: .month, for: .now)?.count ?? 0) - calendar.component(.day, from: .now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Tháng \(month) tổng quan")
                    .font(Typography.font(.callout, size: 16, weight: .semibold))
                    .frame(minHeight: 24)
                Spacer(minLength: 4)
                Text("Còn \(daysLeft) ngày")
                    .font(Typography.font(.caption, size: 11, weight: .medium))
                    .foregroundStyle(Palette.secondaryText)
            }
            HStack(spacing: 12) {
                flowStat("Tiền vào", amount: store.total(.income), income: true)
                flowStat("Tiền ra", amount: expense, income: false)
            }
            Button {
                budgetInput = monthlyBudget > 0 ? String(Int(monthlyBudget)) : ""
                isEditingBudget = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hạn mức chi tiêu")
                        Spacer()
                        Text(monthlyBudget > 0 ? ratio.percentText : "Thiết lập")
                            .monospacedDigit()
                    }
                    .font(Typography.font(.caption, size: 11, weight: .medium))
                    .frame(minHeight: 16.5)
                    GeometryReader { geometry in
                        Capsule().fill(Palette.muted)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(ProgressBar.budgetColor(ratio))
                                    .frame(width: geometry.size.width * min(max(ratio, 0), 1))
                            }
                    }
                    .frame(height: 8)
                    .accessibilityHidden(true)
                    Text(monthlyBudget > 0 ? "Đã dùng \(expense.vndCompact) / \(monthlyBudget.vndCompact)" : "Đặt hạn mức để theo dõi chi tiêu")
                        .font(Typography.font(.caption, size: 11))
                        .monospacedDigit()
                        .frame(minHeight: 16.5)
                }
                .foregroundStyle(Palette.secondaryText)
                .contentShape(Rectangle())
            }
            .buttonStyle(.automatic)
            .accessibilityHint("Chỉnh hạn mức chi tiêu hàng tháng")
        }
        .overviewCard()
    }

    private func flowStat(_ title: String, amount: Double, income: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Typography.font(.caption, size: 11, weight: .medium))
                .foregroundStyle(Palette.secondaryText)
                .frame(minHeight: 16.5)
            Text("\(income ? "+" : "-")\(amount.vndCompact)")
                .font(Typography.font(.callout, size: 16, weight: .bold)).monospacedDigit()
                .foregroundStyle(income ? Palette.ink : Palette.red)
                .lineLimit(1).minimumScaleFactor(0.65)
                .frame(minHeight: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .cardSurface(radius: CardCorners.flow, color: income ? Palette.incomeTile : Palette.muted)
    }

    private var attentionCard: some View {
        let reminders = store.paymentReminders.sorted { $0.dueDate < $1.dueDate }
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Cần chú ý")
                    .font(Typography.font(.callout, size: 16, weight: .semibold))
                    .frame(minHeight: 24)
                Spacer(minLength: 8)
                Text("\(reminders.count) sắp đến hạn")
                    .font(Typography.font(.caption, size: 11, weight: .semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Palette.muted, in: Capsule())
            }
            if reminders.isEmpty {
                Text("Chưa có lịch thanh toán sắp tới.")
                    .font(Typography.font(.caption, size: 11))
                    .foregroundStyle(Palette.secondaryText)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                        if index > 0 {
                            Rectangle().fill(Palette.border)
                                .frame(height: 1)
                                .padding(.leading, 52)
                                .padding(.vertical, 12)
                        }
                        attentionRow(reminder)
                    }
                }
            }
        }
        .overviewCard()
    }

    private func attentionRow(_ reminder: PaymentReminder) -> some View {
        HStack(spacing: 12) {
            SolarIcon(reminder.isIncome ? "solar-user-linear" : "solar-calendar-linear", size: 20)
                .frame(width: 40, height: 40)
                .background(reminder.isIncome ? Palette.secondarySurface : Palette.muted, in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(reminder.title)
                    .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                    .lineLimit(1)
                    .frame(minHeight: 20)
                Text(reminder.dueDescription)
                    .font(Typography.font(.caption, size: 11))
                    .foregroundStyle(Palette.secondaryText)
                    .frame(minHeight: 16.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(reminder.isIncome ? "+" : "-")\(reminder.amount.vnd)")
                .font(Typography.font(.subheadline, size: 14, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(reminder.isIncome ? Palette.ink : Palette.red)
                .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityElement(children: .combine)
    }

    private var calendarCard: some View {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let dayCount = calendar.range(of: .day, in: .month, for: start)!.count
        let offset = (calendar.component(.weekday, from: start) + 5) % 7
        let cellCount = ((offset + dayCount + 6) / 7) * 7
        let transactionsByDay = Dictionary(grouping: store.monthlyTransactions(for: start)) {
            calendar.startOfDay(for: $0.date)
        }
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Lịch thu chi")
                    .font(Typography.font(.callout, size: 16, weight: .semibold))
                    .frame(minHeight: 24)
                Spacer(minLength: 4)
                calendarMonthMenu
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 4), count: 7), spacing: 4) {
                ForEach(["T2", "T3", "T4", "T5", "T6", "T7", "CN"], id: \.self) { title in
                    Text(title)
                        .font(Typography.font(.caption2, size: 10, weight: .medium))
                        .foregroundStyle(Palette.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 15)
                        .padding(.vertical, 4)
                        .accessibilityHidden(true)
                }
                ForEach(0..<cellCount, id: \.self) { index in
                    if index < offset || index >= offset + dayCount {
                        Color.clear.frame(height: calendarDayHeight).accessibilityHidden(true)
                    } else {
                        let date = calendar.date(byAdding: .day, value: index - offset, to: start)!
                        let items = transactionsByDay[calendar.startOfDay(for: date)] ?? []
                        let income = items.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
                        let expense = items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
                        calendarDay(date, income: income, expense: expense)
                    }
                }
            }
        }
        .overviewCard()
    }

    private var calendarMonthMenu: some View {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: displayedMonth)
        let month = calendar.component(.month, from: displayedMonth)
        let isCurrentYear = year == calendar.component(.year, from: .now)
        return Menu {
            Button("Tháng trước") { changeMonth(-1) }
            Button("Tháng hiện tại") { displayedMonth = .now }
            Button("Tháng sau") { changeMonth(1) }
            Divider()
            ForEach((year - 1)...(year + 1), id: \.self) { targetYear in
                Menu(String(targetYear)) {
                    ForEach(1...12, id: \.self) { targetMonth in
                        Button("Tháng \(targetMonth)") {
                            if let date = calendar.date(from: DateComponents(year: targetYear, month: targetMonth, day: 1)) {
                                displayedMonth = date
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                SolarIcon("solar-calendar-linear", size: 14)
                Text(isCurrentYear ? "Tháng \(month)" : "T\(month)/\(year.formatted(.number.grouping(.never)))")
                    .font(Typography.font(.caption, size: 12, weight: .semibold))
                    .monospacedDigit()
                SolarIcon("solar-alt-arrow-down-linear", size: 12)
                    .foregroundStyle(Palette.secondaryText)
            }
            .foregroundStyle(Palette.ink)
        }
        .menuIndicator(.hidden)
        .nativeGlassButton(tint: Palette.muted)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
        .accessibilityLabel("Chọn tháng, tháng \(month) năm \(String(year))")
    }

    private func calendarDay(_ date: Date, income: Double, expense: Double) -> some View {
        let calendar = Calendar.current
        let today = calendar.isDateInToday(date)
        let total = income + expense
        // Three neutral activity levels from the mockup; today overrides the heat map.
        let fill = today ? Palette.lime
            : total >= 3_000_000 ? Palette.secondary.opacity(0.25)
            : total >= 1_000_000 ? Palette.muted
            : Palette.muted.opacity(0.4)
        return Button { selectedDay = CalendarDay(date: date) } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(Typography.font(.caption, size: 11, weight: today ? .bold : .medium))
                    .foregroundStyle(today ? Palette.ink : Palette.secondaryText)
                    .frame(minHeight: 16.5, alignment: .topLeading)
                VStack(alignment: .leading, spacing: 0) {
                    if income > 0 {
                        calendarAmount("+\(income.vndCompact)", color: Palette.ink)
                    }
                    if expense > 0 {
                        calendarAmount("-\(expense.vndCompact)", color: Palette.red)
                    }
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity, minHeight: calendarDayHeight, alignment: .topLeading)
            .background(fill, in: RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.calendarDay, style: .continuous))
        }
        // Calendar cells are flat data tiles in the design; only the month control uses glass.
        .buttonStyle(.plain)
        .accessibilityLabel("\(today ? "Hôm nay, " : "")\(date.formatted(.dateTime.weekday(.wide).day().month().year().locale(.vietnam))), thu \(income.vnd), chi \(expense.vnd)")
        .accessibilityHint("Xem giao dịch trong ngày")
    }

    private func calendarAmount(_ text: String, color: Color) -> some View {
        Text(text)
            .font(Typography.font(.caption2, size: 9, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1).minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: 11.25, alignment: .leading)
    }

    private func changeMonth(_ delta: Int) {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        displayedMonth = calendar.date(byAdding: .month, value: delta, to: start) ?? start
    }

    private func dayDetails(_ date: Date) -> some View {
        let items = store.transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        return NavigationStack {
            List {
                if items.isEmpty {
                    Text("Chưa có giao dịch trong ngày này.").font(Typography.body).foregroundStyle(Palette.secondaryText)
                } else {
                    ForEach(items) { TransactionRow(transaction: $0) }
                }
            }
            .navigationTitle(date.formatted(.dateTime.day().month().locale(.vietnam)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Đóng") { selectedDay = nil } } }
        }
        .presentationDetents([.medium, .large])
    }

    private var budgetEditor: some View {
        NavigationStack {
            Form {
                Section("Hạn mức mỗi tháng (VND)") {
                    TextField("Ví dụ: 30000000", text: $budgetInput).keyboardType(.numberPad)
                    Text("Áp dụng cho mỗi tháng. Nhập 0 để bỏ hạn mức.")
                        .font(Typography.font(.caption, size: 12, weight: .medium)).foregroundStyle(Palette.secondaryText)
                }
                Section {
                    Button("Áp dụng hạn mức") {
                        guard let value = Double(budgetInput), value.isFinite, value >= 0, value <= 1_000_000_000_000 else { return }
                        monthlyBudget = value
                        isEditingBudget = false
                    }
                    .disabled(Double(budgetInput).map { !$0.isFinite || $0 < 0 || $0 > 1_000_000_000_000 } ?? true)
                }
            }
            .navigationTitle("Hạn mức chi tiêu").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .keyboardDoneButton()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ") { isEditingBudget = false } }

            }
        }
        .presentationDetents([.medium])
    }
}

private extension View {
    func overviewCard() -> some View {
        self.padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(color: Palette.card, elevated: true)
    }
}

private extension String {
    var capitalizedFirstLetter: String { prefix(1).uppercased() + dropFirst() }
}

#Preview {
    OverviewView(selectedTab: .constant(.overview))
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .font(Typography.body)
}
