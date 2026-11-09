import SwiftUI

/// Adds or edits a person in "Danh bạ": name and relationship (the built-in ones or one the user
/// added, `RelationshipPickerSheet`). An existing one also lists their loans, each opening its
/// sheet (review 2026-11-08: "1 khoản vay" on the row led nowhere), then "Xoá khỏi danh bạ", with a
/// line under it saying why not while they still have loans (user choice 2026-10-29). Names are unique (case aside,
/// accents count) and at most `Contact.maxNameLength`; ✓ with no name says "Nhập tên.".
struct ContactEditorView: View {
    enum Target: Identifiable {
        /// Someone new, the name started with what was searched ("Lan" in the loan form's picker).
        case new(name: String = "")
        case edit(Contact)

        var id: String {
            switch self {
            case .new: "new"
            case .edit(let contact): contact.id.uuidString
            }
        }
    }

    let target: Target
    /// Called with the saved person, e.g. so the loan form can pick someone it just added.
    var onSave: ((Contact) -> Void)? = nil

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var relationshipID: String
    @State private var isPickingRelationship = false
    /// The loan opened from the list, in its own sheet.
    @State private var openLoan: Loan?
    /// Set by the first ✓: from then on a missing name is shown in red.
    @State private var showsErrors = false

    init(target: Target, onSave: ((Contact) -> Void)? = nil) {
        self.target = target
        self.onSave = onSave
        switch target {
        case .new(let name):
            // At most as long as a name typed here may be.
            _name = State(initialValue: String(Contact.clean(name).prefix(Contact.maxNameLength)))
            _relationshipID = State(initialValue: ContactRelationship.friend.rawValue)
        case .edit(let contact):
            _name = State(initialValue: contact.name)
            _relationshipID = State(initialValue: contact.relationshipID)
        }
    }

    private var original: Contact? {
        if case .edit(let contact) = target { return store.contact(id: contact.id) ?? contact }
        return nil
    }

    private var cleanName: String { Contact.clean(name) }

    /// Someone else already called this.
    private var duplicate: Contact? {
        guard !cleanName.isEmpty else { return nil }
        return store.contacts.first { $0.id != original?.id && $0.hasName(cleanName) }
    }

    private var nameError: String? {
        if showsErrors, cleanName.isEmpty { return "Nhập tên." }
        return duplicate.map { "Danh bạ đã có “\($0.name)”." }
    }

    private var canSave: Bool { !cleanName.isEmpty && duplicate == nil }

    /// ✓ stays on so an empty name can be pointed out instead of the button just doing nothing.
    private func validate() -> Bool {
        withAnimation(.smooth(duration: 0.3)) { showsErrors = true }
        return canSave
    }

    var body: some View {
        let relationship = store.relationship(id: relationshipID)
        SheetScaffold(title: original == nil ? "Thêm vào danh bạ" : "Sửa liên hệ",
                      validate: validate, onConfirm: save) {
            FormGroup(title: "Thông tin", error: nameError) {
                FormTextRow(title: "Tên", text: $name, prompt: "Nguyễn Văn A", isInvalid: nameError != nil,
                            maxLength: Contact.maxNameLength, focusesOnAppear: original == nil)
                FormDivider(hasIcon: false)
                Button { isPickingRelationship = true } label: {
                    FormValueRowContent(title: "Mối quan hệ", icon: nil, value: relationship.name,
                                   valueIcon: relationship.icon)
                }
                .buttonStyle(.row)
                .accessibilityValue(relationship.name)
            }

            if let original {
                // Open ones as Vay nợ orders them (overdue first, then the nearest deadline), then
                // settled, newest first; Vay nợ's rows, the person left out (they are the sheet).
                let all = store.loans(of: original)
                let loans = all.filter { !$0.isSettled }.byUrgency()
                    + all.filter(\.isSettled).sorted { $0.date > $1.date }
                if !loans.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: "Khoản vay", style: .group)
                        LoanRowList(loans: loans, showsPerson: false) { openLoan = $0 }
                    }
                }
                // Short under the row; the alert says that settled ones count too.
                FormGroup(footer: loans.isEmpty ? nil : "Còn \(loans.count) khoản vay nên chưa xoá được.") {
                    deleteRow(original, loans: loans)
                }
            }
        }
        .timiSheetStyle()
        .sheet(item: $openLoan) { LoanDetailSheet(loanID: $0.id) }
        .sheet(isPresented: $isPickingRelationship) {
            RelationshipPickerSheet(selection: $relationshipID)
        }
        .sensoryFeedback(.selection, trigger: relationshipID)
    }

    /// Deletes someone with no loans; for someone with loans the alert only says why not (settled
    /// ones count too, so it says so when there are some).
    private func deleteRow(_ contact: Contact, loans: [Loan]) -> some View {
        let settled = loans.contains(where: \.isSettled) ? " (kể cả khoản đã tất toán)" : ""
        let canDelete = loans.isEmpty
        return FormDestructiveRow(
            title: "Xoá khỏi danh bạ",
            question: canDelete ? "Xoá “\(contact.name)”?" : "Không xoá được “\(contact.name)”",
            message: canDelete
                ? "Không thể hoàn tác."
                : "“\(contact.name)” còn \(loans.count) khoản vay\(settled). Xoá các khoản vay đó trước.",
            canConfirm: canDelete
        ) {
            store.delete(contact)
            dismiss()
        }
    }

    private func save() {
        guard canSave else { return }
        var contact = original ?? Contact(name: cleanName, relationshipID: relationshipID)
        contact.name = cleanName
        // A relationship deleted while this form was open is "Khác" now.
        contact.relationshipID = store.relationship(id: relationshipID).id
        // Saved here by the user: kept even with no loans left.
        contact.isAutoCreated = false
        store.save(contact)
        onSave?(contact)
        dismiss()
    }
}
