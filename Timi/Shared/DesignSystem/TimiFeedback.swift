import SwiftUI

/// Meaning of a badge; colour is used sparingly, red only for real warnings.
enum BadgeTone: CaseIterable, Identifiable {
    case neutral, positive, accent, info, warning

    var id: Self { self }

    var name: String {
        switch self {
        case .neutral: "Trung tính"
        case .positive: "Đã thu"
        case .accent: "Pro"
        case .info: "Thông tin"
        case .warning: "Sắp đến hạn"
        }
    }

    fileprivate var background: Color {
        switch self {
        case .neutral: Palette.fill2
        case .positive: Palette.green.opacity(0.12)
        case .accent: Palette.lime
        case .info: Palette.secondarySurface
        case .warning: Palette.red.opacity(0.10)
        }
    }

    fileprivate var foreground: Color {
        self == .warning ? Palette.red : Palette.ink
    }

    fileprivate var dot: Color {
        switch self {
        case .neutral, .info: Palette.secondary
        case .positive: Palette.green
        case .accent: Palette.ink
        case .warning: Palette.red
        }
    }
}

/// Pill 24 tall with a dot: status, counts, labels.
struct StatusBadge: View {
    let text: String
    var tone: BadgeTone = .neutral
    var showsDot = true

    var body: some View {
        HStack(spacing: 6) {
            if showsDot {
                Circle().fill(tone.dot).frame(width: 6, height: 6)
            }
            Text(text).textRole(.captionStrong).lineLimit(1)
        }
        .fixedSize()
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(tone.background, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// Every amount on screen: tabular digits, "đ" attached, sign and colour by meaning.
struct MoneyText: View {
    enum Size { case row, large, display }
    enum Tone { case plain, signedIncome, signedExpense, negativeRed }

    let amount: Double
    var size: Size = .row
    var tone: Tone = .plain
    var compact = false

    private var text: String {
        let value = compact ? abs(amount).vndCompact : abs(amount).vnd
        switch tone {
        case .signedIncome: return "+" + value
        case .signedExpense: return "-" + value
        case .plain, .negativeRed: return (amount < 0 ? "-" : "") + value
        }
    }

    private var color: Color {
        switch tone {
        case .signedExpense: Palette.red
        case .negativeRed: amount < 0 ? Palette.red : Palette.ink
        case .plain, .signedIncome: Palette.ink
        }
    }

    var body: some View {
        Text(text)
            .modifier(MoneyFont(size: size))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(size == .row ? 0.8 : 0.5)
    }
}

private struct MoneyFont: ViewModifier {
    let size: MoneyText.Size

    func body(content: Content) -> some View {
        switch size {
        case .row: content.textRole(.amount)
        case .large: content.textRole(.amountLarge).frame(minHeight: 32)
        case .display: content.textRole(.display).frame(minHeight: 42.5)
        }
    }
}

/// Data row: icon, title and subtitle, amount and an optional chevron. Same metrics and type as
/// form rows (RowMetrics): title 17 regular, amount 17 medium, subtitle 13.
struct ListRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let amount: Double
    var iconBackground: Color = Palette.muted
    var amountTone: MoneyText.Tone = .negativeRed
    var showsChevron = true

    @Environment(\.formIconStyle) private var iconStyle

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            // Plain style (default) drops every tile, coloured ones too; amounts carry the meaning.
            if iconStyle == .plain {
                SolarIcon(icon, size: RowMetrics.iconGlyph)
                    .foregroundStyle(Palette.ink)
                    .frame(width: RowMetrics.iconColumn)
            } else {
                IconCircle(icon: icon, background: iconBackground)
            }
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(title)
                    .textRole(.body)
                    .lineLimit(1)
                Text(subtitle)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            MoneyText(amount: amount, tone: amountTone)
            if showsChevron {
                SolarIcon("solar-alt-arrow-right-linear", size: 16)
                    .foregroundStyle(Palette.secondary)
            }
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
