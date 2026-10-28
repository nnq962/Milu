import SwiftUI

struct ListsPart: View {
    var body: some View {
        PartSection(part: .lists) {
            VStack(spacing: 0) {
                ListRow(icon: "solar-banknote-2-linear", title: "Ví tiền mặt", subtitle: "Cập nhật hôm nay", amount: 2_350_000)
                ListRow(icon: "solar-cup-hot-linear", title: "Cà phê buổi sáng", subtitle: "Ăn uống · 08:30",
                        amount: 45_000, amountTone: .signedExpense)
                    .overlay(alignment: .top) { RowDivider() }
                ListRow(icon: "solar-wallet-money-linear", title: "Lương tháng 10", subtitle: "Thu nhập · 09:00",
                        amount: 25_000_000, amountTone: .signedIncome)
                    .overlay(alignment: .top) { RowDivider() }
            }
            .cardSurface(color: Palette.card, elevated: true)

            SampleCard(label: "Số tiền · MoneyText") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    MoneyText(amount: 192_090_000, size: .display)
                    MoneyText(amount: 14_119_000, size: .large)
                    HStack(spacing: Spacing.l) {
                        MoneyText(amount: 500_000, tone: .signedIncome)
                        MoneyText(amount: 60_000, tone: .signedExpense)
                        MoneyText(amount: -6_430_000, tone: .negativeRed, compact: true)
                    }
                }
            }

            SampleCard(label: "Avatar · icon tròn") {
                HStack(spacing: Spacing.m) {
                    InitialsAvatar(name: "Minh")
                    InitialsAvatar(name: "Hùng")
                    IconCircle(icon: "solar-card-linear")
                    AssistantAvatar()
                }
            }
        }
    }
}
