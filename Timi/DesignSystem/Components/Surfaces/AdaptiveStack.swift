import SwiftUI

/// Side by side at the usual text sizes, stacked at the accessibility ones, where two things on
/// one line cut each other short: a label and its value, a name and its amount, a heading and the
/// control beside it. One helper for what seven views did by hand (review 2026-10-31).
struct AdaptiveStack<Content: View>: View {
    /// How the pieces line up when side by side.
    var alignment: VerticalAlignment = .center
    var spacing: CGFloat = Spacing.s
    /// The gap once stacked.
    var stackedSpacing: CGFloat = Spacing.xs
    @ViewBuilder var content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: stackedSpacing) { content }
        } else {
            HStack(alignment: alignment, spacing: spacing) { content }
        }
    }
}
