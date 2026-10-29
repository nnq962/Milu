import SwiftUI

/// Creates a loan when `loan` is nil, otherwise edits, settles or deletes it (user requests
/// 2026-10-29):
/// - who it is with is picked from "Danh bạ" (`ContactPickerSheet`), where someone new can be added;
/// - "Khoản có sẵn" is a loan from before the app: no account moves, and what is left to repay is
///   typed ("Còn lại", empty = nothing repaid). A new loan takes its principal out of the account
///   it is lent from, or brings it into the account it came into, on its date; it shows on "Thu
///   chi" as neither income nor spending;
/// - interest is a percent of the principal each month, the same every month.
struct LoanEditorView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let original: Loan?
    @State private var direction: LoanDirection
    @State private var contactID: Contact.ID?
    @State private var principalText: String
    @State private var isExisting: Bool
    @State private var accountID: Account.ID?
    @State private var date: Date
    @State private var outstandingText: String
    @State private var rateText: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var isPickingPerson = false
    /// Set by the first ✓: from then on what is missing shows in red.
    @State private var showsErrors = false

    init(loan: Loan?) {
        original = loan
        _direction = State(initialValue: loan?.direction ?? .lent)
        _contactID = State(initialValue: loan?.contactID)
        _principalText = State(initialValue: loan.map { String(Int($0.principal)).groupedVNDInput } ?? "")
        _isExisting = State(initialValue: loan?.isExisting ?? false)
        _accountID = State(initialValue: loan?.accountID)
        _date = State(initialValue: loan?.date ?? .now)
        // Only a loan from before the app shows what is left; empty means nothing repaid.
        _outstandingText = State(initialValue: loan.flatMap { $0.outstanding < $0.principal
            ? String(Int($0.outstanding)).groupedVNDInput : nil } ?? "")
        _rateText = State(initialValue: loan.map { $0.monthlyInterestRate > 0 ? Self.percent($0.monthlyInterestRate) : "" } ?? "")
        _hasDueDate = State(initialValue: loan?.dueDate != nil)
        _dueDate = State(initialValue: loan?.dueDate ?? Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now)
    }

    // MARK: - Values

    private var person: Contact? { contactID.flatMap { store.contact(id: $0) } }
    private var principal: Double { principalText.vndInputAmount }
    /// Repaid so far, kept when the principal of a loan that moved money changes.
    private var repaid: Double { original.map { $0.principal - $0.outstanding } ?? 0 }
    private var outstanding: Double {
        if isExisting { return outstandingText.isEmpty ? principal : outstandingText.vndInputAmount }
        return max(principal - repaid, 0)
    }
    /// "1,5" or "1.5" → 1.5; empty → 0.
    private var rate: Double? {
        let text = rateText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? 0 : Double(text)
    }
    private var accountOptions: [Account.ID] { store.loanAccountOptions(keeping: original?.accountID) }
    /// The account a new loan moves money with: the one picked, else the first that can.
    private var chosenAccount: Account.ID? { accountID ?? accountOptions.first }

    private var lentLabel: String { direction == .lent ? "Người vay" : "Người cho vay" }

    // MARK: - Problems

    private var personError: String? { person == nil ? "Chọn \(lentLabel.lowercased())." : nil }
    private var amountError: String? { principal <= 0 ? "Nhập số tiền gốc." : nil }
    private var accountError: String? {
        guard !isExisting, chosenAccount == nil else { return nil }
        return "Chưa có tài khoản để ghi. Thêm tài khoản ở tab Tài khoản, hoặc chọn khoản có sẵn."
    }
    private var outstandingError: String? {
        isExisting && outstanding > principal ? "Số còn lại không được lớn hơn số tiền gốc." : nil
    }
    private var rateError: String? {
        guard let rate else { return "Lãi suất là một số, ví dụ 1,5." }
        return rate > 100 ? "Lãi suất tối đa 100% mỗi tháng." : nil
    }

    private var canSave: Bool {
        [personError, amountError, accountError, outstandingError, rateError].allSatisfy { $0 == nil }
    }

    /// ✓ with something missing: shows what, keeps the sheet open (SheetScaffold buzzes).
    private func validate() -> Bool {
        withAnimation(.smooth(duration: 0.3)) { showsErrors = true }
        return canSave
    }

    // MARK: - Form

    var body: some View {
        SheetScaffold(title: original == nil ? "Thêm khoản vay" : "Sửa khoản vay", validate: validate, onConfirm: save) {
            Picker("Loại khoản vay", selection: $direction) {
                ForEach(LoanDirection.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)

            VStack(spacing: Spacing.xs) {
                Text("Số tiền gốc")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                TimiAmountField(text: $principalText, focusesOnAppear: original == nil)
                if showsErrors, let amountError {
                    FormErrorText(text: amountError)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s)
        } content: {
            FormGroup(title: "Thông tin", error: showsErrors ? personError : nil) {
                personRow
                FormDivider(hasIcon: false)
                FormToggleRow(title: "Khoản có sẵn", subtitle: "Có từ trước khi dùng Timi, không đổi số dư",
                              isOn: $isExisting.animation(.smooth(duration: 0.25)))
            }

            if isExisting {
                FormGroup(title: "Đã trả", footer: "Để trống nếu chưa \(direction == .lent ? "thu" : "trả") đồng nào.",
                          error: outstandingError) {
                    FormAmountRow(title: "Còn lại", text: $outstandingText)
                }
                .transition(.opacity)
            } else {
                FormGroup(title: direction == .lent ? "Tiền đi" : "Tiền về", error: accountError) {
                    if let chosen = chosenAccount {
                        FormPickerRow(title: direction == .lent ? "Chi từ" : "Nhận vào",
                                      selection: Binding { chosen } set: { accountID = $0 },
                                      options: accountOptions,
                                      optionIcon: { store.account(id: $0)?.iconName ?? "hugeicons-wallet-01" }) {
                            store.account(id: $0)?.name ?? "Tài khoản đã xoá"
                        }
                        FormDivider(hasIcon: false)
                    }
                    FormDateRow(title: direction == .lent ? "Ngày cho vay" : "Ngày vay", date: $date, latest: .now)
                }
                .transition(.opacity)
            }

            FormGroup(title: "Lãi suất", footer: rateFooter, error: rateError) {
                FormTextRow(title: "% mỗi tháng", text: $rateText, prompt: "0", keyboard: .decimalPad,
                            isInvalid: rateError != nil, maxLength: 6)
            }

            FormGroup(title: "Hạn trả") {
                FormToggleRow(title: "Có hạn trả", isOn: $hasDueDate.animation(.smooth(duration: 0.25)))
                if hasDueDate {
                    FormDivider(hasIcon: false)
                    FormDateRow(title: "Hạn trả", date: $dueDate)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            if let original {
                actions(original)
            }
        }
        .animation(.smooth(duration: 0.25), value: direction)
        .timiSheetStyle()
        .sheet(isPresented: $isPickingPerson) {
            ContactPickerSheet(title: lentLabel, selection: $contactID)
        }
    }

    /// Who it is with, from Danh bạ: their name and relationship icon, or "Chọn" in grey.
    private var personRow: some View {
        Button { isPickingPerson = true } label: {
            FormValueLabel(title: lentLabel, icon: nil, value: person?.name ?? "Chọn",
                           valueIcon: person.map { store.relationship(id: $0.relationshipID).icon },
                           isInvalid: showsErrors && personError != nil)
        }
        .buttonStyle(.row)
        .accessibilityValue(person?.name ?? "Chưa chọn")
    }

    /// The interest each month, worked out as it is typed: "Mỗi tháng 375.000đ, tính trên số gốc."
    private var rateFooter: String? {
        guard let rate, rate > 0, principal > 0 else { return "Tính trên số gốc, tháng nào cũng như nhau." }
        return "Mỗi tháng \((principal * rate / 100).vnd), tính trên số gốc."
    }

    @ViewBuilder
    private func actions(_ original: Loan) -> some View {
        FormGroup {
            if !original.isSettled {
                FormActionRow(title: "Đánh dấu đã tất toán", icon: "hugeicons-checkmark-circle-02") {
                    store.settle(original)
                    dismiss()
                }
                FormDivider()
            }
            FormDestructiveRow(title: "Xoá khoản vay", question: "Xoá khoản vay với “\(original.name)”?",
                               message: original.movedAccountID != nil
                                   ? "Số dư tài khoản sẽ được tính lại."
                                   : "Khoản này sẽ không còn được tính vào cho vay hoặc nợ.") {
                store.delete(original)
                dismiss()
            }
        }
    }

    private func save() {
        guard canSave, let person else { return }
        var loan = original ?? Loan(name: person.name, direction: direction, principal: 0, outstanding: 0, dueDate: nil)
        loan.name = person.name
        loan.contactID = person.id
        loan.direction = direction
        loan.principal = principal
        loan.outstanding = outstanding
        loan.isExisting = isExisting
        loan.accountID = isExisting ? nil : chosenAccount
        loan.date = date
        loan.monthlyInterestRate = rate ?? 0
        loan.dueDate = hasDueDate ? dueDate : nil
        store.save(loan)
        dismiss()
    }

    /// "1,5" for 1.5, as the rate is typed back.
    static func percent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).locale(.vietnam))
    }
}
