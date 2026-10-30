import SwiftUI

struct FoundationPart: View {
    private let colors: [(name: String, hex: String, color: Color)] = [
        ("background", "#FAF7F2", Palette.background),
        ("card", "#FFFFFF", Palette.card),
        ("ink", "#1F2A22", Palette.ink),
        ("primary", "#3E5B3F", Palette.primary),
        ("green (tiền vào)", "#1E5A48", Palette.green),
        ("red (tiền ra)", "#B5543F", Palette.red),
        ("lime (vàng)", "#E0A840", Palette.lime),
        ("sky", "#5FB89A", Palette.sky),
        ("warning", "#E8890C", Palette.warning),
        ("chartCoral", "#E8917A", Palette.chartCoral),
        ("chartRest", "#A9B9A0", Palette.chartRest),
        ("secondaryText", "#6F675B", Palette.secondaryText),
        ("muted", "#F1EEE6", Palette.muted),
        ("border", "#ECE7DC", Palette.border),
        ("input", "#F4F1EA", Palette.input),
        ("incomeTile", "green 12%", Palette.incomeTile),
        ("rowPressed", "primary 10%", Palette.rowPressed),
        ("fill1", "mực 4%", Palette.fill1),
        ("fill2", "mực 6%", Palette.fill2),
        ("fill3", "mực 10%", Palette.fill3),
    ]

    private let radii: [(name: String, value: CGFloat)] = [
        ("sheet", CardCorners.sheet), ("large", CardCorners.large),
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
                                        .strokeBorder(Palette.border, lineWidth: 1)
                                }
                            Text(item.name).textRole(.captionStrong).lineLimit(1).minimumScaleFactor(0.8)
                            Text(item.hex).textRole(.footnote).foregroundStyle(Palette.secondaryText)
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
                                .foregroundStyle(Palette.secondaryText)
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
                            Text("\(Int(step.value))").textRole(.footnote).foregroundStyle(Palette.secondaryText)
                        }
                    }
                    Text("Lề màn \(Int(Spacing.page)) · giữa các phần \(Int(Spacing.section)) · đệm thẻ \(Int(Spacing.card))")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .padding(.top, Spacing.xs)
                }
            }

            SampleCard(label: "Bo góc · CardCorners (continuous)") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 4), spacing: Spacing.l) {
                    ForEach(radii, id: \.name) { item in
                        VStack(spacing: Spacing.xs) {
                            RoundedRectangle(cornerRadius: item.value, style: .continuous)
                                .fill(Palette.muted)
                                .frame(height: 64)
                            Text(item.name).textRole(.captionStrong).lineLimit(1).minimumScaleFactor(0.7)
                            Text("\(Int(item.value))").textRole(.footnote).foregroundStyle(Palette.secondaryText)
                        }
                    }
                }
            }

            SampleCard(label: "Chiều cao điều khiển") {
                Text("Nút lớn 56 · thường 44 · nhỏ 36 · ô nhập 44 · dòng 52 · nút nổi 56. Không thứ gì bấm được thấp hơn 44, trừ chip trong nội dung.")
                    .textRole(.body)
            }
        }
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
