import SwiftUI

/// The lead card of Tổng quan, a white card (HIG pass 2026-10-31: content on solid surfaces,
/// glass only on the bars and controls): "Tài sản ròng" and a chevron
/// at the far right, net worth in large type, how much it moved since the chart's first month in
/// small green words, and the growth line over a faint wash. Tapping it opens "Tài sản ròng",
/// where the figure is taken apart.
struct HeroCard: View {
    let onOpen: () -> Void

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let history = store.netWorthHistory()
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Label, figure and growth drawn as on the Tài sản ròng page, so the one figure
                    // reads the same in both places (strict review 2026-10-31).
                    HStack {
                        Text("Tài sản ròng")
                            .textRole(.captionStrong)
                            .foregroundStyle(Palette.secondaryLabel)
                        Spacer()
                        RowChevron()
                    }
                    // Red below zero.
                    MoneyText(amount: store.netWorth, size: .display, tone: .negativeRed)
                    if let first = history.first {
                        NetWorthGrowth(change: store.netWorth - first.value, since: first)
                    }
                }
                NetWorthChart(points: history, compact: true)
                    .frame(height: 48)
                    .accessibilityHidden(true)
            }
            .card(padding: Spacing.leadCard)
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Xem tài sản ròng gồm những gì")
    }
}
