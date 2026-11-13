import UIKit

/// The app's haptics, one set of rules everywhere, as iOS uses them (user choice 2026-11-13: the
/// knocks were of three strengths, and every save buzzed):
///
/// - Tapping a button, card or row: none. iOS's own buttons do not knock; the press shows it.
/// - `selection()`: a choice changing (a category, a chip, a month, a finger along a chart), and
///   a question sent to Milu or its answer showing.
/// - `milestone()`: something reached, not every save: Milu Pro bought or restored, a goal
///   closed, the welcome done, an archived account brought back. A sheet closing says "saved".
/// - `warning()`: the confirming tap of a delete or erase, not the tap that asks.
/// - `error()`: ✓ with something missing or wrong.
///
/// Called where the action happens, so they play even when the view that started it closes.
@MainActor
enum Haptics {
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func milestone() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}
