import SwiftUI

/// "Timi Pro", last on Tổng quan: a plain white card, the user's pick "3B" (2026-11-02: no more ink
/// card, fewer icons; its lime glow dropped in the Overview review the same day, lime was on every
/// card). "TIMI PRO" in small capitals, "Dùng Timi trọn vẹn" and one line under it, the Fluent Flat crown beside
/// them, its one picture (user request 2026-11-02), and "Tìm hiểu thêm" in lime across
/// the foot: Pro is not on sale yet, so the button says what a tap does (review 2026-10-31). The
/// whole card is one button; the pill only says what it does.
struct ProUpgradeCard: View {
    let onUpgrade: () -> Void

    /// The Fluent Flat crown, the size of every Fluent Flat picture on the page; it grows with the words beside it.
    @ScaledMetric(relativeTo: .body) private var crownSize: CGFloat = RowMetrics.picture

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
        Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                HStack(alignment: .top, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("TIMI PRO")
                            .textRole(.overline)
                            .foregroundStyle(Palette.secondaryLabel)
                        // The 17 SemiBold of every card's title on the page (font pass 2026-11-02:
                        // it was the 20 heading, the only card set larger).
                        Text("Dùng Timi trọn vẹn")
                            .textRole(.title)
                            .foregroundStyle(Palette.label)
                        Text("Không lo hết lượt AI.")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    crown
                }
                // Drawn as the first step's `TimiButton(role: .primary)`, its twin on this page; not a
                // button of its own, the whole card is one.
                TimiButtonTitle(title: "Tìm hiểu thêm", icon: nil)
                    .textRole(.button)
                    .foregroundStyle(Palette.onAccent)
                    .frame(maxWidth: .infinity, minHeight: ControlHeight.regular)
                    .background(Palette.accent, in: Capsule())
            }
            .padding(Spacing.leadCard)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: CardCorners.large)
            .contentShape(shape)
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Timi Pro. Dùng Timi trọn vẹn, không lo hết lượt AI.")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tìm hiểu về Timi Pro, sắp ra mắt")
    }

    /// The card's one picture: Fluent Emoji Flat's crown, tilted a little, on nothing (user request
    /// 2026-11-02: the Fluent Flat pictures, after a lime disc with a line crown).
    private var crown: some View {
        Image(IconCatalog.emojiName("👑"))
            .resizable()
            .scaledToFit()
            .frame(width: crownSize, height: crownSize)
            .rotationEffect(.degrees(12))
            .accessibilityHidden(true)
    }
}
