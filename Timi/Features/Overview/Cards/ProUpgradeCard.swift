import SwiftUI

/// Timi Pro as a tinted banner at the foot of Tổng quan rather than a card (user request
/// 2026-10-30: fewer cards): each benefit on its own ticked line, "Tìm hiểu thêm", and the crown on a gold tile.
struct ProUpgradeCard: View {
    let onUpgrade: () -> Void

    private let benefits = ["300 lượt AI mỗi tháng", "Xuất báo cáo PDF, Excel", "Đồng bộ trên mọi thiết bị"]
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous) }

    var body: some View {
        Button(action: onUpgrade) {
            HStack(spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Nâng cấp Timi Pro")
                        .textRole(.title)
                        .foregroundStyle(Palette.ink)
                    // One line per benefit (user request 2026-10-30).
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(benefits, id: \.self) { benefit in
                            HStack(spacing: Spacing.s) {
                                TimiIcon("hugeicons-tick-02", size: 14)
                                    .foregroundStyle(Palette.warningText)
                                Text(benefit)
                                    .textRole(.caption)
                                    .foregroundStyle(Palette.ink)
                            }
                        }
                    }
                    HStack(spacing: Spacing.xs) {
                        Text("Tìm hiểu thêm")
                        TimiIcon("hugeicons-arrow-right-01", size: 14)
                    }
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.warningText)
                    .padding(.top, Spacing.xs)
                }
                Spacer(minLength: 0)
                // One warm family on the banner: gold tile, brown ticks and link (UI review 2026-10-30).
                TimiIcon("hugeicons-crown", size: 22)
                    .foregroundStyle(Palette.onLime)
                    .frame(width: 44, height: 44)
                    .background(Palette.lime, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.lime.opacity(0.16), in: shape)
            .contentShape(shape)
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .combine)
    }
}
