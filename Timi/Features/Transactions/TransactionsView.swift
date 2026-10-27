//
//  TransactionsView.swift
//  Timi
//

import SwiftUI

enum TransactionSegment: String, CaseIterable, Identifiable {
    case flows, loans

    var id: Self { self }

    var title: String {
        switch self {
        case .flows: "Thu chi"
        case .loans: "Vay nợ"
        }
    }
}

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all, income, expense, transfer

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Tất cả"
        case .income: "Thu"
        case .expense: "Chi"
        case .transfer: "Chuyển khoản"
        }
    }

    func matches(_ transaction: FinanceTransaction) -> Bool {
        switch self {
        case .all: true
        case .income: transaction.kind == .income
        case .expense: transaction.kind == .expense
        // The app has no transfer transactions yet; the chip stays to match the design.
        case .transfer: false
        }
    }
}

struct TransactionsView: View {
    @Environment(FinanceStore.self) private var store
    @AppStorage("overview.monthlyBudget") private var monthlyBudget = SampleData.monthlyBudget
    @State private var segment: TransactionSegment = .flows
    @State private var filter: TransactionFilter = .all
    @State private var loanFilter: LoanFilter = .all
    @State private var displayedMonth = Date.now
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isAddingTransaction = false
    @State private var isAddingLoan = false
    @State private var editingLoan: Loan?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Loại", selection: $segment) {
                        ForEach(TransactionSegment.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)

