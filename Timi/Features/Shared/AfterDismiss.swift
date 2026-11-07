import SwiftUI

/// Runs a change that takes a record out of the list it was opened from (archive, delete, restore,
/// reopen, close) only once the sheet or page showing that record has slid away, then animated.
/// Done at once, the change removed the row the sheet hangs on, so the sheet vanished mid-slide
/// and the list jumped (user report 2026-11-05: "giật lung tung, sheet tự nhiên biến mất"). iOS
/// gives no callback when a sheet started by `dismiss()` or a pop has finished, so this waits a
/// sheet's slide.
extension EnvironmentValues {
    /// The sheet that shows the record a form edits (a transaction's, a loan's), given to that
    /// form: deleting there closes both at once, then the record goes. Closing the form alone left
    /// the record's sheet up as the record went, and it read "đã bị xoá" for a moment as it slid
    /// away (user report 2026-11-07; Tài khoản deletes from the record's own sheet).
    @Entry var recordSheetDismiss: DismissAction? = nil
}

@MainActor
enum AfterDismiss {
    /// A little longer than iOS's sheet and push slides.
    static let delay: Duration = .milliseconds(450)

    static func run(_ change: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: delay)
            withAnimation(.smooth(duration: 0.35)) { change() }
        }
    }
}
