import SwiftUI

/// Tuần / Tháng, and ‹ the period › to step back and forth; › stops at the one holding today.
struct ReportPeriodBar: View {
    @Binding var period: ReportPeriod

    var body: some View {
        VStack(spacing: Spacing.m) {
            // Words at the user's text size and the height of the segments on Thu chi (strict
            // review 2026-10-31: a bare segmented picker stayed small and short).
            ScaledSegmentedPicker(title: "Kỳ báo cáo", selection: unit, options: ReportPeriod.Unit.allCases) { $0.title }
                .controlSize(.large)

            HStack {
                step(-1, icon: "hugeicons-arrow-left-01", label: "\(period.unit.title) trước")
                Spacer(minLength: Spacing.s)
                Text(period.title)
                    .textRole(.title)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Spacer(minLength: Spacing.s)
                step(1, icon: "hugeicons-arrow-right-01", label: "\(period.unit.title) sau")
                    .disabled(period.isCurrent())
            }
        }
        .sensoryFeedback(.selection, trigger: period)
    }

    /// A past period keeps its place (October → 2026); the current one stays current.
    private var unit: Binding<ReportPeriod.Unit> {
        Binding {
            period.unit
        } set: { unit in
            period = ReportPeriod(unit, containing: period.isCurrent() ? .now : period.start)
        }
    }

    private func step(_ count: Int, icon: String, label: String) -> some View {
        // A flat circle, as the report circle on Thu chi: these sit in the page's scroll, where
        // glass trailed it (user choice 2026-10-31: no glass inside content). It grows with the
        // text, as the period's name beside it does.
        Button {
            withAnimation(.snappy) { period = period.shifted(by: count) }
        } label: {
            TimiIcon(icon, size: glyph)
                .foregroundStyle(Palette.primary)
        }
        .flatCircleButton(diameter: diameter)
        .accessibilityLabel(label)
    }

    @ScaledMetric(relativeTo: .body) private var diameter = ControlHeight.regular
    @ScaledMetric(relativeTo: .body) private var glyph = RowMetrics.toolbarGlyph
}

/// "↑ 12% so với cùng kỳ tháng trước": red when it got worse (more spending, less income), green
/// when better. Compares with the same days of the period before (`ReportPeriod.comparison`).
struct ChangeLabel: View {
    let now: Double
    let before: Double
    let period: ReportPeriod
    /// Spending: up is bad. Income: up is good.
    var risingIsBad = true

    var body: some View {
        let name = period.comparisonName()
        // On one line while the period runs: "↑ 80% · cùng kỳ"; VoiceOver reads it in full
        // (user choice 2026-10-30, the long form wrapped).
        let short = period.isCurrent() ? "cùng kỳ" : period.previousName
        Group {
            if let ratio = Change.ratio(now, from: before), let text = Change.text(now, from: before) {
                if abs(ratio) < 0.005 {
                    Text("Như \(short)")
                        .foregroundStyle(Palette.secondaryLabel)
                        .accessibilityLabel("Như \(name)")
                } else {
                    Text(period.isCurrent() ? "\(text) · cùng kỳ" : "\(text) so với \(name)")
                        .foregroundStyle((ratio > 0) == risingIsBad ? Palette.negative : Palette.positive)
                        .accessibilityLabel("\(text) so với \(name)")
                }
            } else {
                Text("Chưa có số \(period.previousName)")
                    .foregroundStyle(Palette.secondaryLabel)
            }
        }
        .textRole(.caption)
        .monospacedDigit()
    }
}

/// A part of a report page: its heading (`.section`, as on every main page), the rows in a list
/// card under it, and a line under the card for a computed figure only. Forms keep `FormGroup`
/// and its small grey heading (strict review 2026-10-31: Báo cáo used the form's).
struct ReportSection<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: title)
            VStack(spacing: 0) { content }
                .listCard()
            if let footer {
                FormFooter(text: footer)
            }
        }
    }
}

/// A row of a breakdown: icon, name and a note under it, the amount, and › when it opens more.
/// The amount is a `MoneyText` like every list's (strict review 2026-10-31: it was a plain string
/// in ink, money out included); a row with no › keeps an empty one's width, so its amount lines
/// up with the rows that open. A chart's colour dot leads the note, so the name and the note start
/// at one edge, where the hairline starts too (user report 2026-10-31: the dot pushed the name in).
/// `isAccount` draws the icon as an account is drawn everywhere (`AccountRow`: a tile in the
/// 32 logo column); its rows take `RowDivider(column: .logo)`.
struct BreakdownRowLabel: View {
    let icon: String
    let title: String
    let detail: String
    let amount: Double
    var tone: MoneyText.Tone = .plain
    var compact = true
    var dot: Color? = nil
    /// A ring instead of a filled dot: the empty part of a chart.
    var hollowDot = false
    /// A faint dot ("Khác") drawn with a thin edge so it does not vanish.
    var edgedDot = false
    var opensMore = true
    var isAccount = false

    /// The icon grows with the text beside it, as in `ListRow` and `AccountRow`.
    @ScaledMetric(relativeTo: .body) private var iconSize = RowMetrics.iconColumn
    @ScaledMetric(relativeTo: .body) private var logoSize = RowMetrics.listLogo
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            RowIcon(name: icon, size: isAccount ? logoSize : iconSize, tiled: isAccount)
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                // A second line at the accessibility sizes, where one cut the name short.
                Text(title)
                    .textRole(.body)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                HStack(spacing: Spacing.xs) {
                    if hollowDot {
                        Circle().strokeBorder(Palette.tertiaryLabel, lineWidth: 1.5)
                            .frame(width: RowMetrics.legendDot, height: RowMetrics.legendDot)
                    } else if let dot {
                        LegendDot(color: dot)
                            .overlay { if edgedDot { Circle().strokeBorder(Palette.tertiaryLabel, lineWidth: 1) } }
                    }
                    Text(detail)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Full size: the name gives way first.
            MoneyText(amount: amount, tone: tone, compact: compact)
                .fixedSize()
            RowChevron()
                .opacity(opensMore ? 1 : 0)
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
