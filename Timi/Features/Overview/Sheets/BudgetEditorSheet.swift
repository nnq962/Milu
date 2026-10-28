import SwiftUI

/// Sets the monthly spending limit; an empty or 0 amount removes it.
struct BudgetEditorSheet: View {
    @Binding var monthlyBudget: Double

    @Environment(\.dismiss) private var dismiss
    @State private var input: String

    init(monthlyBudget: Binding<Double>) {
        _monthlyBudget = monthlyBudget
        let current = monthlyBudget.wrappedValue
        _input = State(initialValue: current > 0 ? String(Int(current)).groupedVNDInput : "")
    }

    private var value: Double { input.vndInputAmount }
    private var isValid: Bool { value.isFinite && value <= 1_000_000_000_000 }

    var body: some View {
        SheetScaffold(title: "Hạn mức chi tiêu", canConfirm: isValid, onConfirm: save) {
            VStack(spacing: Spacing.xs) {
                Text("Mỗi tháng")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                TimiAmountField(text: $input, showsSuggestions: false, focusesOnAppear: true)
                Text("Áp dụng cho mọi tháng. Để trống hoặc nhập 0 để bỏ hạn mức.")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.s)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
        }
        .timiSheetStyle([.medium])
    }

    private func save() {
        guard isValid else { return }
        monthlyBudget = value
        dismiss()
    }
}
