import SwiftUI

/// Hairline starting after a 44pt icon: 16 padding + 44 + 12 gap.
/// Use as a top overlay so it adds no row height, like Sleek's absolute divider.
struct RowDivider: View {
    @Environment(\.formIconStyle) private var iconStyle

    var body: some View {
        Palette.border
            .frame(height: 1)
            .padding(.leading, iconStyle == .plain ? RowMetrics.dividerInset : RowMetrics.circleDividerInset)
    }
}

/// Data row: icon, title and subtitle, amount and an optional chevron. Same metrics and type as
/// form rows (RowMetrics): title 17 regular, amount 17 medium, subtitle 13.
struct ListRow: View {
    let icon: String
    let title: String
    /// Second line; leave it out for a one-line row (52pt, like a form row).
    var subtitle: String? = nil
    /// A short line under the amount (a date "28/10", a time "08:15"): the amount then lines up
    /// with the title, and this with the subtitle.
    var trailingSubtitle: String? = nil
    let amount: Double
    var iconBackground: Color = Palette.muted
    var amountTone: MoneyText.Tone = .negativeRed
    var showsChevron = true
    /// Money that does not count (a locked account): a lock badge on the icon's corner, like an
    /// app badge on iOS, and the amount grey (user choice 2026-10-28).
    var isLocked = false

    @Environment(\.formIconStyle) private var iconStyle

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            // Plain style (default) drops every tile, coloured ones too; amounts carry the meaning.
            Group {
                if iconStyle == .plain {
                    RowIcon(name: icon)
                } else {
                    IconCircle(icon: icon, background: iconBackground)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isLocked { LockBadge().offset(x: 5, y: 5) }
            }
            if let trailingSubtitle {
                VStack(spacing: RowMetrics.lineGap) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                        Text(title)
                            .textRole(.body)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        // Full size: the title gives way first.
                        MoneyText(amount: amount, tone: isLocked ? .muted : amountTone)
                            .fixedSize()
                    }
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                        Text(subtitle ?? "")
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(trailingSubtitle)
                            .monospacedDigit()
                    }
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                }
            } else {
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
                MoneyText(amount: amount, tone: isLocked ? .muted : amountTone)
            }
            if showsChevron {
                TimiIcon("hugeicons-arrow-right-01", size: 16)
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

/// A small white lock on a teal circle, ringed in white, pinned to the corner of a row's icon.
struct LockBadge: View {
    static let size: CGFloat = 15
    static let glyph: CGFloat = 9
    static let ring: CGFloat = 1.5

    var body: some View {
        TimiIcon("hugeicons-square-lock-02", size: Self.glyph)
            .foregroundStyle(Palette.onPrimary)
            .frame(width: Self.size, height: Self.size)
            .background(Palette.primary, in: Circle())
            .padding(Self.ring)
            .background(Palette.card, in: Circle())
            .accessibilityHidden(true)
    }
}
