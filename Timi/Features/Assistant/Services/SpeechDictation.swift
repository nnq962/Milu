//
//  SpeechDictation.swift
//  Timi
//

import AVFoundation
import Observation
import Speech

/// Vietnamese speech-to-text for the chat field, using Apple's on-device/server recognizer.
@Observable
final class SpeechDictation {
    enum Failure: Equatable {
        case denied, unavailable, audio
    }

    private(set) var isRecording = false
    private(set) var transcript = ""
    var failure: Failure?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

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
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func beginSession(with recognizer: SFSpeechRecognizer) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // On the phone when it can: what is said stays on it, as Cài đặt's privacy note says
        // (review 2026-11-09: it went to Apple's servers).
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request
        transcript = ""

        let input = audioEngine.inputNode
        Self.installTap(on: input, feeding: request)
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true

        task = recognizer.recognitionTask(with: request, resultHandler: Self.resultHandler(for: self))
    }

    // The tap and the recognizer call back on background queues. Build those closures in
    // nonisolated functions so they are not MainActor-isolated (the project's default),
    // which would trap at runtime, and hop to the main actor before touching state.
    private nonisolated static func installTap(on input: AVAudioInputNode, feeding request: SFSpeechAudioBufferRecognitionRequest) {
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
    }

    private nonisolated static func resultHandler(for dictation: SpeechDictation) -> @Sendable (SFSpeechRecognitionResult?, Error?) -> Void {
        { [weak dictation] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            guard let dictation else { return }
            Task { @MainActor in
                if let text { dictation.transcript = text }
                if isFinal || failed { dictation.stop() }
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
