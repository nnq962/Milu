import SwiftUI

enum LoanFilter: String, CaseIterable, Identifiable {
    case all, lent, borrowed, settled

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Tất cả"
        case .lent: "Cho vay"
        case .borrowed: "Đi vay"
        case .settled: "Đã tất toán"
        }
    }
}

/// "Vay nợ" tab of the Transactions screen.
struct LoansContent: View {
    @Environment(FinanceStore.self) private var store
    @Binding var filter: LoanFilter
    let searchText: String
    let onEdit: (Loan) -> Void

    private func matchesSearch(_ name: String) -> Bool {
        searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
    }

    private var activeLoans: [Loan] {
        store.loans.filter { !$0.isSettled && matchesSearch($0.name) }
    }

    private var lentLoans: [Loan] { activeLoans.filter { $0.direction == .lent } }
    private var borrowedLoans: [Loan] { activeLoans.filter { $0.direction == .borrowed } }
    private var settledLoans: [Loan] { store.loans.filter { $0.isSettled && matchesSearch($0.name) } }

    /// Credit cards carrying a balance are shown as borrowing.
    private var cardDebts: [Account] {
        store.accounts.filter { $0.type == .credit && $0.balance < 0 && matchesSearch($0.name) }
    }

    var body: some View {
        summaryCard
        ChipRow(options: LoanFilter.allCases, selection: $filter) { $0.title }
        switch filter {
        case .all:
            attentionSection
            lentSection
            borrowedSection
        case .lent:
            lentSection
        case .borrowed:
            borrowedSection
        case .settled:
            settledSection
        }
    }

    // MARK: - Tổng quan

    private var summaryCard: some View {
        let net = store.totalLent - store.totalDebt
        let lenders = store.loans.filter { $0.direction == .lent && !$0.isSettled }.count
        let debts = store.accounts.filter { $0.type == .credit && $0.balance < 0 }.count
            + store.loans.filter { $0.direction == .borrowed && !$0.isSettled }.count
        return VStack(alignment: .leading, spacing: 4) {
            Text("Tổng cho vay trừ nợ")
                .font(Typography.font(.caption, size: 12, weight: .medium))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16, relativeTo: .caption)
            Text(net.vnd)
                .font(Typography.font(.largeTitle, size: 34, weight: .heavy))
                .designLineHeight(42.5, relativeTo: .largeTitle)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            Text(net < 0 ? "Đang ở mức âm: bạn nợ nhiều hơn số đang cho vay"
                 : net > 0 ? "Đang ở mức dương: số đang cho vay nhiều hơn số bạn nợ"
                 : "Số đang cho vay bằng số bạn đang nợ")
                .font(Typography.font(.caption2, size: 11))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16.5, relativeTo: .caption2)
            HStack(spacing: 12) {
                summaryTile("Đang cho vay", amount: store.totalLent.vndCompact, detail: "\(lenders) người",
                            color: Palette.ink, background: Palette.incomeTile)
                summaryTile("Đang nợ", amount: store.totalDebt.vndCompact, detail: "\(debts) khoản",
                            color: Palette.red, background: Palette.muted)
            }
            .padding(.top, 12)
        }
        .sleekCard()
    }

    private func summaryTile(_ title: String, amount: String, detail: String, color: Color, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Typography.font(.caption2, size: 11, weight: .medium))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16.5, relativeTo: .caption2)
            Text(amount)
                .font(Typography.font(.callout, size: 16, weight: .bold))
                .foregroundStyle(color)
                .designLineHeight(24, relativeTo: .callout)
                .monospacedDigit()
            Text(detail)
                .font(Typography.font(.caption2, size: 11))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16.5, relativeTo: .caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .cardSurface(radius: CardCorners.flow, color: background)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Cần chú ý

    @ViewBuilder
    private var attentionSection: some View {
        let reminders = store.paymentReminders
            .filter { matchesSearch($0.title) || matchesSearch($0.detail) }
            .sorted { $0.dueDate < $1.dueDate }
        if !reminders.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Cần chú ý") {
                    Text("\(reminders.count) sắp đến hạn")
                        .font(Typography.font(.caption2, size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Palette.muted, in: Capsule())
                }
                ForEach(reminders) { reminder in
                    HStack(spacing: 12) {
                        switch reminder.avatar {
                        case .initials(let name): InitialsAvatar(name: name)
                        case .icon(let icon): IconCircle(icon: icon)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(reminder.title)
                                .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                                .designLineHeight(20, relativeTo: .subheadline)
                                .lineLimit(1)
                            Text(reminder.detail)
                                .font(Typography.font(.caption2, size: 11))
                                .foregroundStyle(Palette.secondaryText)
                                .designLineHeight(16.5, relativeTo: .caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(reminder.isIncome ? "+" : "-")\(reminder.amount.vnd)")
                                .font(Typography.font(.subheadline, size: 14, weight: .bold))
                                .foregroundStyle(reminder.isIncome ? Palette.ink : Palette.red)
                                .designLineHeight(20, relativeTo: .subheadline)
                                .monospacedDigit()
                            Text("Hạn \(reminder.dueDate.dayMonth)")
                                .font(Typography.font(.caption2, size: 11))
                                .foregroundStyle(Palette.secondaryText)
                                .designLineHeight(16.5, relativeTo: .caption2)
                        }
                    }
                    .padding(17)
                    // Bordered, shadowless card; the 1pt border sits inside like CSS.
                    .background {
                        RoundedRectangle(cornerRadius: CardCorners.large, style: .continuous)
                            .fill(Palette.card)
                            .strokeBorder(Palette.border, lineWidth: 1)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: - Cho vay / Đi vay / Đã tất toán

    private var lentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Cho vay") { remainingLabel(lentLoans.reduce(0) { $0 + $1.outstanding }) }
            if lentLoans.isEmpty {
                EmptyStateCard(icon: "solar-hand-money-linear", title: "Chưa có khoản cho vay",
                               message: "Nhấn + để ghi lại số tiền bạn cho người khác vay.")
            }
            ForEach(lentLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.plain)
            }
        }
    }

    private var borrowedSection: some View {
        let total = cardDebts.reduce(0) { $0 - $1.balance } + borrowedLoans.reduce(0) { $0 + $1.outstanding }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Đi vay") { remainingLabel(total) }
            if cardDebts.isEmpty && borrowedLoans.isEmpty {
                EmptyStateCard(icon: "solar-card-linear", title: "Chưa có khoản đi vay",
                               message: "Dư nợ thẻ tín dụng và các khoản bạn vay sẽ hiện ở đây.")
            }
            ForEach(cardDebts) { card in
                NavigationLink(value: card.id) { CreditCardDebtCard(card: card) }
                    .buttonStyle(.plain)
            }
            ForEach(borrowedLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.plain)
            }
        }
    }

    private var settledSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Đã tất toán")
            if settledLoans.isEmpty {
                EmptyStateCard(icon: "solar-check-read-linear", title: "Chưa có khoản nào tất toán",
                               message: "Khoản vay đã thu hoặc trả đủ sẽ được lưu ở đây.")
            }
            ForEach(settledLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func remainingLabel(_ amount: Double) -> some View {
        Text("Còn \(amount.vndCompact)")
            .font(Typography.font(.caption2, size: 11, weight: .semibold))
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
    }
}

#Preview("Sửa khoản vay") {
    LoanEditorView(loan: SampleData.loans[0])
        .environment(FinanceStore())
}
