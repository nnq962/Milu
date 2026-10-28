import SwiftUI

/// Picks one value in a short sheet: rows (with an icon when `icon` is given) and a check on the
/// current one; picking closes it.
struct ChoiceSheet<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    var icon: ((Value) -> String)? = nil
    let label: (Value) -> String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            SheetHeader(title: title)
            FormGroup {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    Button {
                        selection = option
                        dismiss()
                    } label: {
                        HStack(spacing: RowMetrics.gap) {
                            if let icon {
                                RowIcon(name: icon(option))
                            }
                            Text(label(option)).textRole(.body)
                            Spacer()
                            if option == selection {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Palette.primary)
                            }
                        }
                        .padding(.horizontal, RowMetrics.horizontal)
                        .padding(.vertical, RowMetrics.vertical)
                        .frame(minHeight: RowMetrics.minHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.row)
                    .accessibilityAddTraits(option == selection ? .isSelected : [])
                    .overlay(alignment: .top) { if index > 0 { FormDivider(hasIcon: icon != nil) } }
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, Spacing.page)
        .padding(.bottom, Spacing.xxl)
        .timiFittedSheet()
    }
}
