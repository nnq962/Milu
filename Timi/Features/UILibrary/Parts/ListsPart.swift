import SwiftUI

struct ListsPart: View {
    @Environment(FinanceStore.self) private var store

    private static let accounts: [Account] = [
        Account(name: "Ví tiền mặt", type: .cash, balance: 2_350_000),
        Account(name: "Vietcombank", type: .bank, balance: 45_800_000, institutionID: "vietcombank"),
        Account(name: "Quỹ dự phòng", type: .bank, balance: 20_000_000, isLocked: true),
    ]

    var body: some View {
        PartSection(part: .lists) {
            // A list of rows sits on `listCard` (corners 24), its hairlines from where the words start.
            SampleList(label: "Dòng · ListRow") {
                ListRow(icon: "hugeicons-restaurant-01", title: "Cà phê buổi sáng", subtitle: "Ăn uống",
                        trailingSubtitle: "08:30", amount: 45_000, amountTone: .signedExpense)
                ListRow(icon: "hugeicons-money-bag-02", title: "Lương tháng 10", subtitle: "Thu nhập",
                        trailingSubtitle: "09:00", amount: 25_000_000, amountTone: .signedIncome)
                    .overlay(alignment: .top) { RowDivider() }
            }

            // The one way to draw an account in any list.
            SampleList(label: "Tài khoản · AccountRow") {
                ForEach(Array(Self.accounts.enumerated()), id: \.element.id) { index, account in
                    AccountRow(account: account)
                        .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                }
            }

            // Goals and loans: the logo column too, so the three lists line up.
            if !store.activeGoals.isEmpty {
                SampleList(label: "Hũ · GoalRow") {
                    ForEach(Array(store.activeGoals.prefix(2).enumerated()), id: \.element.id) { index, goal in
                        GoalRow(goal: goal)
                            .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                    }
                }
            }
            if !store.loans.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.headerGap) {
                    SectionHeader(title: "Khoản vay · LoanRowList", style: .group)
                    LoanRowList(loans: Array(store.loans.prefix(2))) { _ in }
                }
            }

            // Where the hairline starts: under the title after an icon, after a 32 logo, avatar or
            // ring, or at the row's margin with no icon. It grows with the text as the icons do.
            SampleList(label: "Vạch kẻ · RowDivider(column:)") {
                dividerSample(".icon · ListRow, form", column: .icon)
                dividerSample(".logo · AccountRow, GoalRow, LoanRow, danh bạ", column: .logo)
                dividerSample(".none · dòng không icon", column: .none)
            }

            SummaryCard(label: "Tổng số dư · SummaryCard", amount: 68_150_000, icon: "hugeicons-wallet-01") {
                ProgressBar(value: 0.62)
                    .padding(.top, Spacing.l)
            }

            SampleCard(label: "Số tiền · MoneyText") {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    MoneyText(amount: 192_090_000, size: .display)
                    MoneyText(amount: 14_119_000, size: .large)
                    moneyLine(".signedIncome · tiền vào", MoneyText(amount: 500_000, tone: .signedIncome))
                    moneyLine(".signedExpense · tiền ra", MoneyText(amount: 60_000, tone: .signedExpense))
                    moneyLine(".signedNet · dư ra", MoneyText(amount: 1_250_000, tone: .signedNet))
                    moneyLine(".signedNet · thiếu", MoneyText(amount: -340_000, tone: .signedNet))
                    moneyLine(".negativeRed · số dư âm", MoneyText(amount: -6_430_000, tone: .negativeRed, compact: true))
                    moneyLine(".muted · không tính", MoneyText(amount: 20_000_000, tone: .muted, compact: true))
                    moneyLine(".plain · chuyển giữa tài khoản", MoneyText(amount: 2_000_000))
                }
            }

            SampleCard(label: "Hai cột · SplitTotals") {
                SplitTotals(items: [
                    .init("Đã chi", amount: 8_400_000, tone: .signedExpense),
                    .init("Đã thu", amount: 25_000_000, tone: .signedIncome),
                ]) { item in
                    Text(item.title == "Đã chi" ? "↑ 12% · cùng kỳ" : "Như cùng kỳ")
                        .textRole(.caption)
                        .foregroundStyle(item.title == "Đã chi" ? Palette.negative : Palette.secondaryLabel)
                }
            }

            SampleCard(label: "Thanh chia phần · SegmentedBar, LegendRow") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    SegmentedBar(segments: [
                        .init(id: "a", color: ChartShades.color(at: 0), amount: 4_200_000),
                        .init(id: "b", color: ChartShades.color(at: 1), amount: 2_100_000),
                        .init(id: "c", color: ChartShades.color(at: 2), amount: 900_000),
                        .init(id: "d", color: ChartShades.rest, amount: 600_000),
                    ], whole: 12_000_000)
                    LegendRow(items: [
                        .init(id: "a", color: ChartShades.color(at: 0), text: "Ăn uống"),
                        .init(id: "b", color: ChartShades.color(at: 1), text: "Đi lại"),
                        .init(id: "c", color: ChartShades.color(at: 2), text: "Nhà ở"),
                        .init(id: "d", color: ChartShades.rest, text: "Khác"),
                    ])
                }
            }

            SampleCard(label: "Dấu nhỏ · RowChevron") {
                HStack(spacing: Spacing.s) {
                    Text("Mở thêm").textRole(.body)
                    Spacer()
                    RowChevron()
                }
            }

            // The app's one short date: no year this year, the year in another.
            SampleCard(label: "Ngày ngắn · Date.shortDay") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    dateLine("Năm nay", Date.now)
                    dateLine("Năm khác", Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now)
                }
            }

            SampleCard(label: "Logo ngân hàng & ví · \(Institution.banks.count) + \(Institution.eWallets.count)") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 8),
                          spacing: Spacing.s) {
                    ForEach(Institution.all) { institution in
                        InstitutionLogo(image: institution.logoImage, size: RowMetrics.listLogo)
                            .accessibilityLabel(institution.shortName)
                    }
                }
            }

            SampleCard(label: "Avatar · InitialsAvatar") {
                HStack(spacing: Spacing.m) {
                    InitialsAvatar(name: "Minh")
                    InitialsAvatar(name: "Hùng", size: RowMetrics.listLogo)
                    AssistantAvatar()
                }
            }
        }
    }

    private func dividerSample(_ title: String, column: RowDivider.Column) -> some View {
        Text(title)
            .textRole(.caption)
            .foregroundStyle(Palette.secondaryLabel)
            .frame(maxWidth: .infinity, minHeight: RowMetrics.minHeight, alignment: .leading)
            .padding(.horizontal, RowMetrics.horizontal)
            .overlay(alignment: .bottom) { RowDivider(column: column) }
    }

    private func dateLine(_ title: String, _ date: Date) -> some View {
        HStack {
            Text(title).textRole(.body)
            Spacer(minLength: Spacing.s)
            Text(date.shortDay).textRole(.body).monospacedDigit().foregroundStyle(Palette.secondaryLabel)
        }
    }

    private func moneyLine(_ title: String, _ amount: MoneyText) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Text(title)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryLabel)
            Spacer(minLength: Spacing.s)
            amount
        }
    }

}