                    switch segment {
                    case .flows:
                        summaryCard
                        FilterChips(selection: $filter)
                        flowList
                    case .loans:
                        LoansContent(filter: $loanFilter, searchText: searchText) { editingLoan = $0 }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                // Leave room for the floating + button above the tab bar.
                .padding(.bottom, 96)
            }
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            .overlay(alignment: .bottomTrailing) { addButton }
            // The title names the back button of pushed screens; the leading heading is the visible title.
            .navigationTitle("Giao dịch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) { heading }
                        .sharedBackgroundVisibility(.hidden)
                    ToolbarItem(placement: .topBarTrailing) {
                        searchButton.nativeCircleButton(diameter: 44)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) { heading }
                    ToolbarItem(placement: .topBarTrailing) { searchButton }
                }
            }
            .modifier(OnDemandSearch(text: $searchText, isPresented: $isSearching,
                                     prompt: segment == .flows ? "Tìm giao dịch" : "Tìm khoản vay"))
            .navigationDestination(for: Account.ID.self) { AccountDetailView(accountID: $0) }
            .sheet(isPresented: $isAddingTransaction) { AddTransactionView() }
            .sheet(isPresented: $isAddingLoan) { LoanEditorView(loan: nil) }
            .sheet(item: $editingLoan) { LoanEditorView(loan: $0) }
        }
    }

    private var heading: some View {
        Text("Giao dịch")
            .font(Typography.font(.title2, size: 24, weight: .semibold))
            .foregroundStyle(Palette.ink)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
    }

    private var searchButton: some View {
        Button { isSearching = true } label: {
            SolarIcon("solar-magnifer-linear", size: 20)
                .frame(width: 28, height: 28)
        }
        .buttonBorderShape(.circle)
        .tint(Palette.ink)
        .accessibilityLabel(segment == .flows ? "Tìm giao dịch" : "Tìm khoản vay")
    }

    private var addButton: some View {
        Button {
            switch segment {
            case .flows: isAddingTransaction = true
            case .loans: isAddingLoan = true
            }
        } label: {
            SolarIcon("material-symbols-add-rounded", size: 26)
                .foregroundStyle(Palette.ink)
        }
        .nativeFloatingButton(diameter: 56, tint: Palette.lime)
        .padding(.trailing, 20)
        .padding(.bottom, 16)
        .accessibilityLabel(segment == .flows ? "Thêm giao dịch" : "Thêm khoản vay")
    }

    // MARK: - Thu chi

    private var monthTransactions: [FinanceTransaction] {
        store.monthlyTransactions(for: displayedMonth)
    }

    private var summaryCard: some View {
        let expenses = monthTransactions.filter { $0.kind == .expense }
        let incomes = monthTransactions.filter { $0.kind == .income }
        let spent = expenses.reduce(0) { $0 + $1.amount }
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                MonthMenu(month: $displayedMonth)
            }
            HStack(spacing: 0) {
                flowTotal("Đã chi · \(expenses.count)", amount: spent)
                    .padding(.trailing, 16)
                    .overlay(alignment: .trailing) { Palette.border.frame(width: 1) }
                flowTotal("Đã thu · \(incomes.count)", amount: incomes.reduce(0) { $0 + $1.amount })
                    .padding(.leading, 16)
            }
            .padding(.top, 20)
            DailySpendingChart(month: displayedMonth, transactions: expenses)
                .padding(.top, 20)
            if monthlyBudget > 0 {
                budgetRow(spent: spent)
                    .padding(.top, 16)
                    .overlay(alignment: .top) { Palette.border.frame(height: 1) }
                    .padding(.top, 16)
            }
        }
        .sleekCard(radius: CardCorners.extraLarge)
    }

    private func flowTotal(_ title: String, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Typography.font(.caption, size: 12, weight: .medium))
                .foregroundStyle(Palette.secondaryText)
                .designLineHeight(16, relativeTo: .caption)
            // Exact line height + minimumScaleFactor shrinks text unexpectedly on iOS; use min-height.
            Text(amount.vnd)
                .font(Typography.font(.title2, size: 24, weight: .heavy))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                .frame(minHeight: 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func budgetRow(spent: Double) -> some View {
        let ratio = spent / monthlyBudget
        let over = spent > monthlyBudget
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Đã dùng \(ratio.percentText) hạn mức tổng")
                    .font(Typography.font(.subheadline, size: 14, weight: .medium))
                    .designLineHeight(20, relativeTo: .subheadline)
                Spacer(minLength: 8)
                Text(over ? "vượt \((spent - monthlyBudget).vndCompact)" : "còn \((monthlyBudget - spent).vndCompact)")
                    .font(Typography.font(.caption, size: 12, weight: .semibold))
                    .foregroundStyle(over ? Palette.red : Palette.secondaryText)
                    .monospacedDigit()
            }
            // Same colors as the Overview limit bar: green within budget, red when over.
            ProgressBar(value: ratio, color: over ? Palette.red : Palette.green, height: 8)
        }
        .accessibilityElement(children: .combine)
    }

    private var filteredTransactions: [FinanceTransaction] {
        monthTransactions.filter { transaction in
            filter.matches(transaction)
                && (searchText.isEmpty
                    || transaction.title.localizedCaseInsensitiveContains(searchText)
                    || transaction.category.title.localizedCaseInsensitiveContains(searchText))
        }
    }

    /// Gom giao dịch theo ngày, ngày mới nhất lên đầu.
    private var transactionsByDay: [(day: Date, items: [FinanceTransaction])] {
        let groups = Dictionary(grouping: filteredTransactions) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in (day, groups[day] ?? []) }
    }

    @ViewBuilder
    private var flowList: some View {
        let groups = transactionsByDay
        if groups.isEmpty {
            EmptyStateCard(icon: filter == .transfer ? "solar-transfer-horizontal-linear" : "solar-inbox-linear",
                           title: emptyTitle, message: emptyMessage)
        } else {
            ForEach(groups, id: \.day) { group in
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: group.day.transactionDayTitle) { DayTotals(items: group.items) }
                    VStack(spacing: 0) {
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, transaction in
                            FlowRow(transaction: transaction)
                                .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                                .contextMenu {
                                    Button("Xoá giao dịch", role: .destructive) { store.delete(transaction) }
                                }
                        }
                    }
                    .cardSurface(color: Palette.card, elevated: true)
                }
            }
        }
    }

    private var emptyTitle: String {
        if !searchText.isEmpty { return "Không tìm thấy" }
        return filter == .transfer ? "Chưa có giao dịch chuyển khoản" : "Chưa có giao dịch"
    }

    private var emptyMessage: String {
        if !searchText.isEmpty { return "Không có giao dịch nào khớp với “\(searchText)” trong tháng này." }
        if filter == .transfer { return "Chuyển tiền giữa các tài khoản sẽ có trong bản cập nhật sau." }
        return "Thêm giao dịch đầu tiên để bắt đầu theo dõi."
    }
}

// MARK: - Thành phần

/// Sleek shows only a search button, so the native search field is attached while searching
/// and removed (with its query) when the user cancels.
private struct OnDemandSearch: ViewModifier {
    @Binding var text: String
    @Binding var isPresented: Bool
    let prompt: String

    func body(content: Content) -> some View {
        if isPresented {
            content
                .searchable(text: $text, isPresented: $isPresented, prompt: prompt)
                .onDisappear { text = "" }
        } else {
            content
        }
    }
}

/// Month button from the design: "Tháng 5" + chevron on a muted capsule.
private struct MonthMenu: View {
    @Binding var month: Date

