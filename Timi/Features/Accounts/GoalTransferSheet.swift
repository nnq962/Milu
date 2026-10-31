import SwiftUI

/// "Nạp tiền" moves money from a payment account into the goal; "Rút tiền" moves it back. The
/// account goes down by what the goal goes up, so totals stay the same and reports ignore it.
/// A withdrawal cannot take more than the goal holds. A deposit offers the monthly amount (with a
/// deadline) and what is still missing as ready chips. `closesGoal` is "Rút hết về tài khoản" on a
/// goal that reached its target: everything comes out and the goal is closed. Given `editing`,
/// it changes that deposit or withdrawal (both balances are worked out again) or deletes it.
struct GoalTransferSheet: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let goal: SavingsGoal
    let direction: GoalTransfer.Direction
    var closesGoal = false
    private var editing: GoalTransfer?
    /// What the goal holds without the transfer being edited, as the sheet opened: saving changes
    /// the goal, and the sheet must not redraw a limit error on that while it slides away.
    @State private var savedWithout: Double

    @State private var amountText = ""
    @State private var accountID: Account.ID?
    @State private var date = Date.now
    @State private var note = ""
    @State private var showsErrors = false

    /// `account` is the one offered first. It and "Rút hết"'s amount are set here, not on appear,
    /// so the sheet opens as it stays: no row slid in, no amount changing under the eye
    /// (re-review 2026-10-31).
    init(goal: SavingsGoal, direction: GoalTransfer.Direction, closesGoal: Bool = false,
         account: Account.ID? = nil) {
        self.goal = goal
        self.direction = direction
        self.closesGoal = closesGoal
        _savedWithout = State(initialValue: goal.saved)
        _accountID = State(initialValue: account)
        if closesGoal {
            _amountText = State(initialValue: String(Int(goal.saved)).groupedVNDInput)
        }
    }

    init(editing transfer: GoalTransfer, goal: SavingsGoal) {
        self.goal = goal
        direction = transfer.direction
        editing = transfer
        _savedWithout = State(initialValue: goal.saved - transfer.goalDelta)
        _amountText = State(initialValue: String(Int(transfer.amount)).groupedVNDInput)
        _accountID = State(initialValue: transfer.accountID)
        _date = State(initialValue: transfer.date)
        _note = State(initialValue: transfer.note)
    }

    private var isDeposit: Bool { direction == .deposit }
    private var amount: Double { amountText.vndInputAmount }
    /// A withdrawal can take at most what the goal holds; a deposit made smaller cannot leave the
    /// goal below 0đ (money already taken out after it).
    private var limitError: String? {
        if !isDeposit, amount > savedWithout { return "Hũ chỉ có \(savedWithout.vnd)." }
        if isDeposit, savedWithout + amount < 0 { return "Cần nạp ít nhất \((-savedWithout).vnd), vì tiền đã được rút hoặc dùng." }
        return nil
    }
    private var canSave: Bool { amount > 0 && accountID != nil && limitError == nil }

    /// ✓ stays on so what is missing can be pointed out instead of the button just doing
    /// nothing (sheet review 2026-10-30: it greyed out here, against the app's rule).
    private func validate() -> Bool {
        withAnimation(.smooth(duration: 0.3)) { showsErrors = true }
        return canSave
    }
    /// Deleting a deposit whose money was already taken out would leave the goal below 0đ.
    private var canDelete: Bool { savedWithout >= 0 }

    private var title: String {
        if editing != nil { return isDeposit ? "Sửa lần nạp" : "Sửa lần rút" }
        return closesGoal ? "Rút hết" : isDeposit ? "Nạp tiền" : "Rút tiền"
    }

    /// Unlocked accounts, plus the one this transfer is on when it is being edited.
    private var accountOptions: [Account.ID] {
        store.paymentAccounts.filter { !$0.isLocked || $0.id == editing?.accountID }.map(\.id)
    }

    var body: some View {
        SheetScaffold(title: title, validate: validate, onConfirm: save) {
            SheetAmountHeader(title: goal.name) {
                // "Rút hết" takes everything: the amount is shown, not typed.
                TimiAmountField(text: $amountText, showsSuggestions: !closesGoal,
                                focusesOnAppear: !closesGoal && editing == nil,
                                presets: isDeposit && editing == nil ? presets : [])
                    .disabled(closesGoal)
            }
        } content: {
            FormGroup(title: "Chi tiết", error: accountOptions.isEmpty ? Self.noAccountError(store)
                        : limitError ?? (showsErrors && amount <= 0 ? "Nhập số tiền." : nil)) {
                if let accountID {
                    FormPickerRow(title: isDeposit ? "Từ tài khoản" : "Về tài khoản",
                                  selection: Binding { accountID } set: { self.accountID = $0 },
                                  options: accountOptions,
                                  optionIcon: { store.account(id: $0)?.iconName ?? "hugeicons-wallet-01" }) {
                        store.account(id: $0)?.name ?? "—"
                    }
                    FormDivider(hasIcon: false)
                }
                // Money already moved: no day after today (user choice 2026-10-29).
                FormDateTimeRow(title: "Thời gian", date: $date, latest: .now)
            }

            FormGroup(title: "Ghi chú") {
                FormNoteRow(text: $note, prompt: "Thêm ghi chú")
            }

            if let editing {
                FormGroup {
                    FormDestructiveRow(
                        title: isDeposit ? "Xoá lần nạp" : "Xoá lần rút",
                        question: isDeposit ? "Xoá lần nạp này?" : "Xoá lần rút này?",
                        message: canDelete
                            ? "\(editing.amount.vnd) sẽ được trả về \(isDeposit ? store.account(id: editing.accountID)?.name ?? "tài khoản" : "hũ")."
                            : "Tiền của lần nạp này đã được rút hoặc dùng. Xoá lần rút hoặc khoản chi đó trước.",
                        canConfirm: canDelete
                    ) {
                        store.delete(editing)
                        dismiss()
                    }
                }
            }
        }
        .timiSheetStyle()
    }

    /// "Mỗi tháng 167k" with a deadline, and "Còn thiếu 2tr" when it differs.
    private var presets: [AmountPreset] {
        guard goal.remaining > 0 else { return [] }
        var chips: [AmountPreset] = []
        if let dueDate = goal.dueDate, !goal.isOverdue {
            chips.append(AmountPreset(title: "Mỗi tháng",
                                      value: SavingsGoal.monthlySaving(remaining: goal.remaining, until: dueDate)))
        }
        if !chips.contains(where: { $0.value == goal.remaining }) {
            chips.append(AmountPreset(title: "Còn thiếu", value: goal.remaining))
        }
        return chips
    }

    /// Every payment account is locked, or there is none: say what to do instead of a dead ✓.
    static func noAccountError(_ store: FinanceStore) -> String {
        store.paymentAccounts.isEmpty ? "Thêm một tài khoản thanh toán trước." : "Mọi tài khoản đang khoá. Mở khoá một tài khoản trước."
    }

    private func save() {
        guard canSave, let accountID else { return }
        if var transfer = editing {
            transfer.accountID = accountID
            transfer.amount = amount
            transfer.date = date
            transfer.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            store.update(transfer)
            dismiss()
            return
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if closesGoal {
            store.withdrawAll(from: goal, to: accountID, date: date, note: trimmedNote)
        } else {
            store.add(GoalTransfer(goalID: goal.id, accountID: accountID, direction: direction,
                                   amount: amount, date: date, note: trimmedNote))
        }
        dismiss()
    }
}

#Preview {
    GoalTransferSheet(goal: SampleData.savingsGoals[1], direction: .deposit)
        .environment(FinanceStore())
}
