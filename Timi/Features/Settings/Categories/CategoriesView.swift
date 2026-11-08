import SwiftUI

/// "Hạng mục" (Cài đặt): spending and income groups, one row each in one card (icon, name, its
/// first items under it, ›), as iOS Settings lists its sections (user choice 2026-10-29). Tapping a
/// group opens it with its items; "Thêm nhóm" ends the card, as "Thêm hạng mục" ends a group's
/// (review 2026-11-08: a bare + on the bar did not say what it added); "Sắp xếp" beside the
/// card's heading orders the groups, as on a group's page.
struct CategoriesView: View {
    @Environment(FinanceStore.self) private var store
    @State private var kind: TransactionKind
    @State private var editing: CategoryEditorView.Target?
    @State private var isOrdering = false

    /// Opens on `kind`: spending from Cài đặt, the kind being recorded from the transaction form.
    init(kind: TransactionKind = .expense) {
        _kind = State(initialValue: kind)
    }

    var body: some View {
        let groups = store.groups(kind)
        let hidden = store.hiddenCategories(kind).count
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                // Its words grow with the text size (strict review 2026-10-31).
                ScaledSegmentedPicker(title: "Loại hạng mục", selection: $kind,
                                      options: TransactionKind.allCases) { $0.title }
                    .controlSize(.large)

                // One layout with or without groups: the heading, and a card ending in "Thêm nhóm"
                // (review 2026-11-08: an empty card with its own button broke the empty cards'
                // rule; the app also keeps one group of each kind, so it is rarely empty).
                OutsideHeaderSection(title: "Nhóm") {
                    if groups.count > 1 { orderLink { isOrdering = true } }
                } content: {
                    VStack(spacing: 0) {
                        ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                            NavigationLink {
                                CategoryGroupView(groupID: group.id)
                            } label: {
                                // What is inside, rather than a bare count that said nothing of
                                // what it counted (review 2026-11-08).
                                NavigationRowContent(title: group.name, subtitle: Self.itemNames(store.items(of: group)),
                                                     icon: group.icon)
                            }
                            .buttonStyle(.row)
                            .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                        }
                        FormActionRow(title: "Thêm nhóm", icon: "hugeicons-add-01") {
                            editing = .newGroup(kind)
                        }
                        .overlay(alignment: .top) { if !groups.isEmpty { FormDivider() } }
                    }
                    .listCard()
                }

                if hidden > 0 {
                    NavigationLink {
                        HiddenCategoriesView(kind: kind)
                    } label: {
                        NavigationRowContent(title: "Hạng mục đã ẩn", icon: "hugeicons-archive-02", value: "\(hidden)", spokenValue: "\(hidden) hạng mục")
                    }
                    .buttonStyle(.row)
                    .listCard()
                }
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Hạng mục")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { target in
            CategoryEditorView(target: target)
        }
        .sheet(isPresented: $isOrdering) {
            CategoryOrderSheet(title: "Sắp xếp nhóm", categories: groups)
        }
    }

    /// "Ăn sáng · Ăn trưa · Ăn tối", or with more "Ăn sáng · Ăn trưa · +4 mục": a count, not "…",
    /// which read as a word cut short (review 2026-11-08); short enough for one line (it wraps
    /// rather than cuts at the large text sizes). "·", not ",": a name may hold a comma ("Taxi,
    /// xe ôm" read as two items).
    static func itemNames(_ items: [Category]) -> String? {
        guard !items.isEmpty else { return nil }
        guard items.count > 3 else { return items.map(\.name).joined(separator: " · ") }
        return items.prefix(2).map(\.name).joined(separator: " · ") + " · +\(items.count - 2) mục"
    }
}

/// "Sắp xếp" beside a card's heading: opens the order sheet. On the heading rather than the bar,
/// where beside ✎ it left a long group name little room (review 2026-11-08: "Chi phí nhà…").
private func orderLink(_ action: @escaping () -> Void) -> some View {
    Button(action: action) { HeaderLink(title: "Sắp xếp") }
        .headerLinkButton()
}

/// A category row that opens its sheet: icon, name, an optional line under it; no ›, which is
/// for a row that opens a page (review 2026-11-08).
private struct CategorySheetRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String

    var body: some View {
        FormRowLabel(title: title, subtitle: subtitle, icon: icon)
            .frame(maxWidth: .infinity, alignment: .leading)
            .formRowFrame()
            .contentShape(Rectangle())
    }
}

