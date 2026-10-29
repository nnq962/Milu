import SwiftUI

/// ✕ in a sheet's navigation bar: Apple's close button on iOS 26, an "xmark" before.
struct SheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close) { dismiss() }
        } else {
            Button { dismiss() } label: { Image(systemName: "xmark") }
                .accessibilityLabel("Đóng")
        }
    }
}

/// The tick on the chosen row of a picking sheet (`ChoiceSheet`, the bank picker).
struct SelectionCheck: View {
    var body: some View {
        TimiIcon("hugeicons-tick-02", size: 20)
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
                Text(title)
                    .textRole(.body)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryText)
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
