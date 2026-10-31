import SwiftUI

/// The one chip of the app (not glass, user choice 2026-10-31): white capsule, thin outline; filled
/// in the primary colour when chosen or prominent. The capsule is 36 tall, the button 44 (HIG:
/// nothing to tap under 44), the difference clear above and below.
/// With `onRemove` it is a filter that is on ("Chi ×"): the chip opens it, × drops it. Without, a
/// suggestion in grey that one tap turns on. `isProminent` is the filled one ("Bộ lọc · 2", the chosen filter).
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
                    if let icon { TimiIcon(icon, size: RowMetrics.chevron) }
                    Text(title)
                        .textRole(.captionStrong)
                        .monospacedDigit()
                        .lineLimit(1)
                }
                .foregroundStyle(isProminent ? Palette.onPrimary : isSuggestion ? Palette.secondaryLabel : Palette.label)
                .padding(.leading, Spacing.m)
                .padding(.trailing, onRemove == nil ? Spacing.m : Spacing.xxs)
                // At least 44 to tap, taller with larger text (Dynamic Type).
                .padding(.vertical, Spacing.xs)
                .frame(minHeight: ControlHeight.regular)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(hint ?? "")
            if let onRemove {
                Button(action: onRemove) {
                    TimiIcon("hugeicons-cancel-01", size: RowMetrics.linkChevron)
                        .foregroundStyle(Palette.secondaryLabel)
                        // Right after the words (user report 2026-10-31: a 44 frame left a gap
                        // inside the chip); the area that takes a tap reaches past the glyph to 44.
                        .frame(width: RowMetrics.iconColumn)
                        .padding(.trailing, Spacing.xs)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle().inset(by: -Spacing.s))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Bỏ \(title)")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        // The capsule drawn 4 in from the top and bottom of the 44 button.
        .background {
            Capsule().fill(isProminent ? Palette.primary : Palette.surface)
                .padding(.vertical, Spacing.xs)
        }
        .overlay {
            if !isProminent {
                Capsule().strokeBorder(Palette.separator, lineWidth: 1)
                    .padding(.vertical, Spacing.xs)
            }
        }
    }
}
