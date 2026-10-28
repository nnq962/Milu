import SwiftUI

/// Picks one value in a sheet (roomier than a menu): the row shows the current value and ›.
struct FormPickerRow<Value: Hashable>: View {
    let title: String
    var icon: String? = nil
    @Binding var selection: Value
    let options: [Value]
    /// Icon beside each choice in the sheet (categories, accounts).
    var optionIcon: ((Value) -> String)? = nil
    let label: (Value) -> String

    @State private var isPicking = false

    var body: some View {
        Button { isPicking = true } label: {
            FormValueLabel(title: title, icon: icon, value: label(selection))
        }
        .buttonStyle(.row)
        .accessibilityValue(label(selection))
        .sensoryFeedback(.selection, trigger: selection)
        .sheet(isPresented: $isPicking) {
            ChoiceSheet(title: title, selection: $selection, options: options, icon: optionIcon, label: label)
        }
    }
}

/// On/off with Apple's switch: on iOS 26 its knob turns to Liquid Glass while dragged. Black when on.
struct FormToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            FormRowLabel(title: title, subtitle: subtitle, icon: icon)
        }
        .tint(Palette.primary)
        .formRowFrame()
    }
}

/// Label, grey value and › on one row: the look shared by every row that opens a picker sheet.
struct FormValueLabel: View {
    let title: String
    let icon: String?
    let value: String

    var body: some View {
        HStack(spacing: Spacing.s) {
            FormRowLabel(title: title, icon: icon)
            Spacer(minLength: Spacing.s)
            Text(value)
                .textRole(.body)
                .foregroundStyle(Palette.secondaryText)
                .lineLimit(1)
            SolarIcon("solar-alt-arrow-right-linear", size: 16)
                .foregroundStyle(Palette.secondary)
        }
        .formRowFrame()
    }
}

/// Opens something else: value and › on the right.
struct FormNavigationRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var value: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                FormRowLabel(title: title, subtitle: subtitle, icon: icon)
                Spacer(minLength: Spacing.s)
                if let value {
                    Text(value)
                        .textRole(.body)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }
                SolarIcon("solar-alt-arrow-right-linear", size: 16)
                    .foregroundStyle(Palette.secondary)
            }
            .formRowFrame()
        }
        .buttonStyle(.row)
    }
}

/// A red text row at the end of a form ("Xoá tài khoản"), as at the end of iOS Contacts. Nothing is
/// deleted on the first tap: iOS's own confirmation sheet asks first (`question`, an optional
/// `message`, a red button repeating `title`); the phone gives a warning buzz when it goes.
struct FormDestructiveRow: View {
    let title: String
    let question: String
    var message: String? = nil
    let action: () -> Void

    @State private var isConfirming = false

    var body: some View {
        Button(role: .destructive) { isConfirming = true } label: {
            Text(title)
                .textRole(.body)
                .foregroundStyle(Palette.red)
                .formRowFrame()
        }
        .buttonStyle(.row)
        .confirmationDialog(question, isPresented: $isConfirming, titleVisibility: .visible) {
            Button(title, role: .destructive) {
                Haptics.warning()
                action()
            }
        } message: {
            if let message { Text(message) }
        }
    }
}
