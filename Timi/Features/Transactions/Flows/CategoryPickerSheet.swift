import SwiftUI

/// "Hạng mục" in a transaction form: the chosen item (icon and name) and ›; opens
/// `CategoryPickerSheet`. Nothing is picked for the user (user choice 2026-10-29): until then it
/// reads "Chưa chọn", red once saving was tried (`showsError`). A transaction from before items
/// existed is on a group: the row shows it in red until an item is picked (kept as it was until
/// edited).
struct CategoryPickerRow: View {
    let kind: TransactionKind
    @Binding var selection: String
    var showsError = false
    /// An item hidden since that the transaction being edited is on: it stays valid (hiding keeps
    /// history as it was), though it is no longer offered.
    var kept: String? = nil

    @Environment(FinanceStore.self) private var store
    @State private var isPicking = false

    /// Whether the selection is an item that can still be picked.
    static func isPickable(_ id: String, kind: TransactionKind, in store: FinanceStore, kept: String? = nil) -> Bool {
        if let kept, id == kept, let item = store.category(id: id), !item.isGroup, item.kind == kind { return true }
        return store.pickableItems(kind).contains { $0.id == id }
    }

    /// The item's name; with its group before it ("Mua sắm · Khác") when another item of this kind
    /// has the same name.
    private var name: String {
        guard !selection.isEmpty else { return "Chưa chọn" }
        let name = store.categoryName(selection)
        guard let parentID = store.category(id: selection)?.parentID,
              store.pickableItems(kind).contains(where: { $0.id != selection && $0.name == name })
        else { return name }
        return "\(store.categoryName(parentID)) · \(name)"
    }

    var body: some View {
        let isEmpty = selection.isEmpty
        Button { isPicking = true } label: {
            FormValueRowContent(title: "Hạng mục", icon: nil, value: name,
                           valueIcon: isEmpty ? nil : store.categoryIcon(selection),
                           isInvalid: isEmpty ? showsError : !Self.isPickable(selection, kind: kind, in: store, kept: kept))
        }
        .buttonStyle(.row)
        .accessibilityValue(name)
        .sensoryFeedback(.selection, trigger: selection)
        .sheet(isPresented: $isPicking) {
            CategoryPickerSheet(kind: kind, selection: $selection)
        }
    }
}

/// Picks an item of "Hạng mục" (user choice 2026-10-29): the last few used on top, then every group
/// in use with its items; Apple's search field filters by item or group name. Picking closes it.
/// The pencil opens the "Hạng mục" settings in the same sheet, to add or change one on the spot.
struct CategoryPickerSheet: View {
    let kind: TransactionKind
    @Binding var selection: String

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var isManaging = false

    private var matches: [Category] {
        let words = query.trimmingCharacters(in: .whitespaces).searchKey
        return store.pickableItems(kind).filter { item in
            let group = item.parentID.map(store.categoryName) ?? ""
            return "\(item.name) \(group)".searchKey.contains(words)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // The gap between groups of the form sheets (`SheetScaffold`, strict review 2026-10-31).
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    if !query.isEmpty {
                        if matches.isEmpty {
                            EmptyStateCard(icon: "hugeicons-search-01", title: "Không tìm thấy",
                                           message: "Không có hạng mục nào khớp từ này.")
                        } else {
                            section(nil, items: matches, showsGroup: true)
                        }
                    } else {
                        let recent = store.recentItems(kind)
                        if !recent.isEmpty {
                            section("Gần đây", items: recent, showsGroup: true)
                        }
                        ForEach(store.groups(kind)) { group in
                            section(group.name, items: store.items(of: group), showsGroup: false)
                        }
                    }
                }
            }
            .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
            .contentMargins(.top, Spacing.s, for: .scrollContent)
            .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
            .scrollDismissesKeyboard(.immediately)
            .pageBackground()
            .foregroundStyle(Palette.label)
            .navigationTitle("Chọn hạng mục")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Tìm hạng mục")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    EditToolbarButton { isManaging = true }
                        .accessibilityLabel("Sửa hạng mục")
                }
            }
            .navigationDestination(isPresented: $isManaging) { CategoriesView(kind: kind) }
        }
        .timiSheetStyle()
    }

    private func section(_ title: String?, items: [Category], showsGroup: Bool) -> some View {
        FormGroup(title: title) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let selected = item.id == selection
                Button {
                    selection = item.id
                    dismiss()
                } label: {
                    PickerRowContent(icon: item.icon, title: item.name,
                                   subtitle: showsGroup ? item.parentID.map(store.categoryName) : nil,
                                   isSelected: selected)
                }
                .buttonStyle(.row)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .overlay(alignment: .top) { if index > 0 { FormDivider() } }
            }
        }
    }
}
