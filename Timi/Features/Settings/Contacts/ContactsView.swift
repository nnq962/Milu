import SwiftUI

/// "Danh bạ" (Cài đặt): the people loans are with, A→Z in one card (initial in a circle as on
/// Vay nợ, name, "Bạn bè · 1 khoản vay"). Tapping someone edits them; + in the toolbar adds one.
/// Pushed from Cài đặt (user choice 2026-10-29); Vay nợ can open it on its own as `ContactsSheet`.
struct ContactsView: View {
    @Environment(FinanceStore.self) private var store
    @State private var editing: ContactEditorView.Target?

    var body: some View {
        let contacts = store.sortedContacts
        ScrollView {
            if contacts.isEmpty {
                EmptyStateCard(icon: "hugeicons-user-group", title: "Danh bạ trống",
                               message: "Người bạn cho vay hoặc vay sẽ hiện ở đây.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
                        Button { editing = .edit(contact) } label: {
                            ContactRowLabel(name: contact.name, subtitle: subtitle(contact))
                        }
                        .buttonStyle(.row)
                        .overlay(alignment: .top) { if index > 0 { RowDivider(column: .logo) } }
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
        .navigationTitle("Danh bạ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = .new() } label: {
                    // The toolbar's one +: a bare + in its 28 frame, as on Tài khoản; the bar's glass
                    // is the circle (2026-11-03, ⊕ before).
                    TimiIcon("hugeicons-add-01", size: RowMetrics.toolbarGlyph)
                        .frame(width: RowMetrics.toolbarGlyphFrame, height: RowMetrics.toolbarGlyphFrame)
                }
                .buttonBorderShape(.circle)
                .tint(Palette.primary)
                .accessibilityLabel("Thêm người")
            }
        }
        .sheet(item: $editing) { target in
            ContactEditorView(target: target)
        }
    }

    /// "Bạn bè", or "Bạn bè · 2 khoản vay" when they have loans.
    private func subtitle(_ contact: Contact) -> String {
        let count = store.loans(of: contact).count
        return [store.relationship(id: contact.relationshipID).name, count > 0 ? "\(count) khoản vay" : nil]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

/// A person's row: the same initial in a circle as their loan card on Vay nợ (user choice
/// 2026-10-29), name, relationship and loans, and ›. The circle is a list logo's size and the gap
/// a row's, as an account in a list (strict review 2026-10-31: 44 and 12).
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
            RowChevron()
        }
        .formRowFrame()
        .accessibilityElement(children: .combine)
    }
}

/// "Danh bạ" on its own, to open from Vay nợ: the same screen in a sheet, with ✕ to close.
struct ContactsSheet: View {
    var body: some View {
        NavigationStack {
            ContactsView()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
                }
        }
        .timiSheetStyle()
    }
}

#Preview {
    NavigationStack { ContactsView() }
        .environment(FinanceStore())
}
