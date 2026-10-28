import SwiftUI

extension View {
    /// A standard iOS sheet: Apple's own corners, grabber and dimming; Timi only sets the page colour.
    func timiSheetStyle(_ detents: Set<PresentationDetent> = [.large]) -> some View {
        self
            .presentationDetents(detents)
            .presentationBackground(Palette.background)
    }

    /// A standard iOS sheet as tall as its content (short choices, a calendar).
    func timiFittedSheet() -> some View {
        modifier(FittedSheet())
    }
}

private struct FittedSheet: ViewModifier {
    @State private var height: CGFloat = 400

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            // Ignore the zero height reported before layout; a 0pt detent is not a valid sheet size.
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { if $0 > 1 { height = $0 } }
            .frame(maxHeight: .infinity, alignment: .top)
            .presentationDetents([.height(height)])
            .presentationBackground(Palette.background)
    }
}
