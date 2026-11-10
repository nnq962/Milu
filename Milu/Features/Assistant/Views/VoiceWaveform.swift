import SwiftUI

/// What the mic hears, as Claude draws it (user request 2026-11-09): a line of dots across the
/// field that runs right to left without stopping, each dot growing into a bar as tall as the
/// voice was loud then; the newest on the right, the oldest fading out on the left.
///
/// Each dot sits where its moment is on the clock (`SpeechDictation.startedAt`), so the line runs
/// at one speed, silence or speech (user report 2026-11-10: fast in silence). It reads the levels
/// itself, so only the wave redraws ten times a second, not the whole chat. Drawn in one `Canvas`.
struct VoiceWaveform: View {
    let dictation: SpeechDictation

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var dot: CGFloat = 3
    @ScaledMetric(relativeTo: .body) private var step: CGFloat = 6

    var body: some View {
        let levels = dictation.levels
        let total = dictation.levelTotal
        let startedAt = dictation.startedAt
        let interval = SpeechDictation.tickInterval
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                // How far the clock has run past the newest level, in steps.
                let now = reduceMotion ? 0
                    : timeline.date.timeIntervalSince(startedAt) / interval - Double(total)
                let lead = CGFloat(min(max(now, 0), 2))
                let count = min(levels.count, Int(size.width / step) + 2)
                let tallest = size.height * 0.75
                for index in 0..<count {
                    let level = CGFloat(levels[levels.count - 1 - index])
                    let height = max(dot, level * tallest)
                    let x = size.width - dot - (CGFloat(index) + lead) * step
                    guard x > -dot else { continue }
                    let rect = CGRect(x: x, y: (size.height - height) / 2, width: dot, height: height)
                    context.fill(Path(roundedRect: rect, cornerRadius: dot / 2), with: .color(Palette.label))
                }
            }
        }
        // The oldest fade out at the left end, the newest come in softly at the right.
        .mask {
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.12),
                                   .init(color: .black, location: 0.94), .init(color: .clear, location: 1)],
                           startPoint: .leading, endPoint: .trailing)
        }
        .accessibilityHidden(true)
    }
}
