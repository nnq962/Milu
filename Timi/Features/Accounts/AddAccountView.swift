import SwiftUI

/// Adds a payment account: cash, bank or e-wallet.
struct AddAccountView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var type: AccountType = .bank
    @State private var name = ""
    @State private var detail = ""
    @State private var balanceText = ""

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        SheetScaffold(title: "Thêm tài khoản", canConfirm: !trimmedName.isEmpty, onConfirm: save) {
            VStack(spacing: Spacing.xs) {
                Text("Số dư hiện tại")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                TimiAmountField(text: $balanceText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)

            FormGroup {
                FormTextRow(title: "Tên tài khoản", text: $name, prompt: "Vietcombank")
                FormDivider(hasIcon: false)
                FormPickerRow(title: "Loại", selection: $type, options: AccountType.paymentTypes,
                              optionIcon: { $0.icon }) { $0.title }
                FormDivider(hasIcon: false)
                FormTextRow(title: "Mô tả", text: $detail, prompt: "•••• 4821")
            }
        }
        .timiSheetStyle()
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
