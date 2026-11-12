import SwiftUI

/// "Giao dịch định kỳ" (Cài đặt → Quản lý tài chính, user request 2026-11-12): every rule in one
/// card, running ones first, then the paused; tapping one opens its sheet. "Thêm khoản định kỳ"
/// ends the card, as "Thêm người" ends Danh bạ's.
struct RecurringListView: View {
    @Environment(FinanceStore.self) private var store
    @State private var editing: RecurringEditorSheet.Target?
    /// A rule tapped to read it (then change it from its sheet).
    @State private var viewing: RecurringRule?

    var body: some View {
        let rules = store.recurringRules.sorted { lhs, rhs in
            if lhs.isPaused != rhs.isPaused { return !lhs.isPaused }
            let left = store.nextDue(lhs) ?? .distantFuture
            let right = store.nextDue(rhs) ?? .distantFuture
            return left == right ? lhs.createdAt < rhs.createdAt : left < right
        }
        let waiting = Set(store.waitingRecurring().map(\.rule.id))
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                if rules.isEmpty {
                    EmptyStateCard(title: "Chưa có khoản định kỳ",
                                   message: "Tiền nhà, lương, gói cước… Milu nhắc hoặc tự ghi mỗi lần tới hạn.",
                                   picture: IconCatalog.emojiName("📅"))
                }
                VStack(spacing: 0) {
                    ForEach(Array(rules.enumerated()), id: \.element.id) { index, rule in
                        Button { viewing = rule } label: {
                            ListRow(title: store.title(of: rule),
                                    subtitle: waiting.contains(rule.id) ? "\(rule.scheduleText) · Chờ ghi" : subtitle(rule),
                                    subtitleColor: waiting.contains(rule.id) ? Palette.warningLabel : Palette.secondaryLabel,
                                    showsChevron: false) {
                                RowIcon(name: store.categoryIcon(rule.categoryID))
                            } trailing: {
                                ListRowAmount(amount: rule.amount,
                                              tone: rule.isPaused ? .muted : rule.kind == .income ? .signedIncome : .signedExpense)
                            }
                        }
                        .buttonStyle(.row)
                        .accessibilityHint("Xem chi tiết")
                        .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                    }
                    FormActionRow(title: "Thêm khoản định kỳ", icon: "hugeicons-add-01") {
                        editing = .new
                    }
                    .overlay(alignment: .top) { if !rules.isEmpty { FormDivider() } }
                }
                .listCard()
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Giao dịch định kỳ")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { RecurringEditorSheet(target: $0) }
        .sheet(item: $viewing) { RecurringDetailSheet(ruleID: $0.id) }
    }

    /// Short enough for one line: "Hằng tháng · 15/12", "Hằng tháng · Tạm dừng"; the rest is in
    /// its sheet.
    private func subtitle(_ rule: RecurringRule) -> String {
        if rule.isPaused { return "\(rule.scheduleText) · Tạm dừng" }
        guard let next = store.nextDue(rule) else { return "\(rule.scheduleText) · Đã kết thúc" }
        return "\(rule.scheduleText) · \(next.daysFromToday == 0 ? "Hôm nay" : next.shortDay)"
    }
}

/// Adds or edits a recurring rule: kind, amount, item, account, how often, from when to when,
/// whether Milu records it by itself, paused, note. Saving changes what comes next only; what it
/// recorded stays as it is.
struct RecurringEditorSheet: View {
    enum Target: Identifiable {
        case new
        case edit(RecurringRule)

        var id: String {
            switch self {
            case .new: "new"
            case .edit(let rule): rule.id.uuidString
            }
        }
    }

    let target: Target

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var kind: TransactionKind
    @State private var amountText: String
    @State private var categoryID: String
    @State private var accountID: Account.ID?
    @State private var repeatChoice: RepeatChoice
    @State private var startDate: Date
    @State private var hasEnd: Bool
    @State private var endDate: Date
    @State private var autoRecords: Bool
    @State private var isPaused: Bool
    @State private var note: String
    @State private var showsErrors = false

