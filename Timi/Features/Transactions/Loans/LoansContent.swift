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
    /// Searching shows only what matches: no total card, no chips, only the sections with a match;
    /// nothing typed yet, a hint (as the search of "Thu chi").
    var isSearching = false
    let onEdit: (Loan) -> Void

    /// Every word found in the name, accents and stray spaces aside ("chi lan" finds "Chị Lan"),
    /// as the search of "Thu chi" does.
    private func matchesSearch(_ name: String) -> Bool {
        let words = searchText.searchKey.split(separator: " ")
        guard !words.isEmpty else { return true }
        let key = name.searchKey
        return words.allSatisfy { key.contains($0) }
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
        if isSearching && searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            Text("Tìm theo tên người cho vay, người vay hoặc thẻ tín dụng.")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
                .padding(.horizontal, RowMetrics.horizontal)
        } else if isSearching {
            // Only the sections with a match: their empty cards are for a first visit (one even
            // points at a + the search does not have). Nothing at all: one "Không tìm thấy".
            if reminders.isEmpty && lentLoans.isEmpty && cardDebts.isEmpty && borrowedLoans.isEmpty
                && settledLoans.isEmpty {
                EmptyStateCard(icon: "hugeicons-search-01", title: "Không tìm thấy",
                               message: "Không có khoản vay nào khớp với “\(searchText.trimmingCharacters(in: .whitespaces))”.")
            } else {
                attentionSection
                if !lentLoans.isEmpty { lentSection }
                if !cardDebts.isEmpty || !borrowedLoans.isEmpty { borrowedSection }
                if !settledLoans.isEmpty { settledSection }
            }
        } else {
            summaryCard
            ChipRow(options: LoanFilter.allCases, selection: $filter) { $0.title }
            sections
        }
    }

    @ViewBuilder
    private var sections: some View {
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
        // The tab's lead card, the same `SummaryCard` as "Tổng số dư" on Tài khoản.
        return SummaryCard(label: "Tổng cho vay trừ nợ", amount: net, tone: .plain) {
            Text(net < 0 ? "Đang ở mức âm: bạn nợ nhiều hơn số đang cho vay"
                 : net > 0 ? "Đang ở mức dương: số đang cho vay nhiều hơn số bạn nợ"
                 : "Số đang cho vay bằng số bạn đang nợ")
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
                .padding(.top, Spacing.xs)
            HStack(spacing: Spacing.m) {
                summaryTile("Đang cho vay", amount: store.totalLent.vndCompact, detail: "\(lenders) người",
                            color: Palette.ink, background: Palette.incomeTile)
                summaryTile("Đang nợ", amount: store.totalDebt.vndCompact, detail: "\(debts) khoản",
                            color: Palette.red, background: Palette.muted)
            }
            .padding(.top, Spacing.m)
        }
    }

    private func summaryTile(_ title: String, amount: String, detail: String, color: Color, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .textRole(.captionStrong)
                .foregroundStyle(Palette.secondaryText)
            Text(amount)
                .textRole(.bodyStrong)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(detail)
                .textRole(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .cardSurface(radius: CardCorners.flow, color: background)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Cần chú ý

    private var reminders: [PaymentReminder] {
        store.paymentReminders
            .filter { matchesSearch($0.title) || matchesSearch($0.detail) }
            .sorted { $0.dueDate < $1.dueDate }
    }

    @ViewBuilder
    private var attentionSection: some View {
        let reminders = reminders
        if !reminders.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.m) {
                SectionHeader(title: "Cần chú ý") {
                    StatusBadge(text: "\(reminders.count) sắp đến hạn", tone: .warning)
                }
                .padding(.bottom, Spacing.headerGap - Spacing.m)
                ForEach(reminders) { reminder in
                    HStack(spacing: 12) {
                        switch reminder.avatar {
                        case .initials(let name): InitialsAvatar(name: name)
                        case .icon(let icon): IconCircle(icon: icon)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(reminder.title)
                                .textRole(.body)
                                .lineLimit(1)
                            Text(reminder.detail)
                                .textRole(.caption)
                                .foregroundStyle(Palette.secondaryText)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(reminder.isIncome ? "+" : "-")\(reminder.amount.vnd)")
                                .textRole(.amount)
                                .foregroundStyle(reminder.isIncome ? Palette.ink : Palette.red)
                                .monospacedDigit()
                            Text("Hạn \(reminder.dueDate.dayMonth)")
                                .textRole(.caption)
                                .foregroundStyle(Palette.secondaryText)
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
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader(title: "Cho vay") { remainingLabel(lentLoans.reduce(0) { $0 + $1.outstanding }) }
                .padding(.bottom, Spacing.headerGap - Spacing.m)
            if lentLoans.isEmpty {
                EmptyStateCard(icon: "hugeicons-hand-coins", title: "Chưa có khoản cho vay",
                               message: "Nhấn + để ghi lại số tiền bạn cho người khác vay.")
            }
            ForEach(lentLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.card)
            }
        }
    }

    private var borrowedSection: some View {
        let total = cardDebts.reduce(0) { $0 - $1.balance } + borrowedLoans.reduce(0) { $0 + $1.outstanding }
        return VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader(title: "Đi vay") { remainingLabel(total) }
                .padding(.bottom, Spacing.headerGap - Spacing.m)
            if cardDebts.isEmpty && borrowedLoans.isEmpty {
                EmptyStateCard(icon: "hugeicons-credit-card", title: "Chưa có khoản đi vay",
                               message: "Dư nợ thẻ tín dụng và các khoản bạn vay sẽ hiện ở đây.")
            }
            ForEach(cardDebts) { card in
                NavigationLink(value: card.id) { CreditCardDebtCard(card: card) }
                    .buttonStyle(.card)
            }
            ForEach(borrowedLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.card)
            }
        }
    }

    private var settledSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader(title: "Đã tất toán")
                .padding(.bottom, Spacing.headerGap - Spacing.m)
            if settledLoans.isEmpty {
                EmptyStateCard(icon: "hugeicons-checkmark-circle-02", title: "Chưa có khoản nào tất toán",
                               message: "Khoản vay đã thu hoặc trả đủ sẽ được lưu ở đây.")
            }
            ForEach(settledLoans) { loan in
                Button { onEdit(loan) } label: { LoanCard(loan: loan) }
                    .buttonStyle(.card)
            }
        }
    }

    private func remainingLabel(_ amount: Double) -> some View {
        Text("Còn \(amount.vndCompact)")
            .textRole(.captionStrong)
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
    }
}

#Preview("Sửa khoản vay") {
    LoanEditorView(loan: SampleData.loans[0])
        .environment(FinanceStore())
}
