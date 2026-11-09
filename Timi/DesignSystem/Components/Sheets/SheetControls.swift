import SwiftUI

/// ✕ in a sheet's navigation bar: Apple's own close button.
struct SheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button(role: .close) { dismiss() }
            } else {
                // Before iOS 26 there is no close role: iOS 17's own sheet ✕, small and bold on a
                // grey disc (user choice 2026-11-09), as in Music and Weather.
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.secondaryLabel)
                        .frame(width: LegacyBar.sheetControl, height: LegacyBar.sheetControl)
                        .background(Palette.fill, in: Circle())
                        .contentShape(Circle())
                }
                .accessibilityLabel("Đóng")
            }
        }
        // Its own tint, not the one around it: the add sheet opened from the + at the app's root
        // sits outside the tabs' tint, and its ✕ came out black (user report 2026-11-07).
        .tint(Palette.primary)
    }
}

/// The tick on the chosen row of a picking sheet (`ChoiceSheet`, the bank picker).
struct SelectionCheck: View {
    /// Grows with the text beside it.
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = IconSize.bar

    var body: some View {
        // iOS's own tick, as in its menus and pickers.
        Image(systemName: "checkmark")
            .font(.system(size: RowMetrics.capped(size, base: IconSize.bar), weight: .semibold))
            .foregroundStyle(Palette.primary)
            .accessibilityHidden(true)
    }
}

/// One choice in a picking sheet: icon or logo (optional), title, an optional second line, and the
/// tick when it is the current one. Put it in a `Button` with `.buttonStyle(.row)`.
struct PickerRowContent: View {
    var icon: String? = nil
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // One line: the picture and ✓ on the words' middle, not the line's box (as form rows,
        // review 2026-11-07); with a second line, centred on both.
        HStack(alignment: subtitle == nil ? .firstTextBaseline : .center, spacing: RowMetrics.gap) {
            if let icon {
                RowIcon(name: icon)
                    .centeredOnTextLine()
            }
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                // Two lines before "…": a long bank or person name stays readable at large text.
                Text(title)
                    .textRole(.body)
                    .lineLimit(2)
                if let subtitle {
                    // Whole at the accessibility sizes: a bank's full name was cut (review 2026-11-07).
                    Text(subtitle)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if isSelected {
                SelectionCheck()
            }
        }
        .formRowFrame()
    }
}
