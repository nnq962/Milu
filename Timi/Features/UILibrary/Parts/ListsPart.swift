import SwiftUI

struct ListsPart: View {
    var body: some View {
        PartSection(part: .lists) {
            VStack(spacing: 0) {
                ListRow(icon: "hugeicons-money-02", title: "Ví tiền mặt", subtitle: "Cập nhật hôm nay", amount: 2_350_000)
                ListRow(icon: "Institutions/vietcombank", title: "Vietcombank", subtitle: "Logo ngân hàng giữ cột icon 24pt",
                        amount: 45_800_000)
                    .overlay(alignment: .top) { RowDivider() }
                ListRow(icon: "hugeicons-restaurant-01", title: "Cà phê buổi sáng", subtitle: "Ăn uống · 08:30",
                        amount: 45_000, amountTone: .signedExpense)
                    .overlay(alignment: .top) { RowDivider() }
                ListRow(icon: "hugeicons-money-bag-02", title: "Lương tháng 10", subtitle: "Thu nhập · 09:00",
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

            SampleCard(label: "Logo ngân hàng & ví · \(Institution.banks.count) + \(Institution.eWallets.count)") {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 8),
                              spacing: Spacing.s) {
                        ForEach(Institution.all) { institution in
                            InstitutionLogo(image: institution.logoImage, size: 32)
                                .accessibilityLabel(institution.shortName)
                        }
                    }
                    Text("Màu gốc của thương hiệu, trên nền trắng có viền mảnh. Chọn khi Thêm tài khoản (Ngân hàng / Ví điện tử).")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            }

            SampleCard(label: "Avatar · icon tròn") {
                HStack(spacing: Spacing.m) {
                    InitialsAvatar(name: "Minh")
                    InitialsAvatar(name: "Hùng")
                    IconCircle(icon: "hugeicons-credit-card")
                    AssistantAvatar()
                }
            }
        }
    }
}
