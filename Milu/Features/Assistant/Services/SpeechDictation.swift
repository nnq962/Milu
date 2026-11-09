//
//  SpeechDictation.swift
//  Timi
//

import AVFoundation
import Observation
import Speech

/// Vietnamese speech-to-text for the chat field, using Apple's on-device/server recognizer.
///
/// Listens until the user stops it (■, ✕ or ↑), pauses included: the recognizer ends a stretch
/// after a silence, or starts the words over, so each finished stretch is kept and a new one is
/// started on the same microphone (user report 2026-11-09: after a pause the earlier sentence was
/// gone and it had to be said again).
@Observable
final class SpeechDictation {
    enum Failure: Equatable {
        case denied, unavailable, audio
    }

    private(set) var isRecording = false
    private(set) var transcript = ""
    var failure: Failure?
    /// How loud the last moments were, oldest first, each 0…1: the wave in the field.
    private(set) var levels = [Float](repeating: 0, count: SpeechDictation.levelCount)
    /// Enough for the widest field; the wave draws as many as fit, newest on the right.
    static let levelCount = 96
    /// One step of the wave: a new level this often, on a steady clock.
    static let tickInterval: TimeInterval = 0.05
    /// When the last level was added: the wave slides between steps from here.
    @ObservationIgnored private(set) var lastTick = Date.now

    @ObservationIgnored private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    /// The request the microphone feeds; swapped for a new one at each new stretch.
    @ObservationIgnored private let feed = RequestFeed()
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    /// Which stretch the recognizer's answers belong to: a stopped one's late answers are dropped.
    @ObservationIgnored private var generation = 0
    /// The stretches already finished, and the words of the one being heard.
    @ObservationIgnored private var committed = ""
    @ObservationIgnored private var partial = ""
    /// Stretches ended by an error in a row; past a few, it stops instead of trying again.
    @ObservationIgnored private var failedStretches = 0
    /// The loudest moment since the last step of the wave.
    @ObservationIgnored private var peak: Float = 0
    @ObservationIgnored private var timer: Timer?

    func toggle() async {
        if isRecording {
            stop()
        } else {
            await start()
        }
    }

    func start() async {
        guard !isRecording else { return }
        guard await Self.requestPermissions() else {
            failure = .denied
            return
        }
        guard let recognizer, recognizer.isAvailable else {
            failure = .unavailable
            return
        }
        do {
            try beginSession(with: recognizer)
        } catch {
            stop()
            failure = .audio
        }
    }

    func stop() {
        guard isRecording || task != nil else { return }
        timer?.invalidate()
        timer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        endStretch()
        isRecording = false
        levels = [Float](repeating: 0, count: Self.levelCount)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Phiên nghe

    private func beginSession(with recognizer: SFSpeechRecognizer) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        committed = ""
        partial = ""
        transcript = ""
        failedStretches = 0

        Self.installTap(on: audioEngine.inputNode, feed: feed, dictation: self)
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        startStretch(with: recognizer)
        startClock()
    }

    /// A new recognition on the running microphone.
    private func startStretch(with recognizer: SFSpeechRecognizer) {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // On the phone when it can: what is said stays on it, as Cài đặt's privacy note says
        // (review 2026-11-09: it went to Apple's servers).
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        generation += 1
        feed.request = request
        task = recognizer.recognitionTask(with: request, resultHandler: Self.resultHandler(for: self, generation: generation))
    }

    private func endStretch() {
        feed.request?.endAudio()
        feed.request = nil
        task?.cancel()
        task = nil
        generation += 1
    }

    /// Keeps what was heard and listens on.
    private func continueAfterStretch() {
        commitPartial()
        endStretch()
        guard isRecording, let recognizer, recognizer.isAvailable else { return stop() }
        startStretch(with: recognizer)
    }

    private func handle(text: String?, isFinal: Bool, failed: Bool, generation: Int) {
        guard isRecording, generation == self.generation else { return }
        if let text {
            failedStretches = 0
            // The recognizer started the words over after a pause: keep the earlier ones.
            if DictationText.restarted(from: partial, to: text) { commitPartial() }
            partial = text
            updateTranscript()
        }
        if isFinal {
            continueAfterStretch()
        } else if failed {
            failedStretches += 1
            if failedStretches > 3 {
                commitPartial()
                stop()
            } else {
                continueAfterStretch()
            }
        }
    }

    private func commitPartial() {
        guard !partial.isEmpty else { return }
        committed = [committed, partial].filter { !$0.isEmpty }.joined(separator: " ")
        partial = ""
        updateTranscript()
    }

    private func updateTranscript() {
        transcript = [committed, partial].filter { !$0.isEmpty }.joined(separator: " ")
    }

    // MARK: - Sóng âm

    /// A step of the wave on a steady clock, whatever the microphone's rhythm.
    private func startClock() {
        lastTick = .now
        let timer = Timer(timeInterval: Self.tickInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        guard isRecording else { return }
        levels.removeFirst()
        levels.append(peak)
        // Falls away between words rather than dropping at once.
        peak *= 0.35
        lastTick = .now
    }

    private func hear(_ level: Float) {
        guard isRecording else { return }
        peak = max(peak, level)
    }

    // The tap and the recognizer call back on background queues. Build those closures in
    // nonisolated functions so they are not MainActor-isolated (the project's default),
    // which would trap at runtime, and hop to the main actor before touching state.
    private nonisolated static func installTap(on input: AVAudioInputNode, feed: RequestFeed, dictation: SpeechDictation) {
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak dictation] buffer, _ in
            feed.append(buffer)
            let level = Self.level(of: buffer)
            guard let dictation else { return }
            Task { @MainActor in dictation.hear(level) }
        }
    }

    /// The buffer's loudness, 0 (−50 dB and below, a quiet room) to 1 (−10 dB, speaking close).
    private nonisolated static func level(of buffer: AVAudioPCMBuffer) -> Float {
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for index in 0..<count { sum += samples[index] * samples[index] }
        let rms = (sum / Float(count)).squareRoot()
        let decibels = 20 * log10(max(rms, 0.000_01))
        return min(max((decibels + 50) / 40, 0), 1)
    }

    private nonisolated static func resultHandler(for dictation: SpeechDictation, generation: Int)
        -> @Sendable (SFSpeechRecognitionResult?, Error?) -> Void {
        { [weak dictation] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            guard let dictation else { return }
            Task { @MainActor in
                dictation.handle(text: text, isFinal: isFinal, failed: failed, generation: generation)
            }
        }
    }

    private nonisolated static func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        guard speech else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }
}

extension SpeechDictation: @unchecked Sendable {}

/// The request the microphone's tap feeds, behind a lock: the tap runs on the audio thread while
/// a new stretch swaps the request on the main one.
private final class RequestFeed: @unchecked Sendable {
    private let lock = NSLock()
    private var current: SFSpeechAudioBufferRecognitionRequest?

    var request: SFSpeechAudioBufferRecognitionRequest? {
        get { lock.withLock { current } }
        set { lock.withLock { current = newValue } }
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.withLock { current?.append(buffer) }
    }
}

/// Reading the recognizer's words as they come.
enum DictationText {
    /// Whether `new` is a fresh start rather than `old` revised: a revision keeps the opening
    /// words; a fresh start is shorter and opens differently.
    nonisolated static func restarted(from old: String, to new: String) -> Bool {
        guard !old.isEmpty, new.count < old.count else { return false }
        let opening = String(old.lowercased().prefix(min(old.count, 6)))
        return !new.lowercased().hasPrefix(opening)
    }
}
