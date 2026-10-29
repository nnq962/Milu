import SwiftUI

/// Adds a transaction, or edits `editing` (and then offers to delete it).
struct AddTransactionView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Giao dịch đang sửa; nil khi thêm mới.
    private let editing: FinanceTransaction?
    @State private var kind: TransactionKind
    @State private var amountText: String
    @State private var title: String
    @State private var category: TransactionCategory
    @State private var accountID: Account.ID?
    @State private var date: Date
    @State private var note: String

    init(editing: FinanceTransaction? = nil) {
        self.editing = editing
        _kind = State(initialValue: editing?.kind ?? .expense)
        _amountText = State(initialValue: editing.map { String(Int($0.amount)).groupedVNDInput } ?? "")
        _title = State(initialValue: editing?.title ?? "")
        _category = State(initialValue: editing?.category ?? .food)
        _accountID = State(initialValue: editing?.accountID)
        _date = State(initialValue: editing?.date ?? .now)
        _note = State(initialValue: editing?.note ?? "")
    }

    private var amount: Double { amountText.vndInputAmount }

    /// The categories to pick from; a balance adjustment being edited keeps its own, which is
    /// never offered otherwise.
    private var categoryOptions: [TransactionCategory] {
        let options = TransactionCategory.categories(for: kind)
        if let editing, editing.category.isAdjustment, editing.category.kind == kind {
            return [editing.category] + options
        }
        return options
    }
    /// The kind stays as it is for a balance adjustment (it would turn into reported income or
    /// spending) and for spending from a goal (a goal only spends).
    private var isKindFixed: Bool {
        guard let editing else { return false }
        return editing.category.isAdjustment || store.goal(id: editing.accountID) != nil
    }

    /// Spending from a goal stays on that goal; other transactions pick an unlocked account in use
    /// (plus the one they are on).
    private var accountOptions: [Account.ID] {
        if let editing, store.goal(id: editing.accountID) != nil { return [editing.accountID] }
        return store.accounts.filter { !$0.isLocked || $0.id == editing?.accountID }.map(\.id)
    }

    /// Spent from a closed goal: shown, but changed only once the goal is reopened.
    private var isReadOnly: Bool { editing.map { !store.isEditable($0) } ?? false }
    /// Spending recorded on a goal ("Dùng tiền", then reopened) cannot take more than the goal holds.
    private var goalLimitError: String? {
        guard kind == .expense, let accountID, let goal = store.goal(id: accountID) else { return nil }
        let available = goal.saved + (editing?.accountID == accountID && editing?.kind == .expense ? editing?.amount ?? 0 : 0)
        return amount > available ? "Hũ chỉ có \(available.vnd)." : nil
    }
    private var canSave: Bool { amount > 0 && accountID != nil && !isReadOnly && goalLimitError == nil }

    var body: some View {
        SheetScaffold(title: editing == nil ? "Thêm giao dịch" : "Sửa giao dịch",
                      canConfirm: canSave, onConfirm: save) {
            Picker("Loại giao dịch", selection: $kind) {
                ForEach(TransactionKind.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .disabled(isKindFixed || isReadOnly)

            TimiAmountField(text: $amountText, kind: kind, showsSuggestions: !isReadOnly,
                            focusesOnAppear: editing == nil)
                .padding(.vertical, Spacing.s)
                .disabled(isReadOnly)
        } content: {
            FormGroup(title: "Chi tiết",
                      footer: editing.flatMap(store.readOnlyReason),
                      error: goalLimitError) {
                FormTextRow(title: "Tên", text: $title, prompt: category.title)
                FormDivider(hasIcon: false)
                FormPickerRow(title: "Danh mục", selection: $category,
                              options: categoryOptions,
                              optionIcon: { $0.icon }) { $0.title }
                if let accountID {
                    FormDivider(hasIcon: false)
                    FormPickerRow(title: "Tài khoản",
                                  selection: Binding { accountID } set: { self.accountID = $0 },
                                  options: accountOptions,
                                  optionIcon: { store.account(id: $0)?.iconName ?? store.goal(id: $0)?.icon ?? "hugeicons-wallet-01" }) {
                        // A goal when the money was spent from one ("Dùng tiền").
                        store.account(id: $0)?.name ?? store.goal(id: $0)?.name ?? "Hũ đã xoá"
                    }
                }
                FormDivider(hasIcon: false)
                FormDateRow(title: "Ngày", date: $date)
                FormDivider(hasIcon: false)
                FormTimeRow(title: "Giờ", date: $date)
            }
            // Read-only (closed goal, archived account): shown, not typed into.
            .disabled(isReadOnly)

            FormGroup(title: "Ghi chú") {
                FormNoteRow(text: $note, prompt: "Thêm ghi chú")
            }
            .disabled(isReadOnly)

            if let editing, !isReadOnly {
                FormGroup {
                    FormDestructiveRow(title: "Xoá giao dịch", question: "Xoá giao dịch “\(editing.title)”?",
                                       message: store.goal(id: editing.accountID) != nil
                                           ? "Số tiền được trả lại vào hũ."
                                           : "Số dư tài khoản sẽ được tính lại.") {
                        store.delete(editing)
                        dismiss()
                    }
                }
            }
        }
        .timiSheetStyle()
        .onChange(of: kind) { _, newKind in
            guard !isKindFixed else { return }
            category = TransactionCategory.categories(for: newKind).first ?? category
        }
        .onAppear {
            accountID = accountID ?? store.usableAccounts.first?.id
        }
    }

    private func save() {
        guard let accountID, amount > 0 else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var transaction = editing ?? FinanceTransaction(title: "", amount: 0, category: category, accountID: accountID, date: date)
        transaction.title = trimmedTitle.isEmpty ? category.title : trimmedTitle
        transaction.amount = amount
        transaction.category = category
        transaction.accountID = accountID
        transaction.date = date
        transaction.note = note
        if editing == nil {
            store.add(transaction)
        } else {
            store.update(transaction)
        }
        dismiss()
    }
}

#Preview {
    AddTransactionView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
