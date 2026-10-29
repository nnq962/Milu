import SwiftUI

/// TODO(user, 2026-10-29): "Dùng tiền" should open the full add-transaction sheet (prefilled from the
/// goal) once that sheet is finished; this sheet is the stand-in until then. See DESIGN_NOTES.
/// "Dùng tiền" on a goal that reached its target: the category it was spent on (no name, as any
/// transaction), recorded as an expense from the goal (it counts in reports, like any spending). The amount starts at what the
/// goal holds; spending less sends the rest to an account. Saving closes the goal.
struct GoalSpendSheet: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let goal: SavingsGoal

    @State private var amountText: String
    @State private var categoryID = ""
    @State private var date = Date.now
    @State private var leftoverAccount: Account.ID?

    init(goal: SavingsGoal) {
        self.goal = goal
        _amountText = State(initialValue: String(Int(goal.saved)).groupedVNDInput)
    }

    private var amount: Double { amountText.vndInputAmount }
    private var leftover: Double { goal.saved - amount }
    private var isTooMuch: Bool { amount > goal.saved }
    /// Too much, or money left over with no unlocked account to send it to.
    private var error: String? {
        if isTooMuch { return "Hũ chỉ có \(goal.saved.vnd)." }
        if showsErrors, amount <= 0 { return "Nhập số tiền." }
        if showsErrors, categoryID.isEmpty { return "Chọn hạng mục." }
        if leftover >= 1, leftoverAccount == nil {
            return "Còn \(leftover.vnd) trong hũ. \(GoalTransferSheet.noAccountError(store))"
        }
        return nil
    }
    private var canSave: Bool {
        amount > 0 && !isTooMuch && (leftover < 1 || leftoverAccount != nil)
            && CategoryPickerRow.isPickable(categoryID, kind: .expense, in: store)
    }

    @State private var showsErrors = false

    /// ✓ with something missing: shows what, keeps the sheet open (SheetScaffold buzzes).
    private func validate() -> Bool {
        withAnimation(.smooth(duration: 0.3)) { showsErrors = true }
        return canSave
    }

    var body: some View {
        SheetScaffold(title: "Dùng tiền", validate: validate, onConfirm: save) {
            SheetAmountHeader(caption: goal.name) {
                TimiAmountField(text: $amountText, kind: .expense, showsSuggestions: false)
            }
        } content: {
            FormGroup(title: "Chi tiết", error: error) {
                CategoryPickerRow(kind: .expense, selection: $categoryID, showsError: showsErrors)
                FormDivider(hasIcon: false)
                // Money already moved: no day after today (user choice 2026-10-29).
                FormDateRow(title: "Ngày", date: $date, latest: .now)
                FormDivider(hasIcon: false)
                FormTimeRow(title: "Giờ", date: $date)
            }

            // Spent less than the goal holds: the rest goes back to an account.
            if leftover >= 1, let leftoverAccount {
                FormGroup(title: "Phần còn lại", footer: "\(leftover.vnd) sẽ về tài khoản này.") {
                    FormPickerRow(title: "Về tài khoản",
                                  selection: Binding { leftoverAccount } set: { self.leftoverAccount = $0 },
                                  options: store.paymentAccounts.filter { !$0.isLocked }.map(\.id),
                                  optionIcon: { store.account(id: $0)?.iconName ?? "hugeicons-wallet-01" }) {
                        store.account(id: $0)?.name ?? "—"
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.3), value: leftover >= 1)
        .timiSheetStyle()
        .onAppear {
            leftoverAccount = leftoverAccount ?? store.paymentAccounts.first { !$0.isLocked }?.id
        }
    }

    private func save() {
        guard canSave else { return }
        store.spend(from: goal, categoryID: categoryID,
                    amount: amount, date: date, leftoverAccount: leftover >= 1 ? leftoverAccount : nil)
        dismiss()
    }
}
