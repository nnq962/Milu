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
                               message: "Thêm những người bạn hay cho vay hoặc vay tiền.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
                        Button { editing = .edit(contact) } label: {
                            ContactRowLabel(name: contact.name, subtitle: subtitle(contact))
                        }
                        .buttonStyle(.row)
                        .overlay(alignment: .top) { if index > 0 { RowDivider() } }
                    }
                }
                .listCard()
                // The divider starts after the 44pt avatar, as on lists with icon circles.
                .environment(\.formIconStyle, .tile)
            }
        }
        .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
        .contentMargins(.top, Spacing.l, for: .scrollContent)
        .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle("Danh bạ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = .new } label: {
                    TimiIcon("hugeicons-add-01", size: RowMetrics.toolbarGlyph)
                }
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
/// 2026-10-29), name, relationship and loans, and ›.
private struct ContactRowLabel: View {
    let name: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Spacing.m) {
            InitialsAvatar(name: name)
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                Text(name)
                    .textRole(.body)
                    .lineLimit(2)
                Text(subtitle)
                    .textRole(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            TimiIcon("hugeicons-arrow-right-01", size: 16)
                .foregroundStyle(Palette.secondary)
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
