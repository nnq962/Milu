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
    private var canSave: Bool { amount > 0 && accountID != nil }

    var body: some View {
        SheetScaffold(title: editing == nil ? "Thêm giao dịch" : "Sửa giao dịch",
                      canConfirm: canSave, onConfirm: save) {
            Picker("Loại giao dịch", selection: $kind) {
                ForEach(TransactionKind.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)

            TimiAmountField(text: $amountText, kind: kind, focusesOnAppear: editing == nil)
                .padding(.vertical, Spacing.s)
        } content: {
            FormGroup {
                FormTextRow(title: "Tên", text: $title, prompt: category.title)
                FormDivider(hasIcon: false)
                FormPickerRow(title: "Danh mục", selection: $category,
                              options: TransactionCategory.categories(for: kind),
                              optionIcon: { $0.icon }) { $0.title }
                if let accountID {
                    FormDivider(hasIcon: false)
                    FormPickerRow(title: "Tài khoản",
                                  selection: Binding { accountID } set: { self.accountID = $0 },
                                  options: store.accounts.map(\.id),
                                  optionIcon: { store.account(id: $0)?.iconName ?? "solar-wallet-linear" }) {
                        store.account(id: $0)?.name ?? "—"
                    }
                }
                FormDivider(hasIcon: false)
                FormDateRow(title: "Ngày", date: $date)
                FormDivider(hasIcon: false)
                FormTimeRow(title: "Giờ", date: $date)
            }

            FormGroup {
                FormNoteRow(text: $note, prompt: "Ghi chú")
            }

            if let editing {
                FormGroup {
                    FormDestructiveRow(title: "Xoá giao dịch", question: "Xoá giao dịch “\(editing.title)”?",
                                       message: "Số dư tài khoản sẽ được tính lại.") {
                        store.delete(editing)
                        dismiss()
                    }
                }
            }
        }
        .timiSheetStyle()
        .onChange(of: kind) { _, newKind in
            category = TransactionCategory.categories(for: newKind).first ?? category
        }
        .onAppear {
            accountID = accountID ?? store.accounts.first?.id
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
