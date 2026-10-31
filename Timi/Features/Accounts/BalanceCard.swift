import SwiftUI

/// "Tổng số dư": the total, how it moved this month and how much is locked away. One header for
/// both layouts of Tài khoản, large on the page or at the top of `BalanceCard` (strict review
/// 2026-10-31: the card left out the lock line and turned a total below zero red, the page did
/// neither the same way).
struct TotalBalanceHeader: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        // Money set aside: what is owed on a locked account is not "khoá" money.
        let lockedMoney = store.lockedPaymentAccounts.reduce(0) { $0 + max($1.balance, 0) }
        // Money in less money out on counted accounts since the 1st; moves between them, and
        // into goals, leave it as it was.
        let change = store.netWorthChange(since: DateInterval.month(of: .now).start)
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Tổng số dư")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
            MoneyText(amount: store.paymentBalance, size: .display, tone: .balance)
            if change != 0 || lockedMoney > 0 {
                // Wraps onto a second line at large text instead of running off the edge.
                FlowLayout(spacing: Spacing.xs) {
                    if change != 0 {
                        Text("\(change > 0 ? "↑" : "↓") \(abs(change).vnd) trong tháng này")
                            .textRole(.captionStrong)
                            .monospacedDigit()
                            .foregroundStyle(change > 0 ? Palette.positive : Palette.negative)
                            .padding(.trailing, Spacing.m)
                    }
                    if lockedMoney > 0 {
                        HStack(spacing: Spacing.xs) {
                            TimiIcon("hugeicons-square-lock-02", size: RowMetrics.inlineGlyph)
                            Text("Đã khoá \(lockedMoney.vnd)")
                        }
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The head of Tài khoản: the total in a card, with a bar of where the money is, like the
/// storage bar in iPhone Settings (`SegmentedBar`). The bar splits only money that is there: each counted account
/// with a balance above zero and the money in goals, the four biggest in the chart colours, the
/// rest as "Khác". Accounts below zero cannot be a length on a bar, so a red line under it names
/// them; a total at or below zero leaves the bar out. Locked accounts are left out, as they are
/// from the total.
struct BalanceCard: View {
    @Environment(FinanceStore.self) private var store

    private struct Part: Identifiable {
        let id: String
        let name: String
        let amount: Double
    }

    var body: some View {
        let total = store.paymentBalance
        let counted = store.paymentAccounts.filter { !$0.isLocked }
        let parts = self.parts(counted)
        let negatives = counted.filter { $0.balance < 0 }
        VStack(alignment: .leading, spacing: Spacing.l) {
            TotalBalanceHeader()
            // A bar says something only with a total above zero and money in two places or more.
            if total > 0, parts.count > 1 {
                SegmentedBar(segments: parts.enumerated().map { index, part in
                    SegmentedBar.Segment(id: part.id, color: ChartShades.color(at: index), amount: part.amount)
                })
                LegendRow(items: legend(parts))
            }
            if !negatives.isEmpty {
                let owed = negatives.reduce(0) { $0 + $1.balance }
                HStack(spacing: Spacing.xs) {
                    TimiIcon("hugeicons-alert-circle", size: RowMetrics.inlineGlyph)
                    Text(negatives.count == 1
                         ? "Âm \(abs(owed).vnd) ở \(negatives[0].name)"
                         : "Âm \(abs(owed).vnd) ở \(negatives.count) tài khoản")
                }
                .textRole(.captionStrong)
                .foregroundStyle(Palette.negative)
            }
        }
        // 16 at the sides, as the rows and headings below, so "Tổng số dư" starts on their edge
        // (re-review 2026-10-31: 20 put it 4pt in from the logos); 20 above and below.
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, Spacing.card)
        .card(padding: 0)
        .accessibilityElement(children: .combine)
    }

    /// Money that is there, biggest first: counted accounts above zero and the goals together.
    /// After the four biggest, the rest is one "Khác".
    private func parts(_ counted: [Account]) -> [Part] {
        var parts = counted.filter { $0.balance > 0 }
            .map { Part(id: $0.id.uuidString, name: $0.name, amount: $0.balance) }
        if store.totalSaved > 0 {
            parts.append(Part(id: "goals", name: "Hũ tiết kiệm", amount: store.totalSaved))
        }
        parts.sort { $0.amount > $1.amount }
        let limit = ChartShades.steps.count
        guard parts.count > limit + 1 else { return parts }
        let rest = parts[limit...].reduce(0) { $0 + $1.amount }
        return Array(parts[..<limit]) + [Part(id: "rest", name: "Khác", amount: rest)]
    }

    /// Each part's name and share, after its dot.
    private func legend(_ parts: [Part]) -> [LegendRow.Item] {
        let sum = parts.reduce(0) { $0 + $1.amount }
        return parts.enumerated().map { index, part in
            LegendRow.Item(id: part.id, color: ChartShades.color(at: index), text: "\(part.name) \((part.amount / sum).percentText)")
        }
    }
}