    init(target: Target) {
        self.target = target
        let rule: RecurringRule? = if case .edit(let rule) = target { rule } else { nil }
        _kind = State(initialValue: rule?.kind ?? .expense)
        _amountText = State(initialValue: rule.map { String(Int($0.amount)).groupedVNDInput } ?? "")
        _categoryID = State(initialValue: rule?.categoryID ?? "")
        _accountID = State(initialValue: rule?.accountID)
        _repeatChoice = State(initialValue: rule.map { RepeatChoice(frequency: $0.frequency, interval: $0.interval) } ?? .monthly)
        _startDate = State(initialValue: rule?.startDate ?? .now)
        _hasEnd = State(initialValue: rule?.endDate != nil)
        // A year after the start, or after today when that is already past (review 2026-11-12: an
        // old rule's end came up red as soon as it was switched on).
        let yearAfterStart = Calendar.current.date(byAdding: .year, value: 1, to: rule?.startDate ?? .now) ?? .now
        let defaultEnd = yearAfterStart > .now ? yearAfterStart
            : Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
        _endDate = State(initialValue: rule?.endDate ?? defaultEnd)
        _autoRecords = State(initialValue: rule?.autoRecords ?? false)
        _isPaused = State(initialValue: rule?.isPaused ?? false)
        _note = State(initialValue: rule?.note ?? "")
    }

    private var original: RecurringRule? {
        if case .edit(let rule) = target { return store.recurringRule(id: rule.id) ?? rule }
        return nil
    }

    private var amount: Double { amountText.vndInputAmount }

    /// The accounts in use; the rule's own when locked stays offered. One archived or deleted is
    /// not: it has to be changed (`accountGone`).
    private var accountOptions: [Account.ID] {
        var ids = store.usableAccounts.map(\.id)
        if let kept = original?.accountID, !ids.contains(kept), store.canRecord(onto: kept) { ids.append(kept) }
        return ids
    }

    private var missesCategory: Bool {
        !CategoryPickerRow.isPickable(categoryID, kind: kind, in: store, kept: original?.categoryID)
    }

    private var endsBeforeStart: Bool {
        hasEnd && Calendar.current.startOfDay(for: endDate) < Calendar.current.startOfDay(for: startDate)
    }

    /// An end already past, newly set: the rule would never come (review 2026-11-12). One that
    /// ended before and is only being looked at again keeps its end.
    private var endsInThePast: Bool {
        let calendar = Calendar.current
        guard hasEnd, calendar.startOfDay(for: endDate) < calendar.startOfDay(for: .now) else { return false }
        return original?.endDate.map { !calendar.isDate($0, inSameDayAs: endDate) } ?? true
    }

    private var scheduleError: String? {
        if endsBeforeStart { return "Ngày kết thúc phải sau ngày bắt đầu." }
        if endsInThePast { return "Ngày kết thúc đã qua." }
        return nil
    }

    /// The account kept from the rule was archived or deleted since: another must be picked.
    private var accountGone: Bool {
        accountID.map { !store.canRecord(onto: $0) } ?? false
    }

    private var detailsError: String? {
        if accountID == nil, store.usableAccounts.isEmpty { return "Thêm một tài khoản trước." }
        // Only pausing it: no need to pick another account first.
        if accountGone, !isPaused, let accountID {
            return store.account(id: accountID).map { "“\($0.name)” đã lưu trữ, chọn tài khoản khác." }
                ?? "Tài khoản đã xoá, chọn tài khoản khác."
        }
        guard showsErrors else { return nil }
        if missesCategory { return "Chọn hạng mục." }
        return nil
    }

    private var canSave: Bool {
        amount > 0 && !missesCategory && accountID != nil && (!accountGone || isPaused) && scheduleError == nil
    }

    /// A new rule starting in the past: when it first comes, as nothing before today is recorded.
    private var noBackfillNote: String? {
        guard original == nil, let schedule = repeatChoice.schedule,
              let handled = FinanceStore.firstHandled(forNewRuleStarting: startDate) else { return nil }
        var preview = RecurringRule(kind: kind, amount: 0, categoryID: "", accountID: UUID(),
                                    frequency: schedule.frequency, interval: schedule.interval, startDate: startDate)
        preview.endDate = hasEnd ? endDate : nil
        // An end already past is the red line's to say.
        guard let next = preview.nextOccurrence(after: handled) else { return nil }
        let when = next.daysFromToday == 0 ? "hôm nay" : next.shortDay
        return "Lần tới: \(when). Milu không ghi bù các lần đã qua."
    }

    private func validate() -> Bool {
        withAnimation(Motion.gentle(.smooth(duration: 0.3))) { showsErrors = true }
        return canSave
    }

