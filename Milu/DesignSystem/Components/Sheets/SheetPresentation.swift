import SwiftUI

extension View {
    /// A standard iOS sheet: Apple's own corners, grabber and dimming; Milu only sets its colour,
    /// Surface/Card (white by day, blue at night). A short sheet sized to its rows uses `SheetScaffold(fitsContent: true)` instead.
    func miluSheetStyle(_ detents: Set<PresentationDetent> = [.large]) -> some View {
        self
            // Half the screen as a height of its own, not iOS's `.medium`: at `.medium` iOS draws
            // the ✕ on a flat grey disc whatever the ground, where every other sheet has the white
            // glass one (Simulator 2026-11-20, "Hôm nay, 20/11").
            .presentationDetents(Set(detents.map { $0 == .medium ? .fraction(0.5) : $0 }))
            // Solid when it can stand lower than the screen (`sheetGround`).
            .sheetGround(Palette.surface, solid: detents != [.large])
            .environment(\.isInSheet, true)
            // A sheet opened from a row inside a `HeaderCard` inherits its "already in a card"
            // flag, and every card in it went flat and grey (user report 2026-11-03): a sheet
            // starts its own cards again.
            .environment(\.isInHeaderCard, false)
            // A sheet does not inherit the app's hidden indicators (user report 2026-10-31).
            .scrollIndicators(.hidden, axes: .vertical)
    }
}
