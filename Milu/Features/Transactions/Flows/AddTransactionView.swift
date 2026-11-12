import SwiftUI

/// Adds a transaction or a transfer between two accounts, or edits `editing` / `editingTransfer`
/// (and then offers to delete it). Spending and income have no name: they are filed under an item
/// of "Hạng mục" (`CategoryPickerRow`) and show it, and can be left out of reports; a transfer has
/// a source, a destination and an optional fee, recorded as spending from the source (user
/// choices 2026-10-29). The last account used is picked first; the category never is. ✓ always
/// answers: with the amount or the category missing it says so in red instead of saving.
/// Opened from "Mua ngay" on a goal that reached its target (`buying:`), it records spending from
/// the goal: the goal is the account (fixed), the amount starts at what it holds, whatever is left
/// goes to an account, and saving closes the goal.
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
    @Environment(\.recordSheetDismiss) private var recordSheetDismiss
    @AppStorage(StorageKey.lastAccountID) private var lastAccountID = ""
    @AppStorage(StorageKey.monthlyBudget) private var monthlyBudget = 0.0
    @AppStorage(StorageKey.categoryBudgets) private var categoryBudgets = CategoryBudgets()

    /// Giao dịch đang sửa; nil khi thêm mới.
    private let editing: FinanceTransaction?
    /// The account to start on (the one being viewed); otherwise the last one used.
    private var preferredAccount: Account.ID? = nil
    private let editingTransfer: AccountTransfer?
    /// "Mua ngay": the goal the money is spent from, and what it held when the sheet opened (saving
    /// empties and closes it, and the sheet must not redraw on that while it slides away).
    private var buyingGoal: SavingsGoal.ID? = nil
    private var buyingSaved: Double = 0
    private var buyingName = ""
    private var buyingIcon = ""
    /// Where what the goal still holds after the purchase goes.
    @State private var leftoverAccount: Account.ID?
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
    /// The account of Chi tiêu / Thu nhập, kept while Chuyển khoản is shown.
    @State private var accountBeforeTransfer: Account.ID?

    init(editing: FinanceTransaction? = nil, preferredAccount: Account.ID? = nil) {
        self.editing = editing
        self.preferredAccount = preferredAccount
        editingTransfer = nil
        _mode = State(initialValue: editing?.kind == .income ? .income : .expense)
        _amountText = State(initialValue: editing.map { String(Int($0.amount)).groupedVNDInput } ?? "")
        _categoryID = State(initialValue: editing?.categoryID ?? "")
        _isExcluded = State(initialValue: editing?.isExcluded ?? false)
        // Known from the first frame, so the "Tài khoản" row is there as the sheet slides up: set
        // on appear it popped in and the form jumped (user report 2026-10-30). `fillDefaults`
        // still swaps it for a usable one if this one is not.
        _accountID = State(initialValue: editing?.accountID
            ?? preferredAccount ?? UserDefaults.standard.string(forKey: StorageKey.lastAccountID).flatMap(UUID.init))
        _toAccountID = State(initialValue: nil)
        _feeText = State(initialValue: "")
        _date = State(initialValue: editing?.date ?? .now)
        _note = State(initialValue: editing?.note ?? "")
    }

    /// A new one starting on `mode`: the quick actions on Tổng quan (Ghi chi, Ghi thu, Chuyển tiền).
    init(mode: Mode) {
        self.init()
        _mode = State(initialValue: mode)
        // A transfer's two accounts are the user's to pick (user request 2026-10-30).
        if mode == .transfer { _accountID = State(initialValue: nil) }
    }

    /// "Mua ngay" on a goal that reached its target.
    init(buying goal: SavingsGoal) {
        self.init()
        buyingGoal = goal.id
        buyingSaved = goal.saved
        buyingName = goal.name
        buyingIcon = goal.icon
        _accountID = State(initialValue: goal.id)
        _amountText = State(initialValue: String(Int(goal.saved)).groupedVNDInput)
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
    private var goalBought: SavingsGoal? { buyingGoal.flatMap { store.goal(id: $0) } }
    /// What the goal still holds after this purchase.
    private var leftover: Double { buyingGoal == nil ? 0 : buyingSaved - amount }
    private var leftoverOptions: [Account.ID] { store.paymentAccounts.filter { !$0.isLocked }.map(\.id) }
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
        if editingTransfer != nil || buyingGoal != nil { return [] }
        return editing == nil ? Mode.allCases : [.expense, .income]
    }

    /// Spending from a goal stays on that goal; other transactions pick an unlocked account in use
    /// (plus the one they are on).
    private var accountOptions: [Account.ID] {
        if let buyingGoal { return [buyingGoal] }
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
        if mode == .transfer, store.usableAccounts.count >= 2, !isEditing, accountID == nil || toAccountID == nil {
            return showsErrors ? "Chọn tài khoản chuyển và nhận." : nil
        }
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
        if buyingGoal != nil {
            if amount > buyingSaved { return "Hũ chỉ có \(buyingSaved.vnd)." }
            // "Mua ngay" closes the goal: what is left needs somewhere to go.
            if leftover >= 1, leftoverAccount == nil {
                return "Còn \(leftover.vnd) trong hũ. \(GoalTransferSheet.noAccountError(store))"
            }
            return nil
        }
        guard mode == .expense, let accountID, let goal = store.goal(id: accountID) else { return nil }
        // Spending recorded on a goal ("Mua ngay", then reopened) cannot take more than the goal holds.
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
        withAnimation(Motion.gentle(.smooth(duration: 0.3))) { showsErrors = true }
        return canSave
    }

    /// Read-only (a closed goal, an archived account): no ✓ at all rather than a grey one.
    private var confirmAction: (() -> Void)? {
        isReadOnly ? nil : { save() }
    }

    var body: some View {
        // Worked out once a draw: each scans the month's spending, and it was asked twice (the
        // note and its animation) on every keystroke of the amount (review 2026-11-09).
        let budgetNotice = self.budgetNotice
        SheetScaffold(title: title(for: isEditing), validate: validate, onConfirm: confirmAction) {
            if !modes.isEmpty {
                // Its words at the user's text size (strict review 2026-10-31).
                ScaledSegmentedPicker(title: "Loại giao dịch", selection: $mode, options: modes) { $0.title }
                    .controlSize(.large)
                    .disabled(isModeFixed || isReadOnly)
            }

            VStack(spacing: Spacing.s) {
                MiluAmountField(text: $amountText, kind: mode.kind, showsSuggestions: !isReadOnly,
                                focusesOnAppear: !isEditing)
                if showsErrors, missesAmount {
                    FormErrorText(message: "Nhập số tiền.")
                }
            }
            .padding(.vertical, Spacing.s)
            .disabled(isReadOnly)
        } content: {
            // A new spending or income: the items most used, one tap away (user request 2026-10-30).
            if !isEditing, buyingGoal == nil, let kind = mode.kind {
                QuickCategoryGrid(kind: kind, selection: $categoryID)
                    .id(kind)
            }
            // Titled groups, as on every other form (user report 2026-10-31).
            FormGroup(title: "Chi tiết", footer: readOnlyReason ?? footer, error: detailsError) {
                if mode == .transfer {
                    transferRows
                } else {
                    transactionRows
                }
                FormDivider(hasIcon: false)
                // Day and time on one row (user request 2026-10-30); money already moved: no day
                // after today (user choice 2026-10-29).
                FormDateTimeRow(title: "Thời gian", date: $date, latest: .now)
            }
            // Read-only (closed goal, archived account): shown, not typed into.
            .disabled(isReadOnly)
            // What this spending leaves of its limit, as it is typed (user choice 2026-10-30).
            if let budgetNotice {
                // Under the group it speaks of: 8 below it rather than the form's 24 between groups.
                BudgetNoticeRow(notice: budgetNotice)
                    .padding(.top, -(Spacing.xxl - Spacing.s))
                    .transition(.opacity)
            }

            // "Mua ngay" for less than the goal holds: the rest goes back to an account.
            if buyingGoal != nil, leftover >= 1, let leftoverAccount {
                // The figure as a row, no sentence under it (strict review 2026-10-31).
                FormGroup(title: "Phần còn lại") {
                    FormAmountInfoRow(title: "Số tiền", amount: leftover)
                    FormDivider(hasIcon: false)
                    FormPickerRow(title: "Về tài khoản",
                                  selection: Binding { leftoverAccount } set: { self.leftoverAccount = $0 },
                                  options: leftoverOptions,
                                  optionIcon: { store.account(id: $0)?.iconName ?? "hugeicons-wallet-01" }) {
                        store.account(id: $0)?.name ?? "—"
                    }
                }
                .transition(.opacity)
            }

            // "Không tính vào báo cáo" above the note, each under its title as on Thêm tài khoản
            // (user report 2026-10-31). A balance adjustment is never counted, a transfer neither:
            // the switch is for spending and income.
            if mode != .transfer && !keepsSystemCategory {
                // No explanatory footer (strict review 2026-10-31).
                FormGroup(title: "Tuỳ chọn") {
                    FormToggleRow(title: "Không tính vào báo cáo", isOn: $isExcluded)
                }
                .disabled(isReadOnly)
            }
            FormGroup(title: "Ghi chú") {
                FormNoteRow(text: $note, prompt: "Thêm ghi chú")
            }
            .disabled(isReadOnly)

            if isEditing, !isReadOnly {
                FormGroup { deleteRow }
            }
        }
        .miluSheetStyle()
        // An item of the other kind no longer fits: the one picked for the new kind comes back, or
        // none (the user picks). Editing too: Ăn trưa → Thu nhập is empty, back → Ăn trưa again.
        .onChange(of: mode) { oldMode, newMode in
            // A new transfer starts with no accounts picked; back from it, the account comes back.
            if !isEditing, editingTransfer == nil {
                if newMode == .transfer {
                    accountBeforeTransfer = accountID
                    accountID = nil
                    toAccountID = nil
                } else if oldMode == .transfer {
                    accountID = accountBeforeTransfer
                    fillDefaults()
                }
            }
            guard !isModeFixed else { return }
            if let oldKind = oldMode.kind { pickedByKind[oldKind] = categoryID }
            guard let kind = newMode.kind,
                  !CategoryPickerRow.isPickable(categoryID, kind: kind, in: store) else { return }
            categoryID = pickedByKind[kind] ?? ""
        }
        .animation(Motion.gentle(.smooth(duration: 0.3)), value: leftover >= 1)
        .animation(Motion.gentle(.smooth(duration: 0.3)), value: budgetNotice == nil)
        .onAppear(perform: fillDefaults)
    }

    /// The limit note: a counted spending only, not in a goal (its money was set aside already)
    /// and not on a read-only one.
    private var budgetNotice: BudgetNotice? {
        guard mode == .expense, !isReadOnly, !keepsSystemCategory, buyingGoal == nil,
              accountID.flatMap(store.goal(id:)) == nil else { return nil }
        return store.budgetNotice(amount: amount, categoryID: categoryID, accountID: accountID, date: date,
                                  isExcluded: isExcluded, replacing: editing, monthLimit: monthlyBudget,
                                  groupLimits: categoryBudgets.keeping(store.budgetGroupIDs))
    }

    private func title(for isEditing: Bool) -> String {
        // Named after its button, as "Nạp tiền" and "Rút hết" are.
        if buyingGoal != nil { return "Mua ngay" }
        return switch (mode, isEditing) {
        case (.transfer, false): "Chuyển khoản"
        case (.transfer, true): "Sửa chuyển khoản"
        case (_, false): "Thêm giao dịch"
        case (_, true): "Sửa giao dịch"
        }
    }

    /// Under the details of a transfer with a fee: the computed figure only, what leaves the source
    /// account in all (strict review 2026-10-31: the sentence explaining the fee went).
    private var footer: String? {
        guard mode == .transfer, fee > 0 else { return nil }
        return "Tổng trừ \((amount + fee).vnd)"
    }

    @ViewBuilder
    private var transactionRows: some View {
        if keepsSystemCategory {
            FormValueRowContent(title: "Hạng mục", icon: nil, value: store.categoryName(categoryID),
                           valueIcon: store.categoryIcon(categoryID))
        } else if let kind = mode.kind {
            CategoryPickerRow(kind: kind, selection: $categoryID, showsError: showsErrors,
                              kept: editing?.categoryID)
        }
        if let accountID {
            FormDivider(hasIcon: false)
            if buyingGoal != nil {
                // "Mua ngay" spends from this goal: shown, not picked.
                FormInfoRow(title: "Hũ", value: buyingName, valueIcon: buyingIcon)
            } else if let goal = store.goal(id: accountID) {
                // A purchase from a goal, being changed: it stays on the goal (as its view sheet says).
                FormInfoRow(title: "Hũ", value: goal.name, valueIcon: goal.icon)
            } else if editing.map({ store.goal(id: $0.accountID) == nil && store.account(id: $0.accountID) == nil }) == true {
                FormInfoRow(title: "Hũ", value: "Hũ đã xoá")
            } else {
                accountRow(title: "Tài khoản", selection: accountID) { self.accountID = $0 }
            }
        }
    }

    @ViewBuilder
    private var transferRows: some View {
        // "Chọn" until picked; picking on one side the account already on the other swaps them.
        // One buzz a pick, also when it swaps the sides and so changes both (review 2026-11-07:
        // each side buzzed its own).
        optionalAccountRow(title: "Từ", selection: accountID) { new in
            if new != accountID { Haptics.selection() }
            if new == toAccountID { toAccountID = self.accountID }
            self.accountID = new
        }
        FormDivider(hasIcon: false)
        optionalAccountRow(title: "Đến", selection: toAccountID) { new in
            if new != toAccountID { Haptics.selection() }
            if new == accountID { accountID = self.toAccountID }
            self.toAccountID = new
        }
        FormDivider(hasIcon: false)
        FormAmountRow(title: "Phí", text: $feeText)
    }

    /// A transfer's side, "Chọn" (red after ✓) until an account is picked.
    private func optionalAccountRow(title: String, selection: Account.ID?,
                                    set: @escaping (Account.ID) -> Void) -> some View {
        OptionalAccountRow(title: title, selection: selection,
                           options: accountOptions.filter { store.account(id: $0) != nil },
                           isInvalid: showsErrors && selection == nil, set: set)
    }

    private func accountRow(title: String, selection: Account.ID, set: @escaping (Account.ID) -> Void) -> some View {
        FormPickerRow(title: title,
                      selection: Binding { selection } set: { set($0) },
                      options: mode == .transfer ? accountOptions.filter { store.account(id: $0) != nil } : accountOptions,
                      optionIcon: { store.account(id: $0)?.iconName ?? store.goal(id: $0)?.icon ?? "hugeicons-wallet-01" }) {
            // A goal when the money was spent from one ("Mua ngay").
            store.account(id: $0)?.name ?? store.goal(id: $0)?.name ?? "Hũ đã xoá"
        }
    }

    @ViewBuilder
    private var deleteRow: some View {
        if let editingTransfer {
            FormDestructiveRow(title: "Xoá chuyển khoản", question: "Xoá chuyển khoản này?",
                               message: "Số dư hai tài khoản sẽ được tính lại.") {
                // The sheets first (this and the transfer's own), then the row out of its list,
                // animated (`AfterDismiss`), as on Tài khoản.
                (recordSheetDismiss ?? dismiss)()
                AfterDismiss.run { store.delete(editingTransfer) }
            }
        } else if let editing {
            FormDestructiveRow(title: "Xoá giao dịch", question: "Xoá giao dịch “\(store.title(of: editing))”?",
                               message: store.goal(id: editing.accountID) != nil
                                   ? "Số tiền được trả lại vào hũ."
                                   : "Số dư tài khoản sẽ được tính lại.") {
                (recordSheetDismiss ?? dismiss)()
                AfterDismiss.run { store.delete(editing) }
            }
        }
    }

    private func fillDefaults() {
        if buyingGoal != nil {
            leftoverAccount = leftoverAccount ?? leftoverOptions.first
            return
        }
        // A new transfer leaves both accounts to the user (user request 2026-10-30).
        guard mode != .transfer else { return }
        let usable = store.usableAccounts.map(\.id)
        if accountID.map({ !usable.contains($0) }) ?? true, !isEditing {
            let last = UUID(uuidString: lastAccountID)
            accountID = [preferredAccount, last].compactMap { $0 }.first { usable.contains($0) } ?? usable.first
        }
    }

    private func save() {
        guard canSave, let accountID else { return }
        if let goal = goalBought {
            let (category, amount, date, note, excluded) = (categoryID, amount, date, note, isExcluded)
            let leftoverTo = leftover >= 1 ? leftoverAccount : nil
            dismiss()
            AfterDismiss.run {
                store.spend(from: goal, categoryID: category, amount: amount, date: date, note: note,
                            isExcluded: excluded, leftoverAccount: leftoverTo)
            }
            return
        }
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
            let isNew = editingTransfer == nil
            AfterDismiss.run { if isNew { store.add(transfer) } else { store.update(transfer) } }
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
            let isNew = editing == nil
            // The sheet slides away first, then the row comes in, animated (`AfterDismiss`).
            AfterDismiss.run { if isNew { store.add(transaction) } else { store.update(transaction) } }
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

/// One line under the details: the limit's state after this spending, in the app's one look for
/// a limit (`BudgetStatusLine`).
private struct BudgetNoticeRow: View {
    let notice: BudgetNotice

    private var level: BudgetStatusLine.Level {
        switch notice.level {
        case .fine: .fine
        case .nearing: .nearing
        case .over: .over
        }
    }

    var body: some View {
        BudgetStatusLine(level: level, message: notice.text)
            .padding(.horizontal, RowMetrics.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(Motion.gentle(.snappy), value: notice)
    }
}

/// An account row that may have nothing picked yet ("Chọn"), opening the same choice sheet.
private struct OptionalAccountRow: View {
    let title: String
    let selection: Account.ID?
    let options: [Account.ID]
    var isInvalid = false
    let set: (Account.ID) -> Void

    @Environment(FinanceStore.self) private var store
    @State private var isPicking = false

    var body: some View {
        Button { isPicking = true } label: {
            FormValueRowContent(title: title, icon: nil,
                           value: selection.flatMap { store.account(id: $0)?.name } ?? "Chọn",
                           valueIcon: selection.flatMap { store.account(id: $0)?.iconName },
                           isInvalid: isInvalid)
        }
        .buttonStyle(.row)
        .accessibilityLabel(title)
        .accessibilityValue(selection.flatMap { store.account(id: $0)?.name } ?? "Chưa chọn")
        .sheet(isPresented: $isPicking) {
            ChoiceSheet(title: title,
                        selection: Binding<Account.ID?> { selection } set: { if let new = $0 { set(new) } },
                        options: options.map(Optional.some),
                        optionIcon: { $0.flatMap { store.account(id: $0)?.iconName } ?? "hugeicons-wallet-01" },
                        optionTitle: { $0.flatMap { store.account(id: $0)?.name } ?? "—" })
        }
    }
}
