import SwiftUI

/// Adds a payment account of the type picked in "Thêm mới": cash, bank or e-wallet. Banks and
/// wallets come from the catalogue (with their logo), which also fills in the name. A name (and,
/// for a bank or wallet, which one) is required: tapping ✓ without it marks the row red and says
/// what is missing. An empty balance means 0đ.
/// Given an `account`, the same form edits it instead: a changed balance is recorded as an
/// "Điều chỉnh số dư" transaction, and "Xoá tài khoản" sits at the end, as on the goal form.
struct AddAccountView: View {
    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let type: AccountType
    private let original: Account?
    /// Called after "Xoá tài khoản" closes the form; the presenter deletes the account (and, from
    /// its detail screen, leaves it first).
    private var onDelete: (() -> Void)?
    @State private var institutionID: String?
    @State private var name = ""
    @State private var note = ""
    @State private var balanceText = ""
    @State private var isNegative = false
    @State private var openedAt = Date.now
    @State private var isLocked = false
    @State private var isPickingInstitution = false
    /// Set by the first ✓ tap; from then on missing fields show as errors and clear as they are fixed.
    @State private var showsErrors = false

    init(type: AccountType = .bank) {
        self.type = type
        original = nil
    }

    init(account: Account, onDelete: @escaping () -> Void) {
        type = account.type
        original = account
        self.onDelete = onDelete
        _institutionID = State(initialValue: account.institutionID)
        _name = State(initialValue: account.name)
        _note = State(initialValue: account.detail)
        _balanceText = State(initialValue: account.balance == 0 ? "" : String(Int(abs(account.balance))).groupedVNDInput)
        _isNegative = State(initialValue: account.balance < 0)
        _openedAt = State(initialValue: account.openedAt)
        _isLocked = State(initialValue: account.isLocked)
    }

    private var institution: Institution? { Institution.find(institutionID) }
    private var hasInstitutions: Bool { !Institution.list(for: type).isEmpty }

    private var title: String {
        if original != nil { return "Sửa tài khoản" }
        return switch type {
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
                TimiAmountField(text: $balanceText, focusesOnAppear: original == nil, isNegative: isNegative)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
        } content: {
            // Labels say it all: no captions or footers (user prefers few words, 2026-10-28).
            FormGroup(error: error) {
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
                FormDateRow(title: "Số dư tính từ", date: $openedAt)
                FormDivider(hasIcon: false)
                FormTimeRow(title: "Giờ", date: $openedAt)
            }

            // A locked account stays in the list but out of totals, and cannot be picked when
            // recording money (user choice 2026-10-28, replacing "Không tính vào báo cáo").
            FormGroup {
                FormToggleRow(title: "Khoá tài khoản", isOn: $isLocked)
            }

            FormGroup {
                FormNoteRow(text: $note, prompt: "Ghi chú")
            }

            if let original {
                FormGroup {
                    FormDestructiveRow(title: "Xoá tài khoản", question: "Xoá tài khoản “\(original.name)”?",
                                       message: AccountsView.deleteMessage(
                                           transactionCount: store.accountTransactions(original).count)) {
                        dismiss()
                        onDelete?()
                    }
                }
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
                TimiIcon("hugeicons-arrow-right-01", size: 16)
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
        // One animation for the whole sheet: the red line fades in and the groups below slide
        // down to make room, instead of jumping. The error haptic comes from SheetScaffold.
        withAnimation(.smooth(duration: 0.3)) { showsErrors = true }
        return !missesInstitution && !missesName
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = balanceText.vndInputAmount
        let balance = isNegative ? -amount : amount
        if var account = original {
            account.name = trimmedName
            account.detail = trimmedNote
            account.institutionID = hasInstitutions ? institutionID : nil
            account.openedAt = openedAt
            account.isLocked = isLocked
            store.update(account, balance: balance)
            dismiss()
            return
        }
        store.add(Account(
            name: trimmedName,
            type: type,
            balance: balance,
            detail: trimmedNote,
            institutionID: hasInstitutions ? institutionID : nil,
            openedAt: openedAt,
            isLocked: isLocked
        ))
        dismiss()
    }
}

#Preview("Thêm tiền mặt") {
    AddAccountView(type: .cash)
        .environment(FinanceStore())
}
