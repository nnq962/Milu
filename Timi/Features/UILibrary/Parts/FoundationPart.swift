import SwiftUI

struct FoundationPart: View {
    /// The tokens themselves; the hex under each is read from the colour, so it follows a combo
    /// tried in "Màu (thử)" (strict review 2026-10-31: written by hand, it went stale).
    private var colors: [(name: String, color: Color)] {
        [
            // Surfaces
            ("background", Palette.background), ("surface (thẻ)", Palette.surface),
            ("surfaceMuted (khối nhạt)", Palette.surfaceMuted), ("separator (kẻ mảnh)", Palette.separator),
            ("inputBackground", Palette.inputBackground),
            // Words
            ("label (chữ)", Palette.label), ("secondaryLabel", Palette.secondaryLabel),
            ("tertiaryLabel (chevron)", Palette.tertiaryLabel),
            // Actions
            ("primary", Palette.primary), ("onPrimary", Palette.onPrimary),
            ("rowPressed", Palette.rowPressed), ("primaryTint", Palette.primaryTint),
            ("primaryTrack", Palette.primaryTrack), ("primaryDash", Palette.primaryDash),
            ("fill1", Palette.fill1), ("fill2", Palette.fill2), ("fill3", Palette.fill3),
            // Meaning
            ("negative (tiền ra)", Palette.negative), ("onNegative", Palette.onNegative),
            ("positive (dấu hiệu tốt)", Palette.positive),
            ("warning", Palette.warning), ("warningLabel (chữ cam)", Palette.warningLabel),
            ("info (cho vay, người)", Palette.info),
            // Accent
            ("accent (Pro)", Palette.accent), ("onAccent", Palette.onAccent),
            // Data
            ("chart[0]", Palette.chart[0]), ("chart[1]", Palette.chart[1]),
            ("chart[2]", Palette.chart[2]), ("chart[3]", Palette.chart[3]), ("chartRest (Khác)", Palette.chartRest),
        ]
    }

    private let heights: [(name: String, value: CGFloat)] = [
        ("Nút lớn", ControlHeight.large), ("Nút thường", ControlHeight.regular),
        ("Nút nhỏ, chip", ControlHeight.small), ("Ô nhập", ControlHeight.field),
        ("Dòng", RowMetrics.minHeight), ("Icon đứng riêng", RowMetrics.featureIcon),
        ("Logo trong danh sách", RowMetrics.listLogo), ("Cột icon dòng", RowMetrics.iconColumn),
        ("Glyph icon dòng", RowMetrics.iconGlyph), ("Khoảng icon → chữ", RowMetrics.gap),
        ("Icon trong sheet chọn icon", RowMetrics.iconChoice),
        ("Glyph trên thanh", RowMetrics.toolbarGlyph), ("Khung glyph trên thanh", RowMetrics.toolbarGlyphFrame),
        ("Mũi tên › cuối dòng", RowMetrics.chevron), ("› ⌄ × sau chữ", RowMetrics.linkChevron),
        ("Glyph trước dòng chữ", RowMetrics.inlineGlyph), ("Chấm chú thích", RowMetrics.legendDot),
        ("Nét vòng tiến độ", RowMetrics.ringStroke), ("Vạch kẻ lùi (cột icon)", RowMetrics.dividerInset),
    ]

    private let radii: [(name: String, value: CGFloat)] = [
        ("large", CardCorners.large),
        ("inset", CardCorners.inset), ("flow", CardCorners.flow), ("field", CardCorners.field),
        ("icon", CardCorners.icon), ("calendarDay", CardCorners.calendarDay),
    ]

