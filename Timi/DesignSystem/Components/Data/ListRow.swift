import SwiftUI

/// Hairline starting under the titles of rows: margin + icon column + gap, the column growing with
/// the text as the rows' icons do (strict review 2026-10-31: a fixed 54 started before the titles
/// at large text). `.logo` for rows with a 32 logo, avatar or ring (`AccountRow`, `LoanRow`,
/// `GoalRow`, contacts), `.none` for rows with no icon. Use as a top overlay so it adds no height.
struct RowDivider: View {
    enum Column { case icon, logo, none }
    var column: Column = .icon

    @ScaledMetric(relativeTo: .body) private var iconColumn = RowMetrics.iconColumn
    @ScaledMetric(relativeTo: .body) private var logoColumn = RowMetrics.listLogo

    var body: some View {
        let inset: CGFloat = switch column {
        case .icon: RowMetrics.horizontal + iconColumn + RowMetrics.gap
        case .logo: RowMetrics.horizontal + logoColumn + RowMetrics.gap
        case .none: RowMetrics.horizontal
        }
        Palette.border
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

/// Data row: icon, title and subtitle, amount and an optional chevron. Same metrics and type as
/// form rows (RowMetrics): title 16 SemiBold, amount 16 Bold, subtitle 13.
struct ListRow: View {
    let icon: String
    let title: String
    /// Second line; leave it out for a one-line row (52pt, like a form row).
    var subtitle: String? = nil
    /// A short line under the amount (a date "28/10", a time "08:15"): the amount then lines up
    /// with the title, and this with the subtitle.
    var trailingSubtitle: String? = nil
    let amount: Double
    var amountTone: MoneyText.Tone = .negativeRed
    var showsChevron = true
    /// Money that does not count (a locked account): a lock badge on the icon's corner, like an
    /// app badge on iOS, and the amount grey (user choice 2026-10-28).
    var isLocked = false
    /// "10,3tr" instead of "10.300.000đ": every list of accounts and goals (Tài khoản, Lưu trữ,
    /// Tài sản ròng) shows the short form, so one account reads the same everywhere.
    var compactAmount = false

    /// The icon grows with the text beside it (HIG review 2026-10-30: 24 by large text looked lost).
    @ScaledMetric(relativeTo: .body) private var iconSize = RowMetrics.iconColumn
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Titles take a second line at the accessibility text sizes, where one cut "Cho vay" to "Ch…".
    private var titleLines: Int { dynamicTypeSize.isAccessibilitySize ? 2 : 1 }

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            // No tile, coloured ones neither; amounts carry the meaning.
            RowIcon(name: icon, size: iconSize)
                .overlay(alignment: .bottomTrailing) {
                    if isLocked { LockBadge().offset(x: 5, y: 5) }
                }
            if let trailingSubtitle {
                VStack(spacing: RowMetrics.lineGap) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                        Text(title)
                            .textRole(.body)
                            .lineLimit(titleLines)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        // Full size: the title gives way first.
                        MoneyText(amount: amount, tone: isLocked ? .muted : amountTone, compact: compactAmount)
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
                        .lineLimit(titleLines)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                MoneyText(amount: amount, tone: isLocked ? .muted : amountTone, compact: compactAmount)
                    .fixedSize()
            }
            if showsChevron { RowChevron() }
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A small white lock on a circle in the primary colour, ringed in white, pinned to the corner of a row's icon.
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

/// The › at the end of a row that opens something: one size and colour on every list, form and
/// card (strict review 2026-10-31: 12, 14 and 16 were in use side by side).
struct RowChevron: View {
    var body: some View {
        TimiIcon("hugeicons-arrow-right-01", size: RowMetrics.chevron)
            .foregroundStyle(Palette.secondary)
            .accessibilityHidden(true)
    }
}

/// A small coloured dot naming a slice of a chart or a split bar.
struct LegendDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: RowMetrics.legendDot, height: RowMetrics.legendDot)
            .accessibilityHidden(true)
    }
}

/// A thin vertical line between two halves of a card (Đã chi | Đã thu).
struct VerticalDivider: View {
    var body: some View {
        Palette.border.frame(width: 1)
    }
}
