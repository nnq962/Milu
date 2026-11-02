import SwiftUI

/// "Timi Pro", last on Tổng quan: a plain white card, the user's pick "3B" (2026-11-02: no more ink
/// card, fewer icons; its lime glow dropped in the Overview review the same day, lime was on every
/// card). "TIMI PRO" in small capitals, "Dùng Timi trọn vẹn" and one line under it, the crown on a
/// lime disc beside them, its one icon (user request 2026-11-02), and "Tìm hiểu thêm" in lime across
/// the foot: Pro is not on sale yet, so the button says what a tap does (review 2026-10-31). The
/// whole card is one button; the pill only says what it does.
struct ProUpgradeCard: View {
    let onUpgrade: () -> Void

    /// The crown's disc; it grows with the words beside it.
    @ScaledMetric(relativeTo: .body) private var crownSize: CGFloat = 48

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
        Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                HStack(alignment: .top, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("TIMI PRO")
                            .textRole(.overline)
                            .foregroundStyle(Palette.secondaryLabel)
                        Text("Dùng Timi trọn vẹn")
                            .textRole(.heading)
                            .foregroundStyle(Palette.label)
                        Text("Không lo hết lượt AI.")
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    crown
                }
                Text("Tìm hiểu thêm")
                    .textRole(.bodyStrong)
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

    /// The card's one icon (user request 2026-11-02): the crown in ink on a lime disc.
    private var crown: some View {
        TimiIcon("hugeicons-crown", size: RowMetrics.toolbarGlyph)
            .foregroundStyle(Palette.onAccent)
            .frame(width: crownSize, height: crownSize)
            .background(Palette.accent, in: Circle())
            .accessibilityHidden(true)
    }
}
