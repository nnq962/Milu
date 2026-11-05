import SwiftUI

/// ✕ in a sheet's navigation bar: Apple's own close button.
struct SheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close) { dismiss() }
        } else {
            // Before iOS 26 there is no close role: the ✕ drawn by hand.
            Button { dismiss() } label: { Image(systemName: "xmark") }
                .accessibilityLabel("Đóng")
        }
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

    var body: some View {
        HStack(spacing: RowMetrics.gap) {
            if let icon {
                RowIcon(name: icon)
            }
            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                // Two lines before "…": a long bank or person name stays readable at large text.
                Text(title)
                    .textRole(.body)
                    .lineLimit(2)
                if let subtitle {
                    Text(subtitle)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .lineLimit(1)
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
