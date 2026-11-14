import StoreKit
import SwiftUI

/// "Milu Pro": what it brings, the two plans (the year chosen first, with what it saves), and the
/// one button that buys (user request 2026-11-12). Below it what Apple asks every plan to say:
/// it renews until cancelled, how to cancel, restoring a purchase, the terms and the privacy
/// policy; and "Nhập mã ưu đãi" for an offer code. Owned already: the plan and "Quản lý gói".
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = ProStore.shared
    @State private var plan = ProStore.Plan.yearly
    @State private var isBuying = false
    @State private var isRestoring = false
    @State private var isRedeeming = false
    @State private var isManaging = false
    @State private var legal: LegalPage?
    /// Debug, made-up prices: the question Apple's purchase sheet would ask.
    @State private var isConfirmingMock = false

    private enum LegalPage: String, Identifiable {
        case terms, privacy
        var id: Self { self }
        var document: LegalDocument { self == .terms ? .terms : .privacy }
    }

    var body: some View {
        SheetScaffold(title: "Milu Pro") {
            hero
        } content: {
            // The plans first, what Pro brings under them (user request 2026-11-12, as Claude's).
            if store.isPro {
                owned
            } else {
                VStack(spacing: Spacing.l) {
                    plans
                    buyButton
                }
            }
            benefits
            finePrint
        }
        .miluSheetStyle()
        .task { await store.loadProducts() }
        .offerCodeRedemption(isPresented: $isRedeeming) { _ in
            Task { await store.refresh() }
        }
        .manageSubscriptionsSheet(isPresented: $isManaging)
        // Back from Apple's sheet (a plan cancelled or changed there): what is owned now.
        .onChange(of: isManaging) { _, open in if !open { Task { await store.refresh() } } }
        .sheet(item: $legal) { page in
            NavigationStack { LegalDocumentView(document: page.document) }
                .miluSheetStyle()
        }
        .systemAlert("Mua thử \(plan.title)", isPresented: $isConfirmingMock) {
            Button("Mua thử") { Task { await buy() } }
            Button("Huỷ", role: .cancel) {}
        } message: {
            Text("Giá thử, chỉ có ở bản Debug: không trừ tiền, chỉ bật Milu Pro trên máy này.")
        }
        .systemAlert("Milu Pro", isPresented: Binding { store.failure != nil } set: { if !$0 { store.failure = nil } }) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.failure ?? "")
        }
    }

    // MARK: - Đầu trang

    private var hero: some View {
        // Words only, no picture: the plans come up the page (user request 2026-11-12).
        VStack(spacing: Spacing.xs) {
            Text(store.isPro ? "Bạn đang dùng Milu Pro" : "Dùng Milu trọn vẹn")
                .textRole(.pageTitle)
                .accessibilityAddTraits(.isHeader)
            Text(store.isPro ? "Cảm ơn bạn đã ủng hộ Milu!" : "Chọn gói phù hợp với bạn")
                .textRole(.body)
                .foregroundStyle(Palette.secondaryLabel)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s)
    }

    /// What Pro brings today, and what is still to come said so.
    private var benefits: some View {
        FormGroup(title: "Có trong Milu Pro") {
            benefit("\(AIQuota.weeklyPro) lượt hỏi Milu mỗi tuần", detail: "Gói miễn phí có \(AIQuota.weeklyFree) lượt",
                    icon: "hugeicons-ai-magic")
            FormDivider()
            benefit("Khoá app bằng \(AppLock.biometryName)", detail: "Chỉ bạn mới mở được Milu",
                    icon: "hugeicons-square-lock-02")
            FormDivider()
            benefit("Xuất báo cáo PDF, Excel", detail: "Sắp có", icon: "hugeicons-file-02")
        }
    }

    private func benefit(_ title: String, detail: String, icon: String) -> some View {
        FormRowLabel(title: title, subtitle: detail, icon: icon)
            .formRowFrame()
            .accessibilityElement(children: .combine)
    }

    // MARK: - Gói

    /// The two plans side by side, the month on the left and the year on the right, as the
    /// user asked (2026-11-12, after Claude's plan picker); stacked at the accessibility sizes.
    private var plans: some View {
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            if store.isMocking {
                Text("Giá thử (bản Debug): gói chưa có trên App Store.")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .padding(.horizontal, RowMetrics.horizontal)
            }
            AdaptiveStack(alignment: .top, spacing: Spacing.m, stackedSpacing: Spacing.m) {
                planCard(.monthly)
                planCard(.yearly)
            }
            // Both as tall as the taller one.
            .fixedSize(horizontal: false, vertical: true)
        }
        .sensoryFeedback(.selection, trigger: plan)
    }

    private func planCard(_ option: ProStore.Plan) -> some View {
        let selected = plan == option
        let price = store.price(option)
        let saving = option == .yearly ? store.yearlySaving() : nil
        let perMonth = option == .yearly ? store.yearlyPerMonth() : nil
        let shape = RoundedRectangle(cornerRadius: CardCorners.card, style: .continuous)
        return Button { plan = option } label: {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(spacing: Spacing.s) {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(selected ? Palette.primary : Palette.tertiaryLabel)
                    Spacer(minLength: 0)
                    if let saving {
                        StatusBadge(title: saving, tone: .pro, showsDot: false)
                            .fixedSize()
                    }
                }
                .frame(minHeight: StatusBadge.height)
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    // A grey bar of the same size until the App Store answers.
                    Text(price ?? "000.000đ")
                        .textRole(.title)
                        .monospacedDigit()
                        .redacted(reason: price == nil ? .placeholder : [])
                    Text(option == .yearly ? "Thanh toán mỗi năm" : "Thanh toán mỗi tháng")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                    if let perMonth {
                        Text("Chỉ \(perMonth)")
                            .textRole(.captionStrong)
                            .foregroundStyle(Palette.primary)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.l)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // The chosen one tinted, as the selected plan in Claude's picker.
            .background {
                ZStack {
                    shape.fill(Palette.surface)
                    if selected { shape.fill(Palette.primaryTint) }
                }
            }
            .overlay { shape.strokeBorder(selected ? Palette.primary : Palette.separator, lineWidth: selected ? 2 : 1) }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel([option.title, price, perMonth.map { "chỉ \($0)" }, saving].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .animation(Motion.gentle(.easeOut(duration: 0.15)), value: selected)
    }

    private var buyButton: some View {
        let price = store.price(plan)
        let ready = price != nil && !isBuying
        return MiluButton(role: .primary, fullWidth: true) {
            if store.isMocking { isConfirmingMock = true } else { Task { await buy() } }
        } label: {
            if isBuying || store.isLoading {
                ProgressView().tint(Palette.onAccent)
            } else if let price {
                Text("Đăng ký · \(price)/\(plan == .yearly ? "năm" : "tháng")")
            } else {
                Text("Chưa tải được gói")
            }
        }
        .disabled(!ready)
    }

    private func buy() async {
        isBuying = true
        if await store.buy(plan) {
            Haptics.milestone()
            dismiss()
        }
        isBuying = false
    }

    /// "20/12/2026", or "hôm nay 22:15" when it is today (a test plan lasts minutes).
    private static func when(_ date: Date) -> String {
        let time = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        if Calendar.current.isDateInToday(date) { return "hôm nay \(time)" }
        return date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year())
    }

    /// Owned already: the plan, and Apple's own sheet to change or cancel it.
    private var owned: some View {
        FormGroup(title: "Gói của bạn") {
            FormInfoRow(title: "Đang dùng", value: store.ownedPlan?.title ?? "Milu Pro")
            FormDivider(hasIcon: false)
            // When it renews, or, cancelled, until when it lasts (Pro stays to the end of what
            // was paid, then goes by itself).
            if let end = store.expiresAt {
                FormInfoRow(title: store.renews ? "Gia hạn vào" : "Đã huỷ, dùng đến", value: Self.when(end))
                FormDivider(hasIcon: false)
            }
            #if DEBUG
            if store.isMockOwned {
                FormNavigationRow(title: "Huỷ gói thử", subtitle: "Bản Debug: trở lại gói miễn phí", accessory: .none) {
                    Task { await store.cancelMock() }
                }
            } else {
                FormNavigationRow(title: "Quản lý gói", accessory: .none) { isManaging = true }
            }
            #else
            FormNavigationRow(title: "Quản lý gói", accessory: .none) { isManaging = true }
            #endif
        }
    }

    // MARK: - Chữ nhỏ

    /// What Apple asks a plan that renews to say, then the links.
    private var finePrint: some View {
        VStack(spacing: Spacing.m) {
            if !store.isPro {
                Text("Gói tự gia hạn cho tới khi bạn huỷ. Huỷ bất cứ lúc nào trong Cài đặt › Apple ID › Đăng ký, chậm nhất 24 giờ trước kỳ gia hạn.")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            FormGroup {
                FormNavigationRow(title: "Khôi phục giao dịch mua", icon: "hugeicons-history", accessory: .none) {
                    Task {
                        isRestoring = true
                        await store.restore()
                        isRestoring = false
                        if store.isPro { Haptics.milestone() }
                    }
                }
                .disabled(isRestoring)
                FormDivider()
                FormNavigationRow(title: "Nhập mã ưu đãi", icon: "hugeicons-coupon-01", accessory: .none) {
                    isRedeeming = true
                }
                FormDivider()
                FormNavigationRow(title: "Điều khoản sử dụng", icon: "hugeicons-legal-document-01", accessory: .none) {
                    legal = .terms
                }
                FormDivider()
                FormNavigationRow(title: "Chính sách quyền riêng tư", icon: "hugeicons-security-check", accessory: .none) {
                    legal = .privacy
                }
            }
        }
    }
}
