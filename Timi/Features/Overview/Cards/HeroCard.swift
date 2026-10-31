import SwiftUI

/// The lead card of Tổng quan, a card (HIG pass 2026-10-31: content on solid surfaces,
/// glass only on the bars and controls): "Tài sản ròng" and a chevron at the far right, net worth
/// in large type, how much it moved since the chart's first month in small green words, and the
/// growth line over a faint wash; tapping it opens "Tài sản ròng", where the figure is taken
/// apart. Across its foot a quiet strip from Timi (user choice 2026-10-31, "B"): the ✦, a few
/// teasing words from the figures (`TimiInsight`) and "Hỏi Timi ›", the way into the assistant;
/// a button of its own that opens it, asking nothing.
struct HeroCard: View {
    let onOpen: () -> Void
    let onOpenAssistant: () -> Void

    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget

    /// The growth line's height.
    private static let chartHeight: CGFloat = 48

    var body: some View {
        let history = store.netWorthHistory()
        VStack(spacing: 0) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Label, figure and growth drawn as on the Tài sản ròng page, so the one
                        // figure reads the same in both places (strict review 2026-10-31).
                        HStack {
                            Text("Tài sản ròng")
                                .textRole(.captionStrong)
                                .foregroundStyle(Palette.secondaryLabel)
                            Spacer()
                            RowChevron()
                        }
                        // Red below zero.
                        MoneyText(amount: store.netWorth, size: .display, tone: .balance)
                        if let first = history.first {
                            NetWorthGrowth(change: store.netWorth - first.value, since: first)
                        }
                    }
                    NetWorthChart(points: history, compact: true)
                        .frame(height: Self.chartHeight)
                        .accessibilityHidden(true)
                }
                .padding(Spacing.leadCard)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.card)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Xem tài sản ròng gồm những gì")

            timiStrip
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: CardCorners.large)
    }

    /// Edge to edge across the card's foot, a hairline over it and the quiet block colour under it.
    private var timiStrip: some View {
        let insight = TimiInsight.make(store: store, monthlyBudget: monthlyBudget, now: .now)
        return Button(action: onOpenAssistant) {
            HStack(spacing: Spacing.s) {
                TimiIcon("hugeicons-ai-magic", size: RowMetrics.iconGlyph)
                    .foregroundStyle(Palette.primary)
                    .accessibilityHidden(true)
                Text(insight.text)
                    .textRole(.caption)
                    .foregroundStyle(Palette.label)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: Spacing.xxs) {
                    Text("Hỏi Timi")
                    TimiIcon("hugeicons-arrow-right-01", size: RowMetrics.linkChevron)
                }
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryLabel)
                .fixedSize()
            }
            .padding(.horizontal, Spacing.leadCard)
            .padding(.vertical, Spacing.m)
            .frame(minHeight: ControlHeight.regular)
            .background(Palette.surfaceMuted.opacity(0.6))
            .overlay(alignment: .top) { Rectangle().fill(Palette.separator).frame(height: 0.5) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.row)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Timi: \(insight.text)")
        .accessibilityHint("Hỏi Timi, mở trợ lý AI")
    }
}
