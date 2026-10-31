import SwiftUI

/// Picks who a loan is with from "Danh bạ" (user choice 2026-10-29): everyone A→Z with their
/// relationship, then "Thêm người mới" as the last row, which opens the Danh bạ form and picks the
/// person it saves. Picking closes the sheet. The search is the system one, as the bank and category
/// pickers have: on iOS 26 it sits at the bottom, by the thumb (user request 2026-10-29).
struct ContactPickerSheet: View {
    let title: String
    @Binding var selection: Contact.ID?

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var isAdding = false
    /// The person's initial at the size it has on their loan rows and in Danh bạ, growing with the
    /// text so the letter stays inside (re-review 2026-10-31: a fixed 24 the letter outgrew).
    @ScaledMetric(relativeTo: .body) private var avatar = RowMetrics.listLogo

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
                    let people = people
                    if people.isEmpty && !query.isEmpty {
                        EmptyStateCard(icon: "hugeicons-search-01", title: "Không tìm thấy",
                                       message: "Danh bạ chưa có ai tên “\(query.trimmingCharacters(in: .whitespaces))”.")
                    }
                    // Everyone, then "Thêm người mới" as the last row of the list, as the
                    // relationship and category pickers do (user choice 2026-10-29).
                    FormGroup(title: query.isEmpty && !people.isEmpty ? "Danh bạ" : nil) {
                        ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                            row(person)
                                .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                        }
                        FormActionRow(title: "Thêm người mới", icon: "hugeicons-add-01") { isAdding = true }
                            .overlay(alignment: .top) { if !people.isEmpty { FormDivider() } }
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
            // The name searched, unless someone already has it (the form would open on "Danh bạ đã có").
            ContactEditorView(target: .new(name: store.contact(named: Contact.clean(query)) == nil ? query : "")) { person in
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
            // The person's initial, as on their loan rows and in Danh bạ, not the relationship's
            // icon (strict review 2026-10-31), in the logo column as on those rows.
            HStack(spacing: RowMetrics.gap) {
                InitialsAvatar(name: person.name, size: avatar)
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text(person.name)
                        .textRole(.body)
                        .lineLimit(2)
                    Text(relationship.name)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if selected { SelectionCheck() }
            }
            .formRowFrame()
        }
        .buttonStyle(.row)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
