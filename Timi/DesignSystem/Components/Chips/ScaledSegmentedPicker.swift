import SwiftUI

/// The system segmented `Picker`, its words at the user's text size: the fonts are set for that
/// size just before the control is made, and a new size makes a new control, since UIKit keeps the
/// font it was made with (HIG review 2026-10-30: "Thu chi · Vay nợ" stayed small at large sizes).
struct ScaledSegmentedPicker<Value: Hashable & Identifiable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // A side effect in body on purpose: it must run before UIKit makes the control below.
        let _ = Typography.configureSegmentedControls(for: dynamicTypeSize)
        Picker(title, selection: $selection) {
            ForEach(options) { Text(label($0)).tag($0) }
        }
        .pickerStyle(.segmented)
        .id(dynamicTypeSize)
    }
}
