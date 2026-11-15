import SwiftUI

/// Milu's invitation to "Nhắc ghi chi tiêu", over Tổng quan on a new install, before iOS's own
/// prompt (user request 2026-11-15, as many apps do): Than on the sky under a reminder as it would
/// come at 21:00, what it does and when, then "Bật nhắc nhở" (iOS asks; allowed, the reminder
/// comes on) or "Để sau" (iOS is not asked, so Cài đặt → Thông báo can still ask later). A swipe
/// down is "Để sau". Shown once (`NotificationInvite`).
struct NotificationInviteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The page's height, for a sheet just as tall.
    @State private var height: CGFloat?
    @State private var bannerShown = false
    /// iOS's prompt is up: the buttons wait, and the sheet stays.
    @State private var isAsking = false

    /// The reminder's time as set (21:00 unless the user chose another, on another device too),
    /// so the page says when it will come (audit 2026-11-15: it said 21:00 for a 07:00 one).
    @AppStorage(StorageKey.dailyReminderMinutes) private var minutes = DailyReminderPlan.defaultMinutes

    /// The sample reminder: one of the lines the real ones pick from ("Ví ơi ví à 💸": its emoji
    /// reads on the light and the dark card; the paw of another line was lost on the dark one).
    private static let sample = DailyReminderPlan.messages[0]
    /// The reminder's time, as Cài đặt shows it ("21:00").
    private var time: String { String(format: "%02d:%02d", minutes / 60, minutes % 60) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                words
                    .padding(.top, Spacing.xxl)
                buttons
                    .padding(.top, Spacing.xxl)
            }
            .padding(.horizontal, Spacing.page)
            .padding(.top, Spacing.xxl)
            .padding(.bottom, Spacing.s)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .foregroundStyle(Palette.label)
        .presentationDetents([.height(height ?? 560)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.surface)
        .interactiveDismissDisabled(isAsking)
        // Seen once it is on screen (`NotificationInvite`).
        .onAppear { NotificationInvite.markShown() }
        .task {
            // The reminder drops in a beat after the sheet is up, as it would on the lock screen.
            if reduceMotion {
                bannerShown = true
                return
            }
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { bannerShown = true }
        }
    }

    // MARK: - Trời

    /// Than glad on the sky, peeking up from the panel's foot, under the sample reminder.
    private var hero: some View {
        ZStack(alignment: .top) {
            Palette.sky
            Image(MiluHero.Look.vui.image)
                .resizable()
                .scaledToFit()
                .frame(width: 230)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .accessibilityHidden(true)
            banner
                .padding(.horizontal, Spacing.l)
                .padding(.top, Spacing.l)
                .offset(y: bannerShown ? 0 : -18)
                .opacity(bannerShown ? 1 : 0)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: CardCorners.card, style: .continuous))
    }

    /// A reminder as iOS shows it: the app's mark, its name and the time, the line in bold and the
    /// words under it.
    private var banner: some View {
        HStack(alignment: .top, spacing: 10) {
            appMark
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: Spacing.s) {
                    Text("Milu")
                        .textRole(.captionStrong)
                    Spacer(minLength: 0)
                    Text(time)
                        .textRole(.footnote)
                        .foregroundStyle(Palette.tertiaryLabel)
                }
                sampleTitle
                Text(Self.sample.body)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .cardShadow()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ví dụ lời nhắc lúc \(time): \(Self.sample.title) \(Self.sample.body)")
    }

    /// The line in bold, its emoji as Milu draws them (`MiluEmoji2D`): Nunito has none, and the
    /// emoji showed as a box (simulator 2026-11-15).
    private var sampleTitle: some View {
        let words = Self.sample.title.split(separator: " ")
        let emoji = words.last.map(String.init) ?? ""
        let hasEmoji = emoji.unicodeScalars.first?.properties.isEmojiPresentation == true
        return HStack(spacing: Spacing.xs) {
            Text(hasEmoji ? words.dropLast().joined(separator: " ") : Self.sample.title)
                .textRole(.captionStrong)
            if hasEmoji {
                Image(IconCatalog.emojiName(emoji))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
            }
        }
    }

    /// Milu's icon, small: Than's face on the sky.
    private var appMark: some View {
        Palette.sky
            .overlay(alignment: .bottom) {
                Image(MiluHero.Look.nguyenBan.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62)
            }
            .frame(width: 38, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    // MARK: - Lời

    private var words: some View {
        VStack(spacing: Spacing.s) {
            Text("Để Milu nhắc bạn nha?")
                .textRole(.pageTitle)
                .accessibilityAddTraits(.isHeader)
            Text("Mỗi ngày lúc \(time), Milu nhắc bạn ghi lại chi tiêu trong ngày. Đổi giờ hay tắt lúc nào cũng được trong Cài đặt.")
                .textRole(.body)
                .foregroundStyle(Palette.secondaryLabel)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Nút

    private var buttons: some View {
        VStack(spacing: Spacing.xs) {
            MiluButton(role: .primary, fullWidth: true, action: turnOn) {
                Text("Bật nhắc nhở")
            }
            Button {
                dismiss()
            } label: {
                Text("Để sau")
                    .textRole(.button)
                    .foregroundStyle(Palette.primary)
                    .frame(maxWidth: .infinity, minHeight: ControlHeight.regular)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Bật sau trong Cài đặt, mục Thông báo")
        }
        // Not `disabled`: greyed, the buttons would flash while iOS asks.
        .allowsHitTesting(!isAsking)
    }

    /// iOS's prompt over the sheet; whatever the answer, the sheet then goes.
    private func turnOn() {
        guard !isAsking else { return }
        isAsking = true
        Task {
            if await NotificationInvite.accept() { Haptics.milestone() }
            isAsking = false
            dismiss()
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) { NotificationInviteView() }
}
