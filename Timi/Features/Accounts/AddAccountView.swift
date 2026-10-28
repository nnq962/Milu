import SwiftUI

struct AddAccountView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var type: AccountType = .bank
    @State private var name = ""
    @State private var detail = ""
    @State private var balanceText = ""

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Loại tài khoản", selection: $type) {
                        ForEach(AccountType.paymentTypes) { type in
                            Label(type.title, image: type.icon).tag(type)
                        }
                    }
                    TextField("Tên tài khoản (VD: Vietcombank)", text: $name)
                    TextField("Mô tả (VD: •••• 4821)", text: $detail)
                }

                Section("Số dư hiện tại") {
                    AmountField(text: $balanceText)
                }
            }
            .navigationTitle("Thêm tài khoản")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneButton()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu", action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        store.add(Account(
            name: trimmedName,
            type: type,
            balance: balanceText.vndInputAmount,
            color: type.defaultColor,
            detail: trimmedDetail.isEmpty ? type.title : trimmedDetail
        ))
        dismiss()
    }
}

#Preview("Thêm tài khoản") {
    AddAccountView()
        .environment(FinanceStore())
}
