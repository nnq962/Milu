import SwiftUI

/// "Nạp tiền" moves money from a payment account into the goal; "Rút tiền" moves it back. The
/// account goes down by what the goal goes up, so totals stay the same and reports ignore it.
/// A withdrawal cannot take more than the goal holds.
struct GoalTransferSheet: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let goal: SavingsGoal
    let direction: GoalTransfer.Direction

    @State private var amountText = ""
    @State private var accountID: Account.ID?
    @State private var date = Date.now
    @State private var note = ""

    private var isDeposit: Bool { direction == .deposit }
    private var amount: Double { amountText.vndInputAmount }
    private var isTooMuch: Bool { !isDeposit && amount > goal.saved }
    private var canSave: Bool { amount > 0 && accountID != nil && !isTooMuch }

    var body: some View {
        SheetScaffold(title: isDeposit ? "Nạp vào hũ" : "Rút từ hũ", canConfirm: canSave, onConfirm: save) {
            VStack(spacing: Spacing.xs) {
                Text(goal.name)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                TimiAmountField(text: $amountText, focusesOnAppear: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
        } content: {
            FormGroup(error: isTooMuch ? "Hũ chỉ còn \(goal.saved.vnd)." : nil) {
                if let accountID {
                    FormPickerRow(title: isDeposit ? "Từ tài khoản" : "Về tài khoản",
                                  selection: Binding { accountID } set: { self.accountID = $0 },
                                  options: store.paymentAccounts.filter { !$0.isLocked }.map(\.id),
                                  optionIcon: { store.account(id: $0)?.iconName ?? "hugeicons-wallet-01" }) {
                        store.account(id: $0)?.name ?? "—"
                    }
                    FormDivider(hasIcon: false)
                }
                FormDateRow(title: "Ngày", date: $date)
                FormDivider(hasIcon: false)
                FormTimeRow(title: "Giờ", date: $date)
            }

            FormGroup {
                FormNoteRow(text: $note, prompt: "Ghi chú")
            }
        }
        .timiSheetStyle()
        .onAppear {
            accountID = accountID ?? store.paymentAccounts.first { !$0.isLocked }?.id
        }
    }

    private func save() {
        guard canSave, let accountID else { return }
        store.add(GoalTransfer(goalID: goal.id, accountID: accountID, direction: direction,
                               amount: amount, date: date,
                               note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
        dismiss()
    }
}

#Preview {
    GoalTransferSheet(goal: SampleData.savingsGoals[1], direction: .deposit)
        .environment(FinanceStore())
}
