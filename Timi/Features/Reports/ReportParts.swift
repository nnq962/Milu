import SwiftUI

/// Tuần / Tháng, and ‹ the period › to step back and forth; › stops at the one holding today.
struct ReportPeriodBar: View {
    @Binding var period: ReportPeriod

    var body: some View {
        VStack(spacing: Spacing.m) {
            Picker("Kỳ báo cáo", selection: Binding(get: { period.unit }, set: { unit in
                // A past period keeps its place (October → 2026); the current one stays current.
                period = ReportPeriod(unit, containing: period.isCurrent() ? .now : period.start)
            })) {
                ForEach(ReportPeriod.Unit.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

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

    private func step(_ count: Int, icon: String, label: String) -> some View {
        // The same Liquid Glass circle as search beside the month on Giao dịch (user request 2026-10-30).
        Button {
            withAnimation(.snappy) { period = period.shifted(by: count) }
        } label: {
            TimiIcon(icon, size: 18)
                .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
        }
        .nativeCircleButton(diameter: ControlHeight.regular)
        .tint(Palette.ink)
        .accessibilityLabel(label)
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
                    Text("Như \(short)")
                        .foregroundStyle(Palette.secondaryText)
                        .accessibilityLabel("Như \(name)")
                } else {
                    Text(period.isCurrent() ? "\(text) · cùng kỳ" : "\(text) so với \(name)")
                        .foregroundStyle((ratio > 0) == risingIsBad ? Palette.red : Palette.green)
                        .accessibilityLabel("\(text) so với \(name)")
                }
            } else {
                Text("Chưa có số \(period.previousName)")
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .textRole(.caption)
        .monospacedDigit()
    }
}

/// The chart colours of Báo cáo and Phân bổ hạn mức (redone 2026-10-30, the light ones were hard to
/// see): steps of ink, largest first, each clearly apart; the rest share one light grey ("Khác").
/// One colour family like the rest of the app, not a rainbow. What is not split (Chưa phân bổ) is
/// the empty track, marked by a hollow dot.
enum ChartShades {
    static let steps: [Double] = [1, 0.72, 0.52, 0.36, 0.24]
    /// Lighter than the last step, still seen on a card in light and dark (14% was lost, 2026-10-30).
    static let rest = Palette.ink.opacity(0.18)

    /// Whether a colour is the shared "Khác" one, whose dot gets an edge so it stays visible.
    static func isRest(at index: Int) -> Bool { index >= steps.count }

    static func color(at index: Int) -> Color {
        index < steps.count ? Palette.ink.opacity(steps[index]) : rest
    }
}

/// A row of a breakdown: icon, name and a note under it, the amount, and › when it opens more.
struct BreakdownRowLabel: View {
    let icon: String
    let title: String
    let detail: String
    let amount: String
    var dot: Color? = nil
    /// A ring instead of a filled dot: the empty part of a chart.
    var hollowDot = false
    /// A faint dot ("Khác") drawn with a thin edge so it does not vanish.
    var edgedDot = false
    var opensMore = true

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            RowIcon(name: icon)
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                HStack(spacing: Spacing.s) {
                    if hollowDot {
                        Circle().strokeBorder(Palette.secondary, lineWidth: 1.5).frame(width: 9, height: 9)
                    } else if let dot {
                        Circle().fill(dot)
                            .overlay { if edgedDot { Circle().strokeBorder(Palette.secondary, lineWidth: 1) } }
                            .frame(width: 9, height: 9)
                    }
                    Text(title)
                        .textRole(.body)
                        .lineLimit(1)
                }
                Text(detail)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.s)
            Text(amount)
                .textRole(.body)
                .monospacedDigit()
                .lineLimit(1)
            if opensMore {
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
