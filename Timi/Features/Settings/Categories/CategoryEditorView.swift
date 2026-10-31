import SwiftUI

/// Adds or edits a group or an item. A group: name, icon, and when new the name of its first item
/// (a transaction is always filed under an item). An item: name, icon, the group it belongs to.
/// At the end: "Hiện lại" for a hidden one, "Ẩn" when transactions use it (history kept), "Xoá"
/// otherwise; the last item of a group, and the last group of a kind, cannot go. Names are unique
/// among their siblings and at most `Category.maxNameLength` long.
struct CategoryEditorView: View {
    enum Target: Identifiable {
        case newGroup(TransactionKind)
        case newItem(in: Category)
        case edit(Category)

        var id: String {
            switch self {
            case .newGroup(let kind): "new-group-\(kind.rawValue)"
            case .newItem(let group): "new-item-\(group.id)"
            case .edit(let category): category.id
            }
        }
    }

    let target: Target

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var icon: String
    @State private var groupID: String?
    @State private var firstItem = ""
    @State private var showsErrors = false

    init(target: Target) {
        self.target = target
        switch target {
        case .newGroup:
            _name = State(initialValue: "")
            _icon = State(initialValue: "hugeicons-tag-01")
            _groupID = State(initialValue: nil)
        case .newItem(let group):
            _name = State(initialValue: "")
            _icon = State(initialValue: group.icon)
            _groupID = State(initialValue: group.id)
        case .edit(let category):
            _name = State(initialValue: category.name)
            _icon = State(initialValue: category.icon)
            _groupID = State(initialValue: category.parentID)
        }
    }

    private var original: Category? {
        if case .edit(let category) = target { return store.category(id: category.id) ?? category }
        return nil
    }

    private var kind: TransactionKind {
        switch target {
        case .newGroup(let kind): kind
        case .newItem(let group): group.kind
        case .edit(let category): category.kind
        }
    }

    private var isGroup: Bool {
        switch target {
        case .newGroup: true
        case .newItem: false
        case .edit(let category): category.isGroup
        }
    }

    /// Groups in use, plus the item's own group when that one is hidden (so it is still ticked).
    private var groupOptions: [String] {
        var ids = store.groups(kind).map(\.id)
        if let current = original?.parentID, !ids.contains(current) { ids.insert(current, at: 0) }
        return ids
    }

    private var cleanName: String { Self.clean(name) }

