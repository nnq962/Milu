import SwiftUI

/// Timi Pro promotion (redone 2026-10-30 from the user's Sleek theme): a white card with an amber
/// PRO badge, three benefits each with a plain teal tick, a teal "Tìm hiểu Timi Pro", and an amber
/// edge that runs round it once when the card appears (UI review 2026-10-30: a loop never let the
/// eye rest).
struct ProUpgradeCard: View {
    let onUpgrade: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lapStart = Date.now
    @State private var lapDone = false
    private let lap: TimeInterval = 2.4

    private let benefits = ["300 lượt AI mỗi tháng", "Xuất báo cáo PDF, Excel", "Đồng bộ trên mọi thiết bị"]
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            HStack(spacing: Spacing.xs) {
                TimiIcon("hugeicons-crown", size: 14)
                Text("PRO")
                    .textRole(.captionStrong)
                    .tracking(1.2)
            }
            .foregroundStyle(Palette.onLime)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Palette.lime, in: Capsule())

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Timi Pro")
                    .textRole(.pageTitle)
                    .foregroundStyle(Palette.ink)
                Text("Mở khoá mọi tính năng của Timi.")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: Spacing.m) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(spacing: Spacing.m) {
                        TimiIcon("hugeicons-tick-02", size: 18)
                            .foregroundStyle(Palette.primary)
                        Text(benefit)
                            .textRole(.captionStrong)
                            .foregroundStyle(Palette.ink)
                    }
                }
            }
            .accessibilityElement(children: .combine)

            Button(action: onUpgrade) {
                HStack(spacing: Spacing.s) {
                    TimiIcon("hugeicons-crown", size: 16)
                    Text("Tìm hiểu Timi Pro")
                        .textRole(.captionStrong)
                }
                .foregroundStyle(Palette.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Palette.primary, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.card)
        }
        .padding(Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: CardCorners.large, color: Palette.card, elevated: true)
        .overlay { if !lapDone { runningEdge } }
        .task {
            lapStart = .now
            try? await Task.sleep(for: .seconds(lap))
            lapDone = true
        }
    }

    /// An amber highlight going round the edge once; still when Reduce Motion is on.
    private var runningEdge: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            let turn = min(context.date.timeIntervalSince(lapStart) / lap, 1)
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
