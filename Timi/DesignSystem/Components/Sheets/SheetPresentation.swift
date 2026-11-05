import SwiftUI

extension View {
    /// A standard iOS sheet: Apple's own corners, grabber and dimming; Timi only sets its colour,
    /// Surface/Card (white by day, blue at night). A short sheet sized to its rows uses `SheetScaffold(fitsContent: true)` instead.
    func timiSheetStyle(_ detents: Set<PresentationDetent> = [.large]) -> some View {
        self
            .presentationDetents(detents)
            .presentationBackground(Palette.surface)
            .environment(\.isInSheet, true)
            // A sheet opened from a row inside a `HeaderCard` inherits its "already in a card"
            // flag, and every card in it went flat and grey (user report 2026-11-03): a sheet
            // starts its own cards again.
            .environment(\.isInHeaderCard, false)
            // A sheet does not inherit the app's hidden indicators (user report 2026-10-31).
            .scrollIndicators(.hidden, axes: .vertical)
    }
}
