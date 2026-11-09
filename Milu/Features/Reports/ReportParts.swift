import SwiftUI

/// Tuần / Tháng, and ‹ the period › to step back and forth; › stops at the one holding today.
struct ReportPeriodBar: View {
    @Binding var period: ReportPeriod

    @Environment(FinanceStore.self) private var store
    /// How far back ‹ goes, found once on showing: it walks every record (review 2026-11-09:
    /// it ran on every redraw, each ‹ › included).
    @State private var earliest: Date?

    @State private var isPicking = false
    /// The ⌄ the size of the one on Thu chi's month (`MonthTitleButton`), growing with the words.
    @ScaledMetric(relativeTo: .subheadline) private var chevron: CGFloat = IconSize.chevron

    var body: some View {
        VStack(spacing: Spacing.m) {
            // Words at the user's text size and the height of the segments on Thu chi (strict
            // review 2026-10-31: a bare segmented picker stayed small and short).
            ScaledSegmentedPicker(title: "Kỳ báo cáo", selection: unit, options: ReportPeriod.Unit.allCases) { $0.title }
                .controlSize(.large)

            HStack {
                step(-1, icon: "hugeicons-arrow-left-01", label: "\(period.unit.title) trước")
                    // No further back than the pickers go, the start of the oldest record's year:
                    // before it only empty periods (review 2026-11-08).
                    .disabled(earliest.map { period.start <= $0 } ?? false)
                Spacer(minLength: Spacing.s)
                // The name opens a picker, so a far month is one pick away, not many taps of ‹
                // (user request 2026-11-08): the month wheels as on Thu chi, or a calendar for a week.
                Button { isPicking = true } label: {
                    HStack(spacing: IconSize.glyphGap) {
                        Text(period.title)
                            .textRole(.title)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Image(systemName: "chevron.down")
                            .font(.system(size: chevron, weight: .semibold))
                            .foregroundStyle(Palette.primary)
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(Palette.label)
                    .contentShape(Rectangle().inset(by: -Spacing.m))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Chọn \(period.unit.title.lowercased()), \(period.title)")
                Spacer(minLength: Spacing.s)
                step(1, icon: "hugeicons-arrow-right-01", label: "\(period.unit.title) sau")
                    .disabled(period.isCurrent())
            }
        }
        .onAppear { if earliest == nil { earliest = MonthPickerSheet.earliest(in: store) } }
        // A tick from ‹ › and the segments themselves; the pickers' ✓ and "Tháng này" tick their
        // own, and a tick on every change of the period made those two (review 2026-11-08).
        .sheet(isPresented: $isPicking) {
            switch period.unit {
            case .month:
                MonthPickerSheet(month: Binding { period.start } set: { period = ReportPeriod(.month, containing: $0) })
            case .week:
                WeekPickerSheet(period: $period)
            }
        }
    }

    /// A past period keeps its place; the current one stays current. Anchored on the fourth day
    /// (a week's Thursday): a week belongs to the month holding its Thursday, and a month's first
    /// such week holds its fourth day, so Tháng 10 → Tuần → Tháng is Tháng 10 again (review
    /// 2026-11-08: anchored on the first day it came back as Tháng 9).
    private var unit: Binding<ReportPeriod.Unit> {
        Binding {
            period.unit
        } set: { unit in
            let anchor = ReportPeriod.calendar.date(byAdding: .day, value: 3, to: period.start) ?? period.start
            period = ReportPeriod(unit, containing: period.isCurrent() ? .now : anchor)
            Haptics.selection()
        }
    }

    private func step(_ count: Int, icon: String, label: String) -> some View {
        // A flat circle, as the report circle on Thu chi: these sit in the page's scroll, where
        // glass trailed it (user choice 2026-10-31: no glass inside content). It grows with the
        // text, as the period's name beside it does.
        Button {
            Haptics.selection()
            withAnimation(.snappy) { period = period.shifted(by: count) }
        } label: {
            MiluIcon(icon, size: glyph)
                .foregroundStyle(Palette.primary)
        }
        .flatCircleButton(diameter: diameter)
        .accessibilityLabel(label)
    }

    @ScaledMetric(relativeTo: .body) private var diameter = ControlHeight.regular
    @ScaledMetric(relativeTo: .body) private var glyph = RowMetrics.toolbarGlyph
}

/// Picks a week on the iOS calendar: any day picks the week holding it, Monday to Sunday, as
/// Báo cáo counts them. Like the month wheels (`MonthPickerSheet`): "Chọn tuần" with ✕ and ✓, the
/// calendar on a card, days ahead out of reach, and "Tuần này" back to the current one.
struct WeekPickerSheet: View {
    @Binding var period: ReportPeriod

    @Environment(\.dismiss) private var dismiss
    @Environment(FinanceStore.self) private var store
    /// The day picked; its week is written to `period` on ✓.
    @State private var draft: Date
    /// Back no further than the oldest record's year, found once (not on every redraw).
    @State private var earliest = Date.distantPast

    init(period: Binding<ReportPeriod>) {
        _period = period
        _draft = State(initialValue: period.wrappedValue.start)
    }

    var body: some View {
        let picked = ReportPeriod(.week, containing: draft)
        SheetScaffold(title: "Chọn tuần", onConfirm: {
            withAnimation(Motion.gentle(.smooth(duration: 0.3))) { period = picked }
            dismiss()
        }, fitsContent: true) {
            VStack(spacing: Spacing.s) {
                VStack(spacing: Spacing.s) {
                    DatePicker("Tuần", selection: $draft, in: earliest...Date.now,
                               displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .environment(\.locale, .vietnam)
                        .environment(\.calendar, ReportPeriod.calendar)
                        .tint(Palette.primary)
                    // Which week the day stands for.
                    Text("Tuần \(picked.title)")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .monospacedDigit()
                }
                .padding(Spacing.m)
                .cardSurface(radius: CardCorners.card)
                if !period.isCurrent() {
                    Button {
                        Haptics.selection()
                        withAnimation(Motion.gentle(.smooth(duration: 0.3))) { period = ReportPeriod(.week) }
                        dismiss()
                    } label: {
                        Text("Tuần này")
                            .padding(.horizontal, Spacing.l)
                            .frame(minHeight: ControlHeight.regular)
                            .contentShape(Rectangle())
                    }
                    .textRole(.bodyStrong)
                    .tint(Palette.primary)
                }
            }
            .onAppear { earliest = MonthPickerSheet.earliest(in: store) }
        }
    }
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
                    // "Bằng", not "Như": "Như cùng kỳ" read oddly (review 2026-11-08).
                    Text("Bằng \(short)")
                        .foregroundStyle(Palette.secondaryLabel)
                        .accessibilityLabel("Bằng \(name)")
                } else {
                    Text(period.isCurrent() ? "\(text) · cùng kỳ" : "\(text) so với \(name)")
                        .foregroundStyle((ratio > 0) == risingIsBad ? Palette.negative : Palette.positive)
                        // In words, "tăng 12%": VoiceOver may read the arrow as a symbol.
                        .accessibilityLabel("\(Change.spoken(text)) so với \(name)")
                }
            } else {
                // Named as what is compared ("cùng kỳ tháng trước" while this one runs), and in
                // full words (review 2026-11-08: "Chưa có số tháng trước" was clipped, and wrong
                // when last month had spending only after these days).
                Text("Chưa có số liệu \(name)")
                    .foregroundStyle(Palette.secondaryLabel)
            }
        }
        .textRole(.caption)
        .monospacedDigit()
    }
}

/// A part of a report page: its heading on the page over the card, at the card's edge, as every
/// main page (`OutsideHeaderSection`, user report 2026-11-08: Báo cáo alone had it inside), the
/// rows in a list card, and a line under the card for a computed figure only. Forms keep
/// `FormGroup` and its small grey heading (strict review 2026-10-31).
struct ReportSection<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.headerGap) {
            OutsideHeaderSection(title: title) {
                VStack(spacing: 0) { content }
                    .listCard()
            }
            if let footer {
                FormFooter(message: footer)
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
    var tone: MoneyText.Tone = .neutral
    var dot: Color? = nil
    /// A ring instead of a filled dot: the empty part of a chart.
    var hollowDot = false
    /// A faint dot ("Khác") drawn with a thin edge so it does not vanish.
    var edgedDot = false
    var opensMore = true
    var isAccount = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            RowIcon(name: icon, size: isAccount ? RowMetrics.listLogo : RowMetrics.iconColumn, tiled: isAccount)
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
                        .accessibilityLabel(Change.spoken(detail))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Full size: the name gives way first.
            MoneyText(amount: amount, tone: tone)
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
