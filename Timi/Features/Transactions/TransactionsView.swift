//
//  TransactionsView.swift
//  Timi
//

import SwiftUI

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all, expense, income

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Tất cả"
        case .expense: "Chi"
        case .income: "Thu"
        }
    }

    func matches(_ transaction: FinanceTransaction) -> Bool {
        switch self {
        case .all: true
        case .expense: transaction.kind == .expense
        case .income: transaction.kind == .income
        }
    }
}

struct TransactionsView: View {
    @Environment(FinanceStore.self) private var store
    @State private var filter: TransactionFilter = .all
    @State private var searchText = ""
    @State private var isAddingTransaction = false

    private var filteredTransactions: [FinanceTransaction] {
        store.transactions.filter { transaction in
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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Lọc", selection: $filter) {
                        ForEach(TransactionFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                ForEach(transactionsByDay, id: \.day) { group in
                    Section {
                        ForEach(group.items) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                store.delete(group.items[index])
                            }
                        }
                    } header: {
                        HStack {
                            Text(group.day.relativeDayTitle)
                            Spacer()
                            Text(dayNetText(group.items))
                                .monospacedDigit()
                        }
                    }
                }
            }
            .overlay {
                if transactionsByDay.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "Chưa có giao dịch",
                            image: "solar-inbox-linear",
                            description: Text("Nhấn + để thêm giao dịch đầu tiên.")
                        )
                    } else {
                        ContentUnavailableView(
                            "Không tìm thấy",
                            image: "solar-magnifier-linear",
                            description: Text("Không có giao dịch nào khớp với “\(searchText)”.")
                        )
                    }
                }
            }
            .animation(.default, value: filter)
            .searchable(text: $searchText, prompt: "Tìm giao dịch")
            .navigationTitle("Giao dịch")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingTransaction = true
                    } label: {
                        Label("Thêm giao dịch", image: "solar-add-linear")
                    }
                }
            }
            .sheet(isPresented: $isAddingTransaction) {
                AddTransactionView()
            }
        }
    }

    private func dayNetText(_ items: [FinanceTransaction]) -> String {
        let net = items.reduce(0) { $0 + $1.signedAmount }
        return (net > 0 ? "+" : "") + net.vnd
    }
}

#Preview {
    TransactionsView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
