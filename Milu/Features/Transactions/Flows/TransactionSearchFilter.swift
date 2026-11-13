import SwiftUI

/// What a search on "Giao dịch" narrows to besides its words (user request 2026-10-29): the kind,
/// a period, an amount range, accounts and category groups. Empty sets and nil bounds mean "any".
struct TransactionSearchFilter: Equatable {
    enum Period: String, CaseIterable, Identifiable {
        case all, thisMonth, lastMonth, last30Days, custom

        var id: Self { self }

        var title: String {
            switch self {
            case .all: "Mọi lúc"
            case .thisMonth: "Tháng này"
            case .lastMonth: "Tháng trước"
            case .last30Days: "30 ngày qua"
            case .custom: "Tuỳ chọn"
            }
        }
    }

    var kind: TransactionFilter = .all
    var period: Period = .all
    /// The custom period, both days included.
    var from = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    var to = Date.now
    var minAmount: Double?
    var maxAmount: Double?
    var accountIDs: Set<Account.ID> = []
    /// Groups of "Hạng mục"; a transaction counts by its item's group. Transfers have none.
    var groupIDs: Set<String> = []

    /// How many kinds of narrowing are on, for the button's badge.
    var activeCount: Int {
        [kind != .all, period != .all, minAmount != nil || maxAmount != nil, !accountIDs.isEmpty, !groupIDs.isEmpty]
            .filter { $0 }.count
    }

    var isActive: Bool { activeCount > 0 }

