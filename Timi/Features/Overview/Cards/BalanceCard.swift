import SwiftUI

/// Net worth on top, then balance, money lent and debt in three small tiles.
struct BalanceCard: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        // The page's lead card, the same `SummaryCard` as "Tổng số dư" on Tài khoản.
        SummaryCard(label: "Tổng tài sản", amount: store.netWorth, tone: .plain) {
            HStack(spacing: Spacing.s) {
                stat("Số dư", value: store.totalAssets.vndCompact, icon: "hugeicons-wallet-01")
                stat("Cho vay", value: store.totalLent.vndCompact, icon: "hugeicons-hand-coins")
                stat("Nợ", value: (-store.totalDebt).vndCompact, icon: "hugeicons-credit-card", color: Palette.red)
            }
            .padding(.top, Spacing.l)
        }
        .accessibilityElement(children: .contain)
    }

    private func stat(_ title: String, value: String, icon: String, color: Color = Palette.ink) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TimiIcon(icon, size: 16)
                .accessibilityHidden(true)
                .frame(width: 28, height: 28)
                .background(Palette.card, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).textRole(.captionStrong).foregroundStyle(Palette.secondaryText)
                Text(value)
                    .textRole(.amount)
                    .foregroundStyle(color).monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                    .frame(minHeight: 20)
            }
        }
        .accessibilityElement(children: .combine)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .cardSurface(radius: CardCorners.flow, color: Palette.balanceTile)
    }
}
