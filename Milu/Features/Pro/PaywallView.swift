import StoreKit
import SwiftUI

/// "Milu Pro": Than on the sky and one line, what it brings as three tiles, the two plans (the year
/// chosen first, with what it saves), and the one button that buys (user requests 2026-11-12,
/// -14: it read like Cài đặt, rows and many words). Below, in small print, what Apple asks every
/// plan to say (it renews until cancelled) and the links: restore, offer code, terms, privacy.
/// Owned already: the plan, when it renews, and "Quản lý gói".
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppLock.self) private var appLock
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
            benefits
            if store.isPro {
                owned
            } else {
                VStack(spacing: Spacing.l) {
                    plans
                    buyButton
                }
            }
            finePrint
        }
        .miluSheetStyle()
        .task { await store.loadProducts() }
        .offerCodeRedemption(isPresented: $isRedeeming) { _ in
            Task { await store.refresh() }
        }
        .manageSubscriptionsSheet(isPresented: $isManaging)
        // Back from Apple's sheet (a plan cancelled or changed there): what is owned now.
        .onChange(of: isManaging) { _, open in
            // The App Store's sheet runs apart from Milu and leaves it inactive: not leaving, so
            // no cover behind it (review 2026-11-14).
            appLock.isShowingSystemSheet = open
            if !open { Task { await store.refresh() } }
        }
        // Closed with the App Store's sheet still counted as up: the switcher would never be
        // covered again until Milu was quit.
        .onDisappear { if isManaging { appLock.isShowingSystemSheet = false } }
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
        VStack(spacing: Spacing.m) {
            // Than glad on the sky, standing on the panel's foot, as on the tabs' heads.
            ZStack(alignment: .bottom) {
                Palette.sky
                Image(MiluHero.Look.vui.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 210)
                    .accessibilityHidden(true)
            }
            .frame(height: 112)
            .clipShape(RoundedRectangle(cornerRadius: CardCorners.card, style: .continuous))
            VStack(spacing: Spacing.xs) {
                // Not "Milu Pro" again under the bar that says it.
                Text(store.isPro ? "Bạn đang dùng Milu Pro" : "Dùng Milu trọn vẹn")
                    .textRole(.pageTitle)
                    .accessibilityAddTraits(.isHeader)
                Text(store.isPro ? "Cảm ơn bạn đã ủng hộ Milu!" : "Một câu nói là xong, Milu lo phần còn lại")
                    .textRole(.body)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    /// What Pro brings, as a short list on the page itself, no cards (user request 2026-11-14:
    /// three tiles were too many cards; rows in a group read as Cài đặt): a tinted disc, the
    /// thing, and a few words under it.
    private var benefits: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            BenefitRow(emoji: "✨", ground: Palette.honey, title: "Trợ lý AI",
                       detail: "\(AIQuota.weeklyPro) lượt mỗi tuần")
            BenefitRow(emoji: "🔒", ground: Palette.sky, title: "Khoá bằng \(AppLock.biometryName)",
                       detail: "Chỉ bạn mở được Milu")
            BenefitRow(emoji: "📊", ground: Palette.accentSoft, title: "Xuất báo cáo",
                       detail: "PDF và Excel", isComing: true)
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    Text(option == .yearly ? "mỗi năm" : "mỗi tháng")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                    if let perMonth {
                        Text("≈ \(perMonth)")
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
        .accessibilityLabel([option.title, price, perMonth.map { "khoảng \($0)" }, saving].compactMap { $0 }.joined(separator: ", "))
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
        let time = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
        if Calendar.current.isDateInToday(date) { return "hôm nay \(time)" }
        return date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year())
    }

    /// Owned already: the plan and when it renews (or, cancelled, until when it lasts) on one card,
    /// and Apple's own sheet to change or cancel it.
    private var owned: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text(store.ownedPlan?.title ?? "Milu Pro")
                        .textRole(.bodyStrong)
                    // Pro stays to the end of what was paid, then goes by itself.
                    if let end = store.expiresAt {
                        Text("\(store.renews ? "Gia hạn" : "Đã huỷ, dùng đến") \(Self.when(end))")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                StatusBadge(title: "Pro", tone: .pro, showsDot: false)
                    .fixedSize()
            }
            .accessibilityElement(children: .combine)
            #if DEBUG
            if store.isMockOwned {
                MiluButton("Huỷ gói thử", role: .secondary, fullWidth: true) {
                    Task { await store.cancelMock() }
                }
            } else {
                MiluButton("Quản lý gói", role: .secondary, fullWidth: true) { isManaging = true }
            }
            #else
            MiluButton("Quản lý gói", role: .secondary, fullWidth: true) { isManaging = true }
            #endif
        }
        .settingsCard()
    }

    // MARK: - Chữ nhỏ

    /// What Apple asks a plan that renews to say, in one short line, then the links as small words
    /// rather than a group of rows (user request 2026-11-14).
    private var finePrint: some View {
        VStack(spacing: Spacing.s) {
            if !store.isPro {
                // Two even lines, not "Apple ID." alone on the second (review 2026-11-14).
                Text("Tự gia hạn đến khi bạn huỷ.\nHuỷ bất cứ lúc nào trong Cài đặt › Apple ID.")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            // The four on one line when they fit, else two lines, close together (user request
            // 2026-11-14: the small print took too much room).
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) {
                    restoreLink; dot; offerLink; dot; termsLink; dot; privacyLink
                }
                VStack(spacing: 0) {
                    HStack(spacing: Spacing.xs) { restoreLink; dot; offerLink }
                    HStack(spacing: Spacing.xs) { termsLink; dot; privacyLink }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var restoreLink: some View {
        FinePrintLink(title: isRestoring ? "Đang khôi phục…" : "Khôi phục") {
            Task {
                isRestoring = true
                await store.restore()
                isRestoring = false
                if store.isPro { Haptics.milestone() }
            }
        }
        .disabled(isRestoring)
        .accessibilityLabel("Khôi phục giao dịch mua")
    }

    private var offerLink: some View {
        FinePrintLink(title: "Mã ưu đãi") { isRedeeming = true }
            .accessibilityLabel("Nhập mã ưu đãi")
    }

    private var termsLink: some View {
        FinePrintLink(title: "Điều khoản") { legal = .terms }
    }

    private var privacyLink: some View {
        FinePrintLink(title: "Quyền riêng tư") { legal = .privacy }
    }

    private var dot: some View {
        Text("·").textRole(.caption).foregroundStyle(Palette.tertiaryLabel).accessibilityHidden(true)
    }
}

/// One thing Pro brings: its Fluent Flat picture on a soft tile of Milu's colours (as the crown
/// on Tổng quan's Pro card), its name, "Sắp có" beside the name while it is still to come, and a
/// few words under it (user request 2026-11-14: grey line glyphs on grey discs looked plain).
private struct BenefitRow: View {
    let emoji: String
    let ground: Color
    let title: String
    let detail: String
    var isComing = false

    @ScaledMetric(relativeTo: .body) private var scaledTile: CGFloat = Self.tileBase
    private static let tileBase: CGFloat = 48
    /// Grows with the words, no more than 1.6 times.
    private var tile: CGFloat { RowMetrics.capped(scaledTile, base: Self.tileBase) }

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            Image(IconCatalog.emojiName(emoji))
                .resizable()
                .scaledToFit()
                .frame(width: tile * 0.58, height: tile * 0.58)
                .frame(width: tile, height: tile)
                .background(ground, in: RoundedRectangle(cornerRadius: CardCorners.small + 6, style: .continuous))
                .saturation(isComing ? 0.4 : 1)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    Text(title)
                        .textRole(.bodyStrong)
                    if isComing {
                        Text("Sắp có")
                            .textRole(.captionStrong)
                            .foregroundStyle(Palette.secondaryLabel)
                            .padding(.horizontal, Spacing.s)
                            .padding(.vertical, Spacing.xxs)
                            .background(Palette.fill, in: Capsule())
                            .fixedSize()
                    }
                }
                Text(detail)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A link in the small print: the action colour, caption size, a tap target a little taller than
/// its words so two lines of links sit close.
private struct FinePrintLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.primary)
                .padding(.vertical, Spacing.s)
                .padding(.horizontal, Spacing.xs)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
