import SwiftUI

/// The items most used for `kind`, as a grid of round icons under the amount (user request
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
    /// The circle and its glyph grow with the text (sheet review 2026-10-30); the glyph is a row
    /// icon's size, not the toolbar's (strict review 2026-10-31).
    @ScaledMetric(relativeTo: .caption) private var circle = RowMetrics.iconChoice
    @ScaledMetric(relativeTo: .caption) private var glyph = RowMetrics.iconColumn

    var body: some View {
        // Three columns at the accessibility sizes, where four cut every name short.
        let columns = dynamicTypeSize.isAccessibilitySize ? 3 : 4
        // A plain Grid, not a lazy one: a lazy grid sized its rows a moment after the sheet came
        // up, so the rows under it jumped as it slid in (user report 2026-10-30).
        let rows = stride(from: 0, to: items.count, by: columns).map { Array(items[$0..<min($0 + columns, items.count)]) }
        Grid(horizontalSpacing: Spacing.s, verticalSpacing: Spacing.m) {
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
        .animation(.snappy(duration: 0.2), value: selection)
    }

    /// A flat white circle with a hairline ring, as a `TagChip`; filled in the primary colour when
    /// chosen (user choice 2026-10-31: no glass inside content, it trailed the sheet's scroll). The
    /// name under it picks it too.
    private func cell(_ item: Category, isChosen: Bool) -> some View {
        // No haptic here: the "Hạng mục" row below gives one for every change of it.
        let pick = { selection = item.id }
        return VStack(spacing: Spacing.xs) {
            Button(action: pick) {
                TimiIcon(item.icon, size: glyph)
                    .foregroundStyle(isChosen ? Palette.onPrimary : Palette.label)
                    .frame(width: circle, height: circle)
                    .overlay { if !isChosen { Circle().strokeBorder(Palette.separator, lineWidth: 1) } }
            }
            .flatCircleButton(diameter: circle, fill: isChosen ? Palette.primary : Palette.surface)
            .accessibilityLabel(item.name)
            .accessibilityAddTraits(isChosen ? .isSelected : [])
            Text(item.name)
                .textRole(.caption)
                .foregroundStyle(isChosen ? Palette.primary : Palette.secondaryLabel)
                .multilineTextAlignment(.center)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .onTapGesture(perform: pick)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
