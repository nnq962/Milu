import SwiftUI

extension View {
    /// A standard iOS sheet: Apple's own corners, grabber and dimming; Timi only sets the page
    /// colour. A short sheet sized to its rows uses `SheetScaffold(fitsContent: true)` instead.
    func timiSheetStyle(_ detents: Set<PresentationDetent> = [.large]) -> some View {
        self
            .presentationDetents(detents)
            .presentationBackground(Palette.background)
            // A sheet does not inherit the app's hidden indicators (user report 2026-10-31).
            .scrollIndicators(.hidden, axes: .vertical)
    }
}
