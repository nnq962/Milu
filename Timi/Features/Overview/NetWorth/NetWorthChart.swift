import Charts
import SwiftUI

/// Tài sản ròng at the end of each month as a soft line over a faded area (user request
/// 2026-10-30). `compact` is the sparkline on the Tổng quan card: a fainter wash, no axes, no point.
/// The full chart names the months and lets a finger pick one (`selection`).
struct NetWorthChart: View {
    let points: [NetWorthPoint]
    var compact = false
    var tint: Color = Palette.primary
    var selection: Binding<Date?>? = nil

    var body: some View {
        let values = points.map(\.value)
        let low = values.min() ?? 0
        let high = values.max() ?? 0
        // A flat line still needs some room above and below it.
        let pad = max((high - low) * 0.2, abs(high) * 0.02, 1)
        let floor = low - pad
        let picked = selection?.wrappedValue.flatMap(nearest)

        Chart {
            ForEach(points) { point in
                AreaMark(x: .value("Tháng", point.month),
                         yStart: .value("Đáy", floor), yEnd: .value("Tài sản ròng", point.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(LinearGradient(colors: [tint.opacity(compact ? 0.12 : 0.22), tint.opacity(0)],
                                                    startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Tháng", point.month),
                         y: .value("Tài sản ròng", point.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: compact ? 2 : 3, lineCap: .round, lineJoin: .round))
            }
            if let picked {
                PointMark(x: .value("Tháng", picked.month),
                          y: .value("Tài sản ròng", picked.value))
                    .symbolSize(90)
                    .foregroundStyle(tint)
            }
            if let picked {
                RuleMark(x: .value("Tháng", picked.month))
                    .foregroundStyle(Palette.separator)
                    .zIndex(-1)
            }
        }
        .chartYScale(domain: floor...(high + pad))
        // The sparkline runs edge to edge; the full chart keeps room for the first and last
        // month's names, centred under their points.
        .chartXScale(domain: (points.first?.month ?? .now)...(points.last?.month ?? .now),
                     range: .plotDimension(padding: compact ? 0 : 14))
        .chartYAxis(.hidden)
        .chartXAxis {
            if !compact {
                AxisMarks(values: points.map(\.month)) { value in
                    AxisValueLabel(anchor: .top) {
                        if let date = value.as(Date.self) {
                            Text("T\(Calendar.current.component(.month, from: date))")
                                .textRole(.caption)
                                .foregroundStyle(Palette.secondaryLabel)
                        }
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .modifier(Selecting(selection: selection))
        .accessibilityElement()
        .accessibilityLabel("Tài sản ròng \(points.count) tháng gần đây")
        .accessibilityValue(points.map { "tháng \(Calendar.current.component(.month, from: $0.month)): \($0.value.vndCompact)" }
            .joined(separator: ", "))
    }

    private func nearest(_ date: Date) -> NetWorthPoint? {
        points.min { abs($0.month.timeIntervalSince(date)) < abs($1.month.timeIntervalSince(date)) }
    }

    /// Picking by touch only on the full chart; the sparkline is part of a button.
    private struct Selecting: ViewModifier {
        let selection: Binding<Date?>?

        func body(content: Content) -> some View {
            if let selection {
                content.chartXSelection(value: selection)
            } else {
                content.allowsHitTesting(false)
            }
        }
    }
}

/// How much net worth moved, in small words under the figure: green up, red down, grey when it
/// did not move. One view for Tổng quan's card and the Tài sản ròng page (strict review
/// 2026-10-31: the card showed "↑ 0đ" in green where the page showed grey).
struct NetWorthGrowth: View {
    let change: Double
    /// What it is measured against: "từ cuối tháng 5".
    private let label: String

    /// Measured from the end of `point`'s month (a history point holds that month's closing
    /// figure), worded the same on Tổng quan and Tài sản ròng (re-review 2026-10-31: "trong 6
    /// tháng" there, which was five, and "so với cuối tháng 5" here).
    init(change: Double, since point: NetWorthPoint) {
        self.change = change
        self.label = "từ cuối tháng \(Calendar.current.component(.month, from: point.month))"
    }

    var body: some View {
        Text("\(change < 0 ? "↓" : "↑") \(abs(change).vndCompact) \(label)")
            .textRole(.captionStrong)
            .monospacedDigit()
            .foregroundStyle(change == 0 ? Palette.secondaryLabel : change > 0 ? Palette.positive : Palette.negative)
    }
}
