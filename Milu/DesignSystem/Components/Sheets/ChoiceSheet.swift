import SwiftUI

/// Picks one value in a short sheet: rows (with an icon when `icon` is given) and a check on the
/// current one; picking closes it.
struct ChoiceSheet<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    var optionIcon: ((Value) -> String)? = nil
    let optionTitle: (Value) -> String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetScaffold(title: title, fitsContent: true) {
            FormGroup {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    Button {
                        // No buzz here: the row that opened this sheet buzzes as its value changes
                        // (`sensoryFeedback`); both made two for one tap (review 2026-11-07).
                        selection = option
                        dismiss()
                    } label: {
                        PickerRowContent(icon: optionIcon?(option), title: optionTitle(option),
                                         isSelected: option == selection)
                    }
                    .buttonStyle(.row)
                    .accessibilityAddTraits(option == selection ? .isSelected : [])
                    .separatorAbove(index > 0, order: index) { FormDivider(hasIcon: optionIcon != nil) }
                }
            }
        }
    }
}
