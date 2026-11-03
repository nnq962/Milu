import SwiftUI

/// The chart colours of Báo cáo, Phân bổ hạn mức and the bars of Tổng quan and Tài khoản: the
/// five largest groups in `Palette.chart`, the rest share one grey ("Khác"). What is not split
/// (Chưa phân bổ) is the empty track, marked by a hollow dot.
enum ChartShades {
    static let steps = Palette.chart
    static let rest = Palette.chartRest

    /// Whether a colour is the shared "Khác" one, whose dot gets an edge so it stays visible.
    static func isRest(at index: Int) -> Bool { index >= steps.count }

    static func color(at index: Int) -> Color {
        index < steps.count ? steps[index] : rest
    }
}

/// A bar split into coloured parts by amount, as the storage bar in iPhone Settings: spending by
/// group against the month's limit (Tổng quan), limits by group (Phân bổ hạn mức). Thin gaps between the parts; `whole` is what the full bar stands for, and
/// what the parts leave of it is the empty track. As tall as every progress bar of the app.
struct SegmentedBar: View {
    struct Segment: Identifiable {
        let id: String
        let color: Color
        let amount: Double
    }

    let segments: [Segment]
    /// The amount the full bar stands for (a limit); nil, or less than the parts, lets them fill it.
    var whole: Double? = nil

    var body: some View {
        let sum = segments.reduce(0) { $0 + $1.amount }
        let total = max(whole ?? sum, sum, 1)
        let gap = Spacing.xxs
        GeometryReader { geometry in
            let gaps = CGFloat(max(segments.count - 1, 0)) * gap
            HStack(spacing: gap) {
                ForEach(segments) { segment in
                    segment.color
                        .frame(width: max((geometry.size.width - gaps) * segment.amount / total, gap))
                }
                if total > sum { Spacer(minLength: 0) }
            }
        }
        .frame(height: ProgressBar.height)
        .background(Palette.progressTrack)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

/// The names under a bar or beside a chart, each after its dot, wrapping onto new lines as the
/// words need. Hidden from VoiceOver: the view around it says the figures in words.
struct LegendRow: View {
    struct Item: Identifiable {
        let id: String
        let color: Color
        let text: String
    }

    let items: [Item]

    var body: some View {
        FlowLayout(spacing: Spacing.s) {
            ForEach(items) { item in
                HStack(spacing: Spacing.xs) {
                    LegendDot(color: item.color)
                    Text(item.text).lineLimit(1)
                }
                .padding(.trailing, Spacing.s)
            }
        }
        .textRole(.caption)
        .foregroundStyle(Palette.secondaryLabel)
        .accessibilityHidden(true)
    }
}
