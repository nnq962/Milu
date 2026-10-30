import SwiftUI

/// This month's money in and out, and the spending limit. The totals open Báo cáo; the limit opens
/// Hạn mức chi tiêu.
struct MonthSummaryCard: View {
    let monthlyBudget: Double
    let onEditBudget: () -> Void
    let onOpenReport: () -> Void

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let expense = store.total(.expense)
        let ratio = monthlyBudget > 0 ? expense / monthlyBudget : 0
        let calendar = Calendar.current
        let month = calendar.component(.month, from: .now)
        let daysLeft = (calendar.range(of: .day, in: .month, for: .now)?.count ?? 0) - calendar.component(.day, from: .now)
        VStack(alignment: .leading, spacing: 16) {
            // The title and the two totals open Báo cáo (user choice 2026-10-30); › says so.
            Button(action: onOpenReport) {
                VStack(alignment: .leading, spacing: 16) {
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
                    HStack(spacing: 12) {
                        flowStat("Tiền vào", amount: store.total(.income), income: true)
                        flowStat("Tiền ra", amount: expense, income: false)
                    }
                }
                .foregroundStyle(Palette.ink)
                .contentShape(Rectangle())
            }
            .buttonStyle(.automatic)
            .accessibilityHint("Mở báo cáo")
            Button(action: onEditBudget) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hạn mức chi tiêu")
                        Spacer()
                        Text(monthlyBudget > 0 ? ratio.percentText : "Thiết lập")
                            .monospacedDigit()
                    }
                    .textRole(.captionStrong)
                    .frame(minHeight: 16.5)
                    ProgressBar(value: ratio, color: ProgressBar.budgetColor(ratio))
                    .accessibilityHidden(true)
                    Text(monthlyBudget > 0 ? "Đã dùng \(expense.vndCompact) / \(monthlyBudget.vndCompact)" : "Đặt hạn mức để theo dõi chi tiêu")
                        .textRole(.caption)
                        .monospacedDigit()
                        .frame(minHeight: 16.5)
                }
                .foregroundStyle(Palette.secondaryText)
                .contentShape(Rectangle())
            }
            .buttonStyle(.automatic)
            .accessibilityHint("Mở hạn mức chi tiêu")
        }
        .overviewCard()
    }

    private func flowStat(_ title: String, amount: Double, income: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryText)
                .frame(minHeight: 16.5)
            Text("\(income ? "+" : "-")\(amount.vndCompact)")
                .textRole(.bodyStrong).monospacedDigit()
                .foregroundStyle(income ? Palette.ink : Palette.red)
                .lineLimit(1).minimumScaleFactor(0.65)
                .frame(minHeight: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .cardSurface(radius: CardCorners.flow, color: income ? Palette.incomeTile : Palette.muted)
    }
}
