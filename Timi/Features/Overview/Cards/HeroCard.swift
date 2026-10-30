import SwiftUI

/// The lead card of Tổng quan: a solid card in the primary colour with net worth in large type and
/// how it grew over six months, nothing else (user request 2026-10-30). Tapping it opens
/// "Tài sản ròng", where the figure is taken apart.
struct HeroCard: View {
    let onOpen: () -> Void

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let history = store.netWorthHistory()
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Text("TÀI SẢN RÒNG")
                            .textRole(.overline)
                            .tracking(1.3)
                        TimiIcon("hugeicons-arrow-right-01", size: 14)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    Text(store.netWorth.vnd)
                        .textRole(.display)
                        .foregroundStyle(.white)
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                }
                NetWorthChart(points: history, compact: true, tint: .white)
                    .frame(height: 64)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { HeroBackground(radius: CardCorners.large) }
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Xem tài sản ròng gồm những gì")
    }
}
