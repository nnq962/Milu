import SwiftUI

/// Timi Pro promotion (redone 2026-10-29, user choice): dark card with a faint lime glow and a lime
/// edge that slowly runs round it, a PRO badge, three benefits, and "Nâng cấp ngay".
struct ProUpgradeCard: View {
    let onUpgrade: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let benefits = ["300 lượt AI mỗi tháng", "Xuất báo cáo PDF, Excel", "Đồng bộ trên mọi thiết bị"]
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            // Lime is kept for the crown, the button and the edge (user note 2026-10-29: too green).
            HStack(spacing: Spacing.s) {
                TimiIcon("hugeicons-crown", size: 14)
                    .foregroundStyle(Palette.lime)
                Text("PRO")
                    .textRole(.captionStrong)
                    .tracking(1.2)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.white.opacity(0.12), in: Capsule())

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Timi Pro")
                    .textRole(.pageTitle)
                Text("Mở khoá mọi tính năng của Timi.")
                    .textRole(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(spacing: Spacing.s) {
                        TimiIcon("hugeicons-checkmark-circle-02", size: 16)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(benefit)
                            .textRole(.captionStrong)
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }
            }
            .accessibilityElement(children: .combine)

            Button(action: onUpgrade) {
                Text("Nâng cấp ngay")
                    .textRole(.captionStrong)
                    .foregroundColor(Palette.onLime)
                    .frame(maxWidth: .infinity, minHeight: 20)
            }
            .nativeGlassButton(tint: Palette.lime)
            .buttonBorderShape(.capsule)
            // Regular, not large: the large one outweighed the card (user note 2026-10-29).
            .controlSize(.regular)
            .tint(Palette.lime)
            .foregroundStyle(Palette.onLime)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Color.clear
                .cardSurface(color: Palette.proCard)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Palette.lime.opacity(0.16))
                        .frame(width: 180, height: 180)
                        .blur(radius: 50)
                        .offset(x: 50, y: -50)
                }
                .clipShape(shape)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .overlay { runningEdge }
    }

    /// A lime highlight going round the edge once every 6 seconds; still when Reduce Motion is on.
    private var runningEdge: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            let turn = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6) / 6
            shape.strokeBorder(
                AngularGradient(stops: [.init(color: Palette.lime.opacity(0.05), location: 0),
                                        .init(color: Palette.lime.opacity(0.05), location: 0.62),
                                        .init(color: Palette.lime, location: 0.82),
                                        .init(color: Palette.lime.opacity(0.05), location: 1)],
                                center: .center, angle: .degrees(reduceMotion ? 300 : turn * 360)),
                lineWidth: 1.5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
