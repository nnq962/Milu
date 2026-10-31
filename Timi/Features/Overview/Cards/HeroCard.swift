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
    /// Timi's disc in the strip; it grows with the words beside it.
    @ScaledMetric(relativeTo: .caption) private var avatarSize = RowMetrics.iconColumn + Spacing.xs

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
                .padding([.horizontal, .top], Spacing.leadCard)
                .padding(.bottom, Spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.card)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Xem tài sản ròng gồm những gì")

            timiStrip
                .padding([.horizontal, .bottom], Spacing.m)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: CardCorners.large)
    }

    /// A rounded block inside the card's foot, on the quiet block colour, the card's own surface
    /// framing it all round (user report 2026-10-31: edge to edge, its grey ran into the grey page
    /// and the card lost its bottom edge; at 60% with a hairline it was hard to see). Timi's ✦ on
    /// a disc of the primary colour leads it, as its avatar in the chat, and "Hỏi Timi ›" closes it
    /// in the primary colour.
    private var timiStrip: some View {
        let insight = TimiInsight.make(store: store, monthlyBudget: monthlyBudget, now: .now)
        return Button(action: onOpenAssistant) {
            HStack(spacing: Spacing.m) {
                TimiIcon("hugeicons-ai-magic", size: RowMetrics.inlineGlyph)
                    .foregroundStyle(Palette.onPrimary)
                    .frame(width: avatarSize, height: avatarSize)
                    .background(Palette.primary, in: Circle())
                    .accessibilityHidden(true)
                Text(insight.text)
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.label)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: Spacing.xxs) {
                    Text("Hỏi Timi")
                    TimiIcon("hugeicons-arrow-right-01", size: RowMetrics.linkChevron)
                }
                .textRole(.captionStrong)
                .foregroundStyle(Palette.primary)
                .fixedSize()
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.m)
            .frame(minHeight: ControlHeight.large)
            .background(Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous))
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Timi: \(insight.text)")
        .accessibilityHint("Hỏi Timi, mở trợ lý AI")
    }
}
