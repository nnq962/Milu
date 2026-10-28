import SwiftUI

/// Adds a payment account of the type picked in "Thêm mới": cash, bank or e-wallet. Banks and
/// wallets come from the catalogue (with their logo), which also fills in the name. A name (and,
/// for a bank or wallet, which one) is required: tapping ✓ without it marks the row red and says
/// what is missing. An empty balance means 0đ.
struct AddAccountView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let type: AccountType
    @State private var institutionID: String?
    @State private var name = ""
    @State private var note = ""
    @State private var balanceText = ""
    @State private var isNegative = false
    @State private var openedAt = Date.now
    @State private var excluded = false
    @State private var isPickingInstitution = false
    /// Set by the first ✓ tap; from then on missing fields show as errors and clear as they are fixed.
    @State private var showsErrors = false
    @State private var failedSaves = 0

    init(type: AccountType = .bank) {
        self.type = type
    }

    private var institution: Institution? { Institution.find(institutionID) }
    private var hasInstitutions: Bool { !Institution.list(for: type).isEmpty }

    private var title: String {
        switch type {
        case .cash: "Thêm tiền mặt"
        case .eWallet: "Thêm ví điện tử"
        default: "Thêm tài khoản ngân hàng"
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var missesInstitution: Bool { hasInstitutions && institution == nil }
    private var missesName: Bool { trimmedName.isEmpty }

    /// What still has to be filled in, as one sentence; nil when the form can be saved.
    private var error: String? {
        guard showsErrors else { return nil }
        let pick = type == .eWallet ? "Chọn ví điện tử" : "Chọn ngân hàng"
        switch (missesInstitution, missesName) {
        case (true, true): return "\(pick) và nhập tên tài khoản."
        case (true, false): return "\(pick)."
        case (false, true): return "Nhập tên tài khoản."
        case (false, false): return nil
        }
    }

    /// Placeholder of the name field.
    private var suggestedName: String {
        switch type {
        case .cash: "Tiền mặt"
        case .eWallet: institution?.shortName ?? "MoMo"
        default: institution?.shortName ?? "Vietcombank"
        }
    }

    var body: some View {
        SheetScaffold(title: title, validate: validate, onConfirm: save) {
            VStack(spacing: Spacing.xs) {
                Text("Số dư hiện tại")
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                TimiAmountField(text: $balanceText, focusesOnAppear: true, isNegative: isNegative)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
        } content: {
            // Every group is plain rows, no captions: the labels on the rows say it all.
            FormGroup(error: error, shakes: failedSaves) {
                if hasInstitutions {
                    institutionRow
                    FormDivider(hasIcon: false)
                }
                FormTextRow(title: "Tên tài khoản", text: $name, prompt: suggestedName,
                            isInvalid: showsErrors && missesName)
                FormDivider(hasIcon: false)
                FormToggleRow(title: "Số dư âm", isOn: $isNegative)
            }

            FormGroup {
                FormDateRow(title: "Ngày", date: $openedAt)
                FormDivider(hasIcon: false)
                FormTimeRow(title: "Giờ", date: $openedAt)
                FormDivider(hasIcon: false)
                FormToggleRow(title: "Không tính vào báo cáo", isOn: $excluded)
            }

            FormGroup {
                FormNoteRow(text: $note, prompt: "Ghi chú")
            }
        }
        .timiSheetStyle()
        .sheet(isPresented: $isPickingInstitution) {
            InstitutionPickerSheet(type: type, selection: $institutionID)
        }
        .onChange(of: institutionID) { oldID, _ in
            // Follow the pick unless the user already typed a name of their own.
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed == Institution.find(oldID)?.shortName {
                name = institution?.shortName ?? ""
            }
        }
    }

    private var institutionRow: some View {
        Button { isPickingInstitution = true } label: {
            HStack(spacing: Spacing.s) {
                FormRowLabel(title: type == .eWallet ? "Ví" : "Ngân hàng", isInvalid: showsErrors && missesInstitution)
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

    /// Turns on the error messages; true when nothing is missing.
    private func validate() -> Bool {
        showsErrors = true
        let isValid = !missesInstitution && !missesName
        if !isValid { failedSaves += 1 }
        return isValid
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = balanceText.vndInputAmount
        store.add(Account(
            name: trimmedName,
            type: type,
            balance: isNegative ? -amount : amount,
            detail: trimmedNote.isEmpty ? (institution?.name ?? type.title) : trimmedNote,
            institutionID: hasInstitutions ? institutionID : nil,
            openedAt: openedAt,
            excluded: excluded
        ))
        dismiss()
    }
}

#Preview("Thêm tiền mặt") {
    AddAccountView(type: .cash)
        .environment(FinanceStore())
}
