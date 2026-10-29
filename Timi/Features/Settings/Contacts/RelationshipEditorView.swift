import SwiftUI

/// Adds or edits a relationship the user makes ("Hàng xóm"): name and icon, as a category. At the
/// end of an existing one: "Xoá loại"; the people in it move to "Khác". Names are unique among all
/// relationships, the built-in ones too, and at most `Relationship.maxNameLength`.
struct RelationshipEditorView: View {
    enum Target: Identifiable {
        case new
        case edit(Relationship)

        var id: String {
            switch self {
            case .new: "new"
            case .edit(let relationship): relationship.id
            }
        }
    }

    let target: Target
    var onSave: ((Relationship) -> Void)? = nil

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var icon: String
    @State private var showsErrors = false

    init(target: Target, onSave: ((Relationship) -> Void)? = nil) {
        self.target = target
        self.onSave = onSave
        switch target {
        case .new:
            _name = State(initialValue: "")
            _icon = State(initialValue: "hugeicons-user")
        case .edit(let relationship):
            _name = State(initialValue: relationship.name)
            _icon = State(initialValue: relationship.icon)
        }
    }

    private var original: Relationship? {
        if case .edit(let relationship) = target { return relationship }
        return nil
    }

    private var cleanName: String { Contact.clean(name) }

    private var duplicate: Relationship? {
        guard !cleanName.isEmpty else { return nil }
        return store.relationships.first { $0.id != original?.id && Contact.sameName($0.name, cleanName) }
    }

    private var nameError: String? {
        if showsErrors, cleanName.isEmpty { return "Nhập tên." }
        return duplicate.map { "Đã có loại “\($0.name)”." }
    }

    private var canSave: Bool { !cleanName.isEmpty && duplicate == nil }

    private func validate() -> Bool {
        withAnimation(.smooth(duration: 0.3)) { showsErrors = true }
        return canSave
    }

    /// People-like icons first: the built-in relationships', then places people are met.
    private static let suggestions = [
        "hugeicons-user", "hugeicons-user-group", "hugeicons-user-love-01", "hugeicons-home-01",
        "hugeicons-briefcase-01", "hugeicons-handshake", "hugeicons-hand-heart", "hugeicons-baby-01",
        "hugeicons-school", "hugeicons-bank", "hugeicons-store-01",
    ]

    var body: some View {
        SheetScaffold(title: original == nil ? "Thêm loại" : "Sửa loại", validate: validate, onConfirm: save) {
            FormGroup(title: "Thông tin", error: nameError) {
                FormTextRow(title: "Tên loại", text: $name, prompt: "Hàng xóm", isInvalid: nameError != nil,
                            maxLength: Relationship.maxNameLength, focusesOnAppear: original == nil)
            }

            FormGroup(title: "Biểu tượng") {
                IconQuickPicker(selection: $icon, suggestions: Self.suggestions)
            }

            if let original {
                let count = store.contacts(in: original).count
                FormGroup {
                    FormDestructiveRow(title: "Xoá loại", question: "Xoá “\(original.name)”?",
                                       message: count > 0
                                           ? "\(count) người thuộc loại này sẽ chuyển sang “Khác”."
                                           : "Không thể hoàn tác.") {
                        store.delete(original)
                        dismiss()
                    }
                }
            }
        }
        .timiSheetStyle()
    }

    private func save() {
        guard canSave else { return }
        var relationship = original ?? Relationship(id: UUID().uuidString, name: cleanName, icon: icon)
        relationship.name = cleanName
        relationship.icon = icon
        store.save(relationship)
        onSave?(relationship)
        dismiss()
    }
}
