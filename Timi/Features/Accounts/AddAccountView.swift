import SwiftUI

/// Adds a payment account: cash, bank or e-wallet. Banks and wallets are picked from the
/// catalogue (with their logo), which also fills in the name.
struct AddAccountView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var type: AccountType = .bank
    @State private var institutionID: String?
    @State private var name = ""
    @State private var detail = ""
    @State private var balanceText = ""
    @State private var isPickingInstitution = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var institution: Institution? { Institution.find(institutionID) }
    private var hasInstitutions: Bool { !Institution.list(for: type).isEmpty }

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
        } content: {
            FormGroup {
                FormPickerRow(title: "Loại", selection: $type, options: AccountType.paymentTypes,
                              optionIcon: { $0.icon }) { $0.title }
                if hasInstitutions {
                    FormDivider(hasIcon: false)
                    institutionRow
                }
                FormDivider(hasIcon: false)
                FormTextRow(title: "Tên tài khoản", text: $name,
                            prompt: type == .cash ? "Ví tiền mặt" : institution?.shortName ?? "Vietcombank")
                FormDivider(hasIcon: false)
                FormTextRow(title: "Mô tả", text: $detail, prompt: type == .eWallet ? "0912 •••• 88" : "•••• 4821")
            }
        }
        .timiSheetStyle()
        .sheet(isPresented: $isPickingInstitution) {
            InstitutionPickerSheet(type: type, selection: $institutionID)
        }
        .onChange(of: type) {
            // A bank picked for "Ngân hàng" makes no sense for a wallet; start the choice again.
            if let institution, !Institution.list(for: type).contains(institution) {
                if name == institution.shortName { name = "" }
                institutionID = nil
            }
        }
        .onChange(of: institutionID) { oldID, _ in
            // Fill the name from the pick, unless the user already typed their own.
            let previous = Institution.find(oldID)?.shortName
            if trimmedName.isEmpty || trimmedName == previous {
                name = institution?.shortName ?? ""
            }
        }
    }

    private var institutionRow: some View {
        Button { isPickingInstitution = true } label: {
            HStack(spacing: Spacing.s) {
                FormRowLabel(title: type == .eWallet ? "Ví" : "Ngân hàng")
                Spacer(minLength: Spacing.s)
                if let institution {
                    InstitutionLogo(image: institution.logoImage, size: 24)
                    Text(institution.shortName)
                        .textRole(.body)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                } else {
                    Text("Chọn")
                        .textRole(.body)
                        .foregroundStyle(Palette.secondaryText)
                }
                SolarIcon("solar-alt-arrow-right-linear", size: 16)
                    .foregroundStyle(Palette.secondary)
            }
            .formRowFrame()
            .contentShape(Rectangle())
        }
        .buttonStyle(.row)
        .accessibilityValue(institution?.shortName ?? "Chưa chọn")
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        store.add(Account(
            name: trimmedName,
            type: type,
            balance: balanceText.vndInputAmount,
            color: type.defaultColor,
            detail: trimmedDetail.isEmpty ? (institution?.name ?? type.title) : trimmedDetail,
            institutionID: hasInstitutions ? institutionID : nil
        ))
        dismiss()
    }
}

#Preview("Thêm tài khoản") {
    AddAccountView()
        .environment(FinanceStore())
}
