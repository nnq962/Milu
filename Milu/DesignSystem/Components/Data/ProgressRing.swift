import SwiftUI

/// Progress as a ring round an icon (a goal, the onboarding steps): one track and line for all.
struct ProgressRing: View {
    let progress: Double
    var color: Color = Palette.progress
    var lineWidth: CGFloat = RowMetrics.ringStroke

    var body: some View {
        ZStack {
            // The empty part, as every bar's.
            Circle().stroke(Palette.progressTrack, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
    }
}
