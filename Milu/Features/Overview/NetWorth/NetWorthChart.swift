import Charts
import SwiftUI

/// Tài sản ròng at the end of each month as a soft line over a faded area (user request
/// 2026-10-30). `compact` is the sparkline along the foot of the Tổng quan card: a fainter wash,
/// no axes, today a ringed dot on a soft halo at its end (2026-11-08). The full chart
/// names the months and lets a finger pick one (`selection`).
struct NetWorthChart: View {
    let points: [NetWorthPoint]
    var compact = false
    var tint: Color = Palette.primary
    var selection: Binding<Date?>? = nil

    /// Today's dot at the sparkline's end, and how far that end stops short of the card's edge so
    /// the dot shows whole.
    private static let endDot: CGFloat = 10
    private static let endHalo: CGFloat = 24
    private static let endInset: CGFloat = 24
    /// The sparkline starts this far in, so its first month's name shows whole under it.
    private static let startInset: CGFloat = 20

    var body: some View {
        let values = points.map(\.value)
        let low = values.min() ?? 0
        let high = values.max() ?? 0
        // A flat line still needs some room above and below it.
        let pad = max((high - low) * 0.2, abs(high) * 0.02, 1)
        // More room under the line than over it, so the faded area shows along the whole line,
        // its flat start included, not only under the rise (user report 2026-10-31: the area
        // seemed missing at both ends).
        let floor = low - pad * 3
        let picked = selection?.wrappedValue.flatMap(nearest)

        Chart {
            ForEach(points) { point in
                AreaMark(x: .value("Tháng", point.month),
                         yStart: .value("Đáy", floor), yEnd: .value("Tài sản ròng", point.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(LinearGradient(colors: [tint.opacity(compact ? 0.20 : 0.22), tint.opacity(0)],
                                                    startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Tháng", point.month),
                         y: .value("Tài sản ròng", point.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(tint)
                    // Square ends: a round cap reached half the line's width past the first and
                    // last points, past the faded area under it, which then looked cut short at
                    // both ends (user report 2026-10-31).
                    .lineStyle(StrokeStyle(lineWidth: compact ? 2.5 : 3, lineCap: .butt, lineJoin: .round))
            }
            if compact, let last = points.last {
                PointMark(x: .value("Tháng", last.month), y: .value("Tài sản ròng", last.value))
                    // Today: a solid dot ringed in the card's white, on a soft halo of the line's
                    // colour (2026-11-08, after a flat dot on the line read as a blot).
                    .symbol {
                        ZStack {
                            Circle()
                                .fill(tint.opacity(0.16))
                                .frame(width: Self.endHalo, height: Self.endHalo)
                            Circle()
                                .fill(tint)
                                .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 2))
                                .frame(width: Self.endDot + 2, height: Self.endDot + 2)
                        }
                    }
            }
            // The picked month: the same ringed dot as today's on the sparkline, so it stands out on
            // the line (2026-11-08).
            if let picked {
                PointMark(x: .value("Tháng", picked.month),
                          y: .value("Tài sản ròng", picked.value))
                    .symbol {
                        Circle()
                            .fill(tint)
                            .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 2))
                            .frame(width: Self.endDot + 4, height: Self.endDot + 4)
                    }
            }
            if let picked {
                RuleMark(x: .value("Tháng", picked.month))
                    .foregroundStyle(Palette.separator)
                    .zIndex(-1)
            }
        }
        // The sparkline keeps more room over its top, so today's halo shows whole.
        .chartYScale(domain: floor...(high + pad * (compact ? 2 : 1)))
        // The sparkline runs edge to edge; the full chart keeps room for the first and last
        // month's names, centred under their points.
        .chartXScale(domain: (points.first?.month ?? .now)...(points.last?.month ?? .now),
                     range: compact ? .plotDimension(startPadding: Self.startInset, endPadding: Self.endInset)
                                    : .plotDimension(padding: 14))
        .chartYAxis(.hidden)
        // Every month named under its point: on the sparkline too, small and quiet (2026-11-08,
        // without them the line said nothing of when).
        .chartXAxis {
            AxisMarks(values: points.map(\.month)) { value in
                AxisValueLabel(anchor: .top) {
                    if let date = value.as(Date.self) {
                        Text("T\(Calendar.current.component(.month, from: date))")
                            .textRole(compact ? .footnote : .caption)
                            .foregroundStyle(compact ? Palette.tertiaryLabel : Palette.secondaryLabel)
                            // Grow only so far: six names must share the width, and the plot its
                            // height; past this the line was squashed flat or the chart filled
                            // the screen (review 2026-11-08). The page reads the months aloud.
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .modifier(Selecting(selection: selection))
        .accessibilityElement()
        .accessibilityLabel("Tài sản ròng \(points.count) tháng gần đây")
        .accessibilityValue(points.map { "tháng \(Calendar.current.component(.month, from: $0.month)): \($0.value < 0 ? "trừ " : "")\(MoneyText.spoken(abs($0.value)))" }
            .joined(separator: ", "))
        // The sparkline is part of the card's button, which says the figure: its six months
        // read on top of it were too much for one tap (review 2026-11-08).
        .accessibilityHidden(compact)
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

/// How much net worth moved, in small words under the figure on the Tài sản ròng page: green up,
/// red down, grey "Không đổi" when it did not move.
struct NetWorthGrowth: View {
    let change: Double
    /// What it is measured against: "từ cuối tháng 5".
    private let label: String

    /// Measured from the end of `point`'s month (a history point holds that month's closing
    /// figure): "từ cuối tháng 6", not "trong 6 tháng", which was five (re-review 2026-10-31).
    init(change: Double, since point: NetWorthPoint) {
        self.change = change
        self.label = "từ cuối tháng \(Calendar.current.component(.month, from: point.month))"
    }

    var body: some View {
        // No arrow when it did not move: "↑ 0đ" read as a rise (review 2026-11-08).
        Text(change == 0 ? "Không đổi \(label)" : "\(change < 0 ? "↓" : "↑") \(abs(change).vnd) \(label)")
            .textRole(.captionStrong)
            .monospacedDigit()
            .foregroundStyle(change == 0 ? Palette.secondaryLabel : change > 0 ? Palette.positive : Palette.negative)
            // Said in words: "Tăng 1.000.000 đồng từ cuối tháng 6", not an arrow and "đ".
            .accessibilityLabel(change == 0 ? "Không đổi \(label)"
                                : "\(change > 0 ? "Tăng" : "Giảm") \(MoneyText.spoken(abs(change))) \(label)")
    }
}
