import SwiftUI

/// One icon of `IconPickerSheet`, standing alone; a circle in the primary colour behind it when
/// chosen. The forms' own picks are `IconTilePicker` (2026-11-05: the "Chọn nhanh" tiles).
struct IconChoiceLabel: View {
    let name: String
    let isSelected: Bool
    /// A tap target, not a picture: the 44 of every control.
    var size: CGFloat = ControlHeight.regular

    var body: some View {
        MiluIcon(name, size: size * (IconCatalog.isEmoji(name) ? 0.68 : 0.5))
            .foregroundStyle(isSelected ? Palette.onAccent : Palette.label)
            .frame(width: size, height: size)
            .background(Circle().fill(isSelected ? Palette.accent : .clear))
            .contentShape(Circle())
    }
}
