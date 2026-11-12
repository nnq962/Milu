import SwiftUI

/// What opens on tapping a transaction: its details to read, the pencil to change it (the form
/// also deletes), and the last few others in the same category, each opening the same way
/// (user request 2026-10-29). Laid out as an account's or a goal's screen: the name in the bar,
/// a `SummaryCard` lead (user choice 2026-10-29), then the details.
struct TransactionDetailSheet: View {
    let transactionID: FinanceTransaction.ID

    var body: some View {
        NavigationStack {
            TransactionDetailView(transactionID: transactionID, isRoot: true)
                .navigationDestination(for: FinanceTransaction.ID.self) { TransactionDetailView(transactionID: $0) }
        }
        .miluSheetStyle()
    }
}

struct TransactionDetailView: View {
    let transactionID: FinanceTransaction.ID
    /// The first screen of the sheet has ✕; one opened from "Cùng hạng mục" has only ‹.
    var isRoot = false

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editing: FinanceTransaction?
    /// The recurring rule that recorded it, opened from "Lặp lại".
    @State private var viewingRule: RecurringRule?

    /// How many others of the same category are listed.
    static let similarLimit = 5

    var body: some View {
        let transaction = store.transaction(id: transactionID)
        SheetPage(title: transaction.map(store.title(of:)) ?? "Giao dịch", showsClose: isRoot,
                       canEdit: transaction.map(store.isEditable) ?? false, onEdit: { editing = transaction }) {
            if let transaction {
                lead(transaction)
                details(transaction)
                if !transaction.note.isEmpty {
                    FormGroup(title: "Ghi chú") { FormNoteText(text: transaction.note) }
                }
                similar(to: transaction)
            } else {
                // Deleted from the form opened here: the sheet closes as that form does.
                EmptyStateCard(icon: "hugeicons-inbox", title: "Giao dịch đã bị xoá",
                               message: "Giao dịch này không còn trong lịch sử.", picture: IconCatalog.emojiName("🧹"))
            }
        }
        // By item, the transaction as it was when the pencil was tapped.
        // Deleting from the form closes this sheet with it, before the transaction goes.
        .sheet(item: $editing) { TransactionEditSheet(transaction: $0).environment(\.recordSheetDismiss, dismiss) }
        .sheet(item: $viewingRule) { RecurringDetailSheet(ruleID: $0.id) }
        // Gone some other way while open: close. (Its form closes this sheet itself before
        // deleting, `recordSheetDismiss`.)
        .onChange(of: store.transaction(id: transactionID) == nil) { _, gone in if gone { dismiss() } }
    }

    /// "Chi tiêu" or "Thu nhập", the signed amount and the category's icon (the category itself is
    /// the bar's title); a badge when it does not count.
    private func lead(_ transaction: FinanceTransaction) -> some View {
        // A balance adjustment is neither income nor spending (user choice 2026-10-29).
        SummaryCard(title: transaction.isAdjustment ? "Điều chỉnh số dư" : transaction.kind.title, amount: transaction.amount,
                    icon: store.categoryIcon(transaction.categoryID),
                    // Money out in ink with "−", as on its row ("B+"; review 2026-11-07: red here only).
                    tone: transaction.kind == .income ? .signedIncome : .outflow) {
            if let excluded = Self.notCountedText(transaction, store: store) {
                StatusBadge(title: excluded)
                    .padding(.top, Spacing.s)
            }
        }
    }

    /// Why it stays out of reports, if it does.
    static func notCountedText(_ transaction: FinanceTransaction, store: FinanceStore) -> String? {
        if transaction.isAdjustment || transaction.isExcluded { return "Không tính vào báo cáo" }
        return store.isReportable(transaction) ? nil : "Tài khoản đã khoá · Không tính"
    }

    private func details(_ transaction: FinanceTransaction) -> some View {
        FormGroup(title: "Chi tiết", footer: store.readOnlyReason(transaction)) {
            // The item is the name above; this says the group it belongs to (user choice 2026-10-29).
            // The system's own categories (balance adjustment) have none.
            if let groupID = groupID(of: transaction) {
                FormInfoRow(title: "Nhóm hạng mục", value: store.categoryName(groupID), valueIcon: store.categoryIcon(groupID))
                FormDivider(hasIcon: false)
            }
            // Spending from a goal ("Mua ngay") is on the goal, even one deleted since.
            FormInfoRow(title: store.account(id: transaction.accountID) == nil ? "Hũ" : "Tài khoản",
                        value: accountName(transaction.accountID), valueIcon: accountIcon(transaction.accountID))
            FormDivider(hasIcon: false)
            FormInfoRow(title: "Thời gian", value: Self.when(transaction.date))
            // Recorded by a recurring rule (user request 2026-11-12): how often, opening the rule.
            if let rule = transaction.recurringRuleID.flatMap(store.recurringRule(id:)) {
                FormDivider(hasIcon: false)
                Button { viewingRule = rule } label: {
                    FormValueRowContent(title: "Lặp lại", value: rule.isPaused ? "\(rule.scheduleText) · Tạm dừng" : rule.scheduleDetail())
                }
                .buttonStyle(.row)
                .accessibilityHint("Xem khoản định kỳ")
            }
        }
    }

