import SwiftUI

/// "Thu nợ" (a loan given) or "Trả nợ" (one taken), user choice 2026-10-29: the principal paid off
/// on top, then the interest apart, the account the money comes into or leaves, and the day. The
/// principal comes off what is left; the interest counts as income or spending. Opened from the
/// loan's sheet; editing one also offers "Xoá".
struct LoanPaymentSheet: View {
    let loan: Loan
    private let original: LoanPayment?

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var principalText: String
    @State private var interestText: String
    @State private var accountID: Account.ID?
    @State private var date: Date
    @State private var showsErrors = false
    /// What was left as the sheet opened: saving changes the loan, and the sheet must not redraw
    /// "không được lớn hơn số còn lại (0 đ)" on that while it slides away.
    @State private var openedLeft: Double?

    init(loan: Loan, editing payment: LoanPayment? = nil, suggestedInterest: Double = 0) {
        self.loan = loan
        original = payment
        _principalText = State(initialValue: payment.map { $0.principal > 0 ? String(Int($0.principal)).groupedVNDInput : "" } ?? "")
        let interest = payment?.interest ?? suggestedInterest
        _interestText = State(initialValue: interest > 0 ? String(Int(interest)).groupedVNDInput : "")
        _accountID = State(initialValue: payment?.accountID ?? loan.movedAccountID)
        _date = State(initialValue: payment?.date ?? .now)
    }

    private var lent: Bool { loan.direction == .lent }
    private var principal: Double { principalText.vndInputAmount }
    private var interest: Double { interestText.isEmpty ? 0 : interestText.vndInputAmount }
    /// What is left before this repayment (its own principal given back when editing).
    /// Never more than the principal less the other repayments' principal.
    private var left: Double { openedLeft ?? liveLeft }
    private var liveLeft: Double {
        let others = store.repaidPrincipal(of: loan) - (original?.principal ?? 0)
        return min(loan.outstanding + (original?.principal ?? 0), max(loan.principal - others, 0))
    }
    private var accountOptions: [Account.ID] { store.loanAccountOptions(keeping: original?.accountID) }
    private var chosenAccount: Account.ID? {
        accountID.flatMap { id in accountOptions.contains(id) ? id : nil } ?? accountOptions.first
    }

    private var amountError: String? {
        if principal > left { return "Tiền gốc không được lớn hơn số còn lại (\(left.vnd))." }
        return showsErrors && principal + interest <= 0 ? "Nhập tiền gốc hoặc tiền lãi." : nil
    }
    private var accountError: String? {
        chosenAccount == nil ? "Chưa có tài khoản để ghi. Thêm tài khoản ở tab Tài khoản." : nil
    }
    private var canSave: Bool {
        principal + interest > 0 && principal <= left && chosenAccount != nil
    }

    private func validate() -> Bool {
        withAnimation(.smooth(duration: 0.3)) { showsErrors = true }
        return canSave
    }

    /// "Hết 45tr" (the chip adds the figure): pays off everything left.
    private var presets: [AmountPreset] {
        left > 0 ? [AmountPreset(label: "Hết", value: left)] : []
    }

    /// The principal is all paid: only interest is left to record (a settled loan's late interest).
    private var interestOnly: Bool { left <= 0 && (original?.principal ?? 0) == 0 }

    private var title: String {
        if interestOnly {
            if original != nil { return lent ? "Sửa lần thu lãi" : "Sửa lần trả lãi" }
            return lent ? "Thu lãi" : "Trả lãi"
        }
        return original == nil ? (lent ? "Thu nợ" : "Trả nợ") : (lent ? "Sửa lần thu" : "Sửa lần trả")
    }

    var body: some View {
        SheetScaffold(title: title, validate: validate, onConfirm: save) {
            SheetAmountHeader(caption: "Tiền gốc", fieldSaysCaption: true) {
                TimiAmountField(text: $principalText, showsSuggestions: !interestOnly,
                                focusesOnAppear: original == nil && !interestOnly, presets: presets, label: "Tiền gốc")
                    .disabled(interestOnly)
                if interestOnly {
                    Text("Đã \(lent ? "thu" : "trả") đủ tiền gốc, chỉ ghi tiền lãi.")
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                    if showsErrors, interest <= 0 {
                        FormErrorText(text: "Nhập tiền lãi.")
                    }
                } else if let amountError {
                    FormErrorText(text: amountError)
                }
            }
        } content: {
            FormGroup(title: "Chi tiết", footer: footer, error: accountError) {
                FormAmountRow(title: "Tiền lãi", text: $interestText,
                              isInvalid: interestOnly && showsErrors && interest <= 0,
                              focusesOnAppear: interestOnly && original == nil)
                FormDivider(hasIcon: false)
                if let chosen = chosenAccount {
                    FormPickerRow(title: lent ? "Nhận vào" : "Chi từ",
                                  selection: Binding { chosen } set: { accountID = $0 },
                                  options: accountOptions,
                                  optionIcon: { store.account(id: $0)?.iconName ?? "hugeicons-wallet-01" }) {
                        store.account(id: $0)?.name ?? "Tài khoản đã xoá"
                    }
                    FormDivider(hasIcon: false)
                }
                FormDateRow(title: "Ngày", date: $date, earliest: loan.isExisting ? nil : loan.date, latest: .now)
            }

            if let original {
                FormGroup {
                    FormDestructiveRow(title: lent ? "Xoá lần thu" : "Xoá lần trả",
                                       question: lent ? "Xoá lần thu nợ này?" : "Xoá lần trả nợ này?",
                                       message: "Số còn lại và số dư tài khoản sẽ được tính lại.") {
                        store.delete(original)
                        dismiss()
                    }
                }
            }
        }
        .timiSheetStyle()
        .onAppear { if openedLeft == nil { openedLeft = liveLeft } }
    }

    /// What is left after this one, and where the interest goes.
    private var footer: String {
        let after = max(left - principal, 0)
        let rest = after > 0 ? "Còn lại sau lần này: \(after.vnd)." : (lent ? "Lần này thu hết khoản vay." : "Lần này trả hết khoản vay.")
        let interestNote = lent ? "Tiền lãi tính là thu nhập." : "Tiền lãi tính là chi tiêu."
        // Only interest left: what is left of the loan is not news.
        if interestOnly { return interestNote }
        return rest + (interest > 0 ? " " + interestNote : "")
    }

    private func save() {
        guard canSave, let account = chosenAccount else { return }
        var payment = original ?? LoanPayment(loanID: loan.id, principal: 0, accountID: account, date: date)
        payment.principal = principal
        payment.interest = interest
        payment.accountID = account
        payment.date = date
        store.save(payment)
        dismiss()
    }
}
