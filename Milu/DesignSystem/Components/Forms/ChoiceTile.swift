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
    /// False for a picture alone (`IconTilePicker`): the name stays for VoiceOver only. A name
    /// under a tile reads as what is chosen, so on a picture it read as a second name for the
    /// same thing, "Cái chảo" beside the category "Ăn sáng" (user 2026-11-06).
    var showsTitle = true
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The tile and its picture grow with the text (sheet review 2026-10-30); the picture is a
    /// row's size, not the toolbar's (strict review 2026-10-31).
    @ScaledMetric(relativeTo: .caption) private var tileSize = RowMetrics.iconChoice
    @ScaledMetric(relativeTo: .caption) private var glyph = RowMetrics.iconColumn

    var body: some View {
        // No more than 1.6 times, as every row icon: uncapped, three tiles ran past the sheet's
        // width at the accessibility sizes (review 2026-11-07).
        let tileSize = RowMetrics.capped(tileSize, base: RowMetrics.iconChoice)
        let glyph = RowMetrics.capped(glyph, base: RowMetrics.iconColumn)
        let tile = RoundedRectangle(cornerRadius: CardCorners.inner, style: .continuous)
        Button(action: action) {
            VStack(spacing: Spacing.s) {
                MiluIcon(icon, size: glyph)
                    .foregroundStyle(isChosen ? Palette.onAccent : Palette.label)
                    .frame(width: tileSize, height: tileSize)
                    .background(isChosen ? Palette.accent : Palette.surfaceMuted, in: tile)
                if showsTitle {
                    Text(title)
                        .textRole(isChosen ? .captionStrong : .caption)
                        .foregroundStyle(Palette.label)
                        .multilineTextAlignment(.center)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.card)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}

/// `ChoiceTile`s four a row (three at the accessibility sizes, where four cut every name short;
/// pictures without names fit five, one fewer at those sizes),
/// with the padding of a form card's content. A plain Grid, not a lazy one: a lazy grid sized its
/// rows a moment after the sheet came up, so the rows under it jumped as it slid in (user report
/// 2026-10-30).
struct ChoiceTileGrid<Item: Hashable, Cell: View>: View {
    let items: [Item]
    var columns = 4
    @ViewBuilder let cell: (Item) -> Cell

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let columns = dynamicTypeSize.isAccessibilitySize ? self.columns - 1 : self.columns
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

/// Likely icons as `ChoiceTile`s, the last tile "Xem thêm" opening the full `IconPickerSheet`: the
/// "Chọn nhanh" look of Thêm giao dịch for a picture (user request 2026-11-05), but the pictures
/// without names, five a row like the full sheet (2026-11-06): only a tile that names a category
/// carries a name. "Xem thêm" goes without its words too: five a row cut them to "Xem thê…"
/// and left a line of its own under the grid; "…" on the last tile is the usual "more".
///
/// The tiles keep the order they opened with (user report 2026-11-08: an icon not among the
/// suggestions used to take the first tile, and choosing another sent every tile one place on);
/// "Đã chọn" above them shows the choice instead, one picked under "…" included.
struct IconTilePicker: View {
    @Binding var selection: String
    let suggestions: [String]
    var groups: [IconGroup] = IconCatalog.emojiGroups

    @State private var isShowingAll = false
    /// The suggestions as they were when the picker first showed: a form whose suggestions follow
    /// what is being edited (a category's group) does not shuffle the tiles under the finger.
    @State private var shownIcons: [String] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Tile: Hashable {
        case icon(String)
        case more
    }

    /// Nine icons and "Xem thêm": two full rows of five.
    private static let count = 9

    private var tiles: [Tile] {
        let icons = shownIcons.isEmpty ? Array(suggestions.prefix(Self.count)) : shownIcons
        return icons.map(Tile.icon) + [.more]
    }

    var body: some View {
        VStack(spacing: 0) {
            chosenRow
            FormDivider(hasIcon: false)
            grid
        }
        .onAppear {
            if shownIcons.isEmpty { shownIcons = Array(suggestions.prefix(Self.count)) }
        }
        // A change that stays on screen ticks through `sensoryFeedback`, as the rule says.
        .sensoryFeedback(.selection, trigger: selection)
        .sheet(isPresented: $isShowingAll) {
            IconPickerSheet(selection: $selection, groups: groups)
        }
    }

    /// "Đã chọn" and the picture, whichever tile or sheet it came from.
    private var chosenRow: some View {
        HStack(spacing: Spacing.s) {
            FormRowLabel(title: "Đã chọn")
            Spacer(minLength: Spacing.s)
            MiluIcon(selection, size: RowMetrics.iconColumn)
                .contentTransition(.opacity)
                .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: selection)
        }
        .formRowFrame()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Biểu tượng đã chọn")
        .accessibilityValue(Self.title(of: selection))
    }

    private var grid: some View {
        ChoiceTileGrid(items: tiles, columns: 5) { tile in
            switch tile {
            case .icon(let name):
                ChoiceTile(icon: name, title: Self.title(of: name), isChosen: name == selection,
                           showsTitle: false) {
                    selection = name
                }
            case .more:
                ChoiceTile(icon: "hugeicons-more-horizontal", title: "Xem thêm", isChosen: false,
                           showsTitle: false) {
                    isShowingAll = true
                }
                .accessibilityLabel("Xem tất cả biểu tượng")
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: selection)
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
