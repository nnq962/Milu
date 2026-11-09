import SwiftUI

extension View {
    /// Closes the keyboard when the content is dragged, the way modern apps do; no "Xong" bar
    /// above the keyboard (removed at the user's request 2026-10-28). Put it on the scroll view and
    /// `keyboardDismissArea()` on its content, so a tap on empty space closes it too.
    func dismissesKeyboardOnDrag() -> some View {
        scrollDismissesKeyboard(.interactively)
    }

    /// A tap target behind the content: a tap on empty space (between cards, around the amount)
    /// closes the keyboard. Being behind, it never takes a tap meant for a field, switch or row:
    /// a gesture over the whole form did, and closed the keyboard a field had just opened.
    func keyboardDismissArea() -> some View {
        background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        }
    }
}
