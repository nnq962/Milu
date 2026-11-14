//
//  SpeechDictation.swift
//  Milu
//

import AVFoundation
import Observation
import Speech

/// Vietnamese speech-to-text for the chat field: the app's server first (its Zipformer model,
/// which knows the banks' names), the iPhone's recognizer when the server cannot be had (user
/// choice 2026-11-12). Both hear the same words: the iPhone's recognizer runs as it listens, and
/// the sound is kept in a file the server reads once the user is done, so falling back waits for
/// nothing.
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
    /// After ■ or ↑: the microphone is off and what was said is being turned into words, which
    /// `finish()` hands back. As ChatGPT does with its own speech service (user request
    /// 2026-11-10): nothing shows while listening, then "Đang chuyển thành chữ…", then the words.
    /// Apple's recognizer for now; the app's own server (zipformer) takes this step later.
    private(set) var isTranscribing = false
    private(set) var transcript = ""
    var failure: Failure?
    /// How loud the last moments were, oldest first, each 0…1: the wave in the field.
    private(set) var levels = [Float](repeating: 0, count: SpeechDictation.levelCount)
    /// Enough for the widest field; the wave draws as many as fit, newest on the right.
    static let levelCount = 96
    /// One step of the wave: a level for every this much time, counted from `startedAt`.
    static let tickInterval: TimeInterval = 0.1
    /// The least time "Milu đang hiểu ý bạn…" shows (`finish()`).
    static let minimumTranscribing: TimeInterval = 1
    /// When listening began, and how many levels since: level `n` stands for the moment
    /// `startedAt + n × tickInterval`, so the wave moves with the clock, not with the timer, and
    /// never runs faster or slower (user report 2026-11-10: fast in silence, slower in speech).
    ///
    /// Watched, not ignored: in silence every level is 0, so `levels` is set to what it already
    /// was and Observation, which skips equal values, tells no one; the count still changes,
    /// and the wave moves on (user report 2026-11-10: it stood still until something was said).
    private(set) var startedAt = Date.now
    private(set) var levelTotal = 0

    @ObservationIgnored private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
    /// The microphone, worked on a queue of its own: turning the audio session on and off blocks
    /// for a moment, which on the main thread made ■ and ✕ stutter (user report 2026-11-10).
    @ObservationIgnored private let microphone = Microphone()
    /// The request the microphone feeds; swapped for a new one at each new stretch.
    @ObservationIgnored private let feed = RequestFeed()
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    /// Which stretch the recognizer's answers belong to: a stopped one's late answers are dropped.
    @ObservationIgnored private var generation = 0
    /// Which listening the microphone's news belongs to: a stopped one's is dropped.
    @ObservationIgnored private var session = 0
    /// The stretches already finished, and the words of the one being heard.
    @ObservationIgnored private var committed = ""
    @ObservationIgnored private var partial = ""
    /// Stretches ended by an error in a row; past a few, it stops instead of trying again.
    @ObservationIgnored private var failedStretches = 0
    /// The loudest moment since the last step of the wave.
    @ObservationIgnored private var peak: Float = 0
    @ObservationIgnored private var timer: Timer?
    /// `finish()` waiting for the recognizer's last word, and whether ✕ ended that wait.
    @ObservationIgnored private var finishing: CheckedContinuation<Void, Never>?
    @ObservationIgnored private var finishCancelled = false
    /// Names the server's recognizer should favour: the user's accounts, the banks and wallets.
    @ObservationIgnored var hotwords: [String] = []
    /// How long the server has for the words before the iPhone's are taken.
    static let serverTimeout: TimeInterval = 5

    func toggle() async {
        if isRecording {
            stop()
        } else {
            await start()
        }
    }

    /// The audio session set up ahead, as the page opens, so the first tap only switches the
    /// microphone on (user report 2026-11-12: the screen flickered as the microphone started; iOS
    /// 26 does it in other apps too, so this only takes the session's setup out of that moment).
    func prepare() {
        microphone.prepare()
    }

    func start() async {
        guard !isRecording else { return }
        // Already allowed: no hop off the main thread, so the wave shows the moment the mic is
        // tapped (seen in testing 2026-11-10: it came a beat late).
        // No Face ID cover over iOS's prompts for speech and the microphone (`AppLock.whileSystemAsks`).
        let allowed = Self.alreadyAllowed ? true : await AppLock.shared.whileSystemAsks { await Self.requestPermissions() }
        guard allowed else {
            failure = .denied
            return
        }
        guard let recognizer, recognizer.isAvailable else {
            failure = .unavailable
            return
        }
        // The field changes at once; the microphone catches up on its own queue.
        committed = ""
        partial = ""
        transcript = ""
        failedStretches = 0
        peak = 0
        levels = [Float](repeating: 0, count: Self.levelCount)
        isRecording = true
        session += 1
        let session = session
        startStretch(with: recognizer)
        startClock()
        microphone.start(feed: feed, onLevel: Self.levelHandler(for: self)) { [weak self] started in
            Task { @MainActor in
                guard let self, !started, self.isRecording, self.session == session else { return }
                self.stop()
                self.failure = .audio
            }
        }
    }

    /// Stops and forgets what was heard (✕, leaving the screen); ends a `finish()` too.
    func stop() {
        guard isRecording || isTranscribing || task != nil else { return }
        timer?.invalidate()
        timer = nil
        endStretch()
        if isTranscribing {
            finishCancelled = true
            resumeFinish()
        }
        isRecording = false
        isTranscribing = false
        session += 1
        microphone.stop { url in url.map { try? FileManager.default.removeItem(at: $0) } }
    }

    /// Stops listening and turns what was said into words: nil when ✕ came first.
    func finish() async -> String? {
        guard isRecording else { return nil }
        timer?.invalidate()
        timer = nil
        isRecording = false
        isTranscribing = true
        session += 1
        let began = Date.now
        // The server reads the recording while the iPhone's recognizer gives its last word.
        let names = hotwords
        let server = Task { () -> String? in
            let recording = await withCheckedContinuation { continuation in
                microphone.stop { continuation.resume(returning: $0) }
            }
            return await Self.serverTranscript(of: recording, names: names)
        }
        // No more sound: the recognizer gives its last word, or is given up on after a moment.
        feed.request?.endAudio()
        feed.request = nil
        if task != nil {
            let session = session
            await withCheckedContinuation { continuation in
                finishing = continuation
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    // Only this wait: a later one has its own.
                    if self.session == session { self.resumeFinish() }
                }
            }
        }
        // At least a second of "Milu đang hiểu ý bạn…", as the server will take (user request
        // 2026-11-10): Apple's answer is near instant, and a flash reads as a glitch.
        let shown = Date.now.timeIntervalSince(began)
        if !finishCancelled, shown < Self.minimumTranscribing {
            try? await Task.sleep(for: .seconds(Self.minimumTranscribing - shown))
        }
        let heardOnServer = await server.value
        if finishCancelled {
            finishCancelled = false
            return nil
        }
        task?.cancel()
        task = nil
        generation += 1
        commitPartial()
        // The server's words when it gave any; the iPhone's otherwise.
        if let heardOnServer, !heardOnServer.isEmpty { transcript = heardOnServer }
        // Still "transcribing" until the caller has put the words in: both change in one go.
        return transcript
    }

    /// The recording's words from the app's server, nil without it (no server set, no network,
    /// too slow, an error); the file is removed either way.
    private nonisolated static func serverTranscript(of recording: URL?, names: [String]) async -> String? {
        guard let recording else { return nil }
        defer { try? FileManager.default.removeItem(at: recording) }
        guard let api = MiluAPI.shared, let audio = try? Data(contentsOf: recording), audio.count > 1_000 else { return nil }
        let text = try? await api.transcribe(audio, names: names, timeout: serverTimeout)
        return text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Ends "Milu đang hiểu ý bạn…", called with the heard words going into the field, in the
    /// same animation: the field grows to its new height and the buttons stay at its foot (user
    /// report 2026-11-10: on a two-line answer they first showed a line up, then slid down).
    func endTranscribing() {
        isTranscribing = false
    }

    private func resumeFinish() {
        finishing?.resume()
        finishing = nil
    }

    // MARK: - Phiên nghe

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
        guard isRecording || isTranscribing, generation == self.generation else { return }
        if let text {
            failedStretches = 0
            // The recognizer started the words over after a pause: keep the earlier ones.
            if DictationText.restarted(from: partial, to: text) { commitPartial() }
            partial = text
            updateTranscript()
        }
        if isTranscribing {
            if isFinal || failed { resumeFinish() }
            return
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

    /// Adds the levels that are due, however late the timer fires.
    private func startClock() {
        startedAt = .now
        levelTotal = 0
        let timer = Timer(timeInterval: Self.tickInterval / 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        guard isRecording else { return }
        let due = Int(Date.now.timeIntervalSince(startedAt) / Self.tickInterval)
        guard due > levelTotal else { return }
        var next = levels
        while levelTotal < due {
            next.removeFirst()
            next.append(peak)
            // Falls away between words rather than dropping at once.
            peak *= 0.4
            levelTotal += 1
        }
        levels = next
    }

    private func hear(_ level: Float) {
        guard isRecording else { return }
        peak = max(peak, level)
    }

    // The tap and the recognizer call back on background queues. Build those closures in
    // nonisolated functions so they are not MainActor-isolated (the project's default),
    // which would trap at runtime, and hop to the main actor before touching state.
    private nonisolated static func levelHandler(for dictation: SpeechDictation) -> @Sendable (Float) -> Void {
        { [weak dictation] level in
            guard let dictation else { return }
            Task { @MainActor in dictation.hear(level) }
        }
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

    private static var alreadyAllowed: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
            && AVAudioApplication.shared.recordPermission == .granted
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

/// The microphone and the audio session, on a serial queue of their own so the main thread never
/// waits on them; a stop queued behind a start runs after it.
private nonisolated final class Microphone: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let queue = DispatchQueue(label: "com.quyetnguyen.Milu.microphone", qos: .userInitiated)
    /// What is heard, kept for the server (`SpeechDictation.finish`).
    private let recording = Recording()

    /// The category set once, not at every start: changing it is what reconfigures the audio
    /// route, and it was done in the very moment the microphone came on.
    func prepare() {
        queue.async { try? Self.configure(AVAudioSession.sharedInstance()) }
    }

    private static func configure(_ session: AVAudioSession) throws {
        guard session.category != .record || session.mode != .measurement else { return }
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        // The tick of a question sent (↑) plays while listening as it does otherwise: iOS keeps
        // haptics quiet while it records, unless told (`Haptics`).
        try? session.setAllowHapticsAndSystemSoundsDuringRecording(true)
    }

    func start(feed: RequestFeed, onLevel: @escaping @Sendable (Float) -> Void,
               completion: @escaping @Sendable (Bool) -> Void) {
        queue.async { [self] in
            do {
                let session = AVAudioSession.sharedInstance()
                try Self.configure(session)
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                let input = engine.inputNode
                let format = input.outputFormat(forBus: 0)
                recording.begin(format: format)
                input.installTap(onBus: 0, bufferSize: 1024, format: format) { [recording] buffer, _ in
                    feed.append(buffer)
                    recording.write(buffer)
                    onLevel(Self.level(of: buffer))
                }
                engine.prepare()
                try engine.start()
                completion(true)
            } catch {
                teardown()
                completion(false)
            }
        }
    }

    /// Stops, and hands back the recording of what was heard, closed (nil when nothing was).
    func stop(_ completion: @escaping @Sendable (URL?) -> Void = { _ in }) {
        queue.async { [self] in
            teardown()
            completion(recording.end())
        }
    }

    private func teardown() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// The buffer's loudness, 0 (−50 dB and below, a quiet room) to 1 (−10 dB, speaking close).
    private static func level(of buffer: AVAudioPCMBuffer) -> Float {
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for index in 0..<count { sum += samples[index] * samples[index] }
        let rms = (sum / Float(count)).squareRoot()
        let decibels = 20 * log10(max(rms, 0.000_01))
        return min(max((decibels + 50) / 40, 0), 1)
    }
}

/// The microphone's sound written to an M4A (AAC) file as it comes, for the server: small (a
/// sentence is a few tens of kB), and read by its recognizer as it reads what browsers record.
/// Written on the audio thread, begun and ended on the microphone's queue, behind a lock.
private nonisolated final class Recording: @unchecked Sendable {
    private let lock = NSLock()
    private var file: AVAudioFile?
    private var url: URL?

    func begin(format: AVAudioFormat) {
        lock.withLock {
            let url = FileManager.default.temporaryDirectory.appending(path: "dictation-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: format.channelCount,
                AVEncoderBitRateKey: 48_000,
            ]
            file = try? AVAudioFile(forWriting: url, settings: settings,
                                    commonFormat: format.commonFormat, interleaved: format.isInterleaved)
            self.url = file == nil ? nil : url
        }
    }

    func write(_ buffer: AVAudioPCMBuffer) {
        lock.withLock { try? file?.write(from: buffer) }
    }

    /// Closed (released) and handed over; the next `begin` starts a new one.
    func end() -> URL? {
        lock.withLock {
            file = nil
            defer { url = nil }
            return url
        }
    }
}

/// The request the microphone's tap feeds, behind a lock: the tap runs on the audio thread while
/// a new stretch swaps the request on the main one.
private nonisolated final class RequestFeed: @unchecked Sendable {
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
