import SwiftUI

/// Picks an icon from `IconCatalog` for a savings goal or a category: groups under small headings,
/// five icons a row, no search (browsing invites the user to pick freely, user choice 2026-10-28).
/// Icons stand alone; the chosen one sits on a circle in the primary colour. Tapping one picks it and closes the sheet.
struct IconPickerSheet: View {
    @Binding var selection: String
    var groups: [IconGroup] = IconCatalog.groups

    @Environment(\.dismiss) private var dismiss

    private static let columns = 5

    /// Lazy by group, each group's grid drawn whole. A lazy grid per group, inside the sheet's
    /// stack, let whole rows go blank for a moment on a quick scroll (user report 2026-11-06):
    /// SwiftUI dropped rows it judged off screen and drew them again, and each icon is an SVG
    /// rendered anew. A group is a few dozen icons, made at once as its heading scrolls near.
    var body: some View {
        SheetScaffold(title: "Biểu tượng") {
            LazyVStack(alignment: .leading, spacing: Spacing.xxl) {
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: Spacing.headerGap) {
                        SectionHeader(title: group.title, style: .group)
                        grid(group.icons)
                    }
                }
            }
        }
        .timiSheetStyle()
    }

    private func grid(_ icons: [CatalogIcon]) -> some View {
        let rows = stride(from: 0, to: icons.count, by: Self.columns)
            .map { Array(icons[$0..<min($0 + Self.columns, icons.count)]) }
        return Grid(horizontalSpacing: Spacing.m, verticalSpacing: Spacing.m) {
            ForEach(rows, id: \.first?.id) { row in
                GridRow {
                    ForEach(row) { icon in
                        cell(icon)
                    }
                    // Keep the columns even on a short last row.
                    ForEach(0..<(Self.columns - row.count), id: \.self) { _ in Color.clear.frame(height: 1) }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.l)
        .cardSurface(radius: CardCorners.card)
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
