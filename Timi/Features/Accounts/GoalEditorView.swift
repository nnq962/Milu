import SwiftUI

/// Creates a new savings goal when `goal` is nil, otherwise edits or deletes it. With a deadline,
/// the form says how much to put aside each month to get there.
struct GoalEditorView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let original: SavingsGoal?
    /// Set from the goal's own screen: called after "Xoá hũ" closes the form, so that screen can
    /// leave first and then delete. Without it the form deletes the goal itself.
    private var onDelete: (() -> Void)?
    @State private var name: String
    @State private var icon: String
    @State private var targetText: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date

    init(goal: SavingsGoal?, onDelete: (() -> Void)? = nil) {
        original = goal
        self.onDelete = onDelete
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

    private static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && targetText.vndInputAmount > 0 }

    /// "Cần để dành 2.500.000đ mỗi tháng trong 6 tháng."; nil without a deadline or a target.
    private var monthlyNote: String? {
        guard hasDueDate else { return nil }
        let remaining = max(targetText.vndInputAmount - (original?.saved ?? 0), 0)
        guard targetText.vndInputAmount > 0 else { return nil }
        if remaining == 0 { return "Đã đủ mục tiêu." }
        let months = SavingsGoal.monthsLeft(until: dueDate)
        let perMonth = SavingsGoal.monthlySaving(remaining: remaining, until: dueDate)
        return "Cần để dành \(perMonth.vnd) mỗi tháng trong \(months) tháng."
    }

    var body: some View {
        SheetScaffold(title: original == nil ? "Thêm hũ tiết kiệm" : "Sửa hũ tiết kiệm",
                      canConfirm: canSave, onConfirm: save) {
            VStack(spacing: Spacing.xs) {
                Text("Mục tiêu")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                TimiAmountField(text: $targetText, focusesOnAppear: original == nil)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
        } content: {
            FormGroup {
                // No "Đã để dành": a goal starts empty and money goes in and out through "Nạp" /
                // "Rút" on its screen, so every change has an account and a date.
                FormTextRow(title: "Tên hũ", text: $name, prompt: "Du lịch Đà Nẵng")
            }

            FormGroup(title: "Biểu tượng") {
                IconQuickPicker(selection: $icon, suggestions: SavingsGoal.suggestedIcons)
            }

            FormGroup(footer: monthlyNote) {
                FormToggleRow(title: "Thời hạn", isOn: $hasDueDate.animation(.smooth(duration: 0.3)))
                if hasDueDate {
                    FormDivider(hasIcon: false)
                    FormDateRow(title: "Đến ngày", date: $dueDate, earliest: Self.tomorrow)
                        .transition(.opacity)
                }
            }

            if let original {
                FormGroup {
                    FormDestructiveRow(title: "Xoá hũ", question: "Xoá hũ “\(original.name)”?",
                                       message: "Số tiền trong hũ sẽ không còn được tính vào tổng số dư.") {
                        dismiss()
                        if let onDelete { onDelete() } else { store.delete(original) }
                    }
                }
            }
        }
        .timiSheetStyle()
    }

    private func save() {
        guard canSave else { return }
        var goal = original ?? SavingsGoal(name: trimmedName, icon: icon, saved: 0, target: 0)
        goal.name = trimmedName
        goal.icon = icon
        goal.target = targetText.vndInputAmount
        goal.dueDate = hasDueDate ? dueDate : nil
        store.save(goal)
        dismiss()
    }
}

#Preview("Sửa hũ") {
    GoalEditorView(goal: SampleData.savingsGoals[0])
        .environment(FinanceStore())
}
