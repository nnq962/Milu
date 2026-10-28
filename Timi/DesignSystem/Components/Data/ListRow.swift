import SwiftUI

/// Hairline starting after a 44pt icon: 16 padding + 44 + 12 gap.
/// Use as a top overlay so it adds no row height, like Sleek's absolute divider.
struct RowDivider: View {
    @Environment(\.formIconStyle) private var iconStyle

    var body: some View {
        Palette.border
            .frame(height: 1)
            .padding(.leading, iconStyle == .plain ? RowMetrics.dividerInset : 72)
    }
}

/// Data row: icon, title and subtitle, amount and an optional chevron. Same metrics and type as
/// form rows (RowMetrics): title 17 regular, amount 17 medium, subtitle 13.
struct ListRow: View {
    let icon: String
    let title: String
    /// Second line; leave it out for a one-line row (52pt, like a form row).
    var subtitle: String? = nil
    let amount: Double
    var iconBackground: Color = Palette.muted
    var amountTone: MoneyText.Tone = .negativeRed
    var showsChevron = true

    @Environment(\.formIconStyle) private var iconStyle

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            // Plain style (default) drops every tile, coloured ones too; amounts carry the meaning.
            if iconStyle == .plain {
                RowIcon(name: icon)
            } else {
                IconCircle(icon: icon, background: iconBackground)
            }
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(title)
                    .textRole(.body)
                    .lineLimit(1)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }
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
