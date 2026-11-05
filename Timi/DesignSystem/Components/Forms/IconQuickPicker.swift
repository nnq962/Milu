import SwiftUI

/// A form card of likely icons, two rows of six, the last place a "more" button that opens the
/// full `IconPickerSheet` (Reminders-style, user choice 2026-10-28): most people pick here and never
/// open the sheet. Icons stand alone, without a tile; only the chosen one sits on a circle in the primary colour.
/// An icon chosen in the sheet that is not among the suggestions takes the first place, so the
/// choice always shows here.
struct IconQuickPicker: View {
    @Binding var selection: String
    /// Eleven icons; the twelfth place is the "more" button.
    let suggestions: [String]
    var groups: [IconGroup] = IconCatalog.groups

    @State private var isShowingAll = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let count = 11
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 6)

    private var shown: [String] {
        let icons = Array(suggestions.prefix(Self.count))
        return icons.contains(selection) ? icons : [selection] + icons.dropLast()
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.s) {
            ForEach(shown, id: \.self) { name in
                IconChoice(name: name, isSelected: name == selection) {
                    selection = name
                }
                .accessibilityLabel(IconCatalog.icon(named: IconCatalog.assetName(for: name))?.title ?? "Biểu tượng đã lưu")
            }
            Button { isShowingAll = true } label: {
                IconChoiceLabel(name: "hugeicons-more-horizontal", isSelected: false)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Xem tất cả biểu tượng")
        }
        .padding(Spacing.l)
        .animation(reduceMotion ? nil : .smooth(duration: 0.2), value: selection)
        // A change that stays on screen ticks through `sensoryFeedback`, as the rule says.
        .sensoryFeedback(.selection, trigger: selection)
        .sheet(isPresented: $isShowingAll) {
            IconPickerSheet(selection: $selection, groups: groups)
        }
    }
}

/// One icon to choose, standing alone; a circle in the primary colour behind it when chosen. Shared by the quick row
/// and `IconPickerSheet`.
struct IconChoice: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            IconChoiceLabel(name: name, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct IconChoiceLabel: View {
    let name: String
    let isSelected: Bool
    /// A tap target, not a picture: the 44 of every control.
    var size: CGFloat = ControlHeight.regular

    var body: some View {
        TimiIcon(name, size: size * (IconCatalog.isEmoji(name) ? 0.68 : 0.5))
            .foregroundStyle(isSelected ? Palette.onAccent : Palette.label)
            .frame(width: size, height: size)
            .background(Circle().fill(isSelected ? Palette.accent : .clear))
            .contentShape(Circle())
    }
}

#Preview {
    @Previewable @State var icon = "hugeicons-piggy-bank"
    FormGroup(title: "Biểu tượng") {
        IconQuickPicker(selection: $icon, suggestions: SavingsGoal.suggestedIcons)
    }
    .padding()
}
