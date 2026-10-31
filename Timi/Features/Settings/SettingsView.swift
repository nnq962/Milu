import SwiftUI

/// Cài đặt, opened from the avatar on Tổng quan as a full sheet (like the account sheet in Apple's
/// own apps). Redone 2026-10-29: the profile card, this month's lượt AI, a Timi Pro invite, then
/// Chung, Thông báo, Hỗ trợ and Nhà phát triển, where the UI library lives. Rows the app cannot do yet open a short note.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota

    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @AppStorage(StorageKey.dailyReminder) private var dailyReminder = true
    @AppStorage(StorageKey.budgetAlerts) private var budgetAlerts = true
    @AppStorage(StorageKey.news) private var news = false

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    VStack(spacing: Spacing.l) {
                        profile
                        aiQuotaCard
                        proInvite
                    }

                    FormGroup(title: "Chung") {
                        NavigationLink {
                            CategoriesView()
                        } label: {
                            NavigationRowLabel(title: "Hạng mục", icon: "hugeicons-tag-01",
                                               value: "\(store.visibleItemCount)",
                                               spokenValue: "\(store.visibleItemCount) hạng mục")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        NavigationLink {
                            ContactsView()
                        } label: {
                            NavigationRowLabel(title: "Danh bạ", icon: "hugeicons-user-group",
                                               value: "\(store.contacts.count)",
                                               spokenValue: "\(store.contacts.count) người")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        // Báo cáo here too, not only from the month cards (user request 2026-10-30).
                        NavigationLink {
                            ReportView()
                        } label: {
                            NavigationRowLabel(title: "Báo cáo", icon: "hugeicons-pie-chart")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        NavigationLink {
                            BudgetView()
                        } label: {
                            NavigationRowLabel(title: "Hạn mức chi tiêu", icon: "hugeicons-chart-increase",
                                               value: monthlyBudget > 0 ? monthlyBudget.vndCompact : "Chưa đặt")
                        }
                        .buttonStyle(.row)
                    }

                    // No footers here: a footer only carries a computed figure or an error
                    // (strict review 2026-10-31).
                    FormGroup(title: "Thông báo") {
                        FormToggleRow(title: "Nhắc ghi chi tiêu", subtitle: "21:00 mỗi ngày",
                                      icon: "hugeicons-notification-01", isOn: $dailyReminder)
                        FormDivider()
                        FormToggleRow(title: "Cảnh báo hạn mức", subtitle: "Khi dùng 80% và 100%",
                                      icon: "hugeicons-alert-circle", isOn: $budgetAlerts)
                        FormDivider()
                        FormToggleRow(title: "Tin từ Timi", icon: "hugeicons-star", isOn: $news)
                    }

                    FormGroup(title: "Hỗ trợ") {
                        FormNavigationRow(title: "Câu hỏi thường gặp", icon: "hugeicons-help-circle") {
                            note = Note(title: "Câu hỏi thường gặp", message: "Sắp có trong app. Hiện bạn có thể xem trên bản web của Timi.")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Góp ý với Timi", icon: "hugeicons-bubble-chat") {
                            mail(subject: "Góp ý cho Timi iOS")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Email hỗ trợ", subtitle: Self.supportEmail, icon: "hugeicons-mail-01") {
                            mail(subject: "Hỗ trợ Timi iOS")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Điều khoản sử dụng", icon: "hugeicons-file-02") {
                            note = Note(title: "Điều khoản sử dụng", message: "Sắp có trong app.")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Chính sách quyền riêng tư", icon: "hugeicons-security-check") {
                            note = Note(title: "Chính sách quyền riêng tư", message: "Dữ liệu trong bản thử nghiệm chỉ nằm trên máy và được đặt lại khi mở lại app. Chính sách đầy đủ sắp có.")
                        }
                        FormDivider()
                        NavigationLink {
                            LicensesView()
                        } label: {
                            NavigationRowLabel(title: "Giấy phép mã nguồn mở", icon: "hugeicons-license")
                        }
                        .buttonStyle(.row)
                    }

                    FormGroup(title: "Nhà phát triển") {
                        NavigationLink {
                            DesignSystemView()
                        } label: {
                            NavigationRowLabel(title: "Thư viện UI", subtitle: "Hệ thống thiết kế, chạm thử được",
                                               icon: "hugeicons-dashboard-square-01")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        // The version shows here only: a line under the last group repeated it (re-review 2026-10-31).
                        FormNavigationRow(title: "Lịch sử phiên bản", icon: "hugeicons-history", value: version) {
                            note = Note(title: "Phiên bản \(version)", message: "Bản thử nghiệm: hệ thống thiết kế, form kiểu iOS, logo ngân hàng và ví, biểu đồ Swift Charts, dữ liệu lưu trên máy.")
                        }
                        // The red row has its bin icon, so its hairline starts at the text too.
                        FormDivider()
                        FormDestructiveRow(title: "Đặt lại dữ liệu mẫu", question: "Đặt lại dữ liệu mẫu?",
                                           message: "Mọi tài khoản, giao dịch, hũ, khoản vay, hạng mục, danh bạ và hạn mức bạn đã thêm hoặc sửa sẽ bị xoá.") {
                            store.resetToSampleData()
                            // The limits too: they live in UserDefaults, not the database.
                            UserDefaults.standard.removeObject(forKey: StorageKey.monthlyBudget)
                            UserDefaults.standard.removeObject(forKey: StorageKey.categoryBudgets)
                        }
                    }

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
                Text("Dữ liệu mẫu · lưu trên máy")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            Spacer(minLength: Spacing.s)
            StatusBadge(text: "Miễn phí", tone: .neutral, showsDot: false)
        }
        .settingsCard()
        .accessibilityElement(children: .combine)
    }

    /// This month's lượt AI: what is left of the 20 and the bonus from Làm quen, then the bar of
    /// what has been used with its words right under it, so an empty bar reads "nothing used"
    /// (user report 2026-10-31: the bar was what is left, full at 0/20, and read as "all used").
    /// Icon and words as a form row's: a 20 glyph in the 24 column, the words at 54 like the
    /// rows below (re-review 2026-10-31).
    private var aiQuotaCard: some View {
        let used = quota.usedThisMonth
        let renews = quota.renewsOn.shortDay
        return HStack(alignment: .top, spacing: RowMetrics.gap) {
            FormRowIcon(icon: "hugeicons-ai-magic")
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Lượt AI tháng này")
                        .textRole(.bodyStrong)
                    Spacer(minLength: Spacing.s)
                    Text("Làm mới \(renews)")
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
                    if quota.bonus > 0 {
                        Spacer(minLength: Spacing.s)
                        Text("+\(quota.bonus) lượt thưởng")
                            .textRole(.caption)
                            .foregroundStyle(Palette.positive)
                    }
                }
                VStack(alignment: .leading, spacing: Spacing.s) {
                    // Fills as lượt are used; orange once 3 or fewer free ones are left.
                    ProgressBar(value: Double(used) / Double(AIQuota.monthlyFree),
                                color: quota.monthlyLeft <= 3 ? Palette.warning : Palette.primary)
                        .accessibilityHidden(true)
                    Text("Đã dùng \(used)/\(AIQuota.monthlyFree) lượt miễn phí")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .monospacedDigit()
                }
            }
        }
        .settingsCard()
        .accessibilityElement(children: .combine)
    }

    /// A short Timi Pro invite: a white card with a plain crown in the accent colour. The crown is a row's
    /// glyph in a row's column, so the words start at 54 like every row (re-review 2026-10-31: 24
    /// and 12, words at 52).
    private var proInvite: some View {
        Button {
            note = Note(title: "Timi Pro · Sắp ra mắt",
                        message: "Timi Pro có \(AIQuota.monthlyPro) lượt AI mỗi tháng, xuất báo cáo PDF, Excel và đồng bộ trên mọi thiết bị. Gói đang được chuẩn bị, chưa mở đăng ký hoặc thanh toán.")
        } label: {
            HStack(spacing: RowMetrics.gap) {
                TimiIcon("hugeicons-crown", size: RowMetrics.iconGlyph)
                    .foregroundStyle(Palette.primary)
                    .frame(width: RowMetrics.iconColumn, height: RowMetrics.iconGlyph)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text("Nâng cấp Timi Pro")
                        .textRole(.bodyStrong)
                        .foregroundStyle(Palette.label)
                    Text("\(AIQuota.monthlyPro) lượt AI mỗi tháng, báo cáo, đồng bộ")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .lineLimit(2)
                }
                Spacer(minLength: Spacing.s)
                RowChevron()
            }
            .settingsCard()
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.inset, style: .continuous))
        }
        .buttonStyle(.card)
    }

    private func mail(subject: String) {
        let query = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(Self.supportEmail)?subject=\(query)") {
            openURL(url)
        }
    }
}

extension View {
    /// A white card of words in Cài đặt and its pages (the cards atop Cài đặt, the month's card on
    /// Hạn mức): corners 24 and words 16 from the edge, like the form groups and headings around
    /// it, so the left edges line up (strict review 2026-10-31: 20 in, corners 28).
    func settingsCard() -> some View {
        padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: CardCorners.inset, outlined: true)
    }
}

#Preview {
    SettingsView()
        .environment(FinanceStore())
        .environment(AIQuota())
}
