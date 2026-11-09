import SwiftUI

/// "Danh bạ" (Cài đặt → Quản lý tài chính): the people loans are with, A→Z in one card (initial in
/// a circle as on Vay nợ, name, "Bạn bè · còn 1 khoản vay"), "Thêm người" ending the card as
/// "Thêm nhóm" ends Hạng mục's (review 2026-11-08: a bare + on the bar). Tapping someone opens
/// their sheet, with their loans. A search field once the list is long enough to need one.
struct ContactsView: View {
    @Environment(FinanceStore.self) private var store
    @State private var editing: ContactEditorView.Target?
    @State private var searchText = ""

    /// From this many people on, a search field above the list.
    private static let searchThreshold = 8

    var body: some View {
        let all = store.sortedContacts
        let isSearchable = all.count >= Self.searchThreshold
        // Only while the field shows: below the threshold (someone deleted mid-search) what was
        // typed would filter the list with no field left to clear it (re-review 2026-11-08).
        let query = isSearchable ? searchText : ""
        let contacts = all.filter { matchesSearch($0.name, query: query) }
        let noMatch = contacts.isEmpty && !query.isEmpty
        let content = ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                if all.isEmpty {
                    // A picture, as every empty card; adding is the card below it.
                    EmptyStateCard(title: "Danh bạ trống", message: "Người bạn cho vay hoặc vay sẽ hiện ở đây.",
                                   picture: IconCatalog.emojiName("🤝"))
                }
                if noMatch {
                    EmptyStateCard(title: "Không tìm thấy", message: "Không có ai tên “\(query)” trong danh bạ.",
                                   picture: IconCatalog.emojiName("🤝"))
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
                            Button { editing = .edit(contact) } label: {
                                ContactRowLabel(name: contact.name, subtitle: subtitle(contact))
                            }
                            .buttonStyle(.row)
                            .accessibilityHint("Xem và sửa thông tin")
                            .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
                        }
                        if query.isEmpty {
                            FormActionRow(title: "Thêm người", icon: "hugeicons-add-01") {
                                editing = .new()
                            }
                            .overlay(alignment: .top) { if !contacts.isEmpty { FormDivider() } }
                        }
                    }
                    .listCard()
                }
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .pageBackground()
        .foregroundStyle(Palette.label)
        .navigationTitle("Danh bạ")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { target in
            ContactEditorView(target: target)
        }
        if isSearchable {
            content.searchable(text: $searchText, prompt: "Tìm người")
        } else {
            content
        }
    }

    /// Every word found in the name, accents aside ("chi lan" finds "Chị Lan"), as Vay nợ's search.
    private func matchesSearch(_ name: String, query: String) -> Bool {
        let words = query.searchKey.split(separator: " ")
        guard !words.isEmpty else { return true }
        let key = name.searchKey
        return words.allSatisfy { key.contains($0) }
    }

    /// "Bạn bè", or "Bạn bè · còn 2 khoản vay": only the ones not settled, so a person square with
    /// you does not read as still owing (review 2026-11-08).
    private func subtitle(_ contact: Contact) -> String {
        let open = store.loans(of: contact).filter { !$0.isSettled }.count
        return [store.relationship(id: contact.relationshipID).name, open > 0 ? "còn \(open) khoản vay" : nil]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

/// A person's row: the same initial in a circle as their loan card on Vay nợ (user choice
/// 2026-10-29), name, relationship and loans. No ›: it opens a sheet, not a page (review
/// 2026-11-08). The circle is a list logo's size and the gap a row's, as an account in a list.
private struct ContactRowLabel: View {
    let name: String
    let subtitle: String

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            InitialsAvatar(name: name, size: RowMetrics.listLogo)
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(name)
                    .textRole(.body)
                    .lineLimit(2)
                Text(subtitle)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .formRowFrame()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { ContactsView() }
        .environment(FinanceStore())
}
