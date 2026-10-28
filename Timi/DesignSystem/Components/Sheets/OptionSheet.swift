import SwiftUI

/// One choice in a short option sheet.
struct SheetOption: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    var subtitle: String? = nil
    var accent = false
}

/// A short sheet of choices (web "Thêm mới"); picking one closes it, then runs the action.
struct OptionSheet: View {
    let title: String
    let options: [SheetOption]
    let onSelect: (SheetOption) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            SheetHeader(title: title)
            FormGroup {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button {
                        Haptics.selection()
                        dismiss()
                        onSelect(option)
                    } label: {
                        HStack(spacing: RowMetrics.gap) {
                            FormIconTile(icon: option.icon)
                            VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                                Text(option.title).textRole(.body)
                                if let subtitle = option.subtitle {
                                    Text(subtitle)
                                        .textRole(.caption)
                                        .foregroundStyle(Palette.secondaryText)
                                }
                            }
                            Spacer()
                            SolarIcon("solar-alt-arrow-right-linear", size: 16)
                                .foregroundStyle(Palette.secondary)
                        }
                        .padding(.horizontal, RowMetrics.horizontal)
                        .padding(.vertical, RowMetrics.vertical)
                        .frame(minHeight: RowMetrics.minHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.row)
                    .overlay(alignment: .top) { if index > 0 { FormDivider() } }
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.xxl)
        .timiFittedSheet()
    }
}
