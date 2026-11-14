import MessageUI
import SwiftUI

/// Cài đặt, opened from the avatar on Tổng quan as a full sheet (like the account sheet in Apple's
/// own apps). The profile card, this month's lượt AI with its upgrade button, then
/// Quản lý tài chính, Giao diện, Thông báo, Hỗ trợ and Về Milu. Developer tools appear only
/// in Debug builds. Notifications, still to come, are shown switched off and greyed, with "Sắp có".
struct SettingsView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota
    @Environment(\.eraseAllData) private var eraseAllData
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = 0.0
    @AppStorage(StorageKey.appearance) private var appearance = AppAppearance.system
    @AppStorage(StorageKey.profileName) private var profileName = ""
    @AppStorage(StorageKey.dailyReminder) private var dailyReminder = false
    @AppStorage(StorageKey.dailyReminderMinutes) private var reminderMinutes = DailyReminderPlan.defaultMinutes
    @AppStorage(StorageKey.budgetAlerts) private var budgetAlerts = false
    @AppStorage(StorageKey.recurringAlerts) private var recurringAlerts = false
    /// Debug: act as Milu Pro (`MiluPlan`).
    @AppStorage(StorageKey.debugPro) private var debugPro = false
    @Environment(AppLock.self) private var appLock
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    /// Notifications are off for Milu in the iPhone's Settings.
    @State private var notificationsDenied = false
    @State private var isAskingForNotifications = false

    @State private var note: Note?
    @State private var isShowingPaywall = false
    @State private var isEditingName = false
    /// The mail form in the app, when the phone can send mail.
    @State private var isComposing = false
    /// No mail account (or Mail would not open): the address to copy instead.
    @State private var isOfferingCopy = false
    /// The second ask before erasing everything: nothing can bring it back (review 2026-11-09).
    @State private var isConfirmingErase = false
    /// The profile's initial: 44 like a header icon, larger with the text inside it, so the letter
    /// never spills out at large sizes (strict review 2026-10-31: a fixed 56).
    @ScaledMetric(relativeTo: .title3) private var avatarSize = RowMetrics.featureIcon

    private static let supportEmail = "support@milu.nnqlab.dev"

    /// A feature still to come: its row opens this instead of a dead end.
    private struct Note: Identifiable {
        let title: String
        let message: String
        var id: String { title }
    }

    /// Turning a notification on asks for permission first; refused, the switch goes back off
    /// (`FormConfirmedToggleRow`, as the Face ID switch).
    private func allowNotifications(_ on: Bool) async -> Bool {
        guard on else { return true }
        if await appLock.whileSystemAsks({ await Reminders.shared.requestPermission() }) {
            notificationsDenied = false
            return true
        }
        notificationsDenied = true
        isAskingForNotifications = true
        return false
    }

    private func checkNotificationPermission() async {
        notificationsDenied = await Reminders.shared.permission() == .denied
    }

    /// Minutes after midnight as a time of day, for the wheels.
    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(byAdding: .minute, value: reminderMinutes, to: Calendar.current.startOfDay(for: .now)) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderMinutes = (parts.hour ?? 21) * 60 + (parts.minute ?? 0)
        }
    }

    private var reminderSubtitle: String {
        if dailyReminder, notificationsDenied { return "Thông báo đang tắt trong Cài đặt iPhone" }
        return "Mỗi ngày vào giờ bạn chọn"
    }

    private var budgetAlertSubtitle: String {
        if budgetAlerts, notificationsDenied { return "Thông báo đang tắt trong Cài đặt iPhone" }
        if monthlyBudget <= 0 { return "Đặt hạn mức chi tiêu để nhận cảnh báo" }
        return "Khi chi tới 80% và khi hết hạn mức"
    }


    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // Lazy: the sheet opens with the groups in view, and those below are built as they
                // scroll in, not the whole page in the frames it slides up (Instruments on the
                // iPhone 2026-11-13: 7 to 15 frames dropped each time Cài đặt opened).
                LazyVStack(alignment: .leading, spacing: Spacing.section) {
                    VStack(spacing: Spacing.l) {
                        profile
                        aiQuotaCard
                    }

                    FormGroup(title: "Quản lý tài chính") {
                        NavigationLink {
                            BudgetView()
                        } label: {
                            NavigationRowContent(title: "Hạn mức chi tiêu", icon: "hugeicons-chart-increase",
                                               value: monthlyBudget > 0 ? monthlyBudget.vnd : "Chưa đặt")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        NavigationLink {
                            CategoriesView()
                        } label: {
                            NavigationRowContent(title: "Hạng mục", icon: "hugeicons-tag-01",
                                               value: "\(store.visibleItemCount)",
                                               spokenValue: "\(store.visibleItemCount) hạng mục")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        // Rent, salary, subscriptions (user request 2026-11-12).
                        NavigationLink {
                            RecurringListView()
                        } label: {
                            NavigationRowContent(title: "Giao dịch định kỳ", icon: "hugeicons-calendar-03",
                                               value: "\(store.recurringRules.count)",
                                               spokenValue: "\(store.recurringRules.count) khoản")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        NavigationLink {
                            ContactsView()
                        } label: {
                            NavigationRowContent(title: "Danh bạ", icon: "hugeicons-user-group",
                                               value: "\(store.contacts.count)",
                                               spokenValue: "\(store.contacts.count) người")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        // Báo cáo here too, not only from the month cards (user request 2026-10-30).
                        NavigationLink {
                            ReportView()
                        } label: {
                            NavigationRowContent(title: "Báo cáo", icon: "hugeicons-pie-chart")
                        }
                        .buttonStyle(.row)
                    }

                    // Where the data is and whether it is in iCloud (user request 2026-11-12).
                    // Nothing to switch: it follows the iPhone's iCloud; the row opens what that means.
                    FormGroup(title: "Sao lưu & đồng bộ") {
                        SyncRow { note = Note(title: "Đồng bộ iCloud", message: $0) }
                    }

                    // Face ID lock, Milu Pro (user request 2026-11-12).
                    SecuritySettings { isShowingPaywall = true }

                    // Changes at once, the whole screen fading across (user request 2026-10-31).
                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Giao diện", style: .group)
                        AppearancePicker(selection: $appearance)
                    }
                    .sensoryFeedback(.selection, trigger: appearance)
                    // After the tapped tile's press has sprung back: the whole-screen fade froze
                    // it, and it bounced only once the new look was on (user report 2026-11-14).
                    .onChange(of: appearance) { _, new in
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.3))
                            // Only the last pick, should two come quickly.
                            if appearance == new { new.apply(animated: true) }
                        }
                    }

                    // No footers here: a footer only carries a computed figure or an error
                    // (strict review 2026-10-31). Working since 2026-11-12 (`Reminders`): turning one
                    // on asks for notifications then, not at launch; refused, it stays off and offers
                    // the iPhone's Settings.
                    FormGroup(title: "Thông báo") {
                        FormConfirmedToggleRow(title: "Nhắc ghi chi tiêu", subtitle: reminderSubtitle,
                                               icon: "hugeicons-notification-01", isOn: $dailyReminder,
                                               confirm: allowNotifications)
                        if dailyReminder {
                            FormDivider()
                            FormTimeRow(title: "Giờ nhắc", icon: "hugeicons-clock-01", date: reminderTime)
                                // Opened under the switch as every row a switch opens (user
                                // request 2026-11-14: one way across Cài đặt and Giao dịch).
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        FormDivider()
                        FormConfirmedToggleRow(title: "Cảnh báo hạn mức", subtitle: budgetAlertSubtitle,
                                               icon: "hugeicons-alert-circle", isOn: $budgetAlerts,
                                               confirm: allowNotifications)
                        FormDivider()
                        FormConfirmedToggleRow(title: "Nhắc khoản định kỳ",
                                               subtitle: recurringAlerts && notificationsDenied
                                                   ? "Thông báo đang tắt trong Cài đặt iPhone" : "8:00 sáng ngày tới hạn",
                                               icon: "hugeicons-calendar-03", isOn: $recurringAlerts,
                                               confirm: allowNotifications)
                    }
                    .animation(Motion.gentle(.smooth(duration: 0.25)), value: dailyReminder)
                    .task { await checkNotificationPermission() }
                    .systemAlert("Milu chưa được gửi thông báo", isPresented: $isAskingForNotifications) {
                        Button("Để sau", role: .cancel) {}
                        Button("Mở Cài đặt") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                        }
                    } message: {
                        Text("Bật thông báo cho Milu trong Cài đặt của iPhone để nhận nhắc nhở và cảnh báo hạn mức.")
                    }

                    // Rows that open a note over the sheet have no ›; the mail row leaves the app,
                    // so ↗ (review 2026-11-09). One mail row: "Góp ý" and "Liên hệ hỗ trợ" opened
                    // the same address.
                    FormGroup(title: "Hỗ trợ") {
                        // A page of its own, pushed (review 2026-11-09: one grey block in a note).
                        NavigationLink {
                            FAQView()
                        } label: {
                            NavigationRowContent(title: "Câu hỏi thường gặp", icon: "hugeicons-help-circle")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        // May break after "@" only, not inside a word (review 2026-11-09: "…nnqlab.de" / "v").
                        FormNavigationRow(title: "Góp ý và hỗ trợ", subtitle: Self.supportEmail.replacingOccurrences(of: "@", with: "@\u{200B}"), icon: "hugeicons-mail-01",
                                          accessory: .external) {
                            mail()
                        }
                        .accessibilityHint("Mở thư gửi Milu")
                    }

                    FormGroup(title: "Về Milu") {
                        // Full pages, pushed (user request 2026-11-12: two short notes). The
                        // version moved to the foot of the page.
                        NavigationLink {
                            LegalDocumentView(document: .privacy)
                        } label: {
                            NavigationRowContent(title: "Chính sách quyền riêng tư", icon: "hugeicons-security-check")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        NavigationLink {
                            LegalDocumentView(document: .terms)
                        } label: {
                            NavigationRowContent(title: "Điều khoản sử dụng", icon: "hugeicons-file-02")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        NavigationLink {
                            LicensesView()
                        } label: {
                            NavigationRowContent(title: "Giấy phép mã nguồn mở", icon: "hugeicons-license")
                        }
                        .buttonStyle(.row)
                    }

                    #if DEBUG
                    FormGroup(title: "Nhà phát triển") {
                        NavigationLink {
                            DesignSystemView()
                        } label: {
                            NavigationRowContent(title: "Thư viện UI", subtitle: "Hệ thống thiết kế, chạm thử được",
                                               icon: "hugeicons-dashboard-square-01")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        FormToggleRow(title: "Giả lập Milu Pro", subtitle: "Thử các tính năng Pro khi chưa mở bán",
                                      icon: "hugeicons-star", isOn: $debugPro)
                            .onChange(of: debugPro) { appLock.refresh() }
                        FormDivider()
                        FormNavigationRow(title: "Xem lại màn chào mừng", icon: "hugeicons-star", accessory: .none) {
                            dismiss()
                            UserDefaults.standard.set(false, forKey: StorageKey.welcomeSeen)
                        }
                        FormDivider()
                        FormDestructiveRow(title: "Đặt lại dữ liệu mẫu", question: "Đặt lại dữ liệu mẫu?",
                                           message: "Mọi tài khoản, giao dịch, hũ, khoản vay, hạng mục, danh bạ và hạn mức bạn đã thêm hoặc sửa sẽ bị xoá.") {
                            store.resetToSampleData()
                            // The sample limits too: they live in UserDefaults, not the database, and
                            // with nothing saved there is no limit at all (2026-11-12).
                            UserDefaults.standard.set(SampleData.monthlyBudget, forKey: StorageKey.monthlyBudget)
                            UserDefaults.standard.set(SampleData.categoryBudgets.rawValue, forKey: StorageKey.categoryBudgets)
                        }
                    }
                    #endif

                    // Cuối trang, chữ đỏ, như "Xoá iPhone" cuối Cài đặt chung của iOS; hỏi lại trước khi xoá.
                    // Asked twice: it cannot be undone and there is no backup (review 2026-11-09).
                    FormGroup {
                        FormDestructiveRow(title: "Xoá toàn bộ dữ liệu", question: "Xoá toàn bộ dữ liệu?",
                                           message: "Mọi tài khoản, giao dịch, hũ, khoản vay, hạng mục, danh bạ, hạn mức và cài đặt sẽ bị xoá. Lượt AI còn lại và các bước Làm quen đã xong vẫn được giữ. Không thể hoàn tác.",
                                           warns: false) {
                            // Once the first alert has gone: raised while it was closing, the
                            // second could be dropped and the tap would do nothing (review 2026-11-09).
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(400))
                                isConfirmingErase = true
                            }
                        }
                    }
                    .systemAlert("Xoá vĩnh viễn?", isPresented: $isConfirmingErase) {
                        Button("Huỷ", role: .cancel) {}
                        Button("Xoá hết", role: .destructive) {
                            Haptics.warning()
                            eraseAllData()
                        }
                    } message: {
                        Text("Dữ liệu cũng bị xoá khỏi iCloud và các thiết bị khác dùng chung Apple ID, không thể lấy lại.")
                    }

                    // The version at the very foot, as apps sign off their settings
                    // (user request 2026-11-12).
                    Text("Milu \(version)")
                        .textRole(.footnote)
                        .foregroundStyle(Palette.secondaryLabel)
                        .frame(maxWidth: .infinity)
                        .textSelection(.enabled)
                        .accessibilityLabel("Milu phiên bản \(version)")

                }
                .padding(.horizontal, Spacing.page)
                // The same top and bottom as every page under Cài đặt and the main tabs.
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xxl)
            }
            .pageBackground()
            .foregroundStyle(Palette.label)
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            }
            .sheet(item: $note) { NoteSheet(title: $0.title, message: $0.message) }
            .sheet(isPresented: $isShowingPaywall) { PaywallView() }
            .sheet(isPresented: $isEditingName) { ProfileNameSheet() }
            // Mail runs apart from the app too: no Face ID cover over it.
            .onChange(of: isComposing) { _, open in appLock.isShowingSystemSheet = open }
            .sheet(isPresented: $isComposing) {
                MailComposer(recipient: Self.supportEmail, subject: "Góp ý cho Milu iOS")
                    .ignoresSafeArea()
            }
            // No mail account set up in Mail (it may be installed): nothing failed, so it says so.
            .systemAlert("Chưa có tài khoản Mail trên máy", isPresented: $isOfferingCopy) {
                Button("Đóng", role: .cancel) {}
                Button("Sao chép địa chỉ") {
                    UIPasteboard.general.string = Self.supportEmail
                }
            } message: {
                Text("Bạn có thể sao chép địa chỉ \(Self.supportEmail) và gửi thư từ ứng dụng thư bạn dùng.")
            }
        }
        .miluSheetStyle()
    }

    /// The name the user set (tap to change), its initial, and the plan. No email until there is
    /// signing in (review 2026-11-09: a made-up "quyet@example.com" and the developer's name
    /// showed on every install). At the accessibility sizes the plan goes under the name, which
    /// otherwise broke one word a line beside it (review 2026-11-09).
    private var profile: some View {
        let stacked = dynamicTypeSize.isAccessibilitySize
        return Button { isEditingName = true } label: {
            HStack(spacing: RowMetrics.gap) {
                ProfileAvatarView(size: avatarSize)
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text(profileName.isEmpty ? "Thêm tên" : profileName)
                        .textRole(.heading)
                        .foregroundStyle(profileName.isEmpty ? Palette.secondaryLabel : Palette.label)
                    Text(profileName.isEmpty ? "Chạm để đặt tên và ảnh" : "Chạm để sửa hồ sơ")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                    if stacked {
                        planBadge
                            .padding(.top, Spacing.xs)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !stacked {
                    planBadge
                        .fixedSize()
                }
            }
            .settingsCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.card)
        // The name and the plan; what a tap does is the hint, not "Chạm để…" read aloud.
        .accessibilityLabel(profileName.isEmpty ? "Chưa đặt tên, gói \(planName)" : "\(profileName), gói \(planName)")
        .accessibilityHint(profileName.isEmpty ? "Đặt tên của bạn" : "Đổi tên của bạn")
    }

    private var isPro: Bool { ProStore.shared.isPro || MiluPlan.pretends(debugPro) }
    private var planName: String { isPro ? "Milu Pro" : "Miễn phí" }

    /// The plan by the name: "Pro" in the brand's colour, or a quiet "Miễn phí".
    private var planBadge: some View {
        StatusBadge(title: isPro ? "Pro" : "Miễn phí", tone: isPro ? .pro : .neutral, showsDot: false)
    }

    /// "Lượt AI tháng này": what is left, large (the free lượt left plus the bonus), over a bar of
    /// what is left on the same scale and one quiet line of the details, then "Tìm hiểu Milu Pro"
    /// across the card. What Pro gives is not listed here: the plans sheet will show it (user
    /// choice 2026-10-31).
    private var aiQuotaCard: some View {
        // One scale for the figure and the bar: what is left of this week's free lượt plus the
        // bonus (review 2026-11-09: the bar filled with the free ones alone, full and orange
        // while 15 bonus lượt were still there).
        let allowance = isPro ? AIQuota.weeklyPro : AIQuota.weeklyFree
        let kind = isPro ? "lượt Pro" : "lượt miễn phí"
        let total = allowance + quota.bonus
        // The bonus and when it runs out (it lasts 7 days, user choice 2026-11-12).
        let bonusLine = quota.bonus > 0
            ? "còn \(quota.bonus) lượt thưởng" + (quota.bonusExpires.map { " (hết hạn \($0.shortDay))" } ?? "")
            : nil
        // The week's free ones used, and the bonus still there (a bonus lượt used is taken off
        // the bonus, so "đã dùng" stops at 10, review 2026-11-09).
        let details = ["Đã dùng \(quota.usedThisWeek)/\(allowance) \(kind)", bonusLine].compactMap { $0 }
        // "3 trên 10", not a slash read aloud (review 2026-11-09).
        let spokenDetails = ["Đã dùng \(quota.usedThisWeek) trên \(allowance) \(kind)", bonusLine].compactMap { $0 }
        return VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    // "Lượt", not "Hạn mức": right above "Hạn mức chi tiêu" the same word meant
                    // two things (review 2026-11-09).
                    Text("Lượt AI tuần này")
                        .textRole(.bodyStrong)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Làm mới thứ Hai \(quota.renewsOn.shortDay)")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                }
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text("\(quota.remaining)")
                        .textRole(.display)
                        .monospacedDigit()
                        .contentTransition(reduceMotion ? .identity : .numericText())
                        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: quota.remaining)
                    Text("lượt còn lại")
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryLabel)
                }
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    // What is left, shrinking as lượt are used; orange once 3 or fewer are left.
                    ProgressBar(value: total > 0 ? Double(quota.remaining) / Double(total) : 0,
                                color: quota.remaining <= 3 ? Palette.warning : Palette.progress)
                        .accessibilityHidden(true)
                    Text(details.joined(separator: " · "))
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .monospacedDigit()
                        .contentTransition(reduceMotion ? .identity : .numericText())
                        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: details)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(spokenDetails.joined(separator: ", "))
                }
            }
            // The plans; once Pro is owned, the same page shows the plan and "Quản lý gói".
            MiluButton(isPro ? "Gói Milu Pro của bạn" : "Nâng cấp Milu Pro",
                       role: isPro ? .secondary : .primary, fullWidth: true) {
                isShowingPaywall = true
            }
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: CardCorners.card)
    }

    /// The mail form inside the app; with no mail account set up, the address to copy (review
    /// 2026-11-09: Mail opened its account set-up and the copy offer never came).
    private func mail() {
        if MFMailComposeViewController.canSendMail() {
            isComposing = true
        } else {
            isOfferingCopy = true
        }
    }

}

