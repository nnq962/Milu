import SwiftUI

/// Haptics for actions that close the view they start in (save, delete, pick and close), where
/// `.sensoryFeedback` could vanish with the view. Changes that stay on screen use `.sensoryFeedback`.
enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    /// A tap's knock, as iOS's own buttons give: `.light` for a control, `.soft` for sending.
    /// One kept generator per style, woken ahead by `prepare()`: a new generator each time
    /// knocked hard the first time, the Taptic Engine starting from rest (user report
    /// 2026-11-11). At iOS's own strength: set lower, it knocked thin and dry.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = impactGenerator(style)
        generator.impactOccurred()
        generator.prepare()
    }

    /// Wakes the engine for the knocks to come (a screen of controls about to be used): the
    /// first one then lands as the others do.
    static func prepare() {
        impactGenerator(.light).prepare()
        impactGenerator(.soft).prepare()
    }

    private static var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]

    private static func impactGenerator(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        if let kept = impactGenerators[style] { return kept }
        let generator = UIImpactFeedbackGenerator(style: style)
        impactGenerators[style] = generator
        return generator
    }
}
