//
//  AddTransactionView.swift
//  Timi
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var kind: TransactionKind = .expense
    @State private var amountText = ""
    @State private var title = ""
    @State private var category: TransactionCategory = .food
    @State private var accountID: Account.ID?
    @State private var date = Date.now
    @State private var note = ""
    @FocusState private var isAmountFocused: Bool

    private var amount: Double {
        Double(amountText.filter(\.isASCIIDigit)) ?? 0
    }

    private var canSave: Bool {
        amount > 0 && accountID != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Loại giao dịch", selection: $kind) {
                        ForEach(TransactionKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section("Số tiền") {
                    HStack(alignment: .firstTextBaseline) {
                        TextField("0", text: $amountText)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(kind == .income ? .green : .primary)
                            .keyboardType(.numberPad)
                            .focused($isAmountFocused)
                        Text("₫")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Chi tiết") {
                    TextField("Tên giao dịch (VD: Cà phê sáng)", text: $title)
                    Picker("Danh mục", selection: $category) {
                        ForEach(TransactionCategory.categories(for: kind)) { category in
                            Label(category.title, systemImage: category.icon).tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    Picker("Tài khoản", selection: $accountID) {
                        ForEach(store.accounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                    DatePicker("Thời gian", selection: $date)
                }

                Section("Ghi chú") {
                    TextField("Thêm ghi chú", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Thêm giao dịch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu", action: save)
                        .disabled(!canSave)
                }
            }
            .onChange(of: kind) { _, newKind in
                category = TransactionCategory.categories(for: newKind).first ?? category
            }
            .onChange(of: amountText) { _, newValue in
                // Tự thêm dấu chấm phân cách hàng nghìn khi gõ: 1250000 → 1.250.000
                let digits = String(newValue.filter(\.isASCIIDigit).prefix(12))
                let formatted = digits.isEmpty ? "" : (Double(digits) ?? 0).formatted(.number.locale(.vietnam))
                if formatted != newValue {
                    amountText = formatted
                }
            }
            .onAppear {
                accountID = accountID ?? store.accounts.first?.id
                isAmountFocused = true
            }
        }
    }

    private func save() {
        guard let accountID, amount > 0 else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        store.add(FinanceTransaction(
            title: trimmedTitle.isEmpty ? category.title : trimmedTitle,
            amount: amount,
            category: category,
            accountID: accountID,
            date: date,
            note: note
        ))
        dismiss()
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}

#Preview {
    AddTransactionView()
        .environment(FinanceStore())
        .environment(\.locale, .vietnam)
}
