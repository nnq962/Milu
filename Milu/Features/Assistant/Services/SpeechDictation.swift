//
//  SpeechDictation.swift
//  Milu
//

import AVFoundation
import Observation
import Speech
import UIKit

/// Vietnamese speech-to-text for the chat field: the app's server first (its Zipformer model,
/// which knows the banks' names), the iPhone's recognizer when the server cannot be had (user
/// choice 2026-11-12). Both hear the same words: the iPhone's recognizer runs as it listens, and
/// the sound is kept in a file the server reads once the user is done, so falling back waits for
/// nothing.
///
/// Listens until the user stops it (■, ✕ or ↑) or it ends by itself (`autoEnd`: 30 seconds at
/// most, 2 seconds quiet once something was said, 6 with nothing said; user choice 2026-11-17).
/// Within that a pause is kept: the recognizer ends a stretch after a silence, or starts the words
/// over, so each finished stretch is kept and a new one is started on the same microphone (user
/// report 2026-11-09: after a pause the earlier sentence was gone and it had to be said again).
@Observable
final class SpeechDictation {
    enum Failure: Equatable {
        case denied, unavailable, audio
        /// Listening ended by itself: why, and whether anything was heard (it is then in
        /// `heardWhenStopped`, for the field).
        case stopped(StopReason, heard: Bool)

        var isStopped: Bool {
            if case .stopped = self { return true }
            return false
        }
    }

    /// Why listening ended by itself (audit round 5, 2026-11-16: the alert always blamed the
    /// network or a call, and said the words were in the field when none were heard).
    enum StopReason: Equatable {
        /// Milu went to the background: the user left it.
        case leftApp
        /// A call or another app took the sound.
        case interrupted
        /// The recognizer kept failing, or went away (often the network).
        case recognizer
    }

