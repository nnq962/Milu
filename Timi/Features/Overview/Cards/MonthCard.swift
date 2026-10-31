import SwiftUI

/// "Tháng này": one white card under its section heading (2026-10-31), with this month's two
/// figures side by side, a hairline, then the spending bar: one segment per group in the report's
/// own shades, largest first, the rest in the "Khác" grey, and the empty part what the month's
/// limit still allows (no limit: the bar is as long as the spending). The legend names the four
/// biggest groups. Tapping the card opens the month's report.
struct MonthCard: View {
    let month: Date
    let onOpenReport: () -> Void

    @Environment(FinanceStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget

    private static let barHeight: CGFloat = 12
    private static let shown = 4

    var body: some View {
        let groups = store.expensesByCategory(inMonthOf: month)
        let spent = store.total(.expense, inMonthOf: month)
        let earned = store.total(.income, inMonthOf: month)
        let top = Array(groups.prefix(Self.shown))
        let rest = groups.dropFirst(Self.shown).reduce(0) { $0 + $1.amount }
        let whole = max(monthlyBudget, spent, 1)
        Button(action: onOpenReport) {
            VStack(alignment: .leading, spacing: Spacing.l) {
                // The two totals, as on Thu chi's month card.
                HStack(alignment: .top, spacing: 0) {
                    total("Đã thu", amount: earned, tone: earned > 0 ? .signedIncome : .plain)
                        .padding(.trailing, Spacing.l)
                        .overlay(alignment: .trailing) { VerticalDivider() }
                    total("Đã chi", amount: spent, tone: spent > 0 ? .signedExpense : .plain)
                        .padding(.leading, Spacing.l)
                }
                if spent > 0 {
                    Palette.border.frame(height: 1)
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Chi theo nhóm")
                                .textRole(.captionStrong)
                                .foregroundStyle(Palette.secondaryText)
                            Spacer(minLength: Spacing.s)
                            if monthlyBudget > 0 {
                                Text("Hạn mức \(monthlyBudget.vndCompact)")
                                    .textRole(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.secondaryText)
                            }
                        }
                        bar(top: top, rest: rest, whole: whole)
                        legend(top: top, hasRest: rest > 0)
                    }
                }
            }
            .sleekCard()
            .contentShape(RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous))
        }
        .buttonStyle(.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label(earned: earned, spent: spent, top: top))
        .accessibilityHint("Xem báo cáo tháng này")
    }

    private func total(_ title: String, amount: Double, tone: MoneyText.Tone) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryText)
            MoneyText(amount: amount, size: .large, tone: tone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bar(top: [CategoryTotal], rest: Double, whole: Double) -> some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(Array(top.enumerated()), id: \.element.id) { index, group in
                    Rectangle()
                        .fill(ChartShades.color(at: index))
                        .frame(width: max(geometry.size.width * group.amount / whole - 2, 0))
                }
                if rest > 0 {
                    Rectangle()
                        .fill(ChartShades.rest)
                        .frame(width: max(geometry.size.width * rest / whole - 2, 0))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: Self.barHeight)
        .background(Palette.fill2)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }

    /// The groups' names after their dots, wrapping at the accessibility sizes.
    private func legend(top: [CategoryTotal], hasRest: Bool) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.m))
        return layout {
            ForEach(Array(top.enumerated()), id: \.element.id) { index, group in
                HStack(spacing: Spacing.xs) {
                    LegendDot(color: ChartShades.color(at: index))
                    Text(group.name).lineLimit(1)
                }
            }
            if hasRest {
                HStack(spacing: Spacing.xs) {
                    LegendDot(color: ChartShades.rest)
                    Text("Khác").lineLimit(1)
                }
            }
        }
        .textRole(.footnote)
        .foregroundStyle(Palette.secondaryText)
        .minimumScaleFactor(0.8)
        .accessibilityHidden(true)
    }

    private func label(earned: Double, spent: Double, top: [CategoryTotal]) -> String {
        var words = "Tháng này đã thu \(earned.vnd), đã chi \(spent.vnd)"
        if monthlyBudget > 0 { words += " trên hạn mức \(monthlyBudget.vnd)" }
        if !top.isEmpty { words += ", nhiều nhất " + top.map { "\($0.name) \($0.amount.vndCompact)" }.joined(separator: ", ") }
        return words
    }
}
