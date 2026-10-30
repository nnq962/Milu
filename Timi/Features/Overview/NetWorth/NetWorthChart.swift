import Charts
import SwiftUI

/// Tài sản ròng at the end of each month as a soft line over a faded area (user request
/// 2026-10-30). `compact` is the sparkline on the Tổng quan card: no axes, white on the card.
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
                    .foregroundStyle(LinearGradient(colors: [tint.opacity(compact ? 0.28 : 0.22), tint.opacity(0)],
                                                    startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Tháng", point.month),
                         y: .value("Tài sản ròng", point.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: compact ? 2.5 : 3, lineCap: .round, lineJoin: .round))
            }
            if let marked = picked ?? (compact ? points.last : nil) {
                PointMark(x: .value("Tháng", marked.month),
                          y: .value("Tài sản ròng", marked.value))
                    .symbolSize(compact ? 50 : 90)
                    .foregroundStyle(tint)
            }
            if let picked {
                RuleMark(x: .value("Tháng", picked.month))
                    .foregroundStyle(Palette.border)
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
                                .foregroundStyle(Palette.secondaryText)
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
