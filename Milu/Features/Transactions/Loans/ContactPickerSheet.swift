import SwiftUI

/// Picks who a loan is with from "Danh bạ" (user choice 2026-10-29): everyone A→Z with their
/// relationship, and a + at the top right of the sheet (user request 2026-10-31, over a last row
/// "Thêm người mới" that went out of sight down a long list), which opens the Danh bạ form and
/// picks the person it saves. Picking closes the sheet. The search is the system one, as the bank and category
/// pickers have: on iOS 26 it sits at the bottom, by the thumb (user request 2026-10-29).
struct ContactPickerSheet: View {
    let title: String
    @Binding var selection: Contact.ID?

    @Environment(FinanceStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var isAdding = false

    /// Spaces alone are not a search (review 2026-11-07).
    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespaces) }

    /// Every word found in the name, accents aside, as the other searches do.
    private var people: [Contact] {
        let words = trimmedQuery.searchKey.split(separator: " ")
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
                    if people.isEmpty && !trimmedQuery.isEmpty {
                        EmptyStateCard(icon: "hugeicons-search-01", title: "Không tìm thấy",
                                       message: "Danh bạ chưa có ai tên “\(trimmedQuery)”.",
                                       picture: IconCatalog.emojiName("🧭"))
                    }
                    if !people.isEmpty {
                        FormGroup(title: trimmedQuery.isEmpty ? "Danh bạ" : nil) {
                            ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                                row(person)
                                    .separatorAbove(index > 0, order: index) { RowDivider(column: .logo) }
                            }
                        }
                    } else if trimmedQuery.isEmpty {
                        EmptyStateCard(icon: "hugeicons-user-group", title: "Danh bạ trống",
                                       message: "Người bạn thêm sẽ hiện ở đây.", picture: IconCatalog.emojiName("📞"))
                    }
                }
            }
            .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
            .contentMargins(.top, Spacing.s, for: .scrollContent)
            .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
            .scrollDismissesKeyboard(.immediately)
            .pageBackground()
            .foregroundStyle(Palette.label)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            // Default placement: on iOS 26 the field sits at the bottom in Liquid Glass; earlier iOS
            // keeps it under the title.
            .searchable(text: $query, prompt: "Tìm trong danh bạ")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isAdding = true } label: {
                        // The toolbar's one +, a bare one as on Danh bạ and Tài khoản.
                        BarSymbol("plus")
                    }
                    .buttonBorderShape(.circle)
                    .tint(Palette.primary)
                    .accessibilityLabel("Thêm người mới")
                }
            }
        }
        .miluSheetStyle()
        .sheet(isPresented: $isAdding) {
            // The person just added is the one picked.
            // The name searched, unless someone already has it (the form would open on "Danh bạ đã có").
            ContactEditorView(target: .new(name: store.contact(named: Contact.clean(query)) == nil ? Contact.clean(query) : "")) { person in
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
                InitialsAvatar(name: person.name, size: RowMetrics.listLogo)
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    // A row's name, as on their loan rows (`ListRow`, review 2026-11-07).
                    Text(person.name)
                        .textRole(.bodyStrong)
                        .lineLimit(2)
                    Text(relationship.name)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
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
