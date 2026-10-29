import SwiftUI

/// Picks a person's relationship, as `ChoiceSheet` does, plus the ones the user added: each has a
/// pencil to rename it, change its icon or delete it, and "Thêm loại mới" adds one (user choice
/// 2026-10-29). A new one is picked at once and the sheet closes.
struct RelationshipPickerSheet: View {
    @Binding var selection: String

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editing: RelationshipEditorView.Target?
    /// Set when a new one is saved: the sheet closes once the editor has.
    @State private var pickedNew = false
    @State private var headerHeight: CGFloat = 60
    @State private var listHeight: CGFloat = 400

    var body: some View {
        let relationships = store.relationships
        // As tall as the list, like `timiFittedSheet`, but the list scrolls once it is taller than
        // the screen (many added relationships): iOS caps the detent at full height.
        VStack(alignment: .leading, spacing: Spacing.l) {
            SheetHeader(title: "Mối quan hệ")
                .padding(.horizontal, Spacing.page)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
            ScrollView {
                FormGroup(footer: store.customRelationships.isEmpty ? nil : "Chạm bút chì để sửa hoặc xoá loại bạn đã thêm.") {
                    ForEach(Array(relationships.enumerated()), id: \.element.id) { index, relationship in
                        row(relationship)
                            .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                    }
                    FormActionRow(title: "Thêm loại mới", icon: "hugeicons-add-01") {
                        editing = .new
                    }
                    .overlay(alignment: .top) { FormDivider() }
                }
                .padding(.horizontal, Spacing.page)
                .padding(.bottom, Spacing.xxl)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { listHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .foregroundStyle(Palette.ink)
        .presentationDetents([.height(max(headerHeight + Spacing.l + listHeight, 200))])
        .presentationBackground(Palette.background)
        .sheet(item: $editing, onDismiss: {
            // The picked one was deleted: its people are "Khác" now, so is this form.
            if !store.relationships.contains(where: { $0.id == selection }) {
                selection = ContactRelationship.other.rawValue
            }
            if pickedNew { dismiss() }
        }) { target in
            RelationshipEditorView(target: target) { saved in
                if case .new = target {
                    selection = saved.id
                    pickedNew = true
                }
            }
        }
    }

    /// Picks on tap; a relationship the user added also has a pencil to edit it.
    private func row(_ relationship: Relationship) -> some View {
        let isSelected = relationship.id == selection
        return HStack(spacing: 0) {
            Button {
                selection = relationship.id
                dismiss()
            } label: {
                PickerRowLabel(icon: relationship.icon, title: relationship.name, isSelected: isSelected)
            }
            .buttonStyle(.row)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            if !relationship.isBuiltIn {
                Button { editing = .edit(relationship) } label: {
                    TimiIcon("hugeicons-pencil-edit-01", size: RowMetrics.iconGlyph)
                        .foregroundStyle(Palette.ink)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, RowMetrics.horizontal - Spacing.s)
                .accessibilityLabel("Sửa \(relationship.name)")
            }
        }
    }
}
