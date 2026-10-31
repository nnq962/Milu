import SwiftUI

/// ✕ in a sheet's navigation bar: Apple's own close button.
struct SheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button(role: .close) { dismiss() }
    }
}

/// The tick on the chosen row of a picking sheet (`ChoiceSheet`, the bank picker).
struct SelectionCheck: View {
    /// Grows with the text beside it.
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 20

    var body: some View {
        TimiIcon("hugeicons-tick-02", size: size)
            .foregroundStyle(Palette.primary)
            .accessibilityHidden(true)
    }
}

/// One choice in a picking sheet: icon or logo (optional), title, an optional second line, and the
/// tick when it is the current one. Put it in a `Button` with `.buttonStyle(.row)`.
struct PickerRowLabel: View {
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
