import SwiftUI

/// "Hạng mục" (Cài đặt): spending and income groups, one row each in one card (icon, name, how
/// many items, ›), as iOS Settings lists its sections (user choice 2026-10-29). Tapping a group opens
/// it with its items; + in the toolbar adds a group.
struct CategoriesView: View {
    @Environment(FinanceStore.self) private var store
    @State private var kind: TransactionKind
    @State private var editing: CategoryEditorView.Target?

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

                if groups.isEmpty {
                    EmptyStateCard(icon: "hugeicons-tag-01", title: "Chưa có nhóm nào",
                                   message: "Các nhóm hạng mục sẽ hiện ở đây.")
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                            NavigationLink {
                                CategoryGroupView(groupID: group.id)
                            } label: {
                                let count = store.items(of: group).count
                                NavigationRowLabel(title: group.name, icon: group.icon,
                                                   value: "\(count)", spokenValue: "\(count) hạng mục")
                            }
                            .buttonStyle(.row)
                            .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                        }
                    }
                    .listCard()
                }

                if hidden > 0 {
                    NavigationLink {
                        HiddenCategoriesView(kind: kind)
                    } label: {
                        NavigationRowLabel(title: "Hạng mục đã ẩn", icon: "hugeicons-archive-02", value: "\(hidden)", spokenValue: "\(hidden) mục")
                    }
                    .buttonStyle(.row)
                    .listCard()
                }
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .background(Palette.background)
        .foregroundStyle(Palette.label)
        .navigationTitle("Hạng mục")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = .newGroup(kind) } label: {
                    // The toolbar's one +: add-circle in its 28 frame, as on Tài khoản and Thu chi
                    // (re-review 2026-10-31).
                    TimiIcon("hugeicons-add-circle", size: RowMetrics.toolbarGlyph)
                        .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
                }
                .buttonBorderShape(.circle)
                .tint(Palette.primary)
                .accessibilityLabel("Thêm nhóm")
            }
        }
        .sheet(item: $editing) { target in
            CategoryEditorView(target: target)
        }
    }
}

/// One group: its items in a card, "Thêm hạng mục" at the end; the pencil edits the group itself
/// (name, icon, hide/delete). Tapping an item edits it. When the group is hidden or deleted from
/// its own sheet, the screen goes back once that sheet has closed.
struct CategoryGroupView: View {
    let groupID: String

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editing: CategoryEditorView.Target?

    private var group: Category? {
        store.category(id: groupID).flatMap { $0.isHidden ? nil : $0 }
    }

    var body: some View {
        let items = group.map { store.items(of: $0) } ?? []
        ScrollView {
            if let group {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        Button { editing = .edit(item) } label: {
                            NavigationRowLabel(title: item.name, icon: item.icon)
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
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .background(Palette.background)
        .foregroundStyle(Palette.label)
        .navigationTitle(group?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let group {
                ToolbarItem(placement: .topBarTrailing) {
                    EditToolbarButton { editing = .edit(group) }
                }
            }
        }
        .sheet(item: $editing, onDismiss: {
            if group == nil { dismiss() }
        }) { target in
            CategoryEditorView(target: target)
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
                EmptyStateCard(icon: "hugeicons-archive-02", title: "Không có hạng mục nào bị ẩn",
                               message: "Hạng mục bạn ẩn sẽ hiện ở đây.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(hidden.enumerated()), id: \.element.id) { index, category in
                        Button { editing = .edit(category) } label: {
                            NavigationRowLabel(title: category.name, subtitle: subtitle(category), icon: category.icon)
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
        .background(Palette.background)
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
