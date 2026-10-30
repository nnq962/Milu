import SwiftUI

/// Cài đặt, opened from the avatar on Tổng quan as a full sheet (like the account sheet in Apple's
/// own apps). Redone 2026-10-29: the profile card, this month's lượt AI, a Timi Pro invite, the
/// look picked right there (three tiles, no list), then Chung, Thông báo, Hỗ trợ and Nhà phát
/// triển, where the UI library lives. Rows the app cannot do yet open a short note.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(FinanceStore.self) private var store
    @Environment(AIQuota.self) private var quota

    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @AppStorage(StorageKey.dailyReminder) private var dailyReminder = true
    @AppStorage(StorageKey.budgetAlerts) private var budgetAlerts = true
    @AppStorage(StorageKey.news) private var news = false
    @AppStorage(StorageKey.appearance) private var appearance = AppAppearance.system.rawValue

    @State private var note: Note?

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
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    VStack(spacing: Spacing.m) {
                        profile
                        aiQuotaCard
                        proInvite
                    }

                    FormGroup(title: "Giao diện") {
                        AppearancePicker(selection: Binding { AppAppearance(rawValue: appearance) ?? .system }
                                             set: { appearance = $0.rawValue })
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

                    FormGroup(title: "Thông báo",
                              footer: "Thông báo chưa được gửi trong bản thử nghiệm; lựa chọn của bạn được lưu sẵn.") {
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

                    FormGroup(title: "Nhà phát triển",
                              footer: "Dữ liệu lưu trên máy bằng SwiftData. Đặt lại sẽ xoá mọi thay đổi và nạp lại dữ liệu mẫu.") {
                        NavigationLink {
                            DesignSystemView()
                        } label: {
                            NavigationRowLabel(title: "Thư viện UI", subtitle: "Hệ thống thiết kế, chạm thử được",
                                               icon: "hugeicons-dashboard-square-01")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        FormNavigationRow(title: "Lịch sử phiên bản", icon: "hugeicons-history", value: version) {
                            note = Note(title: "Phiên bản \(version)", message: "Bản thử nghiệm: hệ thống thiết kế, form kiểu iOS, logo ngân hàng và ví, biểu đồ Swift Charts, dữ liệu lưu trên máy.")
                        }
                        FormDivider(hasIcon: false)
                        FormDestructiveRow(title: "Đặt lại dữ liệu mẫu", question: "Đặt lại dữ liệu mẫu?",
                                           message: "Mọi tài khoản, giao dịch, hũ, khoản vay, hạng mục, danh bạ và hạn mức bạn đã thêm hoặc sửa sẽ bị xoá.") {
                            store.resetToSampleData()
                            // The limits too: they live in UserDefaults, not the database.
                            UserDefaults.standard.removeObject(forKey: StorageKey.monthlyBudget)
                            UserDefaults.standard.removeObject(forKey: StorageKey.categoryBudgets)
                        }
                    }

                    Text("Timi \(version) · Bản thử nghiệm")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, Spacing.s)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close) { dismiss() }
                    } else {
                        Button { dismiss() } label: { Image(systemName: "xmark") }
                            .accessibilityLabel("Đóng")
                    }
                }
            }
            .sheet(item: $note) { note in
                VStack(alignment: .leading, spacing: Spacing.l) {
                    SheetHeader(title: note.title)
                    Text(note.message)
                        .textRole(.body)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Spacing.page)
                .padding(.bottom, Spacing.xxl)
                .timiFittedSheet()
            }
        }
        .timiSheetStyle()
    }

    /// Who is signed in and their plan; the avatar repeats the one on Tổng quan.
    private var profile: some View {
        HStack(spacing: Spacing.m) {
            Text("Q")
                .textRole(.heading)
                .foregroundStyle(Palette.onLime)
                .frame(width: 56, height: 56)
                .background(Palette.lime, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Quyet")
                    .textRole(.heading)
                Text("Dữ liệu mẫu · lưu trên máy")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
            Spacer(minLength: Spacing.s)
            StatusBadge(text: "Miễn phí", tone: .neutral, showsDot: false)
        }
        .padding(Spacing.l)
        .cardSurface(radius: CardCorners.inset, color: Palette.card, elevated: true)
        .accessibilityElement(children: .combine)
    }

    /// This month's lượt AI: what is left of the 20, the bonus from Làm quen, and when it renews.
    private var aiQuotaCard: some View {
        let used = quota.usedThisMonth
        let renews = quota.renewsOn.formatted(.dateTime.day().month(.defaultDigits).locale(.vietnam))
        return VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                TimiIcon("hugeicons-ai-magic", size: 18)
                Text("Lượt AI tháng này")
                    .textRole(.bodyStrong)
                Spacer()
                Text("Làm mới \(renews)")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("\(quota.remaining)")
                    .textRole(.display)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("lượt còn lại")
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryText)
            }
            ProgressBar(value: Double(quota.monthlyLeft) / Double(AIQuota.monthlyFree),
                        color: quota.monthlyLeft <= 3 ? Palette.warning : Palette.primary)
                .accessibilityHidden(true)
            HStack {
                Text("Đã dùng \(used)/\(AIQuota.monthlyFree) lượt miễn phí")
                Spacer()
                if quota.bonus > 0 {
                    Text("+\(quota.bonus) lượt thưởng")
                        .foregroundStyle(Palette.green)
                }
            }
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
        }
        .padding(Spacing.l)
        .cardSurface(radius: CardCorners.inset, color: Palette.card, elevated: true)
        .accessibilityElement(children: .combine)
    }

    /// A short Timi Pro invite, the same dark and lime as the card on Tổng quan.
    private var proInvite: some View {
        Button {
            note = Note(title: "Timi Pro · Sắp ra mắt",
                        message: "Timi Pro có \(AIQuota.monthlyPro) lượt AI mỗi tháng, xuất báo cáo PDF, Excel và đồng bộ trên mọi thiết bị. Gói đang được chuẩn bị, chưa mở đăng ký hoặc thanh toán.")
        } label: {
            HStack(spacing: Spacing.m) {
                TimiIcon("hugeicons-crown", size: 20)
                    .foregroundStyle(Palette.onLime)
                    .frame(width: 40, height: 40)
                    .background(Palette.lime, in: RoundedRectangle(cornerRadius: CardCorners.icon, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nâng cấp Timi Pro")
                        .textRole(.bodyStrong)
                        .foregroundStyle(.white)
                    Text("\(AIQuota.monthlyPro) lượt AI mỗi tháng, báo cáo, đồng bộ")
                        .textRole(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                }
                Spacer(minLength: Spacing.s)
                TimiIcon("hugeicons-arrow-right-01", size: 16)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                Color.clear
                    .cardSurface(radius: CardCorners.inset, color: Palette.proCard)
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(Palette.lime.opacity(0.14))
                            .frame(width: 120, height: 120)
                            .blur(radius: 40)
                            .offset(x: 30, y: -40)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CardCorners.inset, style: .continuous))
            }
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


#Preview {
    SettingsView()
        .environment(FinanceStore())
        .environment(AIQuota())
}
