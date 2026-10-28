import SwiftUI

/// Sets the monthly spending limit; 0 removes it.
struct BudgetEditorSheet: View {
    @Binding var monthlyBudget: Double

    @Environment(\.dismiss) private var dismiss
    @State private var input: String

    init(monthlyBudget: Binding<Double>) {
        _monthlyBudget = monthlyBudget
        let current = monthlyBudget.wrappedValue
        _input = State(initialValue: current > 0 ? String(Int(current)) : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Hạn mức mỗi tháng (VND)") {
                    TextField("Ví dụ: 30000000", text: $input).keyboardType(.numberPad)
                    Text("Áp dụng cho mỗi tháng. Nhập 0 để bỏ hạn mức.")
                        .font(Typography.font(.caption, size: 12, weight: .medium)).foregroundStyle(Palette.secondaryText)
                }
                Section {
                    Button("Áp dụng hạn mức") {
                        guard let value = Double(input), value.isFinite, value >= 0, value <= 1_000_000_000_000 else { return }
                        monthlyBudget = value
                        dismiss()
                    }
                    .disabled(Double(input).map { !$0.isFinite || $0 < 0 || $0 > 1_000_000_000_000 } ?? true)
                }
            }
            .navigationTitle("Hạn mức chi tiêu").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .keyboardDoneButton()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}