    /// The days the period covers; nil for "Mọi lúc".
    var dateRange: ClosedRange<Date>? {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now
        switch period {
        case .all:
            return nil
        case .thisMonth:
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? endOfToday
            return startOfMonth...endOfMonth.addingTimeInterval(-1)
        case .lastMonth:
            let start = calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? startOfMonth
            return start...startOfMonth.addingTimeInterval(-1)
        case .last30Days:
            return (calendar.date(byAdding: .day, value: -30, to: endOfToday) ?? endOfToday)...endOfToday
        case .custom:
            let start = calendar.startOfDay(for: min(from, to))
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: max(from, to))) ?? to
            return start...end.addingTimeInterval(-1)
        }
    }

    /// The checks of one search, with the period's days and each item's group worked out once
    /// rather than once per transaction.
    func matcher(in store: FinanceStore) -> Matcher {
        Matcher(filter: self, range: dateRange,
                groupOf: Dictionary(store.categories.compactMap { item in item.parentID.map { (item.id, $0) } },
                                    uniquingKeysWith: { first, _ in first }))
    }

    struct Matcher {
        let filter: TransactionSearchFilter
        let range: ClosedRange<Date>?
        /// An item's group; a group or a system category is its own.
        let groupOf: [String: String]

        private func fits(amount: Double, date: Date) -> Bool {
            if let min = filter.minAmount, amount < min { return false }
            if let max = filter.maxAmount, amount > max { return false }
            if let range, !range.contains(date) { return false }
            return true
        }

        func matches(_ transaction: FinanceTransaction) -> Bool {
            guard filter.kind != .transfer, filter.kind.matches(transaction),
                  fits(amount: transaction.amount, date: transaction.date) else { return false }
            if !filter.accountIDs.isEmpty, !filter.accountIDs.contains(transaction.accountID) { return false }
            if !filter.groupIDs.isEmpty,
               !filter.groupIDs.contains(groupOf[transaction.categoryID] ?? transaction.categoryID) { return false }
            return true
        }

        /// The money of a new loan: on "Tất cả" only (it is neither income, spending nor a transfer),
        /// by its principal, date and account.
        func matches(_ loan: Loan) -> Bool {
            guard filter.kind == .all, filter.groupIDs.isEmpty, let account = loan.movedAccountID,
                  fits(amount: loan.principal, date: loan.date) else { return false }
            return filter.accountIDs.isEmpty || filter.accountIDs.contains(account)
        }

        /// A loan's repayment: on "Tất cả" only, by what moved, its date and account.
        func matches(_ payment: LoanPayment) -> Bool {
            guard filter.kind == .all, filter.groupIDs.isEmpty, fits(amount: payment.total, date: payment.date) else { return false }
            return filter.accountIDs.isEmpty || filter.accountIDs.contains(payment.accountID)
        }

        /// The transfer itself: its amount, either account.
        func matches(_ transfer: AccountTransfer) -> Bool {
            guard filter.kind == .all || filter.kind == .transfer, filter.groupIDs.isEmpty,
                  fits(amount: transfer.amount, date: transfer.date) else { return false }
            if !filter.accountIDs.isEmpty,
               filter.accountIDs.isDisjoint(with: [transfer.fromAccountID, transfer.toAccountID]) { return false }
            return true
        }

        /// Money put into or taken from a goal: listed with the transfers on Giao dịch, so it is
        /// found under "Tất cả" and "Chuyển khoản" too (review 2026-11-07); by its amount, its day
        /// and either side, its account or its goal (a goal is in the list once it bought something).
        /// It has no category group.
        func matches(_ transfer: GoalTransfer) -> Bool {
            guard filter.kind == .all || filter.kind == .transfer, filter.groupIDs.isEmpty,
                  fits(amount: transfer.amount, date: transfer.date) else { return false }
            return filter.accountIDs.isEmpty || filter.accountIDs.contains(transfer.accountID)
                || filter.accountIDs.contains(transfer.goalID)
        }
    }

    /// One kind of narrowing, for a chip that drops it.
    enum Part: Hashable { case kind, period, amount, accounts, groups }

    struct Chip: Identifiable {
        let part: Part
        let title: String
        /// The title in words for VoiceOver, when it holds amounts.
        var spoken: String? = nil
        var id: Part { part }
    }

    /// Chooses the kind and keeps only the groups that fit it (a transfer has none, income has
    /// income groups), so a group of the other kind cannot leave nothing to show.
    mutating func setKind(_ newKind: TransactionFilter, groupsOf store: FinanceStore) {
        kind = newKind
        let fitting: [Category] = switch newKind {
        case .expense: store.groups(.expense)
        case .income: store.groups(.income)
        case .all: store.groups(.expense) + store.groups(.income)
        case .transfer: []
        }
        groupIDs.formIntersection(Set(fitting.map(\.id)))
    }

    mutating func clear(_ part: Part) {
        switch part {
        case .kind: kind = .all
        case .period: period = .all
        case .amount: minAmount = nil; maxAmount = nil
        case .accounts: accountIDs = []
        case .groups: groupIDs = []
        }
    }

    /// What is on, one chip each: "Chi", "Tháng này", "Từ 100k", "MoMo", "2 nhóm".
    func chips(in store: FinanceStore) -> [Chip] {
        var chips: [Chip] = []
        if kind != .all { chips.append(Chip(part: .kind, title: kind.title)) }
        if period == .custom {
            chips.append(Chip(part: .period, title: "\(min(from, to).shortDay)–\(max(from, to).shortDay)"))
        } else if period != .all {
            chips.append(Chip(part: .period, title: period.title))
        }
        switch (minAmount, maxAmount) {
        case let (min?, max?):
            chips.append(Chip(part: .amount, title: "\(min.vnd)–\(max.vnd)",
                              spoken: "Từ \(MoneyText.spoken(min)) đến \(MoneyText.spoken(max))"))
        case let (min?, nil):
            chips.append(Chip(part: .amount, title: "Từ \(min.vnd)", spoken: "Từ \(MoneyText.spoken(min))"))
        case let (nil, max?):
            chips.append(Chip(part: .amount, title: "Đến \(max.vnd)", spoken: "Đến \(MoneyText.spoken(max))"))
        default: break
        }
        if accountIDs.count == 1, let id = accountIDs.first {
            chips.append(Chip(part: .accounts, title: store.account(id: id)?.name ?? store.goal(id: id)?.name ?? "1 tài khoản"))
        } else if accountIDs.count > 1 {
            chips.append(Chip(part: .accounts, title: "\(accountIDs.count) tài khoản"))
        }
        if groupIDs.count == 1, let id = groupIDs.first {
            chips.append(Chip(part: .groups, title: store.categoryName(id)))
        } else if groupIDs.count > 1 {
            chips.append(Chip(part: .groups, title: "\(groupIDs.count) nhóm"))
        }
        return chips
    }

}

