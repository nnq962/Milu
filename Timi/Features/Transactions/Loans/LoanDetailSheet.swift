import SwiftUI

/// What opens for a tapped loan (user request 2026-10-29): what is left on top with the deadline
/// badge and progress, "Ghi nhận thu nợ / trả nợ", the interest (each month, this month, in all),
/// the details, then every repayment (tap one to change or delete it). The pencil opens the form.
struct LoanDetailSheet: View {
    let loanID: Loan.ID

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
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
            DetailScaffold(title: loan?.name ?? "Khoản vay", showsClose: true, canEdit: loan != nil,
                           onEdit: { isEditing = true }) {
                if let loan {
                    summary(loan)
                    if !loan.isSettled {
                        FormGroup {
                            FormActionRow(title: loan.direction == .lent ? "Ghi nhận thu nợ" : "Ghi nhận trả nợ",
                                          icon: "hugeicons-add-01") { paying = .new }
                        }
                    }
                    if loan.monthlyInterestRate > 0 || store.payments(of: loan).contains(where: { $0.interest > 0 }) {
                        interest(loan)
                    }
                    details(loan)
                    history(loan)
                } else {
                    EmptyStateCard(icon: "hugeicons-inbox", title: "Khoản vay đã bị xoá",
                                   message: "Khoản vay này không còn trong danh sách.")
                }
            }
            .sheet(isPresented: $isEditing, onDismiss: {
                if store.loan(id: loanID) == nil { dismiss() }
            }) {
                if let loan = store.loan(id: loanID) { LoanEditorView(loan: loan) }
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
        let urgency = LoanUrgency(loan)
        let lent = loan.direction == .lent
        return SummaryCard(label: lent ? "Còn phải thu" : "Còn phải trả", amount: loan.outstanding,
                           icon: lent ? "hugeicons-hand-coins" : "hugeicons-money-receive-02", tone: .plain) {
            StatusBadge(text: urgency.text, tone: urgency.tone)
                .padding(.top, Spacing.s)
            ProgressBar(value: loan.paidRatio, color: LoanCard.progressColor(for: loan, urgency: urgency))
                .padding(.top, Spacing.l)
            HStack {
                Text(loan.isSettled ? "Đã trả đủ" : loan.paidRatio > 0 ? "Đã trả \(loan.paidRatio.percentText)" : "Chưa trả")
                Spacer()
                Text("Gốc \(loan.principal.vnd)")
            }
            .textRole(.captionStrong)
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
            .padding(.top, Spacing.s)
        }
    }

    /// Each month's interest, whether this month's came in (or went out), and all of it so far.
    private func interest(_ loan: Loan) -> some View {
        let lent = loan.direction == .lent
        let paid = store.payments(of: loan).reduce(0) { $0 + $1.interest }
        return FormGroup(title: "Lãi") {
            if loan.monthlyInterestRate > 0 {
                FormInfoRow(title: "Mỗi tháng",
                            value: "\(loan.monthlyInterest.vnd) (\(LoanEditorView.percent(loan.monthlyInterestRate))%)")
                FormDivider(hasIcon: false)
                if store.owesInterest(loan) {
                    FormInfoRow(title: "Tháng này",
                                value: store.hasPaidInterest(loan) ? (lent ? "Đã thu" : "Đã trả") : (lent ? "Chưa thu" : "Chưa trả"))
                    FormDivider(hasIcon: false)
                }
            }
            FormInfoRow(title: lent ? "Đã thu tổng cộng" : "Đã trả tổng cộng", value: paid.vnd)
        }
    }

    private func details(_ loan: Loan) -> some View {
        let lent = loan.direction == .lent
        return FormGroup(title: "Chi tiết") {
            FormInfoRow(title: lent ? "Người vay" : "Người cho vay", value: loan.name)
            FormDivider(hasIcon: false)
            if let id = loan.movedAccountID {
                FormInfoRow(title: lent ? "Chi từ" : "Nhận vào", value: store.account(id: id)?.name ?? "Tài khoản đã xoá",
                            valueIcon: store.account(id: id)?.iconName)
                FormDivider(hasIcon: false)
                FormInfoRow(title: lent ? "Ngày cho vay" : "Ngày vay", value: day(loan.date))
            } else {
                FormInfoRow(title: "Loại", value: "Khoản có sẵn")
            }
            FormDivider(hasIcon: false)
            FormInfoRow(title: "Hạn trả", value: loan.dueDate.map(day) ?? "Không có hạn")
        }
    }

    /// Every repayment, newest first: tap one to change or delete it.
    @ViewBuilder
    private func history(_ loan: Loan) -> some View {
        let payments = store.payments(of: loan)
        let lent = loan.direction == .lent
        FormGroup(title: lent ? "Lịch sử thu nợ" : "Lịch sử trả nợ",
                  footer: payments.isEmpty ? (lent ? "Chưa có lần thu nào." : "Chưa có lần trả nào.") : nil) {
            ForEach(Array(payments.enumerated()), id: \.element.id) { index, payment in
                Button { paying = .edit(payment) } label: {
                    ListRow(icon: lent ? "hugeicons-money-receive-02" : "hugeicons-money-send-02",
                            title: lent ? "Thu nợ" : "Trả nợ", subtitle: breakdown(payment),
                            trailingSubtitle: TransactionListRow.dayMonth(payment.date),
                            amount: lent ? payment.total : -payment.total,
                            amountTone: lent ? .signedIncome : .plain, showsChevron: false)
                }
                .buttonStyle(.row)
                .overlay(alignment: .top) { if index > 0 { RowDivider() } }
            }
        }
    }

    /// "Gốc 5tr · Lãi 375k · Vietcombank".
    private func breakdown(_ payment: LoanPayment) -> String {
        var parts: [String] = []
        if payment.principal > 0 { parts.append("Gốc \(payment.principal.vndCompact)") }
        if payment.interest > 0 { parts.append("Lãi \(payment.interest.vndCompact)") }
        parts.append(store.account(id: payment.accountID)?.name ?? "Tài khoản đã xoá")
        return parts.joined(separator: " · ")
    }

    private func day(_ date: Date) -> String {
        date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(.vietnam))
    }
}
