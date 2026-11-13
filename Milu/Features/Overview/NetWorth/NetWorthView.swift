import SwiftUI

/// "Tài sản ròng", pushed from the lead card of Tổng quan (user choice 2026-10-30): the figure and
/// six months of it (a finger on the chart reads a month), then what it is made of. Each part slides
/// in its own list (accounts, goals, loans); the debts open their sheet.
struct NetWorthView: View {
    @Environment(FinanceStore.self) private var store
    @State private var isShowingDebt = false

    var body: some View {
        let history = store.netWorthHistory()
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                NetWorthSummary(history: history)
                parts
            }
            .padding(.horizontal, Spacing.page)
            // The margins of every pushed page, its parts' too (re-review 2026-10-31: 8 and 32).
            .padding(.top, Spacing.l)
            .padding(.bottom, Spacing.xxl)
        }
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Tài sản ròng")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingDebt) { DebtSheet() }
    }

    // MARK: - Thành phần

    private var parts: some View {
        let accounts = store.countedAccounts.filter { $0.balance > 0 }
        let saved = store.totalSaved
        let lent = store.loans.filter { $0.direction == .lent && $0.outstanding > 0 }
        // The heading on the page over its card, as on Tổng quan (review 2026-11-08).
        return OutsideHeaderSection(title: "Thành phần") {
            VStack(spacing: 0) {
                // Hidden with no account above zero, like Hũ and Cho vay: it opened an empty list
                // (strict review 2026-10-31).
                if !accounts.isEmpty {
                    link(.accounts, icon: "hugeicons-wallet-01", subtitle: "\(accounts.count) tài khoản",
                         amount: store.totalAssets - saved, first: true, order: 0)
                }
                if saved > 0 {
                    link(.goals, icon: "hugeicons-piggy-bank", subtitle: "\(store.activeGoals.count) hũ", amount: saved,
                         first: accounts.isEmpty, order: 1)
                }
                if !lent.isEmpty {
                    link(.lent, icon: "hugeicons-hand-coins", subtitle: "\(lent.count) khoản", amount: store.totalLent,
                         first: accounts.isEmpty && saved <= 0, order: 2)
                }
                Button { isShowingDebt = true } label: {
                    ListRow(icon: "hugeicons-credit-card", title: "Nợ", subtitle: "Thẻ âm và đi vay",
                            amount: -store.totalDebt, amountTone: .balance)
                }
                .buttonStyle(.row)
                .separatorAbove(!(accounts.isEmpty && saved <= 0 && lent.isEmpty), order: 3) { RowDivider() }
            }
            .listCard()
        }
    }

    private func link(_ part: NetWorthPart, icon: String, subtitle: String, amount: Double,
                      first: Bool = false, order: Int) -> some View {
        NavigationLink(value: part) {
            ListRow(icon: icon, title: part.title, subtitle: subtitle, amount: amount)
        }
        .buttonStyle(.row)
        .separatorAbove(!first, order: order) { RowDivider() }
    }
}

/// The figure and its six months. Its own view, holding the picked month: a finger moving on the
/// chart redraws only this, not the page, which worked out the six months' history again on every
/// step (review 2026-11-08).
private struct NetWorthSummary: View {
    let history: [NetWorthPoint]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedMonth: Date?
    /// 140, not 180 (user request 2026-11-08: lower). Fixed: the month names under it stop growing
    /// at xxxLarge (`NetWorthChart`), so the plot keeps its room; scaled whole, it reached about
    /// 465 at AX5 (review 2026-11-08).
    private let chartHeight: CGFloat = 140

    var body: some View {
        let picked = selectedMonth.flatMap { date in
            history.min { abs($0.month.timeIntervalSince(date)) < abs($1.month.timeIntervalSince(date)) }
        }
        let shown = picked ?? history.last
        let first = history.first?.value ?? 0
        let current = history.last?.value ?? 0
        VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title(picked))
                    .textRole(.captionStrong)
                    .foregroundStyle(Palette.secondaryLabel)
                    .contentTransition(.opacity)
                // Red below zero (strict review 2026-10-31: drawn by hand, it stayed ink). The
                // digits roll only without Reduce Motion (review 2026-11-08).
                MoneyText(amount: shown?.value ?? current, size: .display, tone: .balance)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                // Kept in place (only faded) while a month is picked, so the chart never jumps.
                if history.count > 1 {
                    NetWorthGrowth(change: current - first, since: history[0])
                        .opacity(picked == nil ? 1 : 0)
                }
            }
            // No animation on the chart: animated, the picked dot faded out and back in as the
            // finger moved, and was often gone (user report 2026-11-08).
            NetWorthChart(points: history, selection: $selectedMonth)
                .frame(height: chartHeight)
                // A tick as the finger reaches a month, none as it lifts.
                .sensoryFeedback(.selection, trigger: picked?.month) { _, new in new != nil }
                .transaction { $0.animation = nil }
        }
        .animation(reduceMotion ? nil : .snappy, value: picked?.month)
        .card(padding: Spacing.xl)
    }

    /// "Hiện có" (the word on Tổng quan's card) for today's figure, the last point, picked or not: "Cuối tháng 11" on the 8th
    /// read as if the month were over (review 2026-11-08).
    private func title(_ picked: NetWorthPoint?) -> String {
        guard let picked, picked.month != history.last?.month else { return "Hiện có" }
        return "Cuối tháng \(Calendar.current.component(.month, from: picked.month))"
    }
}
