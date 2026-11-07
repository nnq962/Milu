import SwiftUI

/// What opens for a tapped loan (user request 2026-10-29): what is left on top with the deadline
/// badge and progress, "Ghi nhận thu nợ / trả nợ", the interest (each month, this month, in all),
/// the details, then every repayment (tap one to change or delete it). The pencil opens the form.
struct LoanDetailSheet: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let loanID: Loan.ID
    /// The page's day, so the badge agrees with the card just after midnight.
    var today = Date.now

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// The loan the form opened on, kept so deleting it does not empty the form as it slides away.
    @State private var editingLoan: Loan?
    @State private var paying: PaymentTarget?

    /// A new repayment, or one to change.
    private enum PaymentTarget: Identifiable {
        case new
        case edit(LoanPayment)

        var id: String {
            switch self {
            case .new: "new"
            case .edit(let payment): payment.id.uuidString
            }
        }
    }

    var body: some View {
        let loan = store.loan(id: loanID)
        NavigationStack {
            // Money on an archived account is frozen: the form keeps who, when and the rate.
            SheetPage(title: loan?.name ?? "Khoản vay", showsClose: true, canEdit: loan != nil,
                           onEdit: { editingLoan = store.loan(id: loanID) }) {
                if let loan {
                    summary(loan)
                    if !loan.isSettled {
                        FormGroup {
                            FormActionRow(title: loan.direction == .lent ? "Ghi nhận thu nợ" : "Ghi nhận trả nợ",
                                          icon: "hugeicons-add-01") { paying = .new }
                        }
                    } else if loan.monthlyInterestRate > 0, store.readOnlyReason(loan) == nil {
                        // Settled, with interest: the last months' interest can still come in late.
                        FormGroup {
                            FormActionRow(title: loan.direction == .lent ? "Ghi nhận thu lãi" : "Ghi nhận trả lãi",
                                          icon: "hugeicons-add-01") { paying = .new }
                        }
                    }
                    // Settled with no interest recorded: nothing worth a group.
                    if (loan.monthlyInterestRate > 0 && !loan.isSettled)
                        || store.payments(of: loan).contains(where: { $0.interest > 0 }) {
                        interest(loan)
                    }
                    details(loan)
                    history(loan)
                } else {
                    EmptyStateCard(icon: "hugeicons-inbox", title: "Khoản vay đã bị xoá",
                                   message: "Khoản vay này không còn trong danh sách.")
                }
            }
            // Gone some other way while open: close. (Its form closes this sheet itself before
            // deleting, `recordSheetDismiss`.)
            .onChange(of: store.loan(id: loanID) == nil) { _, gone in if gone { dismiss() } }
            .sheet(item: $editingLoan) { loan in
                LoanEditorView(loan: loan)
                    // Deleting there closes this sheet too, before the loan goes.
                    .environment(\.recordSheetDismiss, dismiss)
            }
            .sheet(item: $paying) { target in
                if let loan = store.loan(id: loanID) {
                    switch target {
                    case .new:
                        LoanPaymentSheet(loan: loan, suggestedInterest: store.owesInterest(loan) && !store.hasPaidInterest(loan)
                                         ? loan.monthlyInterest : 0)
                    case .edit(let payment):
                        LoanPaymentSheet(loan: loan, editing: payment)
                    }
                }
            }
        }
        .timiSheetStyle()
    }

    private func summary(_ loan: Loan) -> some View {
        let urgency = LoanUrgency(loan, today: today)
        let lent = loan.direction == .lent
        // Settled: what was repaid, the principal the row shows, not a big "0 đ" (re-review
        // 2026-10-31). Open: what is left, in the row's colour (red with "-" while I owe it).
        let label = loan.isSettled ? (lent ? "Đã thu đủ" : "Đã trả đủ") : (lent ? "Còn phải thu" : "Còn phải trả")
        return SummaryCard(title: label, amount: loan.isSettled ? loan.principal : loan.outstanding,
                           icon: lent ? "hugeicons-hand-coins" : "hugeicons-money-receive-02",
                           tone: LoanRow.amountTone(loan)) {
            StatusBadge(title: urgency.text, tone: urgency.tone)
                .padding(.top, Spacing.s)
            ProgressBar(value: loan.paidRatio, color: LoanRow.progressColor(for: loan, urgency: urgency))
                .padding(.top, Spacing.l)
            // How much is repaid and of what; settled, the label and the amount already say both.
            // Stacked at the accessibility text sizes, as on a goal's screen.
            if !loan.isSettled {
                AdaptiveStack(spacing: Spacing.s) {
                    Text(loan.paidText)
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryLabel)
                    if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                    // The amount by MoneyText, grey as the line it sits on (re-review 2026-10-31).
                    HStack(spacing: Spacing.xs) {
                        Text("Gốc")
                            .textRole(.captionStrong)
                            .foregroundStyle(Palette.secondaryLabel)
                        MoneyText(amount: loan.principal, size: .caption, tone: .muted)
                    }
                    .accessibilityElement(children: .combine)
                }
                .padding(.top, Spacing.s)
            }
        }
    }

    /// Each month's interest, whether this month's came in (or went out), and all of it so far.
    private func interest(_ loan: Loan) -> some View {
        let lent = loan.direction == .lent
        let paid = store.payments(of: loan).reduce(0) { $0 + $1.interest }
        return FormGroup(title: "Lãi") {
            // Settled: what came in is what matters, not what each month would be.
            if loan.monthlyInterestRate > 0, !loan.isSettled {
                FormAmountInfoRow(title: "Mỗi tháng (\(LoanEditorView.percent(loan.monthlyInterestRate))%)",
                                  amount: loan.monthlyInterest)
                FormDivider(hasIcon: false)
                if store.owesInterest(loan) {
                    FormInfoRow(title: "Tháng này",
                                value: store.hasPaidInterest(loan) ? (lent ? "Đã thu" : "Đã trả") : (lent ? "Chưa thu" : "Chưa trả"))
                    FormDivider(hasIcon: false)
                }
            }
            // In or out as on the history rows; nothing yet, a plain 0.
            FormAmountInfoRow(title: lent ? "Đã thu tổng cộng" : "Đã trả tổng cộng", amount: paid,
                              tone: paid == 0 ? .neutral : lent ? .signedIncome : .signedExpense)
        }
    }

    private func details(_ loan: Loan) -> some View {
        let lent = loan.direction == .lent
        return FormGroup(title: "Chi tiết") {
            if let id = loan.movedAccountID {
                FormInfoRow(title: lent ? "Chi từ" : "Nhận vào", value: store.account(id: id)?.name ?? "Tài khoản đã xoá",
                            valueIcon: store.account(id: id)?.iconName)
                FormDivider(hasIcon: false)
                FormInfoRow(title: lent ? "Ngày cho vay" : "Ngày vay", value: loan.date.shortDay)
            } else {
                FormInfoRow(title: "Loại", value: "Khoản có sẵn")
            }
            // No deadline: the badge on top already says "Không có hạn" (re-review 2026-10-31).
            if let due = loan.dueDate {
                FormDivider(hasIcon: false)
                FormInfoRow(title: "Hạn trả", value: due.shortDay)
            }
        }
    }

    /// Every repayment, newest first: tap one to change or delete it. A loan that was there before
    /// Timi may have been partly repaid already: that part closes the list as a row of its own, so
    /// "Đã trả 40%" is not over "Chưa có lần thu nào" (review 2026-10-31). Nothing at all: the
    /// empty card every other history uses.
    @ViewBuilder
    private func history(_ loan: Loan) -> some View {
        let payments = store.payments(of: loan)
        let lent = loan.direction == .lent
        let title = lent ? "Lịch sử thu nợ" : "Lịch sử trả nợ"
        let earlier = Self.repaidBeforeTimi(loan, payments: payments)
        if payments.isEmpty && earlier == 0 {
            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                SectionHeader(title: title, style: .group)
                EmptyStateCard(icon: lent ? "hugeicons-money-receive-02" : "hugeicons-money-send-02",
                               title: lent ? "Chưa có lần thu nào" : "Chưa có lần trả nào",
                               message: lent ? "Các lần thu nợ sẽ hiện ở đây." : "Các lần trả nợ sẽ hiện ở đây.",
                               picture: IconCatalog.emojiName("📝"))
                if let reason = store.readOnlyReason(loan) { FormFooter(message: reason) }
            }
        } else {
            FormGroup(title: title, footer: store.readOnlyReason(loan)) {
                ForEach(Array(payments.enumerated()), id: \.element.id) { index, payment in
                    Button { paying = .edit(payment) } label: {
                        ListRow(icon: lent ? "hugeicons-money-receive-02" : "hugeicons-money-send-02",
                                title: lent ? "Thu nợ" : "Trả nợ", subtitle: breakdown(payment),
                                trailingSubtitle: payment.date.shortDay,
                                // A repayment on what I borrowed is money out: ink "-", as in the
                                // account's history and on Giao dịch (review 2026-11-06, "B+").
                                amount: payment.total,
                                amountTone: lent ? .signedIncome : .outflow, showsChevron: false)
                    }
                    .buttonStyle(.row)
                    // On an archived account: shown, not changed (the footer says why).
                    .disabled(store.readOnlyReason(payment) != nil)
                    // Under the titles, the icon column scaled with the text as the rows' icons.
                    .overlay(alignment: .top) { if index > 0 { RowDivider(column: .icon) } }
                }
                if earlier > 0 {
                    // Not a repayment of the app's: no account, no date, nothing to open.
                    ListRow(icon: "hugeicons-checkmark-circle-02",
                            title: lent ? "Đã thu trước đó" : "Đã trả trước đó",
                            subtitle: "Trước khi ghi vào Timi",
                            amount: earlier, amountTone: .neutral, showsChevron: false)
                        .overlay(alignment: .top) { if !payments.isEmpty { RowDivider(column: .icon) } }
                }
            }
        }
    }

    /// What of an existing loan's principal was repaid before it was recorded: the principal less
    /// what is still owed and less the repayments recorded since.
    static func repaidBeforeTimi(_ loan: Loan, payments: [LoanPayment]) -> Double {
        guard loan.isExisting else { return 0 }
        return max(loan.principal - loan.outstanding - payments.reduce(0) { $0 + $1.principal }, 0)
    }

    /// "Gốc 5tr · Lãi 375k · Vietcombank".
    private func breakdown(_ payment: LoanPayment) -> String {
        var parts: [String] = []
        if payment.principal > 0 { parts.append("Gốc \(payment.principal.vnd)") }
        if payment.interest > 0 { parts.append("Lãi \(payment.interest.vnd)") }
        parts.append(store.account(id: payment.accountID)?.name ?? "Tài khoản đã xoá")
        return parts.joined(separator: " · ")
    }
}