/// "Bộ lọc" of the search: kind, period, amount range, accounts and category groups. Changes are
/// applied on ✓; "Đặt lại bộ lọc" clears them.
struct TransactionFilterSheet: View {
    @Binding var filter: TransactionSearchFilter

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: TransactionSearchFilter
    @State private var minText: String
    @State private var maxText: String

    init(filter: Binding<TransactionSearchFilter>) {
        _filter = filter
        _draft = State(initialValue: filter.wrappedValue)
        _minText = State(initialValue: filter.wrappedValue.minAmount.map { String(Int($0)).groupedVNDInput } ?? "")
        _maxText = State(initialValue: filter.wrappedValue.maxAmount.map { String(Int($0)).groupedVNDInput } ?? "")
    }

    private var minAmount: Double? { minText.isEmpty ? nil : minText.vndInputAmount }
    private var maxAmount: Double? { maxText.isEmpty ? nil : maxText.vndInputAmount }
    private var amountError: String? {
        guard let minAmount, let maxAmount, minAmount > maxAmount else { return nil }
        return "Số tiền “Từ” lớn hơn “Đến”."
    }

    private var dateError: String? {
        guard draft.period == .custom,
              Calendar.current.startOfDay(for: draft.from) > Calendar.current.startOfDay(for: draft.to) else { return nil }
        return "“Từ ngày” sau “Đến ngày”."
    }

    /// Groups that fit the kind chosen: spending or income ones, or both.
    private var groups: [Category] {
        switch draft.kind {
        case .expense: store.groups(.expense)
        case .income: store.groups(.income)
        case .all: store.groups(.expense) + store.groups(.income)
        case .transfer: []
        }
    }

    /// Purchases from goals deleted since: still listed, so still filterable.
    private var deletedGoalIDs: [UUID] {
        let known = Set((store.accounts + store.archivedAccounts).map(\.id) + store.savingsGoals.map(\.id))
        var seen = Set<UUID>()
        return store.transactions.map(\.accountID).filter { !known.contains($0) && seen.insert($0).inserted }
    }

    /// Where money is recorded: accounts (archived too), then goals a "Mua ngay" purchase is on.
    private var sources: [(id: UUID, name: String, icon: String)] {
        (store.accounts + store.archivedAccounts).map { ($0.id, $0.name, $0.iconName) }
            + store.savingsGoals.filter { !store.goalTransactions($0).isEmpty }.map { ($0.id, $0.name, $0.icon) }
            // Numbered when there are several, so each row can be told apart (review 2026-11-07).
            + deletedGoalIDs.enumerated().map { index, id in
                (id, deletedGoalIDs.count > 1 ? "Hũ đã xoá \(index + 1)" : "Hũ đã xoá", "hugeicons-piggy-bank")
            }
    }

