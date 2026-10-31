import SwiftUI

/// Picks an icon from `IconCatalog` for a savings goal or a category: groups under small headings,
/// five icons a row, no search (browsing invites the user to pick freely, user choice 2026-10-28).
/// Icons stand alone; the chosen one sits on a circle in the primary colour. Tapping one picks it and closes the sheet.
struct IconPickerSheet: View {
    @Binding var selection: String

    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.xxl) {
                    ForEach(IconCatalog.groups) { group in
                        VStack(alignment: .leading, spacing: Spacing.headerGap) {
                            SectionHeader(title: group.title, style: .group)
                            grid(group.icons)
                        }
                    }
                }
            }
            .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
            .contentMargins(.top, Spacing.s, for: .scrollContent)
            .contentMargins(.bottom, Spacing.xxl, for: .scrollContent)
            .background(Palette.background)
            .foregroundStyle(Palette.ink)
            .navigationTitle("Biểu tượng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            }
        }
        .timiSheetStyle()
    }

    private func grid(_ icons: [CatalogIcon]) -> some View {
        LazyVGrid(columns: columns, spacing: Spacing.m) {
            ForEach(icons) { icon in
                cell(icon)
            }
        }
        .padding(Spacing.l)
        .cardSurface(radius: CardCorners.inset, color: Palette.card, elevated: true)
    }

    private func cell(_ icon: CatalogIcon) -> some View {
        Button {
            selection = icon.name
            Haptics.selection()
            dismiss()
        } label: {
            IconChoiceLabel(name: icon.name, isSelected: icon.name == selection, size: RowMetrics.iconChoice)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon.title)
        .accessibilityAddTraits(icon.name == selection ? .isSelected : [])
    }
}

#Preview {
    IconPickerSheet(selection: .constant("hugeicons-car-01"))
}
