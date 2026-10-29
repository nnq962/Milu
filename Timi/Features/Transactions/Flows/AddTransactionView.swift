import SwiftUI

/// Adds a transaction or a transfer between two accounts, or edits `editing` / `editingTransfer`
/// (and then offers to delete it). Spending and income have no name: they are filed under an item
/// of "Hạng mục" (`CategoryPickerRow`) and show it, and can be left out of reports; a transfer has
/// a source, a destination and an optional fee, recorded as spending from the source (user
/// choices 2026-10-29). The last account used is picked first; the category never is. ✓ always
/// answers: with the amount or the category missing it says so in red instead of saving.
struct AddTransactionView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case expense, income, transfer

        var id: Self { self }

        var title: String {
            switch self {
            case .expense: "Chi tiêu"
            case .income: "Thu nhập"
            case .transfer: "Chuyển khoản"
            }
        }

        var kind: TransactionKind? {
            switch self {
            case .expense: .expense
            case .income: .income
            case .transfer: nil
            }
        }
    }

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("transactions.lastAccountID") private var lastAccountID = ""

    /// Giao dịch đang sửa; nil khi thêm mới.
    private let editing: FinanceTransaction?
    /// The account to start on (the one being viewed); otherwise the last one used.
    private var preferredAccount: Account.ID? = nil
    private let editingTransfer: AccountTransfer?
    @State private var mode: Mode
    @State private var amountText: String
    @State private var categoryID: String
    @State private var isExcluded: Bool
    @State private var accountID: Account.ID?
    @State private var toAccountID: Account.ID?
    @State private var feeText: String
    @State private var date: Date
    @State private var note: String
    /// Set by the first ✓ with something missing: the amount and the category then say so in red.
    @State private var showsErrors = false
    /// The item picked for each kind, so switching Chi tiêu → Thu nhập → Chi tiêu keeps it.
    @State private var pickedByKind: [TransactionKind: String] = [:]

    init(editing: FinanceTransaction? = nil, preferredAccount: Account.ID? = nil) {
        self.editing = editing
        self.preferredAccount = preferredAccount
        editingTransfer = nil
        _mode = State(initialValue: editing?.kind == .income ? .income : .expense)
        _amountText = State(initialValue: editing.map { String(Int($0.amount)).groupedVNDInput } ?? "")
        _categoryID = State(initialValue: editing?.categoryID ?? "")
        _isExcluded = State(initialValue: editing?.isExcluded ?? false)
        _accountID = State(initialValue: editing?.accountID)
        _toAccountID = State(initialValue: nil)
        _feeText = State(initialValue: "")
        _date = State(initialValue: editing?.date ?? .now)
        _note = State(initialValue: editing?.note ?? "")
    }

    init(editingTransfer transfer: AccountTransfer) {
        editing = nil
        editingTransfer = transfer
        _mode = State(initialValue: .transfer)
        _amountText = State(initialValue: String(Int(transfer.amount)).groupedVNDInput)
        _categoryID = State(initialValue: "")
        _isExcluded = State(initialValue: false)
        _accountID = State(initialValue: transfer.fromAccountID)
        _toAccountID = State(initialValue: transfer.toAccountID)
        _feeText = State(initialValue: transfer.fee > 0 ? String(Int(transfer.fee)).groupedVNDInput : "")
        _date = State(initialValue: transfer.date)
        _note = State(initialValue: transfer.note)
    }

    private var isEditing: Bool { editing != nil || editingTransfer != nil }
    private var amount: Double { amountText.vndInputAmount }
    private var fee: Double { feeText.vndInputAmount }

    /// A balance adjustment or spending from a goal keeps its kind (it would turn into reported
    /// income or spending, and a goal only spends); a transaction stays a transaction and a
    /// transfer a transfer.
    private var isModeFixed: Bool {
        guard let editing else { return editingTransfer != nil }
        return editing.isAdjustment || store.goal(id: editing.accountID) != nil
    }

    /// The modes offered: a transaction being edited can switch between spending and income only;
    /// a transfer being edited stays one (no switch shown).
    private var modes: [Mode] {
        if editingTransfer != nil { return [] }
        return editing == nil ? Mode.allCases : [.expense, .income]
    }

    /// Spending from a goal stays on that goal; other transactions pick an unlocked account in use
    /// (plus the one they are on).
    private var accountOptions: [Account.ID] {
        if let editing, store.goal(id: editing.accountID) != nil { return [editing.accountID] }
        let kept = [editing?.accountID, editingTransfer?.fromAccountID, editingTransfer?.toAccountID]
        return store.accounts.filter { !$0.isLocked || kept.contains($0.id) }.map(\.id)
    }

    /// Read-only: spent from a closed goal, or on an archived account.
    private var readOnlyReason: String? {
        if let editing { return store.readOnlyReason(editing) }
        if let editingTransfer { return store.readOnlyReason(editingTransfer) }
        return nil
    }
    private var isReadOnly: Bool { readOnlyReason != nil }

    /// A balance adjustment keeps its own category, never offered in the picker.
    private var keepsSystemCategory: Bool { editing?.isAdjustment == true }

    /// A rule broken, shown at once: nothing to record on, two times the same account, more than a
    /// goal holds.
    private var error: String? {
        if accountID == nil, !isEditing {
            return mode == .transfer && !store.usableAccounts.isEmpty
                ? "Cần ít nhất hai tài khoản để chuyển khoản."
                : "Chưa có tài khoản để ghi. Thêm tài khoản ở tab Tài khoản."
        }
        if mode == .transfer {
            if store.usableAccounts.count < 2, !isEditing { return "Cần ít nhất hai tài khoản để chuyển khoản." }
            if accountID != nil, accountID == toAccountID { return "Chọn hai tài khoản khác nhau." }
            return nil
        }
        guard mode == .expense, let accountID, let goal = store.goal(id: accountID) else { return nil }
        // Spending recorded on a goal ("Dùng tiền", then reopened) cannot take more than the goal holds.
        let available = goal.saved + (editing?.accountID == accountID && editing?.kind == .expense ? editing?.amount ?? 0 : 0)
        return amount > available ? "Hũ chỉ có \(available.vnd)." : nil
    }

    private var missesAmount: Bool { amount <= 0 }
    private var missesCategory: Bool {
        guard mode != .transfer, !keepsSystemCategory, let kind = mode.kind else { return false }
        return !CategoryPickerRow.isPickable(categoryID, kind: kind, in: store, kept: editing?.categoryID)
    }

    /// What is wrong with the category, in words: none picked (switching the kind empties it too),
    /// a group (a transaction from before items existed), or one hidden or deleted since.
    private var categoryProblem: String? {
        guard missesCategory else { return nil }
        if categoryID.isEmpty { return "Chọn hạng mục." }
        let picked = store.category(id: categoryID)
        if picked?.isGroup ?? (TransactionCategory(rawValue: categoryID) != nil) {
            return "Chọn hạng mục con cho giao dịch này."
        }
        return "“\(store.categoryName(categoryID))” không còn dùng được. Chọn hạng mục khác."
    }

    /// The red line under "Chi tiết": a rule broken, or what is wrong with the category. A category
    /// not picked yet waits for the first ✓; one that is there but no longer fits says so at once,
    /// as its row is already red.
    private var detailsError: String? {
        if let error { return error }
        guard let categoryProblem, showsErrors || !categoryID.isEmpty else { return nil }
        return categoryProblem
    }

    private var canSave: Bool {
        guard !missesAmount, !missesCategory, accountID != nil, !isReadOnly, error == nil else { return false }
        return mode != .transfer || toAccountID != nil
    }

    /// ✓ with something missing: shows what, keeps the sheet open (SheetScaffold buzzes).
    private func validate() -> Bool {
        withAnimation(.smooth(duration: 0.3)) { showsErrors = true }
        return canSave
    }

    var body: some View {
        SheetScaffold(title: title(for: isEditing), canConfirm: !isReadOnly, validate: validate, onConfirm: save) {
            if !modes.isEmpty {
                Picker("Loại giao dịch", selection: $mode) {
                    ForEach(modes) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .disabled(isModeFixed || isReadOnly)
            }

            VStack(spacing: Spacing.s) {
                TimiAmountField(text: $amountText, kind: mode.kind, showsSuggestions: !isReadOnly,
                                focusesOnAppear: !isEditing)
                if showsErrors, missesAmount {
                    FormErrorText(text: "Nhập số tiền.")
                }
            }
            .padding(.vertical, Spacing.s)
            .disabled(isReadOnly)
        } content: {
            FormGroup(title: "Chi tiết", footer: readOnlyReason ?? footer, error: detailsError) {
                if mode == .transfer {
                    transferRows
                } else {
                    transactionRows
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

            // A balance adjustment is never counted, a transfer neither: the choice is for spending
            // and income.
            if mode != .transfer, !keepsSystemCategory {
                FormGroup(footer: !isExcluded ? nil
                          : accountID.flatMap(store.goal(id:)) != nil ? "Vẫn tính vào số tiền trong hũ."
                          : "Vẫn tính vào số dư tài khoản.") {
                    FormToggleRow(title: "Không tính vào báo cáo", isOn: $isExcluded)
                }
                .disabled(isReadOnly)
            }

            if isEditing, !isReadOnly {
                FormGroup { deleteRow }
            }
        }
        .timiSheetStyle()
        // An item of the other kind no longer fits: the one picked for the new kind comes back, or
        // none (the user picks). Editing too: Ăn trưa → Thu nhập is empty, back → Ăn trưa again.
        .onChange(of: mode) { oldMode, newMode in
            guard !isModeFixed else { return }
            if let oldKind = oldMode.kind { pickedByKind[oldKind] = categoryID }
            guard let kind = newMode.kind,
                  !CategoryPickerRow.isPickable(categoryID, kind: kind, in: store) else { return }
            categoryID = pickedByKind[kind] ?? ""
        }
        .onAppear(perform: fillDefaults)
    }

    private func title(for isEditing: Bool) -> String {
        switch (mode, isEditing) {
        case (.transfer, false): "Chuyển khoản"
        case (.transfer, true): "Sửa chuyển khoản"
        case (_, false): "Thêm giao dịch"
        case (_, true): "Sửa giao dịch"
        }
    }

    /// Under the details: a transfer with a fee says where the fee goes.
    private var footer: String? {
        guard mode == .transfer, fee > 0 else { return nil }
        let source = accountID.flatMap { store.account(id: $0)?.name } ?? "tài khoản nguồn"
        return "Phí \(fee.vnd) trừ thêm vào \(source) và tính là chi tiêu."
    }

    @ViewBuilder
    private var transactionRows: some View {
        if keepsSystemCategory {
            FormValueLabel(title: "Hạng mục", icon: nil, value: store.categoryName(categoryID),
                           valueIcon: store.categoryIcon(categoryID))
        } else if let kind = mode.kind {
            CategoryPickerRow(kind: kind, selection: $categoryID, showsError: showsErrors,
                              kept: editing?.categoryID)
        }
        if let accountID {
            FormDivider(hasIcon: false)
            accountRow(title: "Tài khoản", selection: accountID) { self.accountID = $0 }
        }
    }

    @ViewBuilder
    private var transferRows: some View {
        // Picking on one side the account already on the other swaps them.
        if let accountID {
            accountRow(title: "Từ", selection: accountID) { new in
                if new == toAccountID { toAccountID = self.accountID }
                self.accountID = new
            }
        }
        if let toAccountID {
            FormDivider(hasIcon: false)
            accountRow(title: "Đến", selection: toAccountID) { new in
                if new == accountID { accountID = self.toAccountID }
                self.toAccountID = new
            }
        }
        FormDivider(hasIcon: false)
        FormAmountRow(title: "Phí", text: $feeText)
    }

    private func accountRow(title: String, selection: Account.ID, set: @escaping (Account.ID) -> Void) -> some View {
        FormPickerRow(title: title,
                      selection: Binding { selection } set: { set($0) },
                      options: mode == .transfer ? accountOptions.filter { store.account(id: $0) != nil } : accountOptions,
                      optionIcon: { store.account(id: $0)?.iconName ?? store.goal(id: $0)?.icon ?? "hugeicons-wallet-01" }) {
            // A goal when the money was spent from one ("Dùng tiền").
            store.account(id: $0)?.name ?? store.goal(id: $0)?.name ?? "Hũ đã xoá"
        }
    }

    @ViewBuilder
    private var deleteRow: some View {
        if let editingTransfer {
            FormDestructiveRow(title: "Xoá chuyển khoản", question: "Xoá chuyển khoản này?",
                               message: "Số dư hai tài khoản sẽ được tính lại.") {
                store.delete(editingTransfer)
                dismiss()
            }
        } else if let editing {
            FormDestructiveRow(title: "Xoá giao dịch", question: "Xoá giao dịch “\(store.title(of: editing))”?",
                               message: store.goal(id: editing.accountID) != nil
                                   ? "Số tiền được trả lại vào hũ."
                                   : "Số dư tài khoản sẽ được tính lại.") {
                store.delete(editing)
                dismiss()
            }
        }
    }

    private func fillDefaults() {
        let usable = store.usableAccounts.map(\.id)
        if accountID == nil {
            let last = UUID(uuidString: lastAccountID)
            accountID = [preferredAccount, last].compactMap { $0 }.first { usable.contains($0) } ?? usable.first
        }
        if toAccountID == nil {
            toAccountID = usable.first { $0 != accountID }
        }
    }

    private func save() {
        guard canSave, let accountID else { return }
        if mode == .transfer {
            guard let toAccountID else { return }
            var transfer = editingTransfer ?? AccountTransfer(fromAccountID: accountID, toAccountID: toAccountID,
                                                              amount: amount, date: date)
            transfer.fromAccountID = accountID
            transfer.toAccountID = toAccountID
            transfer.amount = amount
            transfer.fee = fee
            transfer.date = date
            transfer.note = note
            if editingTransfer == nil { store.add(transfer) } else { store.update(transfer) }
        } else {
            guard let kind = mode.kind else { return }
            // No name of its own: it shows its category.
            var transaction = editing ?? FinanceTransaction(amount: 0, categoryID: categoryID, kind: kind,
                                                            accountID: accountID, date: date)
            transaction.amount = amount
            transaction.isExcluded = isExcluded && !keepsSystemCategory
            transaction.categoryID = categoryID
            transaction.kind = kind
            transaction.accountID = accountID
            transaction.date = date
            transaction.note = note
            if editing == nil { store.add(transaction) } else { store.update(transaction) }
        }
        if store.account(id: accountID) != nil { lastAccountID = accountID.uuidString }
        dismiss()
    }
}

/// The form for a transaction opened to change it (the pencil of its view sheet, the assistant).
struct TransactionEditSheet: View {
    let transaction: FinanceTransaction

    var body: some View {
        AddTransactionView(editing: transaction)
    }
}

#Preview {
    AddTransactionView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
