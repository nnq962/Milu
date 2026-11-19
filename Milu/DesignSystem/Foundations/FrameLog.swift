import SwiftUI
import QuartzCore

extension View {
    /// DEBUG only, and only run with `MILU_FRAME_LOG`: how many frames each animation of `value`
    /// was drawn in, printed once it has stopped (`FrameLog`). Nothing in other builds.
    func frameProbe(_ name: String, value: Double) -> some View {
        #if DEBUG
        modifier(FrameProbe(name: name, animatableData: value))
        #else
        self
        #endif
    }
}

#if DEBUG
/// SwiftUI sets an animated value once in each frame it draws, so the time between two settings
/// is a frame: 8.3 ms at 120 Hz, 16.7 ms at 60 Hz or with a frame missed (user question
/// 2026-11-19: "Bạn có chắc 100% … 120hz hết chưa?", which the Simulator cannot answer).
private struct FrameProbe: ViewModifier, Animatable {
    let name: String
    var animatableData: Double {
        didSet { FrameLog.shared.tick(name) }
    }

    func body(content: Content) -> some View { content }
}

/// The frames of each probed animation (`frameProbe`), printed to the console a moment after it
/// stops: run the app with `MILU_FRAME_LOG=1` (on an iPhone, `devicectl device process launch
/// --console`).
final class FrameLog {
    static let shared = FrameLog()
    private let isOn = ProcessInfo.processInfo.environment["MILU_FRAME_LOG"] != nil
    private var runs: [String: [CFTimeInterval]] = [:]
    private var ends: [String: Task<Void, Never>] = [:]
    private var greeted = false

    func tick(_ name: String) {
        guard isOn else { return }
        if !greeted {
            greeted = true
            greet()
        }
        let now = CACurrentMediaTime()
        // Set twice in one frame (layout, then drawing): one frame.
        if let last = runs[name]?.last, now - last < 0.003 { return }
        runs[name, default: []].append(now)
        ends[name]?.cancel()
        ends[name] = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            self.report(name)
        }
    }

    private func greet() {
        let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen
        let key = Bundle.main.object(forInfoDictionaryKey: "CADisableMinimumFrameDurationOnPhone") as? Bool ?? false
        say("[frames] screen up to \(screen?.maximumFramesPerSecond ?? 0) fps, CADisableMinimumFrameDurationOnPhone \(key), Low Power Mode \(ProcessInfo.processInfo.isLowPowerModeEnabled)")
    }

    private func report(_ name: String) {
        guard let times = runs.removeValue(forKey: name), times.count >= 4,
              let first = times.first, let last = times.last else { return }
        let gaps = zip(times.dropFirst(), times).map { ($0 - $1) * 1000 }.sorted()
        let at120 = gaps.filter { $0 < 11 }.count
        let at60 = gaps.filter { $0 >= 11 && $0 < 20 }.count
        let missed = gaps.filter { $0 >= 20 }.count
        let span = last - first
        say(String(format: "[frames] %@: %d frames in %.2f s = %.0f/s · gaps <11 ms: %d, 11–20 ms: %d, ≥20 ms: %d · median %.1f ms, longest %.1f ms",
                   name, times.count, span, Double(times.count - 1) / max(span, 0.001), at120, at60, missed,
                   gaps[gaps.count / 2], gaps.last ?? 0))
    }

    private func say(_ line: String) {
        print(line)
        fflush(stdout)
    }
}
#endif