    var body: some View {
        // ✓ stays on; the red lines already say what to fix (sheet review 2026-10-30).
        SheetScaffold(title: "Bộ lọc", validate: { amountError == nil && dateError == nil }, onConfirm: apply) {
            // One row each, opening the list to tick (sheet review 2026-10-30: every account and
            // every group inline made the sheet very long). "Tất cả" says what no tick means.
            // Titled as every other group of the sheet (strict review 2026-10-31).
            FormGroup(title: "Phạm vi") {
                // The kind is one row of the scope, first and opening its choices as the period
                // does (user request 2026-11-07: as chips it stood at the heading's 16 and out of
                // line with the cards below).
                FormPickerRow(title: "Loại",
                              selection: Binding { draft.kind } set: { draft.setKind($0, groupsOf: store) },
                              options: TransactionFilter.allCases) { $0.title }
                FormDivider(hasIcon: false)
                NavigationLink {
                    MultiPickPage(title: "Tài khoản", options: sources.map { ($0.id.uuidString, $0.name, $0.icon) },
                                  selection: Binding {
                                      Set(draft.accountIDs.map(\.uuidString))
                                  } set: { draft.accountIDs = Set($0.compactMap(UUID.init(uuidString:))) })
                } label: {
                    FormValueRowContent(title: "Tài khoản", icon: nil,
                                   value: draft.accountIDs.isEmpty ? "Tất cả" : "\(draft.accountIDs.count) tài khoản")
                }
                .buttonStyle(.row)
                if !groups.isEmpty {
                    FormDivider(hasIcon: false)
                    NavigationLink {
                        MultiPickPage(title: "Nhóm hạng mục", options: groups.map { ($0.id, $0.name, $0.icon) },
                                      selection: $draft.groupIDs)
                    } label: {
                        FormValueRowContent(title: "Nhóm hạng mục", icon: nil,
                                       value: draft.groupIDs.isEmpty ? "Tất cả" : "\(draft.groupIDs.count) nhóm")
                    }
                    .buttonStyle(.row)
                }
            }

            FormGroup(title: "Thời gian", error: dateError) {
                FormPickerRow(title: "Khoảng thời gian", selection: $draft.period,
                              options: TransactionSearchFilter.Period.allCases) { $0.title }
                if draft.period == .custom {
                    FormDivider(hasIcon: false)
                    FormDateRow(title: "Từ ngày", date: $draft.from, latest: .now, isInvalid: dateError != nil)
                    FormDivider(hasIcon: false)
                    FormDateRow(title: "Đến ngày", date: $draft.to, latest: .now, isInvalid: dateError != nil)
                }
            }

            FormGroup(title: "Số tiền", error: amountError) {
                FormAmountRow(title: "Từ", text: $minText)
                FormDivider(hasIcon: false)
                FormAmountRow(title: "Đến", text: $maxText)
            }

            if showsReset {
                FormGroup {
                    // Not the ✕ glyph, which read as the sheet's close button.
                    FormActionRow(title: "Đặt lại bộ lọc", icon: "hugeicons-filter-horizontal") {
                        withAnimation(Motion.gentle(.smooth(duration: 0.25))) {
                            draft = TransactionSearchFilter()
                            minText = ""
                            maxText = ""
                        }
                    }
                }
                // Fades in, as in Vay nợ's filter, also when an amount is typed (review 2026-11-07).
                .transition(.opacity)
            }
        }
        .miluSheetStyle()
        .animation(Motion.gentle(.smooth(duration: 0.25)), value: draft.period)
        .animation(Motion.gentle(.smooth(duration: 0.25)), value: draft.kind)
        .animation(Motion.gentle(.smooth(duration: 0.25)), value: showsReset)
    }

    /// Something is on, or an amount typed though not yet applied.
    private var showsReset: Bool { draft.isActive || minAmount != nil || maxAmount != nil }

    private func apply() {
        draft.minAmount = minAmount
        draft.maxAmount = maxAmount
        filter = draft
        dismiss()
    }
}

/// A list to tick any number of, pushed from the filter sheet: none ticked means all of them.
private struct MultiPickPage: View {
    let title: String
    let options: [(id: String, name: String, icon: String)]
    @Binding var selection: Set<String>

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    let isOn = selection.contains(option.id)
                    Button {
                        selection.formSymmetricDifference([option.id])
                        Haptics.selection()
                    } label: {
                        PickerRowContent(icon: option.icon, title: option.name, isSelected: isOn)
                    }
                    .buttonStyle(.row)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                    .separatorAbove(index > 0, order: index) { FormDivider() }
                }
            }
            .listCard()
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        // The top margin of every detail page and sheet (strict review 2026-10-31).
        .contentMargins(.top, Spacing.s, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !selection.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bỏ chọn") { selection = [] }
                }
            }
        }
    }
}
