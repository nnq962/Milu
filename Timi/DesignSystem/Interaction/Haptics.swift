import SwiftUI

/// Haptics for actions that close the view they start in (save, delete, pick and close), where
/// `.sensoryFeedback` could vanish with the view. Changes that stay on screen use `.sensoryFeedback`.
enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
