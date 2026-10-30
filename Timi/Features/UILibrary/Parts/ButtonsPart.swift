import SwiftUI

struct ButtonsPart: View {
    @State private var isPressedSample = false

    var body: some View {
        PartSection(part: .buttons) {
            SampleCard(label: "Vai trò · TimiButton") {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    ForEach(TimiButtonRole.allCases) { role in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            TimiButton(role.name, role: role, fullWidth: true) {}
                            Text(role.usage).textRole(.footnote).foregroundStyle(Palette.secondaryText)
                        }
                    }
                }
            }

            SampleCard(label: "Cỡ · 36 / 44 / 56") {
                HStack(spacing: Spacing.s) {
                    TimiButton("Nhỏ", role: .primary, size: .small) {}
                    TimiButton("Thường", role: .primary) {}
                    TimiButton("Lớn", role: .primary, size: .large) {}
                }
            }

            SampleCard(label: "Có icon · tắt") {
                VStack(spacing: Spacing.m) {
                    TimiButton("Thêm giao dịch", icon: "hugeicons-add-01", role: .primary, fullWidth: true) {}
                    TimiButton("Chưa bấm được", role: .primary, fullWidth: true) {}
                        .disabled(true)
                }
            }

            SampleCard(label: "Nút tròn trên thanh · nút nổi") {
                HStack(spacing: Spacing.l) {
                    Button {} label: {
                        TimiIcon("hugeicons-notification-01", size: 20).frame(width: 28, height: 28)
                    }
                    .tint(Palette.ink)
                    .nativeCircleButton(diameter: 44)
                    Button {} label: {
                        TimiIcon("hugeicons-search-01", size: 20).frame(width: 28, height: 28)
                    }
                    .tint(Palette.ink)
                    .nativeCircleButton(diameter: 44)
                    Spacer()
                    Button {} label: {
                        TimiIcon("hugeicons-add-01", size: 26).foregroundStyle(Palette.onPrimary)
                    }
                    .nativeFloatingButton(diameter: ControlHeight.floating, tint: Palette.primary)
                }
            }
        }
    }
}
