import SwiftUI

/// Adds or edits a person in "Danh bạ": name and relationship (the built-in ones or one the user
/// added, `RelationshipPickerSheet`). At the end of an existing one: "Xoá khỏi danh bạ", which only
/// explains when they still have loans (user choice 2026-10-29). Names are unique (case aside,
/// accents count) and at most `Contact.maxNameLength`; ✓ with no name says "Nhập tên.".
struct ContactEditorView: View {
    enum Target: Identifiable {
        case new
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
    /// Set by the first ✓: from then on a missing name is shown in red.
    @State private var showsErrors = false

    init(target: Target, onSave: ((Contact) -> Void)? = nil) {
        self.target = target
        self.onSave = onSave
        switch target {
        case .new:
            _name = State(initialValue: "")
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
        SheetScaffold(title: original == nil ? "Thêm vào danh bạ" : "Sửa thông tin",
                      validate: validate, onConfirm: save) {
            FormGroup(title: "Thông tin", error: nameError) {
                FormTextRow(title: "Tên", text: $name, isInvalid: nameError != nil,
                            maxLength: Contact.maxNameLength, focusesOnAppear: original == nil)
                FormDivider(hasIcon: false)
                Button { isPickingRelationship = true } label: {
                    FormValueLabel(title: "Mối quan hệ", icon: nil, value: relationship.name,
                                   valueIcon: relationship.icon)
                }
                .buttonStyle(.row)
                .accessibilityValue(relationship.name)
            }

            if let original {
                FormGroup { deleteRow(original) }
            }
        }
        .timiSheetStyle()
        .sheet(isPresented: $isPickingRelationship) {
            RelationshipPickerSheet(selection: $relationshipID)
        }
        .sensoryFeedback(.selection, trigger: relationshipID)
    }

    /// Deletes someone with no loans; for someone with loans the alert only says why not (settled
    /// ones count too, so it says so when there are some).
    private func deleteRow(_ contact: Contact) -> some View {
        let loans = store.loans(of: contact)
        let settled = loans.contains(where: \.isSettled) ? " (kể cả khoản đã tất toán)" : ""
        let canDelete = store.canDelete(contact)
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