    /// Trimmed, with runs of spaces inside made one ("Ăn  sáng" is "Ăn sáng"), so twins are caught.
    private static func clean(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
    /// ✓ stays on so what is missing can be pointed out instead of the button just doing
    /// nothing (sheet review 2026-10-30: it greyed out here, against the app's rule).
    private func validate() -> Bool {
        withAnimation(.smooth(duration: 0.3)) { showsErrors = true }
        return canSave
    }

    private var canSave: Bool {
        !cleanName.isEmpty && (isGroup || groupID != nil) && duplicate == nil && reservedName == nil
    }

    /// The system name this one matches ("Điều chỉnh số dư"), if any.
    private var reservedName: String? {
        Category.reservedNames.first { $0.compare(cleanName, options: .caseInsensitive) == .orderedSame }
    }

    /// Another group of this kind, or another item of the chosen group, with the same name (case
    /// aside; accents count, as "Bán" is not "Bạn"). Hidden ones too: showing one again would
    /// bring the twin back.
    private var duplicate: Category? {
        guard !cleanName.isEmpty else { return nil }
        return store.categories.first { other in
            other.id != original?.id
                && (isGroup ? other.isGroup && other.kind == kind : other.parentID == groupID)
                && other.name.compare(cleanName, options: .caseInsensitive) == .orderedSame
        }
    }

    private var nameError: String? {
        if showsErrors, cleanName.isEmpty { return "Nhập tên." }
        if let reservedName { return "“\(reservedName)” là tên dành cho hệ thống." }
        guard let duplicate else { return nil }
        let place = isGroup ? "Đã có nhóm" : "Nhóm này đã có"
        return duplicate.isHidden
            ? "\(place) “\(duplicate.name)”, đang ẩn trong Hạng mục đã ẩn."
            : "\(place) “\(duplicate.name)”."
    }

    private var title: String {
        switch target {
        case .newGroup: "Thêm nhóm"
        case .newItem: "Thêm hạng mục"
        case .edit(let category): category.isGroup ? "Sửa nhóm" : "Sửa hạng mục"
        }
    }

    /// The icons offered first: the group's own and its items', then common ones.
    private var suggestions: [String] {
        var icons: [String] = []
        if let groupID, let group = store.category(id: groupID) {
            icons = [group.icon] + store.items(of: group).map(\.icon)
        } else if let original, original.isGroup {
            icons = [original.icon] + store.items(of: original).map(\.icon)
        }
        let common = ["hugeicons-restaurant-01", "hugeicons-car-01", "hugeicons-home-01", "hugeicons-shopping-bag-01",
                      "hugeicons-flash", "hugeicons-first-aid-kit", "hugeicons-film-02", "hugeicons-book-02",
                      "hugeicons-gift", "hugeicons-money-bag-02", "hugeicons-tag-01"]
        var seen = Set<String>()
        return (icons + common).filter { seen.insert($0).inserted }
    }

    var body: some View {
        SheetScaffold(title: title, validate: validate, onConfirm: save) {
            // No footer on why "Nhóm" is locked: the greyed row says it (strict review 2026-10-31).
            FormGroup(title: "Thông tin", error: nameError) {
                FormTextRow(title: isGroup ? "Tên nhóm" : "Tên hạng mục", text: $name,
                            prompt: isGroup ? "Du lịch" : "Ăn sáng", isInvalid: nameError != nil,
                            maxLength: Category.maxNameLength)
                if isGroup, original == nil {
                    FormDivider(hasIcon: false)
                    FormTextRow(title: "Hạng mục đầu tiên", text: $firstItem,
                                prompt: cleanName.isEmpty ? "Vé máy bay" : cleanName,
                                maxLength: Category.maxNameLength)
                }
                if !isGroup, let groupID {
                    FormDivider(hasIcon: false)
                    // The last item of a group stays in it: moving it would leave the group empty.
                    FormPickerRow(title: "Nhóm",
                                  selection: Binding { groupID } set: { self.groupID = $0 },
                                  options: groupOptions,
                                  optionIcon: { store.category(id: $0)?.icon ?? "hugeicons-tag-01" }) {
                        store.category(id: $0)?.name ?? "—"
                    }
                    .disabled(original.map { !store.canMove($0) } ?? false)
                }
            }

            FormGroup(title: "Biểu tượng") {
                IconQuickPicker(selection: $icon, suggestions: suggestions)
            }

            if let original {
                FormGroup { leaveRow(original) }
            }
        }
        .timiSheetStyle()
    }

    /// "Hiện lại" for a hidden one; otherwise "Ẩn" (with history) or "Xoá". The last item of a group
    /// and the last group of a kind keep the row, but its alert only says why it cannot go.
    @ViewBuilder
    private func leaveRow(_ category: Category) -> some View {
        let noun = category.isGroup ? "nhóm" : "hạng mục"
        let canGo = store.canRemove(category)
        let reason = category.isGroup
            ? store.groups(category.kind, hidden: true).isEmpty
                ? "Mỗi loại cần ít nhất một nhóm. Thêm nhóm khác trước."
                : "Mỗi loại cần ít nhất một nhóm. Thêm nhóm khác hoặc hiện lại một nhóm đã ẩn trước."
            : "Mỗi nhóm cần ít nhất một hạng mục. Thêm hạng mục khác, hoặc ẩn/xoá cả nhóm."
        if category.isHidden {
            // An eye, not the box of "Ẩn": the two did the opposite with one icon (re-review 2026-10-31).
            FormActionRow(title: "Hiện lại \(noun)", icon: "hugeicons-eye") {
                applyEdits()
                store.unhide(category)
                Haptics.success()
                dismiss()
            }
        } else if store.hasHistory(category) {
            FormActionRow(title: "Ẩn \(noun)", icon: "hugeicons-archive-02",
                          question: canGo ? "Ẩn “\(category.name)”?" : "Không ẩn được “\(category.name)”",
                          message: !canGo ? reason : category.isGroup
                              ? "Nhóm và các hạng mục trong nhóm không còn để chọn. Giao dịch cũ vẫn giữ."
                              : "Hạng mục không còn để chọn. Giao dịch cũ vẫn giữ.",
                          canConfirm: canGo) {
                applyEdits()
                store.remove(category)
                dismiss()
            }
        } else {
            FormDestructiveRow(title: "Xoá \(noun)",
                               question: canGo ? "Xoá “\(category.name)”?" : "Không xoá được “\(category.name)”",
                               message: !canGo ? reason
                                   : category.isGroup ? "Các hạng mục trong nhóm cũng bị xoá." : "Không thể hoàn tác.",
                               canConfirm: canGo) {
                store.remove(category)
                dismiss()
            }
        }
    }

    /// Saves the name, icon and group the form holds (also before "Ẩn" / "Hiện lại", so nothing
    /// chosen is lost). Starts from the stored category. A name that cannot be saved (empty, or a
    /// twin) leaves the name and group as they were; the icon is still kept.
    private func applyEdits() {
        guard var category = original.flatMap({ store.category(id: $0.id) }) else { return }
        category.icon = icon
        if canSave { category.name = cleanName }
        if canSave, !category.isGroup, let groupID, groupID != category.parentID, store.canMove(category) {
            // Moved to another group: last in it.
            category.parentID = groupID
            // After every item of that group, hidden ones too, so no two share a place.
            let newGroup = store.category(id: groupID)
            let siblings = store.categories.filter { $0.parentID == groupID }.map(\.sortOrder)
            category.sortOrder = (siblings.max() ?? newGroup?.sortOrder ?? 0) + 1
        }
        store.save(category)
    }

    private func save() {
        guard canSave else { return }
        if original != nil {
            applyEdits()
        } else {
            let item = Self.clean(firstItem)
            store.save(Category(id: UUID().uuidString, kind: kind, parentID: isGroup ? nil : groupID,
                                name: cleanName, icon: icon),
                       firstItem: item.isEmpty ? nil : item)
        }
        dismiss()
    }
}