    /// The last few others in the same category, newest first: the day, then what tells it apart
    /// (its note) and the account, and the amount. Balance adjustments count as one category,
    /// either way.
    @ViewBuilder
    private func similar(to transaction: FinanceTransaction) -> some View {
        let others = store.transactions
            .filter { other in
                other.id != transaction.id
                    && (transaction.isAdjustment ? other.isAdjustment : other.categoryID == transaction.categoryID)
            }
            .prefix(Self.similarLimit)
        if !others.isEmpty {
            FormGroup(title: "Cùng hạng mục") {
                ForEach(Array(others.enumerated()), id: \.element.id) { index, other in
                    NavigationLink(value: other.id) {
                        ListRow(icon: accountIcon(other.accountID),
                                title: other.date.transactionDayTitle,
                                subtitle: similarSubtitle(other),
                                trailingSubtitle: Self.time(other.date),
                                amount: other.amount,
                                amountTone: other.kind == .income ? .signedIncome : .outflow)
                    }
                    .buttonStyle(.row)
                    .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                }
            }
        }
    }

    /// "Đi chợ WinMart · Vietcombank", or just the account.
    private func similarSubtitle(_ transaction: FinanceTransaction) -> String {
        let note = transaction.note.components(separatedBy: .newlines).first ?? ""
        return [note, accountName(transaction.accountID)].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// The group of the transaction's item, or the group itself for a transaction from before
    /// items existed; nil for the system's own categories.
    private func groupID(of transaction: FinanceTransaction) -> String? {
        if transaction.systemCategory != nil { return nil }
        return store.category(id: transaction.categoryID)?.parentID ?? transaction.categoryID
    }

    /// An account, or a goal when the money was spent from one ("Mua ngay").
    private func accountName(_ id: Account.ID) -> String {
        store.account(id: id)?.name ?? store.goal(id: id)?.name ?? "Hũ đã xoá"
    }

    private func accountIcon(_ id: Account.ID) -> String {
        store.account(id: id)?.iconName ?? store.goal(id: id)?.icon ?? "hugeicons-wallet-01"
    }

    static func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
    }

    /// "Hôm qua, 28/10 · 12:15"; another year shows it.
    static func when(_ date: Date) -> String {
        "\(date.transactionDayTitle) · \(time(date))"
    }
}

/// What opens on tapping a transfer between two accounts: its details to read, the pencil to change
/// it (the form also deletes), as spending and income do (user request 2026-10-29).
struct TransferDetailSheet: View {
    let transferID: AccountTransfer.ID

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    var body: some View {
        let transfer = store.accountTransfer(id: transferID)
        NavigationStack {
            SheetPage(title: "Chuyển khoản", showsClose: true,
                           canEdit: transfer.map { store.readOnlyReason($0) == nil } ?? false,
                           onEdit: { isEditing = true }) {
                if let transfer {
                    // Neither income nor spending: no sign.
                    SummaryCard(title: "Số tiền chuyển", amount: transfer.amount,
                                icon: IconCatalog.emojiName("💸"), tone: .neutral)
                    details(transfer)
                    if !transfer.note.isEmpty {
                        FormGroup(title: "Ghi chú") { FormNoteText(text: transfer.note) }
                    }
                } else {
                    EmptyStateCard(icon: "hugeicons-inbox", title: "Chuyển khoản đã bị xoá",
                                   message: "Chuyển khoản này không còn trong lịch sử.", picture: IconCatalog.emojiName("🧹"))
                }
            }
            .onChange(of: store.accountTransfer(id: transferID) == nil) { _, gone in if gone { dismiss() } }
            .sheet(isPresented: $isEditing) {
                if let transfer = store.accountTransfer(id: transferID) {
                    AddTransactionView(editingTransfer: transfer)
                        .environment(\.recordSheetDismiss, dismiss)
                }
            }
        }
        .miluSheetStyle()
    }

    private func details(_ transfer: AccountTransfer) -> some View {
        // Only why it cannot change, if so; no sentence on where the fee goes (strict review
        // 2026-10-31: no explanatory footers).
        FormGroup(title: "Chi tiết", footer: store.readOnlyReason(transfer)) {
            FormInfoRow(title: "Từ", value: name(transfer.fromAccountID), valueIcon: icon(transfer.fromAccountID))
            FormDivider(hasIcon: false)
            FormInfoRow(title: "Đến", value: name(transfer.toAccountID), valueIcon: icon(transfer.toAccountID))
            if transfer.fee > 0 {
                FormDivider(hasIcon: false)
                // Money out: in ink with "−" ("B+", 2026-11-03).
                FormAmountInfoRow(title: "Phí", amount: transfer.fee, tone: .outflow)
            }
            FormDivider(hasIcon: false)
            FormInfoRow(title: "Thời gian", value: TransactionDetailView.when(transfer.date))
        }
    }

    private func name(_ id: Account.ID) -> String { store.account(id: id)?.name ?? "Tài khoản đã xoá" }
    private func icon(_ id: Account.ID) -> String { store.account(id: id)?.iconName ?? "hugeicons-wallet-01" }
}

#Preview {
    TransactionDetailSheet(transactionID: SampleData.transactions[0].id)
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
