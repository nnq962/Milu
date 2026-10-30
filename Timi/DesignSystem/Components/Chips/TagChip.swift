import SwiftUI

/// A plain chip (not glass: in a scrolling row glass draws a halo): white capsule, thin outline.
/// With `onRemove` it is a filter that is on ("Chi ×"): the chip opens it, × drops it. Without, a
/// suggestion in grey that one tap turns on. `isProminent` is the teal "Bộ lọc · 2".
struct TagChip: View {
    let title: String
    var icon: String? = nil
    var isProminent = false
    var isSuggestion = false
    /// What a tap on the chip itself does, for VoiceOver ("Mở bộ lọc"); × says its own.
    var hint: String? = nil
    let action: () -> Void
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: Spacing.xs) {
                    if let icon { TimiIcon(icon, size: 16) }
                    Text(title)
                        .textRole(.captionStrong)
                        .monospacedDigit()
                        .lineLimit(1)
                }
                .foregroundStyle(isProminent ? Palette.onPrimary : isSuggestion ? Palette.secondaryText : Palette.ink)
                .padding(.leading, Spacing.m)
                .padding(.trailing, onRemove == nil ? Spacing.m : Spacing.xxs)
                // At least 36, taller with larger text (Dynamic Type).
                .padding(.vertical, Spacing.xs)
                .frame(minHeight: ControlHeight.small)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityHint(hint ?? "")
            if let onRemove {
                Button(action: onRemove) {
                    TimiIcon("hugeicons-cancel-01", size: 12)
                        .foregroundStyle(Palette.secondaryText)
                        // A 32pt wide target the chip's full height, not just the glyph.
                        .frame(width: 32)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Bỏ \(title)")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(isProminent ? Palette.primary : Palette.card, in: Capsule())
        .overlay { if !isProminent { Capsule().strokeBorder(Palette.border, lineWidth: 1) } }
    }
}