extension View {
    /// A card of words in Cài đặt and its pages (the cards atop Cài đặt, the month's card on
    /// Hạn mức): corners 24 and words 16 from the edge, like the form groups and headings around
    /// it, so the left edges line up (strict review 2026-10-31: 20 in, corners 28).
    func settingsCard() -> some View {
        padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: CardCorners.card)
    }
}

#Preview {
    SettingsView()
        .environment(FinanceStore())
        .environment(AIQuota())
        .environment(CloudSyncMonitor())
        .environment(AppLock())
}

/// "Đồng bộ iCloud" with what the sync is doing: a view of its own, so a sync event redraws this
/// row and not all of Cài đặt (Instruments on the iPhone 2026-11-13: the whole page was rebuilt
/// while it was open, the sheet hitching as it moved).
private struct SyncRow: View {
    @Environment(CloudSyncMonitor.self) private var sync
    let onExplain: (String) -> Void

    var body: some View {
        FormNavigationRow(title: "Đồng bộ iCloud", subtitle: syncStatus, icon: "hugeicons-cloud",
                          accessory: .none) {
            onExplain(syncExplanation)
        }
    }

    /// The row's second line: what the sync is doing now, else when it last went through.
    private var syncStatus: String {
        switch sync.account {
        case .checking: return "Đang kiểm tra iCloud…"
        case .signedOut: return "iCloud đang tắt, dữ liệu chỉ ở trên máy này"
        case .restricted, .unavailable: return "iCloud chưa dùng được, dữ liệu chỉ ở trên máy này"
        case .available:
            if sync.isOffline { return "Không có mạng, sẽ đồng bộ khi có mạng lại" }
            if sync.isReceiving { return "Đang đồng bộ…" }
            if let problem = sync.problem { return problem }
            guard let last = sync.lastSynced else { return "Đang bật" }
            return "Đã đồng bộ " + Self.when(last)
        }
    }