/// One group: its items in a card, "Thêm hạng mục" at the end, then "Đã ẩn" with its hidden items
/// (review 2026-11-08: they could only be found back on the page before); ✎ edits the group
/// itself (name, icon, hide/delete), "Sắp xếp" beside the items' heading orders them. Tapping
/// an item edits it. When the group is hidden or deleted from its own sheet, the screen goes back
/// once that sheet has closed.
struct CategoryGroupView: View {
    let groupID: String

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editing: CategoryEditorView.Target?
    @State private var isOrdering = false

    private var group: Category? {
        store.category(id: groupID).flatMap { $0.isHidden ? nil : $0 }
    }

    var body: some View {
        let items = group.map { store.items(of: $0) } ?? []
        // Last hidden first, as "Hạng mục đã ẩn" lists them (review 2026-11-08).
        let hiddenItems = (group.map { store.items(of: $0, hidden: true) } ?? [])
            .sorted { ($0.hiddenAt ?? .distantPast) > ($1.hiddenAt ?? .distantPast) }
        ScrollView {
            if let group {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    OutsideHeaderSection(title: "Hạng mục") {
                        if items.count > 1 { orderLink { isOrdering = true } }
                    } content: {
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                Button { editing = .edit(item) } label: {
                                    CategorySheetRow(title: item.name, icon: item.icon)
                                }
                                .buttonStyle(.row)
                                .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                            }
                            // An action, so in ink like every action row (grey reads as disabled).
                            FormActionRow(title: "Thêm hạng mục", icon: "hugeicons-add-01") {
                                editing = .newItem(in: group)
                            }
                            .overlay(alignment: .top) { if !items.isEmpty { FormDivider() } }
                        }
                        .listCard()
                    }

                    if !hiddenItems.isEmpty {
                        OutsideHeaderSection(title: "Đã ẩn") {
                            VStack(spacing: 0) {
                                ForEach(Array(hiddenItems.enumerated()), id: \.element.id) { index, item in
                                    Button { editing = .edit(item) } label: {
                                        CategorySheetRow(title: item.name,
                                                         subtitle: item.hiddenAt.map { "Đã ẩn \($0.shortDay)" },
                                                         icon: item.icon)
                                    }
                                    .buttonStyle(.row)
                                    .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                                }
                            }
                            .listCard()
                        }
                    }
                }
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle(group?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let group {
                ToolbarItem(placement: .topBarTrailing) {
                    EditToolbarButton { editing = .edit(group) }
                        // Says what it edits (review 2026-11-08: read only "Sửa").
                        .accessibilityLabel("Sửa nhóm")
                }
            }
        }
        .sheet(item: $editing, onDismiss: {
            if group == nil { dismiss() }
        }) { target in
            CategoryEditorView(target: target)
        }
        .sheet(isPresented: $isOrdering) {
            CategoryOrderSheet(title: "Sắp xếp hạng mục", categories: items)
        }
    }
}

/// "Hạng mục đã ẩn": hidden groups and items of one kind; tapping one offers "Hiện lại".
struct HiddenCategoriesView: View {
    let kind: TransactionKind

    @Environment(FinanceStore.self) private var store
    @State private var editing: CategoryEditorView.Target?

    var body: some View {
        let hidden = store.hiddenCategories(kind)
        ScrollView {
            if hidden.isEmpty {
                EmptyStateCard(title: "Không có hạng mục nào bị ẩn", message: "Hạng mục bạn ẩn sẽ hiện ở đây.",
                               picture: IconCatalog.emojiName("📦"))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(hidden.enumerated()), id: \.element.id) { index, category in
                        Button { editing = .edit(category) } label: {
                            CategorySheetRow(title: category.name, subtitle: subtitle(category), icon: category.icon)
                        }
                        .buttonStyle(.row)
                        .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                    }
                }
                .listCard()
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Hạng mục đã ẩn")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { target in
            CategoryEditorView(target: target)
        }
    }

    /// "Nhóm · Đã ẩn 29/10", or the item's group: "Ăn uống · Đã ẩn 29/10" (with the year when it
    /// was another: `Date.shortDay`).
    private func subtitle(_ category: Category) -> String {
        let owner = category.parentID.map { store.category(id: $0)?.name ?? "Nhóm đã xoá" } ?? "Nhóm"
        let day = category.hiddenAt.map { "Đã ẩn \($0.shortDay)" }
        return [owner, day].compactMap { $0 }.joined(separator: " · ")
    }
}
