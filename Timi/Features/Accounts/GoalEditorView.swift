import SwiftUI

/// Creates a new savings goal when `goal` is nil, otherwise edits or deletes it.
struct GoalEditorView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let original: SavingsGoal?
    @State private var name: String
    @State private var icon: GoalIcon
    @State private var savedText: String
    @State private var targetText: String

    init(goal: SavingsGoal?) {
        original = goal
        _name = State(initialValue: goal?.name ?? "")
        _icon = State(initialValue: goal?.icon ?? .piggyBank)
        _savedText = State(initialValue: goal.map { $0.saved > 0 ? String(Int($0.saved)).groupedVNDInput : "" } ?? "")
        _targetText = State(initialValue: goal.map { String(Int($0.target)).groupedVNDInput } ?? "")
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && targetText.vndInputAmount > 0 }

    var body: some View {
        SheetScaffold(title: original == nil ? "Thêm hũ tiết kiệm" : "Sửa hũ tiết kiệm",
                      canConfirm: canSave, onConfirm: save) {
            VStack(spacing: Spacing.xs) {
                Text("Số tiền mục tiêu")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                TimiAmountField(text: $targetText, focusesOnAppear: original == nil)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
        } content: {
            FormGroup {
                FormTextRow(title: "Tên hũ", text: $name, prompt: "Du lịch Đà Nẵng")
                FormDivider(hasIcon: false)
                FormPickerRow(title: "Biểu tượng", selection: $icon, options: GoalIcon.allCases,
                              optionIcon: { $0.rawValue }) { $0.title }
                FormDivider(hasIcon: false)
                FormAmountRow(title: "Đã để dành", text: $savedText)
            }

            if let original {
                FormGroup {
                    FormDestructiveRow(title: "Xoá hũ", question: "Xoá hũ “\(original.name)”?",
                                       message: "Số tiền trong hũ sẽ không còn được tính vào tổng số dư.") {
                        store.delete(original)
                        dismiss()
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
        goal.saved = savedText.vndInputAmount
        goal.target = targetText.vndInputAmount
        store.save(goal)
        dismiss()
    }
}

#Preview("Sửa hũ") {
    GoalEditorView(goal: SampleData.savingsGoals[0])
        .environment(FinanceStore())
}
