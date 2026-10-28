import SwiftUI

/// Dark Timi Pro promotion with a lime glow and the "Nâng cấp ngay" button.
struct ProUpgradeCard: View {
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                SolarIcon("solar-crown-bold", size: 20)
                    .foregroundStyle(Palette.ink)
                    .frame(width: 40, height: 40)
                    .background(Palette.lime, in: RoundedRectangle(cornerRadius: CardCorners.icon, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nâng cấp Timi Pro")
                        .textRole(.title)
                        .foregroundStyle(.white)
                    Text("Nhận 300 lượt AI mỗi tháng, xuất báo cáo và đồng bộ trên mọi thiết bị.")
                        .textRole(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button(action: onUpgrade) {
                Text("Nâng cấp ngay")
                    .textRole(.captionStrong)
                    .foregroundColor(Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: 24)
            }
            .nativeGlassButton(tint: Palette.lime)
            .buttonBorderShape(.capsule)
            .controlSize(.regular)
            .tint(Palette.lime)
            .foregroundStyle(Palette.ink)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Color.clear
                .cardSurface(color: Palette.ink)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Palette.lime.opacity(0.25))
                        .frame(width: 144, height: 144)
                        .blur(radius: 40)
                        .offset(x: 40, y: -40)
                }
                .clipShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
