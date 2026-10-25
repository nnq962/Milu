//
//  OverviewView.swift
//  Timi
//

import Charts
import SwiftUI

struct OverviewView: View {
    @Environment(FinanceStore.self) private var store
    @Binding var selectedTab: AppTab
    @State private var isAddingTransaction = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    balanceCard
                    monthSummary
                    insightCard
                    weeklyChart
                    categoryBreakdown
                    recentTransactions
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.screenBackground)
            .navigationTitle("Tổng quan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Thêm giao dịch", systemImage: "plus") {
                        isAddingTransaction = true
                    }
                }
            }
            .sheet(isPresented: $isAddingTransaction) {
                AddTransactionView()
            }
        }
    }

    // MARK: - Thẻ tổng tài sản

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tổng tài sản ròng")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text(store.netWorth.vnd)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
            }
            HStack(spacing: 10) {
                balanceStat(title: "Tài sản", value: store.totalAssets, icon: "arrow.up.right")
                balanceStat(title: "Dư nợ", value: store.totalDebt, icon: "arrow.down.right")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.12))
                .padding(16)
        }
    }

    private func balanceStat(title: String, value: Double, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .frame(width: 24, height: 24)
                .background(.white.opacity(0.2), in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption)
                    .opacity(0.85)
                Text(value.vndCompact)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Thu chi tháng này

    private var monthSummary: some View {
        let income = store.total(.income)
        let expense = store.total(.expense)
        let ratio = income > 0 ? expense / income : 0
        let month = Calendar.current.component(.month, from: .now)

        return CardSection(title: "Tháng \(month)") {
            HStack {
                monthStat(title: "Thu nhập", value: income, icon: "arrow.down.circle.fill", color: .green)
                Divider().frame(height: 36)
                monthStat(title: "Chi tiêu", value: expense, icon: "arrow.up.circle.fill", color: .red)
                    .padding(.leading, 12)
            }
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: min(ratio, 1))
                    .tint(ratio > 1 ? .red : .accentColor)
                Text("Bạn đã chi \(ratio.percentText) thu nhập tháng này")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func monthStat(title: String, value: Double, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.vnd)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Gợi ý từ trợ lý

    @ViewBuilder
    private var insightCard: some View {
        let totalExpense = store.total(.expense)
        if let top = store.expensesByCategory().first, totalExpense > 0 {
            Button {
                selectedTab = .assistant
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Theme.brandGradient, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gợi ý từ Trợ lý AI")
                            .font(.subheadline.weight(.semibold))
                        Text("\(top.category.title) chiếm \((top.amount / totalExpense).percentText) chi tiêu tháng này. Chạm để hỏi cách tối ưu.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Biểu đồ 7 ngày

    private var weeklyChart: some View {
        let days = store.dailyExpenses(lastDays: 7)
        let weekTotal = days.reduce(0) { $0 + $1.amount }

        return CardSection(title: "Chi tiêu 7 ngày qua") {
            Text(weekTotal.vnd)
                .font(.title3.weight(.bold))
                .padding(.top, -8)
            Chart(days) { day in
                BarMark(
                    x: .value("Ngày", day.date, unit: .day),
                    y: .value("Chi tiêu", day.amount)
                )
                .cornerRadius(6)
                .foregroundStyle(Calendar.current.isDateInToday(day.date) ? Color.accentColor : Color.accentColor.opacity(0.35))
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.vndCompact)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(centered: true) {
                        if let date = value.as(Date.self) {
                            // "T2", "T3", ... "CN"
                            Text(date.formatted(.dateTime.weekday(.short).locale(.vietnam)))
                        }
                    }
                }
            }
            .frame(height: 170)
        }
    }

    // MARK: - Chi theo danh mục

    private var categoryBreakdown: some View {
        let items = store.expensesByCategory()
        let total = items.reduce(0) { $0 + $1.amount }

        return CardSection(title: "Chi theo danh mục") {
            if items.isEmpty {
                Text("Tháng này chưa có khoản chi nào.")
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 20) {
                    ZStack {
                        Chart(items) { item in
                            SectorMark(
                                angle: .value("Số tiền", item.amount),
                                innerRadius: .ratio(0.64),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(item.category.color)
                        }
                        VStack(spacing: 0) {
                            Text("Tổng")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(total.vndCompact)
                                .font(.subheadline.weight(.bold))
                        }
                    }
                    .frame(width: 128, height: 128)

                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(items.prefix(5)) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.category.color)
                                    .frame(width: 8, height: 8)
                                Text(item.category.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text((item.amount / total).percentText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Giao dịch gần đây

    private var recentTransactions: some View {
        CardSection(title: "Giao dịch gần đây", actionTitle: "Xem tất cả", onAction: { selectedTab = .transactions }) {
            VStack(spacing: 14) {
                ForEach(store.transactions.prefix(5)) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
    }
}

#Preview {
    OverviewView(selectedTab: .constant(.overview))
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
