import SwiftUI

/// This month's money in and out (tapping it opens Báo cáo), then the month's limit as a bar
/// coloured by `ProgressBar.budgetColor` (tapping it opens Hạn mức chi tiêu). Tiles tinted teal and red as in the user's Sleek theme
/// (2026-10-30).
struct MonthSummaryCard: View {
    let monthlyBudget: Double
    let onOpenReport: () -> Void
    let onOpenBudget: () -> Void

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let expense = store.total(.expense)
        let calendar = Calendar.current
        let month = calendar.component(.month, from: .now)
        let daysLeft = (calendar.range(of: .day, in: .month, for: .now)?.count ?? 0) - calendar.component(.day, from: .now)
        VStack(alignment: .leading, spacing: Spacing.l) {
            Button(action: onOpenReport) {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    HStack(alignment: .center, spacing: Spacing.xs) {
                        Text("Tháng \(month) tổng quan")
                            .textRole(.title)
                            .frame(minHeight: 24)
                        TimiIcon("hugeicons-arrow-right-01", size: 16)
                            .foregroundStyle(Palette.secondary)
                        Spacer(minLength: 4)
                        Text("Còn \(daysLeft) ngày")
                            .textRole(.captionStrong)
                            .foregroundStyle(Palette.secondaryText)
                    }
                    HStack(spacing: Spacing.m) {
                        flowStat("Tiền vào", amount: store.total(.income), income: true)
                        flowStat("Tiền ra", amount: expense, income: false)
                    }
                }
                .foregroundStyle(Palette.ink)
                .contentShape(Rectangle())
            }
            .buttonStyle(.automatic)
            .accessibilityHint("Mở báo cáo")

            if monthlyBudget > 0 {
                let ratio = expense / monthlyBudget
                Button(action: onOpenBudget) {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        HStack {
                            Text("Hạn mức \(monthlyBudget.vndCompact)")
                            Spacer(minLength: Spacing.s)
                            Text(ratio.percentText)
                                .monospacedDigit()
                        }
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryText)
                        // The one limit rule of the app: teal, orange from 80%, red when over.
                        ProgressBar(value: ratio, color: ProgressBar.budgetColor(ratio))
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.automatic)
                .accessibilityLabel("Hạn mức chi tiêu, đã dùng \(ratio.percentText)")
                .accessibilityHint("Mở hạn mức chi tiêu")
            }
        }
        .sleekCard()
    }

    private func flowStat(_ title: String, amount: Double, income: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryText)
            Text("\(income ? "+" : "-")\(amount.vndCompact)")
                .textRole(.heading).monospacedDigit()
                .foregroundStyle(income ? Palette.green : Palette.red)
                .lineLimit(1).minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(income ? Palette.incomeTile : Palette.red.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: CardCorners.flow, style: .continuous))
    }
}
