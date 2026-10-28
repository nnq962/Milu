import SwiftUI

extension View {
    /// Closes the keyboard when the user taps outside a field or drags the content.
    /// Fields, buttons and pickers inside keep their own taps; only empty space reaches this one.
    func dismissesKeyboardOnTap() -> some View {
        self
            .keyboardDoneButton()
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    /// "Xong" above the keyboard, as in Apple's own apps: the number pad has no Return key, so this
    /// is the one obvious way to close it. Put it once on the screen or sheet, not on each field,
    /// or iOS stacks one button per field.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Xong") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
                .tint(Palette.primary)
            }
        }
    }
}
