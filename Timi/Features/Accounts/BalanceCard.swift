import SwiftUI

/// The head of Tài khoản, on the tab's coloured ground (`TabBackdrop`), centred and two short
/// lines, as the head of Tổng quan (user request 2026-11-03, after the card it sat in): "Tổng số
/// dư" with how much it moved this month, and the total in large type under it.
struct TotalBalanceHeader: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        // Money in less money out on counted accounts since the 1st; moves between them, and
        // into goals, leave it as it was.
        let change = store.netWorthChange(since: DateInterval.month(of: .now).start)
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Text("Tổng số dư")
                    .foregroundStyle(Palette.secondaryLabel)
                if change != 0 {
                    // Short, as on Tổng quan; VoiceOver says the full figure below.
                    Text("\(change > 0 ? "↑" : "↓") \(abs(change).vndCompact) tháng này")
                        .monospacedDigit()
                        .foregroundStyle(change > 0 ? Palette.income : Palette.expense)
                }
            }
            .textRole(.captionStrong)
            MoneyText(amount: store.paymentBalance, size: .display, tone: .balance)
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.top, Spacing.s)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// "Tiền đang ở đâu", under the head of Tài khoản: a bar of where the money is, like the storage
/// bar in iPhone Settings (`SegmentedBar`), each counted account with a balance above zero and
/// the money in goals, the five biggest in the chart colours, the rest as "Khác". Accounts below
/// zero cannot be a length on a bar, so a red line under it names them; money in locked accounts,
/// left out of the total, is said last. Nothing to show, no card.
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
        // Money set aside: what is owed on a locked account is not "khoá" money.
        let lockedMoney = store.lockedPaymentAccounts.reduce(0) { $0 + max($1.balance, 0) }
        // A bar says something only with a total above zero and money in two places or more.
        let showsBar = total > 0 && parts.count > 1
        if showsBar || !negatives.isEmpty || lockedMoney > 0 {
            HeaderCard(title: "Tiền đang ở đâu") {
                content(parts: parts, showsBar: showsBar, negatives: negatives, lockedMoney: lockedMoney)
                    .card(padding: RowMetrics.horizontal)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func content(parts: [Part], showsBar: Bool, negatives: [Account], lockedMoney: Double) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if showsBar {
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
            if lockedMoney > 0 {
                HStack(spacing: Spacing.xs) {
                    TimiIcon("hugeicons-square-lock-02", size: RowMetrics.inlineGlyph)
                    Text("Đã khoá \(lockedMoney.vnd), không tính vào tổng")
                }
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
            }
        }
    }

    /// Money that is there, biggest first: counted accounts above zero and the goals together.
    /// After the five biggest, one a chart shade, the rest is one "Khác".
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
