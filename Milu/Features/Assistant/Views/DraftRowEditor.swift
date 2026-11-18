import SwiftUI

/// A row of a card waiting for "Lưu", changed before it is saved: spending or income, the amount,
/// the item (or the new one Milu proposed), the account, the day and the note. ✓ writes back into
/// the card, never into the store: the card's "Lưu" saves (user choice 2026-11-17). Made of the
/// add form's own rows, apart from it, so the form people add with stays as it is.
struct DraftRowEditor: View {
    let row: TransactionDraft.Row
    let onSave: (TransactionDraft.Row) -> Void
    let onRemove: () -> Void

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var kind: TransactionKind
    @State private var amountText: String
    @State private var categoryID: String
    @State private var newItem: TransactionDraft.NewItem?
    @State private var accountID: Account.ID
    @State private var date: Date
    @State private var note: String
    @State private var showsErrors = false
    /// The item picked for each kind, so Chi → Thu → Chi keeps it, as the add form does.
    @State private var pickedByKind: [TransactionKind: String] = [:]

    init(row: TransactionDraft.Row, onSave: @escaping (TransactionDraft.Row) -> Void, onRemove: @escaping () -> Void) {
        self.row = row
        self.onSave = onSave
        self.onRemove = onRemove
        let transaction = row.transaction
        _kind = State(initialValue: transaction.kind)
        _amountText = State(initialValue: String(Int(transaction.amount)).groupedVNDInput)
        _categoryID = State(initialValue: transaction.categoryID)
        _newItem = State(initialValue: row.newItem)
        _accountID = State(initialValue: transaction.accountID)
        _date = State(initialValue: transaction.date)
        _note = State(initialValue: transaction.note)
    }

    private var amount: Double { amountText.vndInputAmount }

    private var hasChanges: Bool {
        let original = row.transaction
        return kind != original.kind || amount != original.amount || categoryID != original.categoryID
            || newItem != row.newItem || accountID != original.accountID || date != original.date || note != original.note
    }

    private var missesCategory: Bool {
        newItem == nil && !CategoryPickerRow.isPickable(categoryID, kind: kind, in: store)
    }

    /// Accounts it can go on, and the one it is on even if locked since (said red on the card).
    private var accountOptions: [Account.ID] {
        store.accounts.filter { !$0.isLocked || $0.id == row.transaction.accountID }.map(\.id)
    }

    private var accountProblem: String? {
        guard let account = store.account(id: accountID) else { return "Chọn tài khoản khác." }
        if account.isArchived { return "Tài khoản “\(account.name)” đã lưu trữ: chọn tài khoản khác." }
        return account.isLocked ? "Tài khoản “\(account.name)” đang khoá: chọn tài khoản khác." : nil
    }

    private var detailsError: String? {
        if let accountProblem { return accountProblem }
        guard showsErrors, missesCategory else { return nil }
        return "Chọn hạng mục."
    }

    private func validate() -> Bool {
        withAnimation(Motion.gentle(.smooth(duration: 0.3))) { showsErrors = true }
        return amount >= 1 && !missesCategory && accountProblem == nil
    }

    var body: some View {
        SheetScaffold(title: "Sửa khoản chờ lưu", validate: validate, onConfirm: save, hasChanges: hasChanges) {
            ScaledSegmentedPicker(title: "Loại giao dịch", selection: $kind, options: TransactionKind.allCases) { $0.title }
                .controlSize(.large)
            VStack(spacing: Spacing.s) {
                MiluAmountField(text: $amountText, kind: kind, showsSuggestions: true, focusesOnAppear: false)
                if showsErrors, amount < 1 {
                    FormErrorText(message: "Nhập số tiền.")
                }
            }
            .padding(.vertical, Spacing.s)
        } content: {
            FormGroup(title: "Chi tiết", error: detailsError) {
                if let newItem {
                    // The item Milu proposes, made on "Lưu"; or one the user already has instead.
                    FormInfoRow(title: "Hạng mục", value: "\(newItem.name) (mới)",
                                valueIcon: store.categoryIcon(newItem.groupID))
                    FormDivider(hasIcon: false)
                    FormActionRow(title: "Chọn hạng mục có sẵn") {
                        withAnimation(Motion.gentle(.smooth(duration: 0.25))) { self.newItem = nil }
                    }
                } else {
                    CategoryPickerRow(kind: kind, selection: $categoryID, showsError: showsErrors)
                }
                FormDivider(hasIcon: false)
                FormPickerRow(title: "Tài khoản", selection: $accountID, options: accountOptions,
                              optionIcon: { store.account(id: $0)?.iconName ?? "hugeicons-wallet-01" }) {
                    store.pickerName(of: $0) ?? "—"
                }
                FormDivider(hasIcon: false)
                // Money already moved: no day after today, as on the add form.
                FormDateTimeRow(title: "Thời gian", date: $date, latest: .now)
            }
            FormGroup(title: "Ghi chú") {
                FormNoteRow(text: $note, prompt: "Thêm ghi chú")
            }
            FormGroup {
                FormDestructiveRow(title: "Bỏ khoản này", question: "Bỏ khoản này?",
                                   message: "Khoản này sẽ không được lưu.") {
                    dismiss()
                    onRemove()
                }
            }
        }
        .miluSheetStyle()
        // An item of the other kind no longer fits: the one picked for the new kind comes back, or
        // none; an item to make goes with its group's kind.
        .onChange(of: kind) { oldKind, newKind in
            pickedByKind[oldKind] = categoryID
            if let newItem, store.category(id: newItem.groupID)?.kind != newKind { self.newItem = nil }
            if !CategoryPickerRow.isPickable(categoryID, kind: newKind, in: store) {
                categoryID = pickedByKind[newKind] ?? ""
            }
        }
    }

    private func save() {
        var changed = row
        changed.transaction.kind = kind
        changed.transaction.amount = amount
        changed.transaction.categoryID = newItem == nil ? categoryID : ""
        changed.newItem = newItem
        changed.transaction.accountID = accountID
        changed.transaction.date = date
        changed.transaction.note = note
        // Picked by the user now, unless left as Milu chose it.
        changed.accountChosenByApp = row.accountChosenByApp && accountID == row.transaction.accountID
        changed.problem = nil
        changed.warning = DraftChecks.duplicate(of: changed, in: store)
        dismiss()
        onSave(changed)
    }
}
