import SwiftUI

/// "Tài sản ròng", pushed from the lead card of Tổng quan (user choice 2026-10-30): the figure and
/// six months of it (a finger on the chart reads a month), then what it is made of. Each part slides
/// in its own list (accounts, goals, loans); the debts open their sheet.
struct NetWorthView: View {
    @Environment(FinanceStore.self) private var store
    @State private var selectedMonth: Date?
    @State private var isShowingDebt = false

    var body: some View {
        let history = store.netWorthHistory()
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                summary(history)
                parts
            }
            .padding(.horizontal, Spacing.page)
            // The margins of every pushed page, its parts' too (re-review 2026-10-31: 8 and 32).
            .padding(.top, Spacing.l)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Tài sản ròng")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingDebt) { DebtSheet() }
    }

    // MARK: - Số và biểu đồ

    private func summary(_ history: [NetWorthPoint]) -> some View {
        let picked = selectedMonth.flatMap { date in
            history.min { abs($0.month.timeIntervalSince(date)) < abs($1.month.timeIntervalSince(date)) }
        }
        let shown = picked ?? history.last
        let first = history.first?.value ?? 0
        return VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(picked.map { "Cuối tháng \(Calendar.current.component(.month, from: $0.month))" } ?? "Hiện tại")
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryText)
                    .contentTransition(.opacity)
                // Red below zero (strict review 2026-10-31: drawn by hand, it stayed ink).
                MoneyText(amount: shown?.value ?? store.netWorth, size: .display, tone: .negativeRed)
                    .contentTransition(.numericText())
                // Kept in place (only faded) while a month is picked, so the chart never jumps.
                if history.count > 1 {
                    NetWorthGrowth(change: store.netWorth - first, since: history[0])
                        .opacity(picked == nil ? 1 : 0)
                }
            }
            NetWorthChart(points: history, selection: $selectedMonth)
                .frame(height: 180)
                .sensoryFeedback(.selection, trigger: picked?.month)
        }
        .animation(.snappy, value: picked?.month)
        .sleekCard(padding: Spacing.xl)
    }

    // MARK: - Thành phần

    private var parts: some View {
        let accounts = store.countedAccounts.filter { $0.balance > 0 }
        let saved = store.totalSaved
        let lent = store.loans.filter { $0.direction == .lent && $0.outstanding > 0 }
        return VStack(alignment: .leading, spacing: Spacing.headerGap) {
            SectionHeader(title: "Gồm")
            VStack(spacing: 0) {
                // Hidden with no account above zero, like Hũ and Cho vay: it opened an empty list
                // (strict review 2026-10-31).
                if !accounts.isEmpty {
                    link(.accounts, icon: "hugeicons-wallet-01", subtitle: "\(accounts.count) tài khoản",
                         amount: store.totalAssets - saved, first: true)
                }
                if saved > 0 {
                    link(.goals, icon: "hugeicons-piggy-bank", subtitle: "\(store.activeGoals.count) hũ", amount: saved,
                         first: accounts.isEmpty)
                }
                if !lent.isEmpty {
                    link(.lent, icon: "hugeicons-hand-coins", subtitle: "\(lent.count) người", amount: store.totalLent,
                         first: accounts.isEmpty && saved <= 0)
                }
                Button { isShowingDebt = true } label: {
                    ListRow(icon: "hugeicons-credit-card", title: "Nợ", subtitle: "Thẻ âm và đi vay",
                            amount: -store.totalDebt, amountTone: .negativeRed)
                }
                .buttonStyle(.row)
                .overlay(alignment: .top) {
                    if !(accounts.isEmpty && saved <= 0 && lent.isEmpty) { RowDivider() }
                }
            }
            .listCard()
        }
    }

    private func link(_ part: NetWorthPart, icon: String, subtitle: String, amount: Double,
                      first: Bool = false) -> some View {
        NavigationLink(value: part) {
            ListRow(icon: icon, title: part.title, subtitle: subtitle, amount: amount)
        }
        .buttonStyle(.row)
        .overlay(alignment: .top) { if !first { RowDivider() } }
    }
}
