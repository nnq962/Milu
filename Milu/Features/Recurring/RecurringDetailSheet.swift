import SwiftUI

/// What opens on tapping a recurring rule (user request 2026-11-12: the row's one line could not
/// say it all): everything about it to read, the pencil to change it, as a transaction's sheet.
/// Then the last times it was recorded.
struct RecurringDetailSheet: View {
    let ruleID: RecurringRule.ID

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editing: RecurringEditorSheet.Target?

    /// How many recorded transactions are listed.
    private static let historyLimit = 5

    var body: some View {
        NavigationStack {
            let rule = store.recurringRule(id: ruleID)
            SheetPage(title: rule.map(store.title(of:)) ?? "Khoản định kỳ", showsClose: true,
                      canEdit: rule != nil, onEdit: { editing = rule.map { .edit($0) } }) {
                if let rule {
                    lead(rule)
                    details(rule)
                    schedule(rule)
                    // The note is the sheet's title when there is one; said again below, it was twice.
                    history(rule)
                }
            }
        }
        .miluSheetStyle()
        .sheet(item: $editing) { RecurringEditorSheet(target: $0) }
        // Deleted from its form: this sheet goes too.
        .onChange(of: store.recurringRule(id: ruleID) == nil) { _, gone in if gone { dismiss() } }
    }

    private func lead(_ rule: RecurringRule) -> some View {
        SummaryCard(title: rule.kind.title, amount: rule.amount, icon: store.categoryIcon(rule.categoryID),
                    tone: rule.kind == .income ? .signedIncome : .outflow) {
            if let status = status(rule) {
                StatusBadge(title: status)
                    .padding(.top, Spacing.s)
            }
        }
    }

    private func status(_ rule: RecurringRule) -> String? {
        if rule.isPaused { return "Tạm dừng" }
        if waiting(rule) != nil { return "Chờ ghi" }
        return store.nextDue(rule) == nil ? "Đã kết thúc" : nil
    }

    private func details(_ rule: RecurringRule) -> some View {
        FormGroup(title: "Chi tiết") {
            FormInfoRow(title: "Hạng mục", value: store.categoryName(rule.categoryID),
                        valueIcon: store.categoryIcon(rule.categoryID))
            FormDivider(hasIcon: false)
            FormInfoRow(title: "Tài khoản", value: accountName(rule.accountID),
                        valueIcon: store.account(id: rule.accountID)?.iconName)
        }
    }

    /// "Ví tiền mặt", "Ví tiền mặt (đã lưu trữ)", "Tài khoản đã xoá".
    private func accountName(_ id: Account.ID) -> String {
        guard let account = store.account(id: id) else { return "Tài khoản đã xoá" }
        return account.isArchived ? "\(account.name) (đã lưu trữ)" : account.name
    }

    private func schedule(_ rule: RecurringRule) -> some View {
        FormGroup(title: "Lịch") {
            FormInfoRow(title: "Lặp lại", value: rule.scheduleDetail())
            FormDivider(hasIcon: false)
            FormInfoRow(title: "Lần tới", value: nextText(rule))
            FormDivider(hasIcon: false)
            FormInfoRow(title: "Bắt đầu", value: rule.startDate.shortDay)
            FormDivider(hasIcon: false)
            FormInfoRow(title: "Kết thúc", value: rule.endDate?.shortDay ?? "Không có")
            FormDivider(hasIcon: false)
            FormInfoRow(title: "Khi tới hạn", value: rule.autoRecords ? "Milu tự ghi" : "Hỏi bạn trước")
        }
    }

    /// The days fallen due still to do, if any (Simulator test 2026-11-12: four months waiting read
    /// "Lần tới: Hôm nay").
    private func waiting(_ rule: RecurringRule) -> RecurringOccurrence? {
        store.waitingRecurring().first { $0.rule.id == rule.id }
    }

    /// "Hôm nay", "12/12 · còn 30 ngày", "4 lần chờ ghi · từ 12/08", "Tạm dừng", "Đã kết thúc".
    private func nextText(_ rule: RecurringRule) -> String {
        if rule.isPaused { return "Tạm dừng" }
        if let waiting = waiting(rule) {
            let count = waiting.moreWaiting + 1
            if count > 1 { return "\(count) lần chờ ghi · từ \(waiting.day.shortDay)" }
            if waiting.day.daysFromToday < 0 { return "Chờ ghi · \(waiting.day.shortDay)" }
        }
        guard let next = store.nextDue(rule) else { return "Đã kết thúc" }
        let days = next.daysFromToday
        return days <= 0 ? "Hôm nay" : days == 1 ? "Ngày mai, \(next.shortDay)" : "\(next.shortDay) · còn \(days) ngày"
    }

    /// The last times it was recorded, newest first; "Xem tất cả" when there are more.
    @ViewBuilder
    private func history(_ rule: RecurringRule) -> some View {
        let recorded = recordedTransactions(rule)
        if !recorded.isEmpty {
            FormGroup(title: "Đã ghi") {
                RecordedRows(transactions: Array(recorded.prefix(Self.historyLimit)))
                if recorded.count > Self.historyLimit {
                    FormDivider()
                    NavigationLink {
                        RecordedHistoryPage(title: store.title(of: rule), ruleID: rule.id)
                    } label: {
                        NavigationRowContent(title: "Xem tất cả", value: "\(recorded.count)",
                                             spokenValue: "\(recorded.count) lần")
                    }
                    .buttonStyle(.row)
                }
            }
        }
    }

    private func recordedTransactions(_ rule: RecurringRule) -> [FinanceTransaction] {
        store.transactions.filter { $0.recurringRuleID == rule.id }.sorted { $0.date > $1.date }
    }
}

/// The times a rule was recorded, as rows: the day, the account, the amount.
private struct RecordedRows: View {
    let transactions: [FinanceTransaction]
    @Environment(FinanceStore.self) private var store

    var body: some View {
        ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
            ListRow(icon: store.account(id: transaction.accountID)?.iconName ?? "hugeicons-wallet-01",
                    title: transaction.date.transactionDayTitle,
                    subtitle: store.account(id: transaction.accountID)?.name,
                    amount: transaction.amount,
                    amountTone: transaction.kind == .income ? .signedIncome : .outflow,
                    showsChevron: false)
                .separatorAbove(index > 0, order: index) { RowDivider(column: .logo) }
        }
    }
}

/// "Xem tất cả": every time a rule was recorded, newest first.
private struct RecordedHistoryPage: View {
    let title: String
    let ruleID: RecurringRule.ID
    @Environment(FinanceStore.self) private var store

    var body: some View {
        let recorded = store.transactions.filter { $0.recurringRuleID == ruleID }.sorted { $0.date > $1.date }
        ScrollView {
            VStack(spacing: 0) { RecordedRows(transactions: recorded) }
                .listCard()
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.vertical, Spacing.l, for: .scrollContent)
        .pageBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
