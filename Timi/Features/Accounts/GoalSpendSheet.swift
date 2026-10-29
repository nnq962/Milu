import SwiftUI

/// TODO(user, 2026-10-29): "Dùng tiền" should open the full add-transaction sheet (prefilled from the
/// goal) once that sheet is finished; this sheet is the stand-in until then. See DESIGN_NOTES.
/// "Dùng tiền" on a goal that reached its target: what the money was spent on, recorded as an
/// expense from the goal (it counts in reports, like any spending). The amount starts at what the
/// goal holds; spending less sends the rest to an account. Saving closes the goal.
struct GoalSpendSheet: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let goal: SavingsGoal

    @State private var amountText: String
    @State private var title = ""
    @State private var category: TransactionCategory = .shopping
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
        if leftover >= 1, leftoverAccount == nil {
            return "Còn \(leftover.vnd) trong hũ. \(GoalTransferSheet.noAccountError(store))"
        }
        return nil
    }
    private var canSave: Bool { amount > 0 && !isTooMuch && (leftover < 1 || leftoverAccount != nil) }

    var body: some View {
        SheetScaffold(title: "Dùng tiền", canConfirm: canSave, onConfirm: save) {
            SheetAmountHeader(caption: goal.name) {
                TimiAmountField(text: $amountText, kind: .expense, showsSuggestions: false)
            }
        } content: {
            FormGroup(title: "Chi tiết", error: error) {
                FormTextRow(title: "Dùng vào", text: $title, prompt: goal.name)
                FormDivider(hasIcon: false)
                FormPickerRow(title: "Danh mục", selection: $category,
                              options: TransactionCategory.categories(for: .expense),
                              optionIcon: { $0.icon }) { $0.title }
                FormDivider(hasIcon: false)
                FormDateRow(title: "Ngày", date: $date)
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
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        store.spend(from: goal, title: trimmed.isEmpty ? goal.name : trimmed, category: category,
                    amount: amount, date: date, leftoverAccount: leftover >= 1 ? leftoverAccount : nil)
        dismiss()
    }
}
