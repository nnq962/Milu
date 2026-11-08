import SwiftUI

/// "Timi Pro", last on Tổng quan, the page's one coloured card (user request 2026-11-08: "màu mè
/// hơn"): "Timi Pro" as the section's heading on the page; in the card Milu's sky running into
/// honey with soft apricot suns, a "✦ PRO" tag, "Dùng Timi trọn vẹn" and one line under it, the
/// Fluent Flat crown with sparkles, and "Tìm hiểu thêm" across the foot: Pro is not on sale yet,
/// so the button says what a tap does. The whole card is one button.
struct ProUpgradeCard: View {
    let onUpgrade: () -> Void

    /// The crown, grown with the words beside it no more than 1.6 times (review 2026-11-08: about
    /// 190 wide at AX5, the title wrapped a word a line); left out at the accessibility sizes.
    @ScaledMetric(relativeTo: .body) private var scaledCrown: CGFloat = Self.crownBase
    private static let crownBase: CGFloat = 64
    private var crownSize: CGFloat { RowMetrics.capped(scaledCrown, base: Self.crownBase) }
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        OutsideHeaderSection(title: "Timi Pro") { card }
    }

    private var card: some View {
        let shape = RoundedRectangle(cornerRadius: CardCorners.card, style: .continuous)
        return Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                HStack(alignment: .top, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        badge
                        // The `title` of every card's name on the page.
                        Text("Dùng Timi trọn vẹn")
                            .textRole(.title)
                            .foregroundStyle(Palette.label)
                        Text("Không lo hết lượt AI.")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if !typeSize.isAccessibilitySize { crown }
                }
                // Drawn as a `TimiButton(role: .primary)`; not a button of its own, the whole card
                // is one.
                TimiButtonTitle(title: "Tìm hiểu thêm", icon: nil)
                    .textRole(.button)
                    .foregroundStyle(Palette.onAccent)
                    .frame(maxWidth: .infinity, minHeight: ControlHeight.regular)
                    .background(Palette.accent, in: Capsule())
            }
            // 20, as the other cards of the page (it neither leads the page nor stands alone).
            .padding(Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { ground.clipShape(shape) }
            .overlay { shape.strokeBorder(Palette.separator, lineWidth: 1) }
            .contentShape(shape)
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .ignore)
        // The heading above already says "Timi Pro"; Voice Control answers to the button's words.
        .accessibilityLabel("Dùng Timi trọn vẹn, không lo hết lượt AI")
        .accessibilityInputLabels(["Tìm hiểu thêm", "Timi Pro"])
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tìm hiểu về Timi Pro, sắp ra mắt")
    }

    /// The colours of Milu's sky (user request 2026-11-08: "màu mè hơn"): sky into honey across the
    /// card, and two soft apricot suns behind the crown. Only brand colours, no new hue; at night
    /// the same three in their dark shades, under the same words.
    private var ground: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(colors: [Palette.sky, Palette.honey],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(Palette.apricot.opacity(0.28))
                .frame(width: 150, height: 150)
                .offset(x: 50, y: -60)
            Circle()
                .fill(Palette.apricot.opacity(0.18))
                .frame(width: 70, height: 70)
                .offset(x: -70, y: 60)
        }
        .accessibilityHidden(true)
    }

    /// "✦ PRO" in a white capsule over the title, the card's tag.
    private var badge: some View {
        Label("PRO", systemImage: "sparkles")
            .labelStyle(.titleAndIcon)
            .textRole(.captionStrong)
            .foregroundStyle(Palette.deep)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xxs)
            .background(Palette.surface.opacity(0.75), in: Capsule())
    }

    /// The card's picture: Fluent Emoji Flat's crown, tilted, with two sparkles beside it.
    private var crown: some View {
        Image(IconCatalog.emojiName("👑"))
            .resizable()
            .scaledToFit()
            .frame(width: crownSize, height: crownSize)
            .rotationEffect(.degrees(12))
            .overlay(alignment: .bottomLeading) {
                Image(IconCatalog.emojiName("✨"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: crownSize * 0.4, height: crownSize * 0.4)
                    .offset(x: -crownSize * 0.3, y: crownSize * 0.15)
            }
            .accessibilityHidden(true)
    }
}