    var body: some View {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: month)
        let number = calendar.component(.month, from: month)
        let isCurrentYear = year == calendar.component(.year, from: .now)
        Menu {
            Button("Tháng trước") { shift(-1) }
            Button("Tháng hiện tại") { month = .now }
            Button("Tháng sau") { shift(1) }
            Divider()
            ForEach((year - 1)...(year + 1), id: \.self) { targetYear in
                Menu(String(targetYear)) {
                    ForEach(1...12, id: \.self) { targetMonth in
                        Button("Tháng \(targetMonth)") {
                            if let date = calendar.date(from: DateComponents(year: targetYear, month: targetMonth, day: 1)) {
                                month = date
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(isCurrentYear ? "Tháng \(number)" : "T\(number)/\(year.formatted(.number.grouping(.never)))")
                    .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                    .monospacedDigit()
                SolarIcon("solar-alt-arrow-down-linear", size: 14)
            }
            .foregroundStyle(Palette.ink)
        }
        .menuIndicator(.hidden)
        .nativeGlassButton(tint: Palette.muted)
        .buttonBorderShape(.capsule)
        .accessibilityLabel("Chọn tháng, tháng \(number) năm \(String(year))")
    }

    private func shift(_ delta: Int) {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        month = calendar.date(byAdding: .month, value: delta, to: start) ?? start
    }
}

/// One bar per day of the month, scaled to the biggest spending day.
private struct DailySpendingChart: View {
    let month: Date
    let transactions: [FinanceTransaction]

    var body: some View {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let totals = Dictionary(grouping: transactions) { calendar.component(.day, from: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        let peak = totals.values.max() ?? 0
        let today = calendar.startOfDay(for: .now)
        let monthNumber = calendar.component(.month, from: start)

        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(1...dayCount, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: start) ?? start
                    let isFuture = date > today
                    let ratio = isFuture || peak == 0 ? 0.06 : max(totals[day, default: 0] / peak, 0.04)
                    Capsule()
                        .fill(calendar.isDate(date, inSameDayAs: today) ? Palette.lime
                              : isFuture ? Palette.muted : Palette.secondary.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 64 * ratio)
                }
            }
            .frame(height: 64, alignment: .bottom)
            HStack {
                Text("1/\(monthNumber)")
                Spacer()
                Text("\(dayCount)/\(monthNumber)")
            }
            .font(Typography.font(.caption2, size: 11))
            .foregroundStyle(Palette.secondaryText)
            .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Biểu đồ chi tiêu theo ngày trong tháng \(monthNumber)")
    }
}

private struct FilterChips: View {
    @Binding var selection: TransactionFilter

    var body: some View {
        ChipRow(options: TransactionFilter.allCases, selection: $selection) { $0.title }
    }
}

/// Day totals beside each date heading: both sides in full, a single side compact.
private struct DayTotals: View {
    let items: [FinanceTransaction]

    var body: some View {
        let income = items.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        let expense = items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        HStack(spacing: 12) {
            if income > 0 && expense > 0 {
                Text("+\(income.formatted(.number.locale(.vietnam)))")
                Text("-\(expense.formatted(.number.locale(.vietnam)))").foregroundStyle(Palette.red)
            } else if income > 0 {
                Text("+\(income.vndCompact)")
            } else {
                Text("-\(expense.vndCompact)").foregroundStyle(Palette.secondaryText)
            }
        }
        .font(Typography.font(.caption2, size: 11, weight: .semibold))
        .monospacedDigit()
    }
}

/// Transaction row: lime icon circle for income, muted for expenses.
private struct FlowRow: View {
    let transaction: FinanceTransaction

    var body: some View {
        let income = transaction.kind == .income
        HStack(spacing: 12) {
            IconCircle(icon: transaction.category.icon, background: income ? Palette.lime : Palette.muted)
            VStack(alignment: .leading, spacing: 0) {
                Text(transaction.title)
                    .font(Typography.font(.subheadline, size: 14, weight: .semibold))
                    .designLineHeight(20, relativeTo: .subheadline)
                    .lineLimit(1)
                Text("\(transaction.category.title) · \(transaction.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam)))")
                    .font(Typography.font(.caption2, size: 11))
                    .foregroundStyle(Palette.secondaryText)
                    .designLineHeight(16.5, relativeTo: .caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(transaction.signedAmountText)
                .font(Typography.font(.subheadline, size: 14, weight: .bold))
                .foregroundStyle(income ? Palette.ink : Palette.red)
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}


#Preview {
    TransactionsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
        .font(Typography.body)
}
