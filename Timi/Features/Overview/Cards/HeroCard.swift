import SwiftUI

/// The lead card of Tổng quan, the one white card on the page: "Tài sản ròng" and a chevron at
/// the far right, net worth in large type, how much it moved over six months in small green
/// words, and the growth line over a faint wash (user choice 2026-10-30: cleaner, no pill). Tapping it opens "Tài sản ròng", where the figure is taken
/// apart.
struct HeroCard: View {
    let onOpen: () -> Void

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let history = store.netWorthHistory()
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("Tài sản ròng")
                            .textRole(.caption)
                        Spacer()
                        TimiIcon("hugeicons-arrow-right-01", size: 14)
                    }
                    .foregroundStyle(Palette.secondaryText)
                    Text(store.netWorth.vnd)
                        .textRole(.display)
                        .foregroundStyle(Palette.ink)
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                    if let first = history.first {
                        growth(store.netWorth - first.value)
                    }
                }
                NetWorthChart(points: history, compact: true)
                    .frame(height: 48)
                    .accessibilityHidden(true)
            }
            .sleekCard()
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Xem tài sản ròng gồm những gì")
    }

    /// How much it moved over the chart's months, as plain small words: green up, red down.
    private func growth(_ change: Double) -> some View {
        let up = change >= 0
        return Text("\(up ? "↑" : "↓") \(abs(change).vndCompact) trong 6 tháng")
            .textRole(.captionStrong)
            .monospacedDigit()
            .foregroundStyle(up ? Palette.green : Palette.red)
    }
}
