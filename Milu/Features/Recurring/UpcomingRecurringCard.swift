import Combine
import SwiftUI

/// "Sắp tới" on Tổng quan (user request 2026-11-12): first what has fallen due and waits for a yes
/// ("Ghi"), then what comes in the next 7 days. Hidden while there is nothing of either. Rows as
/// "Cần chú ý"'s: the day as a small calendar leaf, the name, when, the amount.
struct UpcomingRecurringCard: View {
    @Environment(FinanceStore.self) private var store
    /// "Ghi": the page opens the sheet. Hung on this card, the sheet went with the card when
    /// recording emptied it, and left its dimming behind, eating the next tap.
    let onConfirm: (RecurringOccurrence) -> Void
    @ScaledMetric(relativeTo: .body) private var leafSize: CGFloat = 44
    /// A new day while the app is open: what falls due is worked out again.
    @State private var today = Calendar.current.startOfDay(for: .now)

    var body: some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
                today = Calendar.current.startOfDay(for: .now)
            }
    }

    @ViewBuilder
    private var content: some View {
        let _ = today
        let waiting = store.waitingRecurring()
        let waitingRules = Set(waiting.map(\.rule.id))
        // A rule waiting already shows; its next day would be the same one again.
        let upcoming = store.upcomingRecurring().filter { !waitingRules.contains($0.rule.id) }
        if !waiting.isEmpty || !upcoming.isEmpty {
            // The heading at the card's edge, as "Tuần này".
            OutsideHeaderSection(title: "Sắp tới") {
                EmptyView()
            } content: {
                VStack(spacing: 0) {
                    ForEach(Array((waiting + upcoming).enumerated()), id: \.element.id) { index, occurrence in
                        row(occurrence, isWaiting: index < waiting.count)
                            .separatorAbove(index > 0, order: index) { RowDivider(column: .logo) }
                    }
                }
                .listCard()
            }
        }
    }

    private func row(_ occurrence: RecurringOccurrence, isWaiting: Bool) -> some View {
        let rule = occurrence.rule
        let days = occurrence.day.daysFromToday
        return HStack(spacing: RowMetrics.gap) {
            leaf(occurrence.day)
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(store.title(of: rule))
                    .textRole(.bodyStrong)
                    .lineLimit(1)
                Text(when(occurrence, isWaiting: isWaiting))
                    .textRole(.caption)
                    .foregroundStyle(isWaiting && days < 0 ? Palette.warningLabel : Palette.secondaryLabel)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                MoneyText(amount: rule.amount, tone: rule.kind == .income ? .signedIncome : .signedExpense)
                    .fixedSize()
                if isWaiting {
                    MiluButton("Ghi", role: .primary, size: .compact) { onConfirm(occurrence) }
                        .accessibilityHint("Xem lại số tiền rồi ghi")
                }
            }
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, RowMetrics.vertical)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
    }

    /// "Tới hạn hôm nay", "4 lần chờ ghi · từ 12/08", "Cần chọn tài khoản · 4 lần", "Còn 3 ngày · Tự ghi".
    private func when(_ occurrence: RecurringOccurrence, isWaiting: Bool) -> String {
        let days = occurrence.day.daysFromToday
        if isWaiting {
            // Short enough for one line (Simulator test 2026-11-12: "Tới hạn 12/08 · thêm 3 lầ…").
            let count = occurrence.moreWaiting + 1
            if !store.canRecord(onto: occurrence.rule.accountID) {
                return count > 1 ? "Cần chọn tài khoản · \(count) lần" : "Cần chọn tài khoản"
            }
            if count > 1 { return "\(count) lần chờ ghi · từ \(occurrence.day.shortDay)" }
            return days == 0 ? "Tới hạn hôm nay" : "Tới hạn \(occurrence.day.shortDay)"
        }
        let countdown = days == 1 ? "Ngày mai" : "Còn \(days) ngày"
        let how = !store.canRecord(onto: occurrence.rule.accountID) ? "Cần chọn tài khoản"
            : occurrence.rule.autoRecords ? "Tự ghi" : "Hỏi trước"
        return "\(countdown) · \(how)"
    }

    private func leaf(_ day: Date) -> some View {
        let calendar = Calendar.current
        return VStack(spacing: 0) {
            Text("\(calendar.component(.day, from: day))")
                .textRole(.body)
                .monospacedDigit()
                .foregroundStyle(Palette.label)
            Text("Th\(calendar.component(.month, from: day))")
                .textRole(.footnote)
                .foregroundStyle(Palette.secondaryLabel)
        }
        .frame(minWidth: leafSize, minHeight: leafSize)
        .background(Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// "Ghi" on a day that fell due: the amount as the rule has it, to change if it was different
/// this time; ✓ records it, "Bỏ qua lần này" moves on with nothing recorded. The account can be
/// changed for this time; when the rule's was archived or deleted, it must be (review 2026-11-12:
/// "Ghi" then closed and recorded nothing).
struct RecurringConfirmSheet: View {
    let occurrence: RecurringOccurrence

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String
    @State private var accountID: Account.ID?
    @State private var editingRule: RecurringEditorSheet.Target?
    @State private var showsErrors = false
    /// The rule's account archived or deleted: the one picked here becomes the rule's (on by
    /// default), so the next time does not ask again.
    @State private var keepsAccount = true
    /// With the account moved, whether a rule that records by itself fills in the other days still
    /// waiting (review 2026-11-12: it did so without saying); off, only today's on comes.
    @State private var recordsTheRest = true

    init(occurrence: RecurringOccurrence) {
        self.occurrence = occurrence
        _amountText = State(initialValue: String(Int(occurrence.rule.amount)).groupedVNDInput)
    }

    /// The rule as it is now: changed from this sheet, it shows the change.
    private var rule: RecurringRule { store.recurringRule(id: occurrence.rule.id) ?? occurrence.rule }
    private var amount: Double { amountText.vndInputAmount }
    private var ruleAccountGone: Bool { !store.canRecord(onto: rule.accountID) }
    private var canSave: Bool { amount > 0 && accountID.map(store.canRecord(onto:)) == true }

    private func validate() -> Bool {
        withAnimation(Motion.gentle(.smooth(duration: 0.3))) { showsErrors = true }
        return canSave
    }

    var body: some View {
        let rule = self.rule
        SheetScaffold(title: store.title(of: rule), validate: validate, onConfirm: confirm) {
            VStack(spacing: Spacing.s) {
                MiluAmountField(text: $amountText, kind: rule.kind, showsSuggestions: false)
                if showsErrors, amount <= 0 { FormErrorText(message: "Nhập số tiền.") }
            }
            .padding(.vertical, Spacing.s)
        } content: {
            FormGroup(title: "Chi tiết", error: accountError) {
                FormInfoRow(title: "Hạng mục", value: store.categoryName(rule.categoryID),
                            valueIcon: store.categoryIcon(rule.categoryID))
                FormDivider(hasIcon: false)
                if let accountID {
                    FormPickerRow(title: "Tài khoản",
                                  selection: Binding { accountID } set: { self.accountID = $0 },
                                  options: accountOptions,
                                  optionIcon: { store.account(id: $0)?.iconName ?? "hugeicons-wallet-01" }) {
                        store.account(id: $0)?.name ?? "—"
                    }
                } else {
                    FormInfoRow(title: "Tài khoản", value: "Chưa có tài khoản")
                }
                FormDivider(hasIcon: false)
                FormInfoRow(title: "Ngày", value: occurrence.day.shortDay)
                FormDivider(hasIcon: false)
                FormInfoRow(title: "Lặp lại", value: rule.scheduleDetail())
            }
            if ruleAccountGone, accountID != nil {
                let rest = otherWaiting
                let past = otherWaitingBeforeToday
                let todayToo = rest > past
                FormGroup(footer: !keepsAccount || rest == 0 ? nil
                          : recordsTheRest || past == 0 ? "Milu sẽ ghi tiếp \(rest) lần còn chờ vào tài khoản này."
                          : todayToo ? "\(past) lần trước hôm nay sẽ được bỏ qua, lần hôm nay vẫn được ghi."
                          : "\(past) lần còn chờ sẽ được bỏ qua.") {
                    FormToggleRow(title: "Dùng tài khoản này cho các lần sau", isOn: $keepsAccount)
                    if keepsAccount, past > 0 {
                        FormDivider(hasIcon: false)
                        FormToggleRow(title: "Ghi luôn các lần còn chờ", isOn: $recordsTheRest)
                    }
                }
                .animation(Motion.gentle(.smooth(duration: 0.25)), value: keepsAccount)
            }
            FormGroup {
                FormActionRow(title: "Bỏ qua lần này", icon: "hugeicons-cancel-01",
                              question: "Bỏ qua lần \(occurrence.day.shortDay)?",
                              message: "Milu không ghi lần này, lần sau vẫn nhắc như thường.") {
                    store.skip(occurrence)
                    dismiss()
                }
                FormDivider()
                FormActionRow(title: "Sửa khoản định kỳ", icon: "hugeicons-pencil-edit-02") {
                    editingRule = .edit(rule)
                }
            }
        }
        .miluSheetStyle()
        .onAppear(perform: pickAccount)
        // Back from changing the rule: its new amount and account, unless this time's were changed.
        .sheet(item: $editingRule, onDismiss: refresh) { RecurringEditorSheet(target: $0) }
        .onChange(of: store.recurringRule(id: occurrence.rule.id) == nil) { _, gone in if gone { dismiss() } }
    }

    /// The days after this one still waiting, which a rule that records by itself would fill in
    /// once its account is moved; asking first, they keep coming one by one.
    private var otherWaiting: Int {
        rule.autoRecords ? occurrence.moreWaiting : 0
    }

    /// Of those, the ones before today: what "Ghi luôn các lần còn chờ" off leaves out (today's,
    /// if due, is recorded either way; review 2026-11-12: the count said one too many).
    private var otherWaitingBeforeToday: Int {
        guard rule.autoRecords else { return 0 }
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now)) else { return 0 }
        return rule.occurrences(after: occurrence.day, through: yesterday).count
    }

    /// Why the rule's account is not the one picked: it was archived or deleted.
    private var accountError: String? {
        if accountID == nil { return "Thêm một tài khoản để ghi." }
        guard ruleAccountGone, accountID != rule.accountID else { return nil }
        let name = store.account(id: rule.accountID)?.name
        return name.map { "“\($0)” đã lưu trữ, lần này ghi vào tài khoản khác." }
            ?? "Tài khoản của khoản này đã xoá, lần này ghi vào tài khoản khác."
    }

    /// The accounts in use, as every picker offers them; the rule's own, locked, stays offered.
    private var accountOptions: [Account.ID] {
        var ids = store.usableAccounts.map(\.id)
        if store.canRecord(onto: rule.accountID), !ids.contains(rule.accountID) { ids.append(rule.accountID) }
        return ids
    }

    private func pickAccount() {
        guard accountID == nil || !store.canRecord(onto: accountID!) else { return }
        accountID = store.canRecord(onto: rule.accountID) ? rule.accountID : store.usableAccounts.first?.id
    }

    @State private var lastRuleAmount: Double?

    private func refresh() {
        // The amount typed stays if it was changed here; otherwise the rule's new one.
        if amount == occurrence.rule.amount || amount == lastRuleAmount { amountText = String(Int(rule.amount)).groupedVNDInput }
        lastRuleAmount = rule.amount
        // The account picked for this time stays, unless it can no longer be used.
        pickAccount()
    }

    private func confirm() {
        guard canSave, let accountID else { return }
        let (occurrence, amount) = (occurrence, amount)
        var moved: RecurringRule?
        if ruleAccountGone, keepsAccount {
            moved = rule
            moved?.accountID = accountID
            if otherWaitingBeforeToday > 0, !recordsTheRest {
                // Nothing before today is filled in; today's, if due, still is.
                let calendar = Calendar.current
                let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now)) ?? .now
                moved?.lastHandled = max(rule.lastHandled ?? .distantPast, yesterday)
            }
        }
        dismiss()
        AfterDismiss.run {
            if let moved { store.save(moved) }
            store.confirm(occurrence, amount: amount, accountID: accountID)
            // One that records by itself goes on, from here, onto its new account.
            if moved != nil { store.recordDueRecurring() }
        }
    }
}

extension FinanceStore {
    /// A rule's name: its note, else its item's.
    func title(of rule: RecurringRule) -> String {
        let note = rule.note.trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? categoryName(rule.categoryID) : note
    }
}
