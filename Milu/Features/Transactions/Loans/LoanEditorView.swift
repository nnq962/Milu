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
    @Environment(\.recordSheetDismiss) private var recordSheetDismiss

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
    /// Repaid so far on a new loan: through "Thu nợ" / "Trả nợ", or (saved before that rule) what
    /// the loan already said.
    @State private var repaid: Double

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
        _repaid = State(initialValue: loan.map { $0.principal - $0.outstanding } ?? 0)
    }

    // MARK: - Values

    private var person: Contact? { contactID.flatMap { store.contact(id: $0) } }
    private var principal: Double { principalText.vndInputAmount }
    private var outstanding: Double {
        // Empty: nothing repaid before Timi, so the principal less what came back through it.
        if isExisting { return max(outstandingText.isEmpty ? principal - repaidInApp : outstandingText.vndInputAmount, 0) }
        return max(principal - repaid, 0)
    }
    /// "1,5" or "1.5" → 1.5; empty → 0. Typing keeps it to digits, one comma, two decimals
    /// (`cleanRate`), so this is always a number of 0 or more.
    private var rate: Double {
        Double(rateText.replacingOccurrences(of: ",", with: ".")) ?? 0
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
    /// Repaid through the app ("Thu nợ" / "Trả nợ"): what is left can't be typed back over it.
    private var repaidInApp: Double { original.map(store.repaidPrincipal) ?? 0 }
    private var outstandingError: String? {
        guard isExisting else { return nil }
        if outstanding > principal { return "Số còn lại không được lớn hơn số tiền gốc." }
        if repaidInApp > 0, outstanding > principal - repaidInApp {
            return "Đã \(direction == .lent ? "thu" : "trả") \(repaidInApp.vnd) qua Milu: còn lại tối đa \((principal - repaidInApp).vnd)."
        }
        return nil
    }
    /// A new loan already partly repaid: the principal cannot go under what came back, or it would
    /// quietly count as settled.
    /// An existing loan: what came back through Timi; a new one: all that came back.
    private var principalError: String? {
        let floor = isExisting ? repaidInApp : repaid
        guard floor > 0, principal > 0, principal < floor else { return nil }
        return "Số tiền gốc không được nhỏ hơn số đã \(direction == .lent ? "thu" : "trả") (\(floor.vnd))."
    }
    /// Its repayments moved money one way: whether it was there before Timi cannot change under
    /// them (as the side cannot), so what is left always agrees with them (user choice 2026-10-29).
    private var hasPayments: Bool { original.map { !store.payments(of: $0).isEmpty } ?? false }
    /// Its money is on an archived account: who, when and the rate may change, the amounts not.
    private var moneyLockReason: String? { original.flatMap(store.readOnlyReason) }
    private var isMoneyLocked: Bool { moneyLockReason != nil }
    private var rateError: String? {
        rate > 100 ? "Lãi suất tối đa 100% mỗi tháng." : nil
    }
    /// A new loan's deadline comes after the day it was lent: the next day at the earliest.
    private var dueError: String? {
        guard hasDueDate, !isExisting,
              Calendar.current.startOfDay(for: dueDate) <= Calendar.current.startOfDay(for: date) else { return nil }
        return "Hạn trả phải sau \(direction == .lent ? "ngày cho vay" : "ngày vay")."
    }
    /// The first day a new loan's deadline can be: the day after it was lent.
    private var firstDueDay: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
    }

    private var canSave: Bool {
        [personError, amountError, principalError, accountError, outstandingError, rateError, dueError]
            .allSatisfy { $0 == nil }
    }

    /// ✓ with something missing: shows what, keeps the sheet open (SheetScaffold buzzes).
    private func validate() -> Bool {
        withAnimation(Motion.gentle(.smooth(duration: 0.3))) { showsErrors = true }
        return canSave
    }

    // MARK: - Form

    var body: some View {
        SheetScaffold(title: original == nil ? "Thêm khoản vay" : "Sửa khoản vay", validate: validate, onConfirm: save) {
            // Its words at the user's text size, as every other segmented control (re-review 2026-10-31).
            ScaledSegmentedPicker(title: "Loại khoản vay", selection: $direction,
                                  options: LoanDirection.allCases) { $0.title }
                .controlSize(.large)
                // Its repayments moved money one way: the side cannot flip under them.
                .disabled(hasPayments || isMoneyLocked)

            SheetAmountHeader(title: "Số tiền gốc", fieldSaysCaption: true) {
                TimiAmountField(text: $principalText, showsSuggestions: !isMoneyLocked,
                                focusesOnAppear: original == nil, accessibilityLabel: "Số tiền gốc")
                    .disabled(isMoneyLocked)
                if let error = principalError ?? (showsErrors ? amountError : nil) {
                    FormErrorText(message: error)
                } else if let moneyLockReason {
                    Text(moneyLockReason)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
            }
        } content: {
            FormGroup(title: "Thông tin", error: showsErrors ? personError : nil) {
                personRow
                FormDivider(hasIcon: false)
                // Fewer words (sheet review 2026-10-30): the line under it only when it cannot change.
                FormToggleRow(title: "Khoản có sẵn",
                              subtitle: hasPayments ? "Đã có lần \(direction == .lent ? "thu" : "trả"), không đổi được" : nil,
                              isOn: Binding { isExisting } set: { setExisting($0) })
                    .disabled(hasPayments || isMoneyLocked)
            }

            if isExisting {
                // No "Để trống nếu…" footer: explanations are not footers (strict review 2026-10-31).
                FormGroup(title: direction == .lent ? "Còn phải thu" : "Còn phải trả",
                          error: outstandingError) {
                    FormAmountRow(title: "Còn lại", text: $outstandingText, isInvalid: outstandingError != nil)
                }
                .disabled(isMoneyLocked)
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
                    // Not after its first repayment, nor after today.
                    FormDateRow(title: direction == .lent ? "Ngày cho vay" : "Ngày vay", date: $date,
                                latest: original.flatMap(store.firstPaymentDate).map { min($0, .now) } ?? .now)
                }
                .disabled(isMoneyLocked)
                .transition(.opacity)
            }

            FormGroup(title: "Lãi suất", footer: rateFooter, error: rateError) {
                FormTextRow(title: "% mỗi tháng", text: $rateText, prompt: "0", keyboard: .decimalPad,
                            isInvalid: rateError != nil)
                    // Rewritten as typed (a field keeps its own text when a binding only filters it).
                    .onChange(of: rateText) { _, new in
                        let clean = Self.cleanRate(new)
                        if clean != new { rateText = clean }
                    }
            }

            // Titled like every group of the form; the switch names it, the date is just "Ngày".
            FormGroup(title: "Kế hoạch", error: dueError) {
                FormToggleRow(title: "Hạn trả", isOn: $hasDueDate.animation(Motion.gentle(.smooth(duration: 0.25))))
                if hasDueDate {
                    FormDivider(hasIcon: false)
                    FormDateRow(title: "Ngày", date: $dueDate, earliest: isExisting ? nil : firstDueDay,
                                isInvalid: dueError != nil)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Deleting would take money back out of the archived account.
            if let original, !isMoneyLocked {
                actions(original)
            }
        }
        .animation(Motion.gentle(.smooth(duration: 0.25)), value: direction)
        .timiSheetStyle()
        // A loan from before Timi repaid only through it: what is left was worked out, not typed,
        // so the field stays empty ("empty = the principal less what came back through Milu").
        .onAppear {
            if let original, original.isExisting, store.repaidPrincipal(of: original) > 0,
               original.outstanding == original.principal - store.repaidPrincipal(of: original) {
                outstandingText = ""
            }
        }
        .sheet(isPresented: $isPickingPerson) {
            ContactPickerSheet(title: lentLabel, selection: $contactID)
        }
    }

    /// Switches between a loan from before the app and a new one: what a new loan has had back is
    /// what came back through Timi (or, on a new loan saved before that rule, what it already said);
    /// a figure typed in "Còn lại" does not carry over.
    private func setExisting(_ value: Bool) {
        withAnimation(Motion.gentle(.smooth(duration: 0.25))) {
            if value {
                // Something came back: "Còn lại" shows what is left ("0" when all of it).
                if outstandingText.isEmpty, repaid > 0 {
                    outstandingText = String(Int(max(principal - repaid, 0))).groupedVNDInput
                }
            } else {
                // A new loan is repaid only through "Thu nợ" / "Trả nợ" (none yet: the switch is
                // locked once there are some), so what was typed in "Còn lại" does not carry over.
                if let original, !original.isExisting {
                    repaid = original.principal - original.outstanding
                } else {
                    repaid = repaidInApp
                }
            }
            isExisting = value
        }
    }

    /// Digits, one comma (a dot typed becomes one) and at most two decimals; at most three digits
    /// before it ("100").
    static func cleanRate(_ text: String) -> String {
        var whole = ""
        var decimals: String?
        for character in text {
            if character.isASCII, character.isNumber {
                if decimals == nil { if whole.count < 3 { whole.append(character) } }
                else if decimals!.count < 2 { decimals!.append(character) }
            } else if character == "," || character == ".", decimals == nil {
                decimals = ""
            }
        }
        guard let decimals else { return whole }
        return (whole.isEmpty ? "0" : whole) + "," + decimals
    }

    /// Who it is with, from Danh bạ: their name and relationship icon, or "Chọn" in grey.
    private var personRow: some View {
        Button { isPickingPerson = true } label: {
            FormValueRowContent(title: lentLabel, icon: nil, value: person?.name ?? "Chọn",
                           valueIcon: person.map { store.relationship(id: $0.relationshipID).icon },
                           isInvalid: showsErrors && personError != nil)
        }
        .buttonStyle(.row)
        // The row's name as its label, the value once as its value: the label's words already
        // held the value, so VoiceOver read it twice (review 2026-11-07).
        .accessibilityLabel(lentLabel)
        .accessibilityValue(person?.name ?? "Chưa chọn")
    }

    /// The interest each month, worked out as it is typed: "Mỗi tháng 375.000đ"; the figure alone,
    /// no "tính trên số gốc" (strict review 2026-10-31). Nothing until there is a figure to show.
    private var rateFooter: String? {
        guard rate > 0, principal > 0 else { return nil }
        return "Mỗi tháng \((principal * rate / 100).vnd)."
    }

    @ViewBuilder
    private func actions(_ original: Loan) -> some View {
        // Repaying is recorded from the loan's sheet ("Thu nợ" / "Trả nợ"), so the money moves.
        FormGroup {
            FormDestructiveRow(title: "Xoá khoản vay", question: "Xoá khoản vay với “\(original.name)”?",
                               message: deleteMessage(original)) {
                // The form and the loan's sheet first, then the loan out of its list, animated
                // (`AfterDismiss`), as on Tài khoản.
                (recordSheetDismiss ?? dismiss)()
                AfterDismiss.run { store.delete(original) }
            }
        }
    }

    /// What deleting undoes: its repayments and their money, its own money, or only the figure.
    private func deleteMessage(_ loan: Loan) -> String {
        if !store.payments(of: loan).isEmpty { return "Các lần thu/trả nợ cũng bị xoá, số dư tài khoản sẽ được tính lại." }
        if loan.movedAccountID != nil { return "Số dư tài khoản sẽ được tính lại." }
        return "Khoản này sẽ không còn được tính vào cho vay hoặc nợ."
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
        loan.monthlyInterestRate = rate
        loan.dueDate = hasDueDate ? dueDate : nil
        dismiss()
        AfterDismiss.run { store.save(loan) }
    }

    /// "1,5" for 1.5, as the rate is typed back.
    static func percent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).locale(.vietnam))
    }
}
