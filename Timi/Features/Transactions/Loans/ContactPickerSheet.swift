import SwiftUI

/// Picks who a loan is with from "Danh bạ" (user choice 2026-10-29): "Thêm người mới" on top,
/// which opens the Danh bạ form and picks the person it saves, then everyone A→Z with their
/// relationship. Picking closes the sheet. The search is the system one, as the bank and category
/// pickers have: on iOS 26 it sits at the bottom, by the thumb (user request 2026-10-29).
struct ContactPickerSheet: View {
    let title: String
    @Binding var selection: Contact.ID?

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var isAdding = false

    /// Every word found in the name, accents aside, as the other searches do.
    private var people: [Contact] {
        let words = query.searchKey.split(separator: " ")
        return store.sortedContacts.filter { person in
            let key = person.name.searchKey
            return words.allSatisfy { key.contains($0) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    FormGroup {
                        FormActionRow(title: "Thêm người mới", icon: "hugeicons-add-01") { isAdding = true }
                    }

                    let people = people
                    if !people.isEmpty {
                        FormGroup(title: query.isEmpty ? "Danh bạ" : nil) {
                            ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                                row(person)
                                    .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                            }
                        }
                    } else if !query.isEmpty {
                        EmptyStateCard(icon: "hugeicons-search-01", title: "Không tìm thấy",
                                       message: "Danh bạ chưa có ai tên “\(query.trimmingCharacters(in: .whitespaces))”. Thêm người mới ở trên.")
                    }
                }
            }
            .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
            .contentMargins(.top, Spacing.s, for: .scrollContent)
            .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
            .scrollDismissesKeyboard(.immediately)
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            // Default placement: on iOS 26 the field sits at the bottom in Liquid Glass; earlier iOS
            // keeps it under the title.
            .searchable(text: $query, prompt: "Tìm trong danh bạ")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            }
        }
        .timiSheetStyle()
        .sheet(isPresented: $isAdding) {
            // The person just added is the one picked.
            ContactEditorView(target: .new) { person in
                selection = person.id
                dismiss()
            }
        }
    }

    private func row(_ person: Contact) -> some View {
        let relationship = store.relationship(id: person.relationshipID)
        let selected = person.id == selection
        return Button {
            selection = person.id
            Haptics.selection()
            dismiss()
        } label: {
            PickerRowLabel(icon: relationship.icon, title: person.name, subtitle: relationship.name,
                           isSelected: selected)
        }
        .buttonStyle(.row)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
