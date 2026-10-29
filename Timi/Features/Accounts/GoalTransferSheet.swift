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

    @State private var amountText = ""
    @State private var accountID: Account.ID?
    @State private var date = Date.now
    @State private var note = ""

    init(goal: SavingsGoal, direction: GoalTransfer.Direction, closesGoal: Bool = false) {
        self.goal = goal
        self.direction = direction
        self.closesGoal = closesGoal
    }

    init(editing transfer: GoalTransfer, goal: SavingsGoal) {
        self.goal = goal
        direction = transfer.direction
        editing = transfer
        _amountText = State(initialValue: String(Int(transfer.amount)).groupedVNDInput)
        _accountID = State(initialValue: transfer.accountID)
        _date = State(initialValue: transfer.date)
        _note = State(initialValue: transfer.note)
    }

    private var isDeposit: Bool { direction == .deposit }
    private var amount: Double { amountText.vndInputAmount }
    /// What the goal holds without the transfer being edited.
    private var savedWithout: Double { goal.saved - (editing?.goalDelta ?? 0) }
    /// A withdrawal can take at most what the goal holds; a deposit made smaller cannot leave the
    /// goal below 0đ (money already taken out after it).
    private var limitError: String? {
        if !isDeposit, amount > savedWithout { return "Hũ chỉ có \(savedWithout.vnd)." }
        if isDeposit, savedWithout + amount < 0 { return "Cần nạp ít nhất \((-savedWithout).vnd), vì tiền đã được rút hoặc dùng." }
        return nil
    }
    private var canSave: Bool { amount > 0 && accountID != nil && limitError == nil }
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
        SheetScaffold(title: title, canConfirm: canSave, onConfirm: save) {
            SheetAmountHeader(caption: goal.name) {
                // "Rút hết" takes everything: the amount is shown, not typed.
                TimiAmountField(text: $amountText, showsSuggestions: !closesGoal,
                                focusesOnAppear: !closesGoal && editing == nil,
                                presets: isDeposit && editing == nil ? presets : [])
                    .disabled(closesGoal)
            }
        } content: {
            FormGroup(title: "Chi tiết", error: accountOptions.isEmpty ? Self.noAccountError(store) : limitError) {
                if let accountID {
                    FormPickerRow(title: isDeposit ? "Từ tài khoản" : "Về tài khoản",
                                  selection: Binding { accountID } set: { self.accountID = $0 },
                                  options: accountOptions,
                                  optionIcon: { store.account(id: $0)?.iconName ?? "hugeicons-wallet-01" }) {
                        store.account(id: $0)?.name ?? "—"
                    }
                    FormDivider(hasIcon: false)
                }
                FormDateRow(title: "Ngày", date: $date)
                FormDivider(hasIcon: false)
                FormTimeRow(title: "Giờ", date: $date)
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
        .onAppear {
            accountID = accountID ?? store.paymentAccounts.first { !$0.isLocked }?.id
            if closesGoal, amountText.isEmpty {
                amountText = String(Int(goal.saved)).groupedVNDInput
            }
        }
    }

    /// "Mỗi tháng 167k" with a deadline, and "Còn thiếu 2tr" when it differs.
    private var presets: [AmountPreset] {
        guard goal.remaining > 0 else { return [] }
        var chips: [AmountPreset] = []
        if let dueDate = goal.dueDate {
            chips.append(AmountPreset(label: "Mỗi tháng",
                                      value: SavingsGoal.monthlySaving(remaining: goal.remaining, until: dueDate)))
        }
        if !chips.contains(where: { $0.value == goal.remaining }) {
            chips.append(AmountPreset(label: "Còn thiếu", value: goal.remaining))
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
