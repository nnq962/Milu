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

        /// The transfer itself: its amount, either account.
        func matches(_ transfer: AccountTransfer) -> Bool {
            guard filter.kind == .all || filter.kind == .transfer, filter.groupIDs.isEmpty,
                  fits(amount: transfer.amount, date: transfer.date) else { return false }
            if !filter.accountIDs.isEmpty,
               filter.accountIDs.isDisjoint(with: [transfer.fromAccountID, transfer.toAccountID]) { return false }
            return true
        }
    }

    /// One kind of narrowing, for a chip that drops it.
    enum Part: Hashable { case kind, period, amount, accounts, groups }

    struct Chip: Identifiable {
        let part: Part
        let title: String
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

    /// "29/10" this year, "29/10/2025" another.
    private static func day(_ date: Date) -> String {
        let sameYear = Calendar.current.isDate(date, equalTo: .now, toGranularity: .year)
        return TransactionListRow.dayMonth(date) + (sameYear ? "" : "/\(Calendar.current.component(.year, from: date))")
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
            chips.append(Chip(part: .period, title: "\(Self.day(min(from, to)))–\(Self.day(max(from, to)))"))
        } else if period != .all {
            chips.append(Chip(part: .period, title: period.title))
        }
        switch (minAmount, maxAmount) {
        case let (min?, max?): chips.append(Chip(part: .amount, title: "\(min.vndCompact)–\(max.vndCompact)"))
        case let (min?, nil): chips.append(Chip(part: .amount, title: "Từ \(min.vndCompact)"))
        case let (nil, max?): chips.append(Chip(part: .amount, title: "Đến \(max.vndCompact)"))
        default: break
        }
        if accountIDs.count == 1, let id = accountIDs.first {
            chips.append(Chip(part: .accounts, title: store.account(id: id)?.name ?? "1 tài khoản"))
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

    private var accounts: [Account] { store.accounts + store.archivedAccounts }

    var body: some View {
        SheetScaffold(title: "Bộ lọc", canConfirm: amountError == nil && dateError == nil, onConfirm: apply) {
            // The page's chips, so the four kinds read in full.
            VStack(alignment: .leading, spacing: Spacing.headerGap) {
                SectionHeader(title: "Loại", style: .group)
                FilterChips(selection: Binding { draft.kind } set: { draft.setKind($0, groupsOf: store) })
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

            FormGroup(title: "Tài khoản", footer: "Không chọn là mọi tài khoản.") {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    toggleRow(icon: account.iconName, title: account.name,
                              isOn: draft.accountIDs.contains(account.id)) {
                        draft.accountIDs.formSymmetricDifference([account.id])
                    }
                    .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                }
            }

            if !groups.isEmpty {
                FormGroup(title: "Nhóm hạng mục", footer: "Không chọn là mọi nhóm.") {
                    ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                        toggleRow(icon: group.icon, title: group.name, isOn: draft.groupIDs.contains(group.id)) {
                            draft.groupIDs.formSymmetricDifference([group.id])
                        }
                        .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                    }
                }
            }

            if draft.isActive || minAmount != nil || maxAmount != nil {
                FormGroup {
                    FormActionRow(title: "Đặt lại bộ lọc", icon: "hugeicons-cancel-01") {
                        withAnimation(.smooth(duration: 0.25)) {
                            draft = TransactionSearchFilter()
                            minText = ""
                            maxText = ""
                        }
                    }
                }
            }
        }
        .timiSheetStyle()
        .animation(.smooth(duration: 0.25), value: draft.period)
        .animation(.smooth(duration: 0.25), value: draft.kind)
    }

    private func toggleRow(icon: String, title: String, isOn: Bool, toggle: @escaping () -> Void) -> some View {
        Button {
            toggle()
            Haptics.selection()
        } label: {
            PickerRowLabel(icon: icon, title: title, isSelected: isOn)
        }
        .buttonStyle(.row)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func apply() {
        draft.minAmount = minAmount
        draft.maxAmount = maxAmount
        filter = draft
        dismiss()
    }
}