    var body: some View {
        PartSection(part: .foundation) {
            SampleCard(label: "Màu · Palette") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 3), spacing: Spacing.l) {
                    ForEach(colors, id: \.name) { item in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            RoundedRectangle(cornerRadius: CardCorners.icon, style: .continuous)
                                .fill(item.color)
                                .frame(height: 48)
                                .overlay {
                                    RoundedRectangle(cornerRadius: CardCorners.icon, style: .continuous)
                                        .strokeBorder(Palette.separator, lineWidth: 1)
                                }
                            Text(item.name).textRole(.captionStrong).lineLimit(1).minimumScaleFactor(0.8)
                            Text(Self.hex(item.color)).textRole(.footnote).foregroundStyle(Palette.secondaryLabel)
                                .monospacedDigit()
                        }
                    }
                }
            }

            SampleCard(label: "Chữ · Manrope · .textRole") {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    ForEach(TextRole.allCases) { role in
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(role.isNumeric ? "14.119.000đ" : role.name)
                                .textRole(role)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("\(role.name) · \(role.size.formatted())pt · \(weightName(role.weight))")
                                .textRole(.footnote)
                                .foregroundStyle(Palette.secondaryLabel)
                        }
                    }
                }
            }

            SampleCard(label: "Khoảng cách · Spacing") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(Spacing.scale, id: \.name) { step in
                        HStack(spacing: Spacing.m) {
                            Text(step.name).textRole(.captionStrong).frame(width: 40, alignment: .leading)
                            Capsule().fill(Palette.primary).frame(width: step.value * 4, height: 8)
                            Text("\(Int(step.value))").textRole(.footnote).foregroundStyle(Palette.secondaryLabel)
                        }
                    }
                    Text("Lề màn \(Int(Spacing.page)) · giữa các phần \(Int(Spacing.section)) · tiêu đề → thẻ \(Int(Spacing.headerGap)) · đệm thẻ \(Int(Spacing.card)) (thẻ đầu trang \(Int(Spacing.leadCard))) · dòng lùi \(Int(RowMetrics.horizontal))")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .padding(.top, Spacing.xs)
                }
            }

            SampleCard(label: "Bo góc · CardCorners (continuous)") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 4), spacing: Spacing.l) {
                    ForEach(radii, id: \.name) { item in
                        VStack(spacing: Spacing.xs) {
                            RoundedRectangle(cornerRadius: item.value, style: .continuous)
                                .fill(Palette.surfaceMuted)
                                .frame(height: 64)
                            Text(item.name).textRole(.captionStrong).lineLimit(1).minimumScaleFactor(0.7)
                            Text("\(Int(item.value))").textRole(.footnote).foregroundStyle(Palette.secondaryLabel)
                        }
                    }
                }
            }

            SampleCard(label: "Kích thước · ControlHeight & RowMetrics") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(heights, id: \.name) { item in
                        HStack {
                            Text(item.name).textRole(.body)
                            Spacer(minLength: Spacing.s)
                            Text("\(Int(item.value))").textRole(.body).monospacedDigit()
                                .foregroundStyle(Palette.secondaryLabel)
                        }
                    }
                    Text("Không thứ gì bấm được thấp hơn \(Int(ControlHeight.regular)), trừ chip trong nội dung.")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                }
            }

            SampleCard(label: "Bóng · softCardShadow") {
                HStack(spacing: Spacing.l) {
                    RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous)
                        .fill(Palette.surface)
                        .frame(height: 64)
                        .softCardShadow()
                    RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous)
                        .fill(Palette.surface)
                        .frame(height: 64)
                        .softCardShadow(false)
                }
                .padding(Spacing.s)
                .background(Palette.background, in: RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous))
            }
        }
    }

    /// "#3E5B3F", with "· 10%" when the colour is see-through.
    private static func hex(_ color: Color) -> String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let byte = { (value: CGFloat) in Int((min(max(value, 0), 1) * 255).rounded()) }
        let text = String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue))
        return alpha < 0.995 ? "\(text) · \(Int((alpha * 100).rounded()))%" : text
    }

    private func weightName(_ weight: Font.Weight) -> String {
        switch weight {
        case .heavy: "ExtraBold"
        case .bold: "Bold"
        case .semibold: "SemiBold"
        case .medium: "Medium"
        default: "Regular"
        }
    }
}
