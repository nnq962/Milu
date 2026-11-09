import SwiftUI

/// What the mic hears, as Claude draws it (user request 2026-11-09): a line of dots across the
/// field that runs right to left without stopping, each dot growing into a bar as tall as the
/// voice was loud then; the newest on the right, the oldest fading out on the left.
///
/// It slides every frame, not a step at a time: between two levels it moves on by the part of a
/// step that time has run (user report 2026-11-09: it jumped). Drawn in one `Canvas`: a view per
/// dot, redrawn every frame, would be a hundred views.
struct VoiceWaveform: View {
    /// Oldest first, each 0…1 (`SpeechDictation.levels`).
    let levels: [Float]
    /// When the newest level came, and how often they come.
    let lastTick: Date
    var interval: TimeInterval = SpeechDictation.tickInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var dot: CGFloat = 3
    @ScaledMetric(relativeTo: .body) private var step: CGFloat = 6

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                // How far into the next step: 0 as a level arrives, 1 just before the next.
                let progress = reduceMotion ? 0
                    : CGFloat(min(max(timeline.date.timeIntervalSince(lastTick) / interval, 0), 1))
                let count = min(levels.count, Int(size.width / step) + 1)
                let tallest = size.height * 0.75
                for index in 0..<count {
                    let level = CGFloat(levels[levels.count - 1 - index])
                    let height = max(dot, level * tallest)
                    let x = size.width - dot - (CGFloat(index) + progress) * step
                    guard x > -dot else { continue }
                    let rect = CGRect(x: x, y: (size.height - height) / 2, width: dot, height: height)
                    context.fill(Path(roundedRect: rect, cornerRadius: dot / 2), with: .color(Palette.label))
                }
            }
        }
        // The oldest fade out at the left end rather than stop at an edge.
        .mask {
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.12)],
                           startPoint: .leading, endPoint: .trailing)
        }
        .accessibilityHidden(true)
    }
}
