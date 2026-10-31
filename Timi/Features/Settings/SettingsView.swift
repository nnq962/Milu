import SwiftUI

/// Cài đặt, opened from the avatar on Tổng quan as a full sheet (like the account sheet in Apple's
/// own apps). The profile card, this month's lượt AI with its upgrade button, then
/// Quản lý tài chính, Giao diện, Thông báo, Hỗ trợ and Về Timi. Developer tools appear only
/// in Debug builds. Rows the app cannot do yet open a short note.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @AppStorage(StorageKey.dailyReminder) private var dailyReminder = true
    @AppStorage(StorageKey.dailyReminderMinutes) private var dailyReminderMinutes = 21 * 60
    @AppStorage(StorageKey.budgetAlerts) private var budgetAlerts = true
    @AppStorage(StorageKey.appearance) private var appearance = AppAppearance.system

    @State private var note: Note?
    /// The profile's initial: 44 like a header icon, larger with the text inside it, so the letter
    /// never spills out at large sizes (strict review 2026-10-31: a fixed 56).
    @ScaledMetric(relativeTo: .title3) private var avatarSize = RowMetrics.featureIcon

    private static let supportEmail = "support@timi.nnqlab.dev"

    /// A feature still to come: its row opens this instead of a dead end.
    private struct Note: Identifiable {
        let title: String
        let message: String
        var id: String { title }
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    /// Persist a local time rather than a timestamp, so changing time zones keeps the selected hour.
    private var reminderTime: Binding<Date> {
        Binding {
            let minutes = min(max(dailyReminderMinutes, 0), 24 * 60 - 1)
            return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0,
                                         of: Date(timeIntervalSinceReferenceDate: 0)) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            dailyReminderMinutes = (parts.hour ?? 21) * 60 + (parts.minute ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
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

                    // Changes at once, the whole screen fading across (user request 2026-10-31).
                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Giao diện", style: .group)
                        AppearancePicker(selection: $appearance)
                    }
                    .sensoryFeedback(.selection, trigger: appearance)
                    .onChange(of: appearance) { _, new in new.apply(animated: true) }

                    // No footers here: a footer only carries a computed figure or an error
                    // (strict review 2026-10-31).
                    FormGroup(title: "Thông báo") {
                        FormToggleRow(title: "Nhắc ghi chi tiêu", subtitle: "Mỗi ngày",
                                      icon: "hugeicons-notification-01", isOn: $dailyReminder)
                        // Its hour only while the reminder is on, sliding in and out with the card
                        // (user report 2026-10-31: it popped in with no animation).
                        if dailyReminder {
                            VStack(spacing: 0) {
                                FormDivider()
                                FormTimeRow(title: "Giờ nhắc", icon: "hugeicons-clock-01", date: reminderTime)
                            }
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                        }
                        FormDivider()
                        FormToggleRow(title: "Cảnh báo hạn mức", subtitle: "Khi dùng 80% và 100%",
                                      icon: "hugeicons-alert-circle", isOn: $budgetAlerts)
                    }
                    .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: dailyReminder)

                    FormGroup(title: "Hỗ trợ") {
                        FormNavigationRow(title: "Câu hỏi thường gặp", icon: "hugeicons-help-circle") {
                            note = Note(title: "Câu hỏi thường gặp", message: "Sắp có trong app. Hiện bạn có thể xem trên bản web của Timi.")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Góp ý với Timi", icon: "hugeicons-bubble-chat") {
                            mail(subject: "Góp ý cho Timi iOS")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Liên hệ hỗ trợ", subtitle: Self.supportEmail, icon: "hugeicons-mail-01") {
                            mail(subject: "Hỗ trợ Timi iOS")
                        }
                    }

                    FormGroup(title: "Về Timi") {
                        FormNavigationRow(title: "Lịch sử phiên bản", icon: "hugeicons-history", value: version) {
                            note = Note(title: "Phiên bản \(version)", message: "Bản thử nghiệm: hệ thống thiết kế, form kiểu iOS, logo ngân hàng và ví, biểu đồ Swift Charts, dữ liệu lưu trên máy.")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Chính sách quyền riêng tư", icon: "hugeicons-security-check") {
                            note = Note(title: "Chính sách quyền riêng tư", message: "Dữ liệu trong bản thử nghiệm chỉ nằm trên máy và được đặt lại khi mở lại app. Chính sách đầy đủ sắp có.")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Điều khoản sử dụng", icon: "hugeicons-file-02") {
                            note = Note(title: "Điều khoản sử dụng", message: "Sắp có trong app.")
                        }
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
                        FormDestructiveRow(title: "Đặt lại dữ liệu mẫu", question: "Đặt lại dữ liệu mẫu?",
                                           message: "Mọi tài khoản, giao dịch, hũ, khoản vay, hạng mục, danh bạ và hạn mức bạn đã thêm hoặc sửa sẽ bị xoá.") {
                            store.resetToSampleData()
                            // The limits too: they live in UserDefaults, not the database.
                            UserDefaults.standard.removeObject(forKey: StorageKey.monthlyBudget)
                            UserDefaults.standard.removeObject(forKey: StorageKey.categoryBudgets)
                        }
                    }
                    #endif

                }
                .padding(.horizontal, Spacing.page)
                // The same top and bottom as every page under Cài đặt and the main tabs.
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.label)
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            }
            .sheet(item: $note) { NoteSheet(title: $0.title, message: $0.message) }
        }
        .timiSheetStyle()
    }

    /// Who is signed in and their plan; the avatar repeats the one on Tổng quan. A row's gap after
    /// it, as after every icon on this page (re-review 2026-10-31: 12).
    private var profile: some View {
        HStack(spacing: RowMetrics.gap) {
            Text("Q")
                .textRole(.heading)
                .foregroundStyle(Palette.primary)
                .frame(width: avatarSize, height: avatarSize)
                .background(Palette.primaryTint, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text("Quyet")
                    .textRole(.heading)
                // Placeholder until the app has an authenticated profile.
                Text("quyet@example.com")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            Spacer(minLength: Spacing.s)
            StatusBadge(title: "Miễn phí", tone: .neutral, showsDot: false)
        }
        .settingsCard()
        .accessibilityElement(children: .combine)
    }

    /// "Hạn mức AI tháng này" (user's words, 2026-10-31): what is left, large, over the bar of
    /// what has been used and one quiet line of the details, then a plain "Nâng cấp" button
    /// across the card. What Pro gives is not listed here: the plans sheet will show it (user
    /// choice 2026-10-31). The remaining total includes the bonus; the bar measures only the free
    /// lượt.
    private var aiQuotaCard: some View {
        let used = quota.usedThisMonth
        let details = ["Đã dùng \(used)/\(AIQuota.monthlyFree) lượt",
                       quota.bonus > 0 ? "+\(quota.bonus) lượt thưởng" : nil].compactMap { $0 }
        return VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    Text("Hạn mức AI tháng này")
                        .textRole(.bodyStrong)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Làm mới \(quota.renewsOn.shortDay)")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                }
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text("\(quota.remaining)")
                        .textRole(.display)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("lượt còn lại")
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryLabel)
                }
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    // Fills as lượt are used; orange once 3 or fewer free ones are left.
                    ProgressBar(value: Double(used) / Double(AIQuota.monthlyFree),
                                color: quota.monthlyLeft <= 3 ? Palette.warning : Palette.primary)
                        .accessibilityHidden(true)
                    Text(details.joined(separator: " · "))
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            TimiButton("Nâng cấp", role: .primary, fullWidth: true) {
                note = Note(title: TimiProNote.title, message: TimiProNote.message)
            }
            .accessibilityHint("Xem gói Timi Pro")
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: CardCorners.inset)
    }

    private func mail(subject: String) {
        let query = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(Self.supportEmail)?subject=\(query)") {
            openURL(url)
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
            .cardSurface(radius: CardCorners.inset)
    }
}

#Preview {
    SettingsView()
        .environment(FinanceStore())
        .environment(AIQuota())
}