    /// What was heard when listening ended by itself, for the field; taken once.
    private(set) var heardWhenStopped: String?
    /// Set once while listening, when it should end by itself (`DictationAutoStop`): the page
    /// sends what was heard, or stops when nothing was said. Cleared at each start.
    private(set) var autoEnd: DictationAutoStop.End?

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
    /// `start` is waiting for iOS's permission prompts.
    @ObservationIgnored private var isStarting = false
    /// The stretches already finished, and the words of the one being heard.
    @ObservationIgnored private var committed = ""
    @ObservationIgnored private var partial = ""
    /// Stretches ended by an error in a row; past a few, it stops instead of trying again.
    @ObservationIgnored private var failedStretches = 0
    /// The loudest moment since the last step of the wave.
    @ObservationIgnored private var peak: Float = 0
    /// The loudest moment in the step under way, for `autoStop` (`peak` fades for the wave).
    @ObservationIgnored private var stepPeak: Float = 0
    @ObservationIgnored private var autoStop = DictationAutoStop()
    /// The words at the last step, to tell `autoStop` when new ones came.
    @ObservationIgnored private var wordsAtStep = ""
    @ObservationIgnored private var timer: Timer?
    /// `finish()` waiting for the recognizer's last word, and whether ✕ ended that wait.
    @ObservationIgnored private var finishing: CheckedContinuation<Void, Never>?
    @ObservationIgnored private var finishCancelled = false
    /// Names the server's recognizer should favour: the user's accounts, the banks and wallets.
    @ObservationIgnored var hotwords: [String] = []
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    /// While listening: a call, Siri or another app taking the sound, or Milu going to the
    /// background, ends it as if by itself (audit round 4, 2026-11-16: the wave stayed, hearing
    /// nothing). Watched only while listening, and let go after.
    private func watchInterruptions() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil,
                                            queue: .main) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            guard raw.flatMap(AVAudioSession.InterruptionType.init(rawValue:)) == .began else { return }
            MainActor.assumeIsolated { self?.endOnItsOwn(.interrupted) }
        })
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil,
                                            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.endOnItsOwn(.leftApp) }
        })
    }

    private func stopWatchingInterruptions() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
    }

    /// The words heard when listening ended by itself, once.
    func takeHeardWhenStopped() -> String? {
        defer { heardWhenStopped = nil }
        return heardWhenStopped
    }

    /// Listening ended without ■ or ✕: the words heard so far go to the field and the page says
    /// why, rather than everything going silently (audit round 4, 2026-11-16).
    /// Left the app with nothing heard: nothing to say, the user knows why it stopped.
    private func endOnItsOwn(_ reason: StopReason) {
        guard isRecording else { return }
        commitPartial()
        let heard = transcript
        stop()
        if !heard.isEmpty { heardWhenStopped = heard }
        if reason == .leftApp, heard.isEmpty { return }
        failure = .stopped(reason, heard: !heard.isEmpty)
    }
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
        guard !isRecording, !isStarting else { return }
        #if DEBUG
        if let sentence = Self.nextFakeSentence() {
            startFake(sentence)
            return
        }
        #endif
        // Already allowed: no hop off the main thread, so the wave shows the moment the mic is
        // tapped (seen in testing 2026-11-10: it came a beat late).
        // No Face ID cover over iOS's prompts for speech and the microphone (`AppLock.whileSystemAsks`).
        // A second tap while iOS gets its prompt ready waits for nothing: two starts put two taps
        // on the microphone, and AVAudioEngine stops the app (audit 2026-11-15).
        isStarting = true
        let allowed = Self.alreadyAllowed ? true : await AppLock.shared.whileSystemAsks { await Self.requestPermissions() }
        isStarting = false
        guard !isRecording else { return }
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
        stepPeak = 0
        autoStop = DictationAutoStop()
        autoEnd = nil
        wordsAtStep = ""
        levels = [Float](repeating: 0, count: Self.levelCount)
        isRecording = true
        watchInterruptions()
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
        #if DEBUG
        if Self.fakeSentences != nil {
            fakeTask?.cancel()
            if isTranscribing { finishCancelled = true }
            isRecording = false
            isTranscribing = false
            return
        }
        #endif
        endStretch()
        if isTranscribing {
            finishCancelled = true
            resumeFinish()
        }
        isRecording = false
        isTranscribing = false
        stopWatchingInterruptions()
        session += 1
        microphone.stop { url in url.map { try? FileManager.default.removeItem(at: $0) } }
    }

    /// Stops listening and turns what was said into words: nil when ✕ came first.
    func finish() async -> String? {
        guard isRecording else { return nil }
        timer?.invalidate()
        timer = nil
        #if DEBUG
        if Self.fakeSentences != nil { return await finishFake() }
        #endif
        isRecording = false
        stopWatchingInterruptions()
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
        guard isRecording, let recognizer, recognizer.isAvailable else { return endOnItsOwn(.recognizer) }
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
                endOnItsOwn(.recognizer)
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

    #if DEBUG
    // MARK: - Giọng giả (chỉ bản DEBUG, để thử trên Simulator)

    /// Sentences "heard" with no microphone, one per listening (the last one again after that),
    /// for trying the voice flow on the Simulator, whose microphone is the Mac's (often the
    /// user's headphones): launched with `MILU_FAKE_VOICE="cà phê 35k, gửi xe 5k|tạo mới hết"`.
    /// Never in a build for the App Store or TestFlight.
    private static let fakeSentences: [String]? = ProcessInfo.processInfo.environment["MILU_FAKE_VOICE"]
        .map { $0.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) } }
        .flatMap { $0.isEmpty ? nil : $0 }
    private static var fakeHeard = 0
    @ObservationIgnored private var fakeTask: Task<Void, Never>?

    private static func nextFakeSentence() -> String? {
        guard let sentences = fakeSentences else { return nil }
        defer { fakeHeard += 1 }
        return sentences[min(fakeHeard, sentences.count - 1)]
    }

    /// The words come one by one with the wave, then nothing: the real clock and `autoStop` end
    /// it after the usual pause, as for speech.
    private func startFake(_ sentence: String) {
        transcript = ""
        peak = 0
        stepPeak = 0
        autoStop = DictationAutoStop()
        autoEnd = nil
        wordsAtStep = ""
        finishCancelled = false
        levels = [Float](repeating: 0, count: Self.levelCount)
        isRecording = true
        startClock()
        let words = sentence.split(separator: " ").map(String.init)
        fakeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.8))
            for count in 1...max(words.count, 1) {
                for _ in 0..<3 {
                    guard let self, self.isRecording, !Task.isCancelled else { return }
                    self.hear(Float.random(in: 0.35...0.85))
                    try? await Task.sleep(for: .seconds(0.1))
                }
                guard let self, self.isRecording, !Task.isCancelled else { return }
                self.transcript = words.prefix(count).joined(separator: " ")
            }
        }
    }

    /// A second or so of "Đang chuyển thành chữ", as the server takes; nil when ✕ came first.
    private func finishFake() async -> String? {
        fakeTask?.cancel()
        isRecording = false
        isTranscribing = true
        try? await Task.sleep(for: .seconds(1.2))
        if finishCancelled {
            finishCancelled = false
            return nil
        }
        return transcript
    }
    #endif

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
        var end: DictationAutoStop.End?
        while levelTotal < due {
            next.removeFirst()
            next.append(peak)
            // Falls away between words rather than dropping at once.
            peak *= 0.4
            levelTotal += 1
            end = end ?? autoStop.step(level: stepPeak, newWords: transcript != wordsAtStep,
                                      at: Double(levelTotal) * Self.tickInterval)
            stepPeak = 0
            wordsAtStep = transcript
        }
        levels = next
        if autoEnd == nil, let end { autoEnd = end }
    }

    private func hear(_ level: Float) {
        guard isRecording else { return }
        peak = max(peak, level)
        stepPeak = max(stepPeak, level)
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

/// When listening ends by itself (user choice 2026-11-17: "30s · im 2s · chưa nói 6s", and what
/// was heard is sent at once): at most 30 seconds; once something was said, 2 seconds with no
/// voice and no new word; with nothing said, after 6 seconds. One step every
/// `SpeechDictation.tickInterval`, fed the loudest moment of that step.
///
/// Voice is sound well over the room's own: the quietest the room has been is followed down at
/// once and up slowly, so a fan or a café's murmur stops counting as voice after a few seconds,
/// while a pause between words does not raise it. The recognizer's new words count too.
nonisolated struct DictationAutoStop: Equatable {
    enum End: Equatable {
        /// Something was said, then nothing for `pauseAfterWords`.
        case paused
        /// `longest` reached.
        case timeUp
        /// Nothing said in `waitForWords`.
        case nothingSaid
    }

    static let longest: TimeInterval = 30
    static let pauseAfterWords: TimeInterval = 2
    static let waitForWords: TimeInterval = 6
    /// The field counts down the last seconds of `longest`.
    static let countdown: TimeInterval = 5

    /// Loud enough to be voice in a quiet room (about −38 dB), and how far over the room's own
    /// sound it must be elsewhere.
    static let voiceLevel: Float = 0.3
    static let overRoom: Float = 0.15
    /// How fast the room's level is followed up, each step (0.1 a second).
    static let roomRise: Float = 0.01
    /// Steps of voice before it counts as speaking (0.3 s): a door or a cough alone is not.
    static let speakingSteps = 3

    private(set) var room: Float = 1
    private(set) var spoke = false
    private var voiceSteps = 0
    private var lastActive: TimeInterval = 0

    /// One step `at` seconds since listening began: `level` its loudest moment (0…1), `newWords`
    /// whether the recognizer's words changed in it. The end, once one is due.
    mutating func step(level: Float, newWords: Bool, at time: TimeInterval) -> End? {
        room = min(level, room + Self.roomRise)
        let voice = level >= max(Self.voiceLevel, room + Self.overRoom)
        if voice { voiceSteps += 1 }
        if newWords || voiceSteps >= Self.speakingSteps { spoke = true }
        if voice || newWords { lastActive = time }
        if time >= Self.longest { return .timeUp }
        if spoke { return time - lastActive >= Self.pauseAfterWords ? .paused : nil }
        return time >= Self.waitForWords ? .nothingSaid : nil
    }
}
