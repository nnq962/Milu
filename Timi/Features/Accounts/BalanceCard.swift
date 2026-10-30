import SwiftUI

/// Kiểu A of Tài khoản: the total in a white card, with a bar of where the money is, like the
/// storage bar in iPhone Settings. The bar splits only money that is there: each counted account
/// with a balance above zero and the money in goals, the four biggest in the chart colours, the
/// rest as "Khác". Accounts below zero cannot be a length on a bar, so a red line under it names
/// them; a total at or below zero turns red and leaves the bar out. Locked accounts are left out,
/// as they are from the total.
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
        let change = store.netWorthChange(since: DateInterval.month(of: .now).start)
        VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Tổng số dư")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                Text(total.vnd)
                    .textRole(.display)
                    .monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .foregroundStyle(total < 0 ? Palette.red : Palette.ink)
                if change != 0 {
                    Text("\(change > 0 ? "↑" : "↓") \(abs(change).vndCompact) trong tháng này")
                        .textRole(.captionStrong)
                        .monospacedDigit()
                        .foregroundStyle(change > 0 ? Palette.green : Palette.red)
                }
            }
            // A bar says something only with a total above zero and money in two places or more.
            if total > 0, parts.count > 1 {
                bar(parts)
                legend(parts)
            }
            if !negatives.isEmpty {
                let owed = negatives.reduce(0) { $0 + $1.balance }
                HStack(spacing: Spacing.xs) {
                    TimiIcon("hugeicons-alert-circle", size: 14)
                    Text(negatives.count == 1
                         ? "Âm \(abs(owed).vndCompact) ở \(negatives[0].name)"
                         : "Âm \(abs(owed).vndCompact) ở \(negatives.count) tài khoản")
                }
                .textRole(.captionStrong)
                .foregroundStyle(Palette.red)
            }
        }
        .sleekCard()
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

    private func bar(_ parts: [Part]) -> some View {
        let sum = parts.reduce(0) { $0 + $1.amount }
        return GeometryReader { geometry in
            // 2pt gaps between the pieces, as the storage bar has.
            let gaps = CGFloat(parts.count - 1) * 2
            HStack(spacing: 2) {
                ForEach(Array(parts.enumerated()), id: \.element.id) { index, part in
                    ChartShades.color(at: index)
                        .frame(width: max((geometry.size.width - gaps) * part.amount / sum, 2))
                }
            }
        }
        .frame(height: 10)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }

    private func legend(_ parts: [Part]) -> some View {
        let sum = parts.reduce(0) { $0 + $1.amount }
        return FlowLayout(spacing: Spacing.s) {
            ForEach(Array(parts.enumerated()), id: \.element.id) { index, part in
                HStack(spacing: Spacing.xs) {
                    Circle().fill(ChartShades.color(at: index)).frame(width: 8, height: 8)
                    Text("\(part.name) \((part.amount / sum).percentText)")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
                .padding(.trailing, Spacing.s)
            }
        }
    }
}