    /// "lúc 16:05" today, "hôm qua lúc 16:05", else "12/11 lúc 16:05".
    private static func when(_ date: Date) -> String {
        let calendar = Calendar.current
        let time = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        if calendar.isDateInToday(date) { return "lúc \(time)" }
        if calendar.isDateInYesterday(date) { return "hôm qua lúc \(time)" }
        return date.formatted(.dateTime.day().month(.defaultDigits)) + " lúc \(time)"
    }

    private var syncExplanation: String {
        let state = switch sync.account {
        case .available, .checking: "Milu đang lưu dữ liệu vào iCloud của bạn."
        case .signedOut: "iPhone này chưa đăng nhập iCloud, hoặc iCloud đang tắt cho Milu, nên dữ liệu chỉ nằm trên máy. Bật lại trong Cài đặt của iPhone → tên bạn → iCloud để Milu tự sao lưu."
        case .restricted, .unavailable: "iCloud trên iPhone này chưa dùng được nên dữ liệu chỉ nằm trên máy."
        }
        return state + "\n\nTài khoản, giao dịch, hũ, khoản vay, hạng mục, danh bạ, hạn mức và lượt AI được đồng bộ tự động giữa các thiết bị dùng chung Apple ID. Xoá app rồi cài lại, hay đổi iPhone, dữ liệu tự về.\n\nDữ liệu nằm trong iCloud riêng của bạn, Milu không xem được. Muốn bật hay tắt, vào Cài đặt của iPhone → tên bạn → iCloud, tìm Milu trong danh sách app dùng iCloud. Tắt đi thì dữ liệu vẫn còn trên máy này, chỉ ngừng đồng bộ."
    }
}
