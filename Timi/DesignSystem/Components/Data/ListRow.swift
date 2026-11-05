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
        // The columns capped as the icons in them are (`RowMetrics.capped`).
        let inset: CGFloat = switch column {
        case .icon: RowMetrics.horizontal + RowMetrics.capped(iconColumn, base: RowMetrics.iconColumn) + RowMetrics.gap
        case .logo: RowMetrics.horizontal + RowMetrics.capped(logoColumn, base: RowMetrics.listLogo) + RowMetrics.gap
        case .none: RowMetrics.horizontal
        }
        Palette.separator
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

/// The app's one list row (review 2026-10-31: accounts, loans and goals each drew their own):
/// `leading` in the icon column (a glyph, a logo tile, an avatar, a ring), the title with an
/// optional line under it, `trailing` at the right (the amount, with a date or a state under
/// it: `ListRowAmount`, `ListRowTrailing`), and › when it opens something. The right side goes
/// under the words at the accessibility text sizes, where one line cut both short. Same metrics
/// as form rows (`RowMetrics`): 16 at the sides, at least 52 tall.
struct ListRow<Leading: View, Trailing: View>: View {
    let title: String
    /// Second line; leave it out for a one-line row (52pt, like a form row).
    var subtitle: String? = nil
    /// Grey, or red for a deadline passed.
    var subtitleColor: Color = Palette.secondaryLabel
    var showsChevron = true
    let leading: Leading
    let trailing: Trailing

    init(title: String, subtitle: String? = nil, subtitleColor: Color = Palette.secondaryLabel,
         showsChevron: Bool = true, @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleColor = subtitleColor
        self.showsChevron = showsChevron
        self.leading = leading()
        self.trailing = trailing()
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isAccessibilitySize = dynamicTypeSize.isAccessibilitySize
        HStack(spacing: RowMetrics.gap) {
            leading
            // Title and amount on one baseline; stacked, the words take the row's width so every
            // row starts at the same edge.
            AdaptiveStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    // Whole at the accessibility sizes, where one line cut "Cho vay" to "Ch…".
                    Text(title)
                        .textRole(.body)
                        .lineLimit(isAccessibilitySize ? nil : 1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .textRole(.caption)
                            .foregroundStyle(subtitleColor)
                            .lineLimit(isAccessibilitySize ? nil : 1)
                    }
                }
                if !isAccessibilitySize { Spacer(minLength: 0) }
                trailing
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if showsChevron { RowChevron() }
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

extension ListRow where Leading == RowIcon, Trailing == ListRowAmount {
    /// A row with a glyph and one amount (transactions, the parts of net worth): `trailingSubtitle`
    /// is the short line under the amount (a date "28/10", a time "08:15").
    init(icon: String, title: String, subtitle: String? = nil, trailingSubtitle: String? = nil,
         amount: Double, amountTone: MoneyText.Tone = .balance, showsChevron: Bool = true) {
        self.init(title: title, subtitle: subtitle, showsChevron: showsChevron) {
            // No tile, coloured ones neither; amounts carry the meaning. Line glyphs, not 3D
            // pictures (tried and taken back, user request 2026-11-03).
            RowIcon(name: icon)
        } trailing: {
            ListRowAmount(amount: amount, tone: amountTone, note: trailingSubtitle)
        }
    }
}

/// The right side of a `ListRow`: a figure, and under it a short grey line (a date, "Còn 6
/// ngày", "25%") in `noteColor`. Right-aligned beside the words, left-aligned under them at the
/// accessibility sizes. The figure keeps its room first (`layoutPriority`), so the title gives
/// way before it; it may still shrink a little, as `MoneyText` allows (review 2026-10-31:
/// `fixedSize` let long figures push the title out).
struct ListRowTrailing<Figure: View>: View {
    var note: String? = nil
    var noteColor: Color = Palette.secondaryLabel
    @ViewBuilder let figure: Figure

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isAccessibilitySize = dynamicTypeSize.isAccessibilitySize
        VStack(alignment: isAccessibilitySize ? .leading : .trailing, spacing: RowMetrics.lineGap) {
            figure
                .layoutPriority(1)
            if let note {
                Text(note)
                    .textRole(.caption)
                    .foregroundStyle(noteColor)
                    .monospacedDigit()
                    .lineLimit(isAccessibilitySize ? nil : 1)
            }
        }
    }
}

/// `ListRowTrailing` with one amount as the figure.
struct ListRowAmount: View {
    let amount: Double
    var tone: MoneyText.Tone = .balance
    var note: String? = nil
    var noteColor: Color = Palette.secondaryLabel

    var body: some View {
        ListRowTrailing(note: note, noteColor: noteColor) {
            MoneyText(amount: amount, tone: tone)
        }
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
            .background(Palette.surface, in: Circle())
            .accessibilityHidden(true)
    }
}

/// The › at the end of a row that opens something: one size and colour on every list, form and
/// card (strict review 2026-10-31: 12, 14 and 16 were in use side by side).
struct RowChevron: View {
    /// Grows with the row's words, no further than 1.6 times (HIG review 2026-11-05: at AX5 a 16
    /// chevron stood tiny beside the names).
    @ScaledMetric(relativeTo: .body) private var size = RowMetrics.chevron

    var body: some View {
        TimiIcon("hugeicons-arrow-right-01", size: RowMetrics.capped(size, base: RowMetrics.chevron))
            .foregroundStyle(Palette.tertiaryLabel)
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

/// A thin vertical line between the columns of `SplitTotals` (Đã chi | Đã thu).
struct VerticalDivider: View {
    var body: some View {
        Palette.separator.frame(width: 1)
    }
}

/// The hairline between the parts of a padded card (the totals | the limit), edge to edge of the
/// card's padding: `RowDivider` starts after a row's icon, which these parts have none of. Use as
/// a top overlay so it adds no height.
struct SplitLine: View {
    var body: some View {
        Palette.separator.frame(height: 1)
    }
}
