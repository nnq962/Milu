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
                        PickerRowLabel(icon: icon?(option), title: label(option),
                                       isSelected: option == selection)
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
