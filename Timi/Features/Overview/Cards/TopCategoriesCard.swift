import SwiftUI

/// "Chi nhiều nhất": the three groups that took most this month on one white card under their
/// section heading (2026-10-31), each its glyph in a tinted circle in the report's shade, its
/// name and its figure under it. Tapping the card opens the month's report. Nothing spent this
/// month: the section is not shown.
struct TopCategoriesCard: View {
    let month: Date
    let onOpenReport: () -> Void

    @Environment(FinanceStore.self) private var store

    private static let shown = 3

    var body: some View {
        let top = Array(store.expensesByCategory(inMonthOf: month).prefix(Self.shown))
        Button(action: onOpenReport) {
            HStack(alignment: .top, spacing: Spacing.s) {
                ForEach(Array(top.enumerated()), id: \.element.id) { index, group in
                    VStack(spacing: Spacing.s) {
                        TimiIcon(group.icon, size: RowMetrics.iconColumn)
                            .foregroundStyle(ChartShades.color(at: index))
                            .frame(width: RowMetrics.iconChoice, height: RowMetrics.iconChoice)
                            .background(ChartShades.color(at: index).opacity(0.14), in: Circle())
                            .accessibilityHidden(true)
                        VStack(spacing: RowMetrics.lineGap) {
                            Text(group.name)
                                .textRole(.caption)
                                .foregroundStyle(Palette.ink)
                            Text(group.amount.vndCompact)
                                .textRole(.captionStrong)
                                .monospacedDigit()
                                .foregroundStyle(Palette.secondaryText)
                        }
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .sleekCard()
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chi nhiều nhất: " + top.map { "\($0.name) \($0.amount.vnd)" }.joined(separator: ", "))
        .accessibilityHint("Xem báo cáo tháng này")
    }
}
