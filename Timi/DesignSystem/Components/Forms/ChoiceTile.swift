import SwiftUI

/// One choice in a grid of tiles: a rounded tile of the quiet block colour with the picture, its
/// name in ink under it; the tile filled in the accent when chosen. The look of "Chọn nhanh" on
/// Thêm giao dịch, shared so every tile grid reads the same (user request 2026-11-05: the goal's
/// icon picked as a category is). Flat: no glass inside content, it trailed the sheet's scroll
/// (2026-10-31). The name under it is part of the button: one control.
struct ChoiceTile: View {
    let icon: String
    let title: String
    let isChosen: Bool
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The tile and its picture grow with the text (sheet review 2026-10-30); the picture is a
    /// row's size, not the toolbar's (strict review 2026-10-31).
    @ScaledMetric(relativeTo: .caption) private var tileSize = RowMetrics.iconChoice
    @ScaledMetric(relativeTo: .caption) private var glyph = RowMetrics.iconColumn

    var body: some View {
        let tile = RoundedRectangle(cornerRadius: CardCorners.field + Spacing.xs, style: .continuous)
        Button(action: action) {
            VStack(spacing: Spacing.s) {
                TimiIcon(icon, size: glyph)
                    .foregroundStyle(isChosen ? Palette.onAccent : Palette.label)
                    .frame(width: tileSize, height: tileSize)
                    .background(isChosen ? Palette.accent : Palette.surfaceMuted, in: tile)
                Text(title)
                    .textRole(isChosen ? .captionStrong : .caption)
                    .foregroundStyle(Palette.label)
                    .multilineTextAlignment(.center)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.card)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}

/// `ChoiceTile`s four a row (three at the accessibility sizes, where four cut every name short),
/// with the padding of a form card's content. A plain Grid, not a lazy one: a lazy grid sized its
/// rows a moment after the sheet came up, so the rows under it jumped as it slid in (user report
/// 2026-10-30).
struct ChoiceTileGrid<Item: Hashable, Cell: View>: View {
    let items: [Item]
    @ViewBuilder let cell: (Item) -> Cell

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let columns = dynamicTypeSize.isAccessibilitySize ? 3 : 4
        let rows = stride(from: 0, to: items.count, by: columns).map { Array(items[$0..<min($0 + columns, items.count)]) }
        Grid(horizontalSpacing: Spacing.s, verticalSpacing: Spacing.l) {
            ForEach(rows, id: \.self) { row in
                GridRow(alignment: .top) {
                    ForEach(row, id: \.self) { item in
                        cell(item)
                    }
                    // Keep the columns even on a short last row.
                    ForEach(0..<(columns - row.count), id: \.self) { _ in Color.clear.frame(height: 1) }
                }
            }
        }
        .padding(.horizontal, RowMetrics.horizontal)
        .padding(.vertical, Spacing.l)
    }
}

/// Likely icons as `ChoiceTile`s with their names, the last tile "Xem thêm" opening the full
/// `IconPickerSheet`: the "Chọn nhanh" look of Thêm giao dịch for a picture (user request
/// 2026-11-05). An icon chosen in the sheet that is not among the suggestions takes the first
/// place, so the choice always shows here.
struct IconTilePicker: View {
    @Binding var selection: String
    let suggestions: [String]
    var groups: [IconGroup] = IconCatalog.emojiGroups

    @State private var isShowingAll = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Tile: Hashable {
        case icon(String)
        case more
    }

    /// Seven icons and "Xem thêm": two full rows of four.
    private static let count = 7

    private var tiles: [Tile] {
        let icons = Array(suggestions.prefix(Self.count))
        let shown = icons.contains(selection) ? icons : [selection] + icons.dropLast()
        return shown.map(Tile.icon) + [.more]
    }

    var body: some View {
        ChoiceTileGrid(items: tiles) { tile in
            switch tile {
            case .icon(let name):
                ChoiceTile(icon: name, title: Self.title(of: name), isChosen: name == selection) {
                    selection = name
                }
            case .more:
                ChoiceTile(icon: "hugeicons-more-horizontal", title: "Xem thêm", isChosen: false) {
                    isShowingAll = true
                }
                .accessibilityLabel("Xem tất cả biểu tượng")
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: selection)
        // A change that stays on screen ticks through `sensoryFeedback`, as the rule says.
        .sensoryFeedback(.selection, trigger: selection)
        .sheet(isPresented: $isShowingAll) {
            IconPickerSheet(selection: $selection, groups: groups)
        }
    }

    private static func title(of name: String) -> String {
        IconCatalog.icon(named: IconCatalog.assetName(for: name))?.title ?? "Biểu tượng"
    }
}

#Preview {
    @Previewable @State var icon = SavingsGoal.suggestedIcons[0]
    FormGroup(title: "Biểu tượng") {
        IconTilePicker(selection: $icon, suggestions: SavingsGoal.suggestedIcons)
    }
    .padding()
}
