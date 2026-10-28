import SwiftUI

/// A short side-to-side shake, as iOS does on a wrong passcode: three swings that settle back.
/// Drive it with a counter that goes up on each failed attempt, inside an animation.
struct ShakeEffect: GeometryEffect {
    /// Number of shakes so far; each whole step plays one shake.
    var animatableData: CGFloat
    var distance: CGFloat = 8
    var swings: CGFloat = 3

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: distance * sin(animatableData * .pi * swings * 2), y: 0))
    }
}

extension View {
    /// Shakes the view each time `trigger` goes up.
    func shake(_ trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
            .animation(.linear(duration: 0.4), value: trigger)
    }
}
