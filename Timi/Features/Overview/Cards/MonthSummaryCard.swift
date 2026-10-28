import SwiftUI

/// This month's money in and out, and the spending limit; tapping the limit edits it.
struct MonthSummaryCard: View {
    let monthlyBudget: Double
    let onEditBudget: () -> Void

    @Environment(FinanceStore.self) private var store

    var body: some View {
        let expense = store.total(.expense)
        let ratio = monthlyBudget > 0 ? expense / monthlyBudget : 0
        let calendar = Calendar.current
        let month = calendar.component(.month, from: .now)
        let daysLeft = (calendar.range(of: .day, in: .month, for: .now)?.count ?? 0) - calendar.component(.day, from: .now)
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Tháng \(month) tổng quan")
                    .font(Typography.font(.callout, size: 16, weight: .semibold))
                    .frame(minHeight: 24)
                Spacer(minLength: 4)
                Text("Còn \(daysLeft) ngày")
                    .font(Typography.font(.caption, size: 11, weight: .medium))
                    .foregroundStyle(Palette.secondaryText)
            }
            HStack(spacing: 12) {
                flowStat("Tiền vào", amount: store.total(.income), income: true)
                flowStat("Tiền ra", amount: expense, income: false)
            }
            Button(action: onEditBudget) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hạn mức chi tiêu")
                        Spacer()
                        Text(monthlyBudget > 0 ? ratio.percentText : "Thiết lập")
                            .monospacedDigit()
                    }
                    .font(Typography.font(.caption, size: 11, weight: .medium))
                    .frame(minHeight: 16.5)
                    GeometryReader { geometry in
                        Capsule().fill(Palette.muted)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(ProgressBar.budgetColor(ratio))
                                    .frame(width: geometry.size.width * min(max(ratio, 0), 1))
                            }
                    }
                    .frame(height: 8)
                    .accessibilityHidden(true)
                    Text(monthlyBudget > 0 ? "Đã dùng \(expense.vndCompact) / \(monthlyBudget.vndCompact)" : "Đặt hạn mức để theo dõi chi tiêu")
                        .font(Typography.font(.caption, size: 11))
                        .monospacedDigit()
                        .frame(minHeight: 16.5)
                }
                .foregroundStyle(Palette.secondaryText)
                .contentShape(Rectangle())
            }
            .buttonStyle(.automatic)
            .accessibilityHint("Chỉnh hạn mức chi tiêu hàng tháng")
        }
        .overviewCard()
    }

    private func flowStat(_ title: String, amount: Double, income: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Typography.font(.caption, size: 11, weight: .medium))
                .foregroundStyle(Palette.secondaryText)
                .frame(minHeight: 16.5)
            Text("\(income ? "+" : "-")\(amount.vndCompact)")
                .font(Typography.font(.callout, size: 16, weight: .bold)).monospacedDigit()
                .foregroundStyle(income ? Palette.ink : Palette.red)
                .lineLimit(1).minimumScaleFactor(0.65)
                .frame(minHeight: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .cardSurface(radius: CardCorners.flow, color: income ? Palette.incomeTile : Palette.muted)
    }
}
