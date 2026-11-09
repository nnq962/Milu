import SwiftUI

/// Creates a new savings goal when `goal` is nil, otherwise edits or deletes it. With a deadline,
/// the form says how much to put aside each month to get there.
struct GoalEditorView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let original: SavingsGoal?
    /// How an edited goal leaves the list it was opened from: deleted (its money back to an
    /// account, or none), reopened from "Hũ đã hoàn thành", or closed into it.
    enum Leave { case delete(returningTo: Account.ID?), reopen, close }

    /// Set from the goal's own screen: called as "Xoá hũ", "Mở lại hũ" or "Đóng hũ" closes the
    /// form, so that screen can leave first and then change the goal (`AfterDismiss`). Without it
    /// the form changes the goal itself.
    private var onLeave: ((Leave) -> Void)?
    @State private var name: String
    @State private var icon: String
    @State private var targetText: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date

    /// "Mục tiêu mới" on a reached goal: the keyboard opens on the target.
    private var focusesTarget = false

    init(goal: SavingsGoal?, focusesTarget: Bool = false, onLeave: ((Leave) -> Void)? = nil) {
        self.focusesTarget = focusesTarget
        original = goal
        self.onLeave = onLeave
        _name = State(initialValue: goal?.name ?? "")
        _icon = State(initialValue: goal?.icon ?? SavingsGoal.defaultIcon)
        _targetText = State(initialValue: goal.map { String(Int($0.target)).groupedVNDInput } ?? "")
        _hasDueDate = State(initialValue: goal?.dueDate != nil)
        _dueDate = State(initialValue: goal?.dueDate ?? Self.defaultDueDate)
    }

    /// Six months from today: a first guess the user changes in the calendar.
    private static var defaultDueDate: Date {
        Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    }

    /// A previously saved goal shows its equivalent illustration without rewriting its stored ID on edit.
    private var pickerIcon: Binding<String> {
        Binding(get: { GoalArtwork.name(for: icon) }, set: { icon = $0 })
    }

    private static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    /// Set when "Mở lại hũ" / "Đóng hũ" is tapped with no name: the group says so in red.
    @State private var showsNameError = false

    private func failClose() {
        withAnimation(Motion.gentle(.smooth(duration: 0.3))) { showsNameError = true }
        Haptics.error()
    }
    /// "Mục tiêu mới" on a goal that reached its target: the new one is above what it holds.
    private var targetError: String? {
        guard focusesTarget, let saved = original.flatMap({ store.goal(id: $0.id) })?.saved,
              targetText.vndInputAmount > 0, targetText.vndInputAmount <= saved else { return nil }
        return "Mục tiêu mới phải lớn hơn số đã để dành (\(saved.vnd))."
    }
    private var canSave: Bool { !trimmedName.isEmpty && targetText.vndInputAmount > 0 && targetError == nil }

    /// ✓ stays on so what is missing can be pointed out instead of the button just doing
    /// nothing (sheet review 2026-10-30: it greyed out here, against the app's rule).
    private func validate() -> Bool {
        withAnimation(Motion.gentle(.smooth(duration: 0.3))) { showsNameError = true }
        return canSave
    }

    /// "Cần để dành 2.500.000đ mỗi tháng trong 6 tháng."; nil without a deadline or a target.
    private var monthlyNote: String? {
        guard hasDueDate else { return nil }
        let remaining = max(targetText.vndInputAmount - (original?.saved ?? 0), 0)
        guard targetText.vndInputAmount > 0 else { return nil }
        if remaining == 0 { return "Đã đủ mục tiêu." }
        if Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: .now) {
            return "Hạn đã qua."
        }
        let months = SavingsGoal.monthsLeft(until: dueDate)
        let perMonth = SavingsGoal.monthlySaving(remaining: remaining, until: dueDate)
        return "Cần để dành \(perMonth.vnd) mỗi tháng trong \(months) tháng."
    }

    var body: some View {
        SheetScaffold(title: original == nil ? "Thêm hũ tiết kiệm" : "Sửa hũ tiết kiệm",
                      validate: validate, onConfirm: save) {
            SheetAmountHeader(title: "Mục tiêu") {
                // A closed goal keeps the target it met; reopening it makes the target editable again.
                MiluAmountField(text: $targetText, showsSuggestions: original?.isClosed != true,
                                focusesOnAppear: original == nil || focusesTarget)
                    .disabled(original?.isClosed == true)
                if let error = targetError ?? (showsNameError && targetText.vndInputAmount <= 0 ? "Nhập mục tiêu." : nil) {
                    FormErrorText(message: error)
                }
            }
        } content: {
            FormGroup(title: "Thông tin", error: showsNameError && trimmedName.isEmpty ? "Nhập tên." : nil) {
                // No "Đã để dành": a goal starts empty and money goes in and out through "Nạp" /
                // "Rút" on its screen, so every change has an account and a date.
                // The row's label red with the line under the group, as on the account form.
                FormTextRow(title: "Tên hũ", text: $name, prompt: "Du lịch Đà Nẵng",
                            isInvalid: showsNameError && trimmedName.isEmpty)
            }

            FormGroup(title: "Biểu tượng") {
                // The tiles of "Chọn nhanh" on Thêm giao dịch (user request 2026-11-05).
                IconTilePicker(selection: pickerIcon, suggestions: SavingsGoal.suggestedIcons)
            }

            FormGroup(title: "Kế hoạch", footer: monthlyNote) {
                FormToggleRow(title: "Thời hạn", isOn: $hasDueDate.animation(Motion.gentle(.smooth(duration: 0.3))))
                if hasDueDate {
                    FormDivider(hasIcon: false)
                    FormDateRow(title: "Đến ngày", date: $dueDate, earliest: Self.tomorrow)
                        .transition(.opacity)
                }
            }

            if let original {
                // A closed goal's history is read-only; reopening it puts it back among the cards
                // so deposits, withdrawals and spending can be changed again (user choice 2026-10-29).
                if original.isClosed {
                    FormGroup {
                        FormActionRow(title: "Mở lại hũ", icon: "hugeicons-piggy-bank") {
                            // A name left empty: say so instead of dropping what was typed.
                            guard canSave else { failClose(); return }
                            applyEdits()
                            Haptics.success()
                            leave(.reopen, original)
                        }
                    }
                } else if let current = store.goal(id: original.id), current.saved < 1,
                          !store.goalTransactions(current).isEmpty || current.isReached || !current.closingNote.isEmpty {
                    // A reopened, empty goal can go back to "Hũ đã hoàn thành".
                    FormGroup {
                        FormActionRow(title: "Đóng hũ", icon: "hugeicons-checkmark-badge-01") {
                            guard canSave else { failClose(); return }
                            applyEdits()
                            Haptics.success()
                            leave(.close, original)
                        }
                    }
                }
                FormGroup {
                    deleteRow(original)
                }
            }
        }
        .miluSheetStyle()
    }

    /// A goal with money in it asks which account gets the money back, one button per account; an
    /// empty goal just asks to confirm.
    private func deleteRow(_ goal: SavingsGoal) -> some View {
        let saved = store.goal(id: goal.id)?.saved ?? goal.saved
        let accounts = store.paymentAccounts.filter { !$0.isLocked }
        let hasMoney = saved >= 1
        let noAccountText = store.paymentAccounts.isEmpty
            ? "Thêm một tài khoản để nhận lại tiền trước khi xoá."
            : "Mở khoá một tài khoản để nhận lại tiền trước khi xoá."
        // Same-named accounts (two "Vietcombank") are told apart by their balance.
        let names = Dictionary(grouping: accounts, by: \.name)
        return FormDestructiveRow(
            title: "Xoá hũ", question: "Xoá hũ “\(goal.name)”?",
            message: !hasMoney ? "Không thể hoàn tác."
                : accounts.isEmpty ? "Hũ còn \(saved.vnd). \(noAccountText)"
                : "Hũ còn \(saved.vnd). Chọn tài khoản nhận lại tiền, rồi hũ sẽ bị xoá.",
            choices: !hasMoney ? [] : accounts.map { account in
                let label = (names[account.name]?.count ?? 0) > 1
                    ? "\(account.name) · \(account.balance.vnd)" : account.name
                return .init(id: account.id.uuidString, title: "Chuyển về \(label)") {
                    delete(goal, returningTo: account.id)
                }
            },
            canConfirm: !hasMoney || !accounts.isEmpty
        ) {
            delete(goal, returningTo: nil)
        }
    }

    private func delete(_ goal: SavingsGoal, returningTo accountID: Account.ID?) {
        leave(.delete(returningTo: accountID), goal)
    }

    private func leave(_ leave: Leave, _ goal: SavingsGoal) {
        dismiss()
        if let onLeave { onLeave(leave); return }
        switch leave {
        case .delete(let accountID): store.delete(goal, returningTo: accountID)
        case .reopen: store.reopen(goal.id)
        case .close: store.closeEmpty(goal.id)
        }
    }

    private func save() {
        guard canSave else { return }
        dismiss()
        guard original == nil else { applyEdits(); return }
        // A new goal: the form slides away first, then its jar comes into the grid, animated
        // (user request 2026-11-05, as a new account's row).
        let goal = edited, store = store
        AfterDismiss.run { store.save(goal) }
    }

    /// Saves what the form holds (also before "Mở lại hũ" / "Đóng hũ", so nothing typed is lost).
    private func applyEdits() {
        guard canSave else { return }
        store.save(edited)
    }

    /// The goal as the form holds it. Starts from the stored goal, so its money and state are never
    /// overwritten by the form's copy.
    private var edited: SavingsGoal {
        var goal = original.flatMap { store.goal(id: $0.id) } ?? SavingsGoal(name: trimmedName, icon: icon, saved: 0, target: 0)
        goal.name = trimmedName
        goal.icon = icon
        if goal.isClosed != true { goal.target = targetText.vndInputAmount }
        goal.dueDate = hasDueDate ? dueDate : nil
        return goal
    }
}

#Preview("Sửa hũ") {
    GoalEditorView(goal: SampleData.savingsGoals[0])
        .environment(FinanceStore())
}
