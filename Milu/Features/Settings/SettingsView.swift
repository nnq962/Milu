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

    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @AppStorage(StorageKey.appearance) private var appearance = AppAppearance.system
    @AppStorage(StorageKey.profileName) private var profileName = ""

    @State private var note: Note?
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

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
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
                    // Off and greyed with "Sắp có" until the app sends notifications: on, they
                    // promised a reminder at 21:00 that never came (review 2026-11-09). Their
                    // stored choices come back with the feature.
                    FormGroup(title: "Thông báo") {
                        FormToggleRow(title: "Nhắc ghi chi tiêu", subtitle: "Sắp có",
                                      icon: "hugeicons-notification-01", isOn: .constant(false))
                            .disabled(true)
                        FormDivider()
                        FormToggleRow(title: "Cảnh báo hạn mức", subtitle: "Sắp có",
                                      icon: "hugeicons-alert-circle", isOn: .constant(false))
                            .disabled(true)
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
                        FormDestructiveRow(title: "Đặt lại dữ liệu mẫu", question: "Đặt lại dữ liệu mẫu?",
                                           message: "Mọi tài khoản, giao dịch, hũ, khoản vay, hạng mục, danh bạ và hạn mức bạn đã thêm hoặc sửa sẽ bị xoá.") {
                            store.resetToSampleData()
                            // The limits too: they live in UserDefaults, not the database.
                            UserDefaults.standard.removeObject(forKey: StorageKey.monthlyBudget)
                            UserDefaults.standard.removeObject(forKey: StorageKey.categoryBudgets)
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
            .sheet(isPresented: $isEditingName) { ProfileNameSheet() }
            .sheet(isPresented: $isComposing) {
                MailComposer(recipient: Self.supportEmail, subject: "Góp ý cho Milu iOS")
                    .ignoresSafeArea()
            }
            // No mail account set up in Mail (it may be installed): nothing failed, so it says so.
            .systemAlert("Chưa có tài khoản Mail trên máy", isPresented: $isOfferingCopy) {
                Button("Đóng", role: .cancel) {}
                Button("Sao chép địa chỉ") {
                    UIPasteboard.general.string = Self.supportEmail
                    Haptics.success()
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
                Group {
                    if let initial = ProfileName.initial(of: profileName) {
                        Text(initial).textRole(.heading)
                    } else {
                        Image(systemName: "person.fill").font(.title2)
                    }
                }
                .foregroundStyle(Palette.primary)
                .frame(width: avatarSize, height: avatarSize)
                .background(Palette.primaryTint, in: Circle())
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text(profileName.isEmpty ? "Thêm tên" : profileName)
                        .textRole(.heading)
                        .foregroundStyle(profileName.isEmpty ? Palette.secondaryLabel : Palette.label)
                    Text(profileName.isEmpty ? "Chạm để đặt tên" : "Chạm để đổi tên")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                    if stacked {
                        StatusBadge(title: "Miễn phí", tone: .neutral, showsDot: false)
                            .padding(.top, Spacing.xs)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !stacked {
                    StatusBadge(title: "Miễn phí", tone: .neutral, showsDot: false)
                        .fixedSize()
                }
            }
            .settingsCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.card)
        // The name and the plan; what a tap does is the hint, not "Chạm để…" read aloud.
        .accessibilityLabel(profileName.isEmpty ? "Chưa đặt tên, gói Miễn phí" : "\(profileName), gói Miễn phí")
        .accessibilityHint(profileName.isEmpty ? "Đặt tên của bạn" : "Đổi tên của bạn")
    }

    /// "Lượt AI tháng này": what is left, large (the free lượt left plus the bonus), over a bar of
    /// what is left on the same scale and one quiet line of the details, then "Tìm hiểu Milu Pro"
    /// across the card. What Pro gives is not listed here: the plans sheet will show it (user
    /// choice 2026-10-31).
    private var aiQuotaCard: some View {
        // One scale for the figure and the bar: what is left of this week's free lượt plus the
        // bonus (review 2026-11-09: the bar filled with the free ones alone, full and orange
        // while 15 bonus lượt were still there).
        let total = AIQuota.weeklyFree + quota.bonus
        // The bonus and when it runs out (it lasts 7 days, user choice 2026-11-12).
        let bonusLine = quota.bonus > 0
            ? "còn \(quota.bonus) lượt thưởng" + (quota.bonusExpires.map { " (hết hạn \($0.shortDay))" } ?? "")
            : nil
        // The week's free ones used, and the bonus still there (a bonus lượt used is taken off
        // the bonus, so "đã dùng" stops at 10, review 2026-11-09).
        let details = ["Đã dùng \(quota.usedThisWeek)/\(AIQuota.weeklyFree) lượt miễn phí", bonusLine].compactMap { $0 }
        // "3 trên 10", not a slash read aloud (review 2026-11-09).
        let spokenDetails = ["Đã dùng \(quota.usedThisWeek) trên \(AIQuota.weeklyFree) lượt miễn phí", bonusLine].compactMap { $0 }
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
                        .contentTransition(.numericText())
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
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(spokenDetails.joined(separator: ", "))
                }
            }
            // Says what it opens: Pro is not on sale yet (review 2026-11-09: "Nâng cấp" led to
            // "Sắp ra mắt").
            MiluButton("Tìm hiểu Milu Pro", role: .primary, fullWidth: true) {
                note = Note(title: MiluProNote.title, message: MiluProNote.message)
            }
            .accessibilityHint("Gói Milu Pro sắp ra mắt")
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
}
