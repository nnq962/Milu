import SwiftUI

struct ButtonsPart: View {
    @State private var flatChoice = 0

    var body: some View {
        PartSection(part: .buttons) {
            SampleCard(label: "Vai trò · TimiButton (phẳng)") {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    ForEach(TimiButtonRole.allCases) { role in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            TimiButton(role.name, role: role, fullWidth: true) {}
                            Text(role.usage).textRole(.footnote).foregroundStyle(Palette.secondaryLabel)
                        }
                    }
                }
            }

            SampleCard(label: "Gọn trong thẻ · vùng chạm 44") {
                TimiButton("Nâng cấp", role: .primary, size: .compact) {}
            }

            SampleCard(label: "Có icon · tắt") {
                VStack(spacing: Spacing.m) {
                    TimiButton("Thêm giao dịch", icon: "hugeicons-add-01", role: .primary, fullWidth: true) {}
                    TimiButton("Chưa bấm được", role: .primary, fullWidth: true) {}
                        .disabled(true)
                }
            }

            // Every button inside content is flat (user choice 2026-10-31): a `fill` circle or capsule,
            // the chosen one in the primary colour with onPrimary words (re-review 2026-10-31: the
            // catalogue still showed glass in its cards).
            SampleCard(label: "Phẳng · flatCircleButton, flatCapsuleButton") {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    HStack(spacing: Spacing.s) {
                        Button {} label: {
                            TimiIcon("hugeicons-arrow-left-01", size: RowMetrics.chevron)
                        }
                        .flatCircleButton()
                        .accessibilityLabel("Kỳ trước")
                        Button {} label: {
                            TimiIcon("hugeicons-arrow-right-01", size: RowMetrics.chevron)
                        }
                        .flatCircleButton()
                        .accessibilityLabel("Kỳ sau")
                        Spacer(minLength: Spacing.s)
                        Button { flatChoice = flatChoice == 0 ? 1 : 0 } label: {
                            Text("Thường")
                                .textRole(.body)
                                .foregroundStyle(flatChoice == 0 ? Palette.onPrimary : Palette.label)
                                .padding(.horizontal, Spacing.l)
                                .frame(minHeight: ControlHeight.regular)
                        }
                        .flatCapsuleButton(fill: flatChoice == 0 ? Palette.primary : Palette.fill)
                        .accessibilityAddTraits(flatChoice == 0 ? .isSelected : [])
                    }
                    Text("FlatButtonStyle(fill:shape:) · nền fill, đang chọn nền primary")
                        .textRole(.footnote)
                        .foregroundStyle(Palette.secondaryLabel)
                }
                .tint(Palette.label)
            }

            // In a ToolbarItem a plain Button sits on the bar's glass by itself (rule 2026-10-30);
            // here, off the bar, the same buttons show bare. The + is a bare add-01 in its 28 frame.
            SampleCard(label: "Nút trên thanh · Button trơn") {
                HStack(spacing: Spacing.l) {
                    Button {} label: {
                        TimiIcon("hugeicons-add-01", size: RowMetrics.toolbarGlyph)
                            .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
                    }
                    .tint(Palette.primary)
                    .accessibilityLabel("Thêm")
                    Button {} label: {
                        TimiIcon("hugeicons-search-01", size: RowMetrics.toolbarGlyph)
                            .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
                    }
                    .accessibilityLabel("Tìm")
                    EditToolbarButton {}
                }
                .tint(Palette.label)
            }

            // The one glass button outside a bar: the floating + (explicit exception).
            SampleCard(label: "Nút + nổi · nativeFloatingButton (kính)") {
                Button {} label: {
                    TimiIcon("hugeicons-add-01", size: RowMetrics.toolbarGlyph).foregroundStyle(Palette.onPrimary)
                }
                .nativeFloatingButton(diameter: ControlHeight.large, tint: Palette.primary)
                .accessibilityLabel("Thêm giao dịch")
            }

            SampleCard(label: "Cạnh tiêu đề · HeaderLink") {
                HStack(spacing: Spacing.xl) {
                    Button {} label: { HeaderLink(title: "Xoá") }
                        .headerLinkButton()
                    Button {} label: { HeaderLink(title: "Lưu trữ (2)", opensPage: true) }
                        .headerLinkButton()
                }
            }
        }
    }
}
