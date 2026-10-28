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
    @State private var isConfirmingDelete = false

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
        NavigationStack {
            Form {
                Section {
                    TextField("Tên hũ (VD: Du lịch Đà Nẵng)", text: $name)
                    Picker("Biểu tượng", selection: $icon) {
                        ForEach(GoalIcon.allCases) { icon in
                            Label(icon.title, image: icon.rawValue).tag(icon)
                        }
                    }
                }

                Section("Số tiền mục tiêu") {
                    AmountField(text: $targetText)
                }

                Section("Đã để dành") {
                    AmountField(text: $savedText)
                }

                if original != nil {
                    Section {
                        Button("Xoá hũ", role: .destructive) { isConfirmingDelete = true }
                    }
                }
            }
            .navigationTitle(original == nil ? "Thêm hũ tiết kiệm" : "Sửa hũ tiết kiệm")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneButton()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu", action: save)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Xoá hũ “\(trimmedName)”?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Xoá hũ", role: .destructive) {
                    if let original { store.delete(original) }
                    dismiss()
                }
            } message: {
                Text("Số tiền trong hũ sẽ không còn được tính vào tổng số dư.")
            }
        }
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
