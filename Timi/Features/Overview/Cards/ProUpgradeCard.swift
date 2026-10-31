import SwiftUI

/// "Nâng cấp Timi Pro", the one card of Tổng quan that stands out (the user's design, 2026-10-31):
/// filled in the primary colour, lit from its top corner and with a large faint crown in the other,
/// a "PRO" mark over the title, each benefit on its own ticked row, and "Tìm hiểu thêm" across
/// the foot: Pro is not on sale yet, so the button says what a tap does (review 2026-10-31: it
/// said "Nâng cấp ngay" and opened a "coming soon" note). The whole card is one button; the pill
/// only says what it does. Ink by day; at night a raised grey with white words, since an inverted
/// near-white card was the brightest thing on the dark screen (review 2026-10-31).
///
/// Redone 2026-10-31 (user: dull, and it flashed as the sheet opened). The flash was the shared
/// card press, which dims to 60%: on an ink card the grey page showed through. It now takes a
/// light wash instead (`ProCardButtonStyle`). The corner light is a gradient, not a blurred circle,
/// which was drawn again on every frame of the sheet's slide.
struct ProUpgradeCard: View {
    let onUpgrade: () -> Void

    private static let benefits = [
        "\(AIQuota.monthlyPro) lượt AI mỗi tháng",
        "Xuất báo cáo PDF, Excel",
        "Đồng bộ trên mọi thiết bị",
    ]
    /// The crown watermark in the bottom trailing corner, partly off the card.
    private static let watermarkSize: CGFloat = 168
    private static let watermarkTilt = Angle.degrees(-14)

    /// The tick's disc grows with the benefit's words.
    @ScaledMetric(relativeTo: .body) private var tickSize = RowMetrics.iconColumn
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    /// The card: ink by day, a raised grey at night.
    private var fill: Color { isDark ? Palette.surfaceMuted : Palette.primary }
    /// The words and the button on it: white in both.
    private var ink: Color { isDark ? Palette.label : Palette.onPrimary }
    /// The button's words: the ink of the page, dark in both.
    private var buttonText: Color { isDark ? Palette.onPrimary : Palette.primary }
    /// A faint tile or disc of the words' colour: the PRO mark, a tick's disc.
    private var tint: Color { ink.opacity(0.14) }
    /// Secondary words on the card, as `secondaryLabel` is on a light one.
    private var mutedText: Color { ink.opacity(0.7) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
        Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    proMark
                    Text("Nâng cấp Timi Pro")
                        .textRole(.heading)
                    Text("Dùng Timi trọn vẹn, không lo hết lượt AI.")
                        .textRole(.caption)
                        .foregroundStyle(mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(alignment: .leading, spacing: Spacing.m) {
                    ForEach(Self.benefits, id: \.self) { benefit in
                        HStack(spacing: Spacing.m) {
                            TimiIcon("hugeicons-tick-02", size: RowMetrics.inlineGlyph)
                                .frame(width: tickSize, height: tickSize)
                                .background(tint, in: Circle())
                            Text(benefit)
                                .textRole(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                Text("Tìm hiểu thêm")
                    .textRole(.bodyStrong)
                    .foregroundStyle(buttonText)
                    .frame(maxWidth: .infinity, minHeight: ControlHeight.regular)
                    .background(ink, in: Capsule())
            }
            .foregroundStyle(ink)
            .padding(Spacing.leadCard)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { decoration }
            // A solid fill, no rim: the ink already parts it from the page.
            .cardSurface(radius: CardCorners.large, color: fill, outlined: false)
            .contentShape(shape)
        }
        .buttonStyle(ProCardButtonStyle(wash: ink))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Nâng cấp Timi Pro: " + Self.benefits.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
    }

    /// "♛ PRO" on a faint pill over the title.
    private var proMark: some View {
        HStack(spacing: Spacing.xs) {
            TimiIcon("hugeicons-crown", size: RowMetrics.inlineGlyph)
            Text("PRO")
                .textRole(.overline)
        }
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xs)
        .background(tint, in: Capsule())
    }

    /// Light from the top trailing corner and a large faint crown off the bottom trailing one.
    private var decoration: some View {
        ZStack {
            RadialGradient(colors: [ink.opacity(isDark ? 0.08 : 0.16), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 220)
            TimiIcon("hugeicons-crown", size: Self.watermarkSize)
                .foregroundStyle(ink.opacity(0.06))
                .rotationEffect(Self.watermarkTilt)
                .offset(x: Self.watermarkSize * 0.28, y: Self.watermarkSize * 0.22)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .accessibilityHidden(true)
    }
}

/// The press of the Pro card: a light wash over the ink rather than the 60% dimming of `.card`,
/// which let the grey page show through and flashed as the sheet opened.
private struct ProCardButtonStyle: ButtonStyle {
    /// The card's words colour, laid thin over it while pressed.
    let wash: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
                    .fill(wash.opacity(configuration.isPressed ? 0.08 : 0))
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
