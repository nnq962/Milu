import SwiftUI

/// How things come into and leave the app's lists, one way everywhere (user request 2026-11-13:
/// Giao dịch and Tài khoản should move alike).
extension AnyTransition {
    /// A row (or a day of rows) coming in or going out, as a table in iOS's own apps does it: the
    /// row stays its size and is uncovered from its top down (or covered back up), fading, its
    /// edge keeping pace with the rows that move to make room. The plain fade left it whole while
    /// the others slid, two rows drawn over each other; squeezing it stretched its words (user
    /// reports 2026-11-13).
    static var unfold: AnyTransition {
        .modifier(active: Unfold(shown: 0), identity: Unfold(shown: 1))
    }

    /// A tile in a grid (a savings jar) coming in or going out, as a cell in iOS's own grids:
    /// fading as it grows from a little smaller, evenly, so nothing in it is stretched.
    static var tile: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.88))
    }
}

private struct Unfold: ViewModifier, Animatable {
    var shown: Double

    var animatableData: Double {
        get { shown }
        set { shown = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask(alignment: .top) {
                // A little past the row each way, so a pressed row's wash still reaches over the
                // lines beside it (`RowButtonStyle`).
                Rectangle()
                    .padding(.vertical, -2 * RowMetrics.separator)
                    .scaleEffect(x: 1, y: max(shown, 0.001), anchor: .top)
            }
            .opacity(shown)
    }
}