    var body: some View {
        SheetScaffold(title: original == nil ? "Thêm khoản định kỳ" : "Sửa khoản định kỳ",
                      validate: validate, onConfirm: save) {
            ScaledSegmentedPicker(title: "Loại giao dịch", selection: $kind, options: TransactionKind.allCases) { $0.title }
                .controlSize(.large)
            VStack(spacing: Spacing.s) {
                MiluAmountField(text: $amountText, kind: kind, focusesOnAppear: original == nil)
                if showsErrors, amount <= 0 {
                    FormErrorText(message: "Nhập số tiền.")
                }
            }
            .padding(.vertical, Spacing.s)
        } content: {
            FormGroup(title: "Chi tiết", error: detailsError) {
                CategoryPickerRow(kind: kind, selection: $categoryID, showsError: showsErrors,
                                  kept: original?.categoryID)
                if let accountID {
                    FormDivider(hasIcon: false)
                    FormPickerRow(title: "Tài khoản",
                                  selection: Binding { accountID } set: { self.accountID = $0 },
                                  options: accountOptions,
                                  optionIcon: { store.account(id: $0)?.iconName ?? "hugeicons-wallet-01" }) {
                        store.account(id: $0)?.name ?? "Tài khoản đã xoá"
                    }
                }
            }

            FormGroup(title: "Lịch", footer: noBackfillNote,
                      error: scheduleError) {
                FormPickerRow(title: "Lặp lại", selection: $repeatChoice,
                              options: RepeatChoice.allCases.filter { $0 != .none }) { $0.title }
                FormDivider(hasIcon: false)
                FormDateRow(title: "Bắt đầu", date: $startDate)
                FormDivider(hasIcon: false)
                FormToggleRow(title: "Có ngày kết thúc", isOn: $hasEnd)
                if hasEnd {
                    FormDivider(hasIcon: false)
                    FormDateRow(title: "Kết thúc", date: $endDate, earliest: startDate, isInvalid: scheduleError != nil)
                }
            }
            .animation(Motion.gentle(.smooth(duration: 0.25)), value: hasEnd)

            FormGroup(title: "Tuỳ chọn") {
                FormToggleRow(title: "Tự ghi khi tới hạn",
                              subtitle: autoRecords ? "Milu tự ghi mỗi lần tới hạn" : "Milu hỏi bạn trước khi ghi",
                              isOn: $autoRecords)
                if original != nil {
                    FormDivider(hasIcon: false)
                    FormToggleRow(title: "Tạm dừng", subtitle: "Không nhắc, không ghi cho tới khi tắt",
                                  isOn: $isPaused)
                }
            }

            FormGroup(title: "Ghi chú") {
                FormNoteRow(text: $note, prompt: "Tiền nhà, Netflix, Lương…")
            }

            if let original {
                FormGroup(footer: "Các giao dịch đã ghi vẫn giữ nguyên.") {
                    FormDestructiveRow(title: "Xoá khoản định kỳ", question: "Xoá khoản định kỳ này?",
                                       message: "Milu sẽ không nhắc hay ghi nữa. Các giao dịch đã ghi vẫn giữ nguyên.") {
                        dismiss()
                        AfterDismiss.run { store.delete(original) }
                    }
                }
            }
        }
        .miluSheetStyle()
        .onAppear {
            if accountID == nil { accountID = store.usableAccounts.first?.id }
        }
        .onChange(of: kind) { _, new in
            if !CategoryPickerRow.isPickable(categoryID, kind: new, in: store) { categoryID = "" }
        }
    }

    private func save() {
        guard canSave, let accountID, let schedule = repeatChoice.schedule else { return }
        var rule = original ?? RecurringRule(kind: kind, amount: amount, categoryID: categoryID,
                                             accountID: accountID, startDate: startDate,
                                             lastHandled: FinanceStore.firstHandled(forNewRuleStarting: startDate))
        // A new schedule, or resumed after a pause: what fell due before today is not owed (no
        // catch-up of the paused weeks).
        let calendar = Calendar.current
        if let old = original, !calendar.isDate(old.startDate, inSameDayAs: startDate) || old.frequency != schedule.frequency
            || old.interval != schedule.interval || (old.isPaused && !isPaused) {
            rule.lastHandled = max(old.lastHandled ?? .distantPast,
                                   calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now)) ?? .now)
        }
        rule.kind = kind
        rule.amount = amount
        rule.categoryID = categoryID
        rule.accountID = accountID
        rule.frequency = schedule.frequency
        rule.interval = schedule.interval
        rule.startDate = startDate
        rule.endDate = hasEnd ? endDate : nil
        rule.autoRecords = autoRecords
        rule.pausedAt = isPaused ? (original?.pausedAt ?? .now) : nil
        rule.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let isNew = original == nil
        store.save(rule)
        // One that records by itself and is due today is recorded now, not at the next opening.
        store.recordDueRecurring()
        dismiss()
        if isNew { Task { await RecurringReminderPlan.turnOnIfNeverSet() } }
    }
}
