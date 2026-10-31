import SwiftUI

/// Sets a spending limit. An empty or 0 amount removes it. `check` says what is wrong with an
/// amount (the groups' limits must fit in the month's, `BudgetRules`): ✓ then keeps the sheet open
/// and shows it in red under the amount.
struct BudgetEditorSheet: View {
    @Binding var amount: Double
    var title = "Hạn mức chi tiêu"
    var caption = "Mỗi tháng"
    /// Under the amount, only when there is something to know (a floor); none by default, as
    /// "Mỗi tháng" above already says it (strict review 2026-10-31).
    var note: String? = nil
    var check: (Double) -> String? = { _ in nil }
    /// Ready amounts offered while nothing is typed.
    var presets: [AmountPreset] = []

    @Environment(\.dismiss) private var dismiss
    @State private var input: String
    @State private var error: String?

    init(amount: Binding<Double>, title: String? = nil, caption: String? = nil, note: String? = nil,
         presets: [AmountPreset] = [], check: @escaping (Double) -> String? = { _ in nil }) {
        self.presets = presets
        _amount = amount
        if let title { self.title = title }
        if let caption { self.caption = caption }
        self.note = note
        self.check = check
        let current = amount.wrappedValue
        _input = State(initialValue: current > 0 ? String(Int(current)).groupedVNDInput : "")
    }

    private var value: Double { input.vndInputAmount }
    private var isValid: Bool { value.isFinite && value <= 1_000_000_000_000 }

    var body: some View {
        SheetScaffold(title: title, canConfirm: isValid, validate: validate, onConfirm: save) {
            VStack(spacing: Spacing.xs) {
                Text(caption)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                // Quick chips (user request 2026-10-30): ready amounts before typing, then the field's own
                // suggestions from the digits (5 → 5tr, 50tr…).
                TimiAmountField(text: $input, focusesOnAppear: true, presets: presets)
                if let error {
                    FormErrorText(text: error)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.s)
                } else if let note {
                    Text(note)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.s)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
            .animation(.easeOut(duration: 0.2), value: error)
        } content: {
            EmptyView()
        }
        // A new amount clears the old complaint until ✓ checks again.
        .onChange(of: input) { error = nil }
        // Large like every form sheet: the keyboard opens at once and the chips need room.
        .timiSheetStyle()
    }

    private func validate() -> Bool {
        error = check(value)
        return error == nil
    }

    private func save() {
        guard isValid else { return }
        amount = value
        dismiss()
    }
}

/// The month's limit; it may not drop below what the groups already hold.
struct MonthBudgetEditor: View {
    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = SampleData.categoryBudgets

    var body: some View {
        let groups = categoryBudgets.keeping(store.budgetGroupIDs)
        BudgetEditorSheet(amount: $monthlyBudget, title: "Hạn mức tháng",
                          note: groups.total > 0
                              ? "Tối thiểu \(groups.total.vndCompact), bằng tổng các hạng mục."
                              : nil,
                          // Common monthly limits, none below what the groups already hold.
                          presets: [5, 10, 15, 20, 30].map { AmountPreset(label: "", value: Double($0) * 1_000_000) }
                              .filter { $0.value >= groups.total }) { BudgetRules.monthError($0, groups: groups) }
    }
}

/// A group's limit; it fits in what the month has not given to other groups yet.
struct GroupBudgetEditor: View {
    /// 10%, 25% and 50% of what is still free (rounded down to 100k), and "Hết" for all of it, as
    /// "Hết" on a loan repayment.
    static func presets(room: Double) -> [AmountPreset] {
        guard room > 0 else { return [] }
        let shares = [(0.1, "10%"), (0.25, "25%"), (0.5, "50%")].compactMap { share, label -> AmountPreset? in
            let value = (room * share / 100_000).rounded(.down) * 100_000
            return value > 0 && value < room ? AmountPreset(label: label, value: value) : nil
        }
        return shares + [AmountPreset(label: "Hết", value: room)]
    }

    let groupID: String
    let name: String

    @Environment(FinanceStore.self) private var store
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = SampleData.monthlyBudget
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = SampleData.categoryBudgets

    var body: some View {
        let groups = categoryBudgets.keeping(store.budgetGroupIDs)
        let month = monthlyBudget
        let room = BudgetRules.room(for: groupID, month: month, groups: groups)
        // Saving also drops the limits of groups no longer in use.
        let amount = Binding(get: { groups[groupID] }, set: { value in
            var kept = groups
            kept[groupID] = value
            categoryBudgets = kept
        })
        BudgetEditorSheet(amount: amount, title: name, caption: "Hạn mức mỗi tháng",
                          note: month > 0
                              ? "Còn \(room.vndCompact) chưa phân bổ."
                              : "Cần đặt hạn mức tháng trước.",
                          presets: Self.presets(room: room)) {
            BudgetRules.groupError($0, groupID: groupID, month: month, groups: groups)
        }
    }
}
