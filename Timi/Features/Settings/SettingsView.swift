import SwiftUI

/// Cài đặt, opened from the avatar on Tổng quan as a full sheet (like the account sheet in Apple's
/// own apps). Layout after the web app's settings: profile on top, then Chung, Thông báo, Hỗ trợ
/// and Nhà phát triển, where the UI library lives. Rows the app cannot do yet open a short note.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(FinanceStore.self) private var store

    @AppStorage("overview.monthlyBudget") private var monthlyBudget = SampleData.monthlyBudget
    @AppStorage("settings.dailyReminder") private var dailyReminder = true
    @AppStorage("settings.budgetAlerts") private var budgetAlerts = true
    @AppStorage("settings.news") private var news = false

    @State private var isEditingBudget = false
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
                    profile

                    FormGroup(title: "Chung") {
                        FormNavigationRow(title: "Giao diện", icon: "solar-pallete-2-linear", value: "Sáng") {
                            note = Note(title: "Giao diện", message: "Timi đang dùng giao diện sáng. Chế độ tối sẽ có khi các màn đã chuyển hết sang hệ thống thiết kế.")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Hạng mục", icon: "solar-tag-linear",
                                          value: "\(TransactionCategory.allCases.count)") {
                            note = Note(title: "Hạng mục", message: "Sắp có: thêm, đổi tên và sắp xếp hạng mục thu chi của riêng bạn.")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Hạn mức chi tiêu", icon: "solar-graph-up-linear",
                                          value: monthlyBudget > 0 ? monthlyBudget.vndCompact : "Chưa đặt") {
                            isEditingBudget = true
                        }
                    }

                    FormGroup(title: "Thông báo",
                              footer: "Thông báo chưa được gửi trong bản thử nghiệm; lựa chọn của bạn được lưu sẵn.") {
                        FormToggleRow(title: "Nhắc ghi chi tiêu", subtitle: "21:00 mỗi ngày",
                                      icon: "solar-bell-linear", isOn: $dailyReminder)
                        FormDivider()
                        FormToggleRow(title: "Cảnh báo hạn mức", subtitle: "Khi dùng 80% và 100%",
                                      icon: "solar-bell-bing-linear", isOn: $budgetAlerts)
                        FormDivider()
                        FormToggleRow(title: "Tin từ Timi", icon: "solar-star-linear", isOn: $news)
                    }

                    FormGroup(title: "Hỗ trợ") {
                        FormNavigationRow(title: "Câu hỏi thường gặp", icon: "solar-question-circle-linear") {
                            note = Note(title: "Câu hỏi thường gặp", message: "Sắp có trong app. Hiện bạn có thể xem trên bản web của Timi.")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Góp ý với Timi", icon: "solar-chat-round-line-linear") {
                            mail(subject: "Góp ý cho Timi iOS")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Email hỗ trợ", subtitle: Self.supportEmail, icon: "solar-letter-linear") {
                            mail(subject: "Hỗ trợ Timi iOS")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Điều khoản sử dụng", icon: "solar-document-text-linear") {
                            note = Note(title: "Điều khoản sử dụng", message: "Sắp có trong app.")
                        }
                        FormDivider()
                        FormNavigationRow(title: "Chính sách quyền riêng tư", icon: "solar-shield-check-linear") {
                            note = Note(title: "Chính sách quyền riêng tư", message: "Dữ liệu trong bản thử nghiệm chỉ nằm trên máy và được đặt lại khi mở lại app. Chính sách đầy đủ sắp có.")
                        }
                    }

                    FormGroup(title: "Nhà phát triển",
                              footer: "Dữ liệu lưu trên máy bằng SwiftData. Đặt lại sẽ xoá mọi thay đổi và nạp lại dữ liệu mẫu.") {
                        NavigationLink {
                            DesignSystemView()
                        } label: {
                            NavigationRowLabel(title: "Thư viện UI", subtitle: "Hệ thống thiết kế, chạm thử được",
                                               icon: "solar-widget-4-linear")
                        }
                        .buttonStyle(.row)
                        FormDivider()
                        FormNavigationRow(title: "Lịch sử phiên bản", icon: "solar-history-linear", value: version) {
                            note = Note(title: "Phiên bản \(version)", message: "Bản thử nghiệm: hệ thống thiết kế, form kiểu iOS, logo ngân hàng và ví, biểu đồ Swift Charts, dữ liệu lưu trên máy.")
                        }
                        FormDivider(hasIcon: false)
                        FormDestructiveRow(title: "Đặt lại dữ liệu mẫu", question: "Đặt lại dữ liệu mẫu?",
                                           message: "Mọi tài khoản, giao dịch, hũ và khoản vay bạn đã thêm hoặc sửa sẽ bị xoá.") {
                            store.resetToSampleData()
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
            .sheet(isPresented: $isEditingBudget) { BudgetEditorSheet(monthlyBudget: $monthlyBudget) }
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
        VStack(spacing: Spacing.s) {
            Text("Q")
                .textRole(.display)
                .foregroundStyle(Palette.ink)
                .frame(width: 80, height: 80)
                .background(Palette.muted, in: Circle())
                .accessibilityHidden(true)
            Text("Quyet")
                .textRole(.heading)
            Text("Dữ liệu mẫu · lưu trên máy")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
            StatusBadge(text: "Gói Miễn phí", tone: .neutral, showsDot: false)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.l)
    }

    private func mail(subject: String) {
        let query = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(Self.supportEmail)?subject=\(query)") {
            openURL(url)
        }
    }
}

/// The inside of a navigation row, for a `NavigationLink` that pushes instead of running an action.
private struct NavigationRowLabel: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil

    var body: some View {
        HStack(spacing: Spacing.s) {
            FormRowLabel(title: title, subtitle: subtitle, icon: icon)
            Spacer(minLength: Spacing.s)
            SolarIcon("solar-alt-arrow-right-linear", size: 16)
                .foregroundStyle(Palette.secondary)
        }
        .formRowFrame()
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
        .environment(FinanceStore())
}
