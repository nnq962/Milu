import SwiftUI

/// The items most used for `kind`, as a grid of tiles in a "Chọn nhanh" card under the amount (user request
/// 2026-10-30, as MoMo and Money Lover do): most spending is the amount and one tap. The
/// "Hạng mục" row below still opens every item.
struct QuickCategoryGrid: View {
    let kind: TransactionKind
    @Binding var selection: String

    @Environment(FinanceStore.self) private var store

    /// Most used first, by how many transactions sit under each; topped up in the list's order.
    private var items: [Category] {
        let pickable = store.pickableItems(kind)
        let counts = Dictionary(grouping: store.transactions.filter { $0.kind == kind }, by: \.categoryID)
            .mapValues(\.count)
        let used = pickable.filter { counts[$0.id] != nil }
            .sorted { counts[$0.id, default: 0] > counts[$1.id, default: 0] }
        return Array((used + pickable.filter { counts[$0.id] == nil }).prefix(8))
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The tile and its glyph grow with the text (sheet review 2026-10-30); the glyph is a row
    /// icon's size, not the toolbar's (strict review 2026-10-31).
    @ScaledMetric(relativeTo: .caption) private var tileSize = RowMetrics.iconChoice
    @ScaledMetric(relativeTo: .caption) private var glyph = RowMetrics.iconColumn

    var body: some View {
        // Three columns at the accessibility sizes, where four cut every name short.
        let columns = dynamicTypeSize.isAccessibilitySize ? 3 : 4
        // A plain Grid, not a lazy one: a lazy grid sized its rows a moment after the sheet came
        // up, so the rows under it jumped as it slid in (user report 2026-10-30).
        let rows = stride(from: 0, to: items.count, by: columns).map { Array(items[$0..<min($0 + columns, items.count)]) }
        // A titled card like the groups under it (user request 2026-10-31: the bare circles on the
        // page read loose, the grey names faint, and it sat tight on "Chi tiết").
        FormGroup(title: "Chọn nhanh") {
            Grid(horizontalSpacing: Spacing.s, verticalSpacing: Spacing.l) {
                ForEach(rows, id: \.first?.id) { row in
                    GridRow(alignment: .top) {
                        ForEach(row) { item in
                            cell(item, isChosen: item.id == selection)
                        }
                        // Keep the columns even on a short last row.
                        ForEach(0..<(columns - row.count), id: \.self) { _ in Color.clear.frame(height: 1) }
                    }
                }
            }
            .padding(.horizontal, RowMetrics.horizontal)
            .padding(.vertical, Spacing.l)
        }
        .animation(.snappy(duration: 0.2), value: selection)
    }

    /// A rounded tile of the quiet block colour with the item's glyph, its name in ink under it;
    /// filled in the accent when chosen. Flat: no glass inside content, it trailed the
    /// sheet's scroll (2026-10-31). The name under it is part of the button: one control.
    private func cell(_ item: Category, isChosen: Bool) -> some View {
        let tile = RoundedRectangle(cornerRadius: CardCorners.field + Spacing.xs, style: .continuous)
        // No haptic here: the "Hạng mục" row below gives one for every change of it.
        return Button { selection = item.id } label: {
            VStack(spacing: Spacing.s) {
                TimiIcon(item.icon, size: glyph)
                    .foregroundStyle(isChosen ? Palette.onAccent : Palette.label)
                    .frame(width: tileSize, height: tileSize)
                    .background(isChosen ? Palette.accent : Palette.surfaceMuted, in: tile)
                Text(item.name)
                    .textRole(isChosen ? .captionStrong : .caption)
                    .foregroundStyle(Palette.label)
                    .multilineTextAlignment(.center)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.card)
        .accessibilityLabel(item.name)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}
