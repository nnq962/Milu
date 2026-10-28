import SwiftUI

/// Net worth on top, then balance, money lent and debt in three small tiles.
struct BalanceCard: View {
    @Environment(FinanceStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tổng tài sản").textRole(.captionStrong).foregroundStyle(Palette.secondaryText)
                Text(store.netWorth.vnd)
                    .textRole(.display)
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            }
            HStack(spacing: 8) {
                stat("Số dư", value: store.totalAssets.vndCompact, icon: "solar-wallet-linear")
                stat("Cho vay", value: store.totalLent.vndCompact, icon: "solar-hand-money-linear")
                stat("Nợ", value: (-store.totalDebt).vndCompact, icon: "solar-card-linear", color: Palette.red)
            }
        }
        .overviewCard()
        .accessibilityElement(children: .contain)
    }

    private func stat(_ title: String, value: String, icon: String, color: Color = Palette.ink) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SolarIcon(icon, size: 16)
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
