import SwiftUI

/// Sleek shows only a search button, so the native search field is attached while searching
/// and removed (with its query) when the user cancels.
struct OnDemandSearch: ViewModifier {
    @Binding var text: String
    @Binding var isPresented: Bool
    let prompt: String

    func body(content: Content) -> some View {
        if isPresented {
            content
                .searchable(text: $text, isPresented: $isPresented, prompt: prompt)
                .onDisappear { text = "" }
        } else {
            content
        }
    }
}
