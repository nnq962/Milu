import SwiftUI

/// "Tháng này": one white card under its section heading (2026-10-31), with this month's two
/// figures side by side (`SplitTotals`), a hairline, then the spending bar (`SegmentedBar`): one
/// part per group in the chart's shades, largest first, the rest in the "Khác" grey, and the empty
/// part what the month's limit still allows. The legend names the four biggest groups. Tapping
/// the card opens the month's report.
struct MonthCard: View {
    let month: Date
    let onOpenReport: () -> Void

    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget

    /// Groups named on the bar and in the legend; the rest is "Khác".
    private static let shown = 4

    var body: some View {
        let groups = store.expensesByCategory(inMonthOf: month)
        let spent = store.total(.expense, inMonthOf: month)
        let earned = store.total(.income, inMonthOf: month)
        let top = Array(groups.prefix(Self.shown))
        let rest = groups.dropFirst(Self.shown).reduce(0) { $0 + $1.amount }
        Button(action: onOpenReport) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                // The two totals, as on Thu chi's month card.
                SplitTotals(items: [
                    .init("Đã thu", amount: earned, tone: earned > 0 ? .signedIncome : .neutral),
                    .init("Đã chi", amount: spent, tone: spent > 0 ? .signedExpense : .neutral),
                ])
                if spent > 0 {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Chi theo nhóm")
                                .textRole(.captionStrong)
                                .foregroundStyle(Palette.secondaryLabel)
                            Spacer(minLength: Spacing.s)
                            if monthlyBudget > 0 {
                                Text("Hạn mức \(monthlyBudget.vndCompact)")
                                    .textRole(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.secondaryLabel)
                            }
                        }
                        // The empty part is what the month's limit still allows; with no limit
                        // the spending fills the bar.
                        SegmentedBar(segments: segments(top: top, rest: rest), whole: monthlyBudget)
                        LegendRow(items: legend(top: top, hasRest: rest > 0))
                    }
                    .padding(.top, Spacing.l)
                    .overlay(alignment: .top) { SplitLine() }
                }
            }
            .card()
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label(earned: earned, spent: spent, top: top))
        .accessibilityHint("Xem báo cáo tháng này")
    }

    private func segments(top: [CategoryTotal], rest: Double) -> [SegmentedBar.Segment] {
        top.enumerated().map { index, group in
            SegmentedBar.Segment(id: "\(group.id)", color: ChartShades.color(at: index), amount: group.amount)
        } + (rest > 0 ? [SegmentedBar.Segment(id: "rest", color: ChartShades.rest, amount: rest)] : [])
    }

    private func legend(top: [CategoryTotal], hasRest: Bool) -> [LegendRow.Item] {
        top.enumerated().map { index, group in
            LegendRow.Item(id: "\(group.id)", color: ChartShades.color(at: index), text: group.name)
        } + (hasRest ? [LegendRow.Item(id: "rest", color: ChartShades.rest, text: "Khác")] : [])
    }

    private func label(earned: Double, spent: Double, top: [CategoryTotal]) -> String {
        var words = "Tháng này đã thu \(earned.vnd), đã chi \(spent.vnd)"
        if monthlyBudget > 0 { words += " trên hạn mức \(monthlyBudget.vnd)" }
        if !top.isEmpty { words += ", nhiều nhất " + top.map { "\($0.name) \($0.amount.vndCompact)" }.joined(separator: ", ") }
        return words
    }
}
