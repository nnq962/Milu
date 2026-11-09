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

    var body: some View {
        let relationships = store.relationships
        // As tall as the list; it scrolls once taller than the screen (many added relationships).
        SheetScaffold(title: "Mối quan hệ", fitsContent: true) {
            // No footer: the pencil names itself to VoiceOver (strict review 2026-10-31).
            FormGroup {
                ForEach(Array(relationships.enumerated()), id: \.element.id) { index, relationship in
                    row(relationship)
                        .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                }
                FormActionRow(title: "Thêm loại mới", icon: "hugeicons-add-01") {
                    editing = .new
                }
                .overlay(alignment: .top) { FormDivider() }
            }
        }
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

    /// Picks on tap; a relationship the user added also has a pencil to edit it. Once any has one,
    /// every row keeps the pencil's place (empty on the built-in ones), so the ✓ stays in one
    /// column; the pencil's glyph ends 16 from the edge like everything else on the right
    /// (strict review 2026-10-31: the ✓ jumped ~52pt left on rows with a pencil).
    private func row(_ relationship: Relationship) -> some View {
        let isSelected = relationship.id == selection
        let hasPencils = !store.customRelationships.isEmpty
        let pencilTrailing = RowMetrics.horizontal - (ControlHeight.regular - IconSize.control) / 2
        return HStack(spacing: 0) {
            Button {
                selection = relationship.id
                dismiss()
            } label: {
                HStack(spacing: 0) {
                    PickerRowContent(icon: relationship.icon, title: relationship.name, isSelected: isSelected)
                    if hasPencils, relationship.isBuiltIn {
                        // The pencil's place, part of the row so it still picks.
                        Color.clear
                            .frame(width: ControlHeight.regular + pencilTrailing)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.row)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            if !relationship.isBuiltIn {
                Button { editing = .edit(relationship) } label: {
                    MiluIcon("hugeicons-pencil-edit-01", size: IconSize.control)
                        .foregroundStyle(Palette.label)
                        .frame(width: ControlHeight.regular, height: ControlHeight.regular)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, pencilTrailing)
                .accessibilityLabel("Sửa \(relationship.name)")
            }
        }
    }
}
