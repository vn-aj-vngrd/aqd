import Foundation
import Observation
import AVFoundation
@preconcurrency import Speech

/// User-enabled on-device dictation; actual permission/locale readiness is checked before recording.
@MainActor @Observable final class AgentVoiceModel {
    enum Phase { case permission, listening, transcribing, review, unavailable }
    static let qualified = true
    static var isSupported: Bool { qualified && SFSpeechRecognizer(locale: Locale.current)?.supportsOnDeviceRecognition == true }
    var phase: Phase = qualified ? .permission : .unavailable
    var transcript = ""
    var reason = "On-device voice input isn’t enabled yet. Keep typing; your draft and context stay."
    var startedAt: Date?
    var level: Float = 0
    private let engine = AVAudioEngine()
    private var recognition: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var token = UUID()
    private var tapInstalled = false
    func begin() async {
        guard Self.qualified else { phase = .unavailable; return }
        let current = UUID(); token = current
        let status = await withCheckedContinuation { continuation in SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) } }
        guard token == current else { return }
        guard status == .authorized, await AVAudioApplication.requestRecordPermission() else {
            reason = "Microphone or speech access is off. Enable it in iPhone Settings, or keep typing."; phase = .unavailable; return
        }
        guard token == current, let recognizer = SFSpeechRecognizer(locale: Locale.current), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            reason = "On-device speech recognition is unavailable for this language. Keep typing."; phase = .unavailable; return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest(); request.requiresOnDeviceRecognition = true; request.shouldReportPartialResults = true
            self.request = request; transcript = ""
            let input = engine.inputNode, format = engine.inputNode.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else { throw CocoaError(.featureUnsupported) }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                request.append(buffer)
                if let values = buffer.floatChannelData?.pointee {
                    let count = Int(buffer.frameLength)
                    let magnitude = count > 0 ? (0..<count).reduce(Float(0)) { $0 + abs(values[$1]) } / Float(count) : 0
                    Task { @MainActor [weak self] in if self?.token == current { self?.level = magnitude } }
                }
            }
            tapInstalled = true
            recognition = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString, final = result?.isFinal ?? false, failed = error != nil
                Task { @MainActor [weak self] in
                    guard let self, token == current else { return }
                    if let text { transcript = text }
                    if final || failed {
                        stopAudio()
                        if !transcript.isEmpty { phase = .review }
                        else { reason = failed ? "Transcription could not finish. Record again or keep typing." : "No speech was detected. Record again or keep typing."; phase = .unavailable }
                    }
                }
            }
            engine.prepare(); try engine.start(); startedAt = Date(); phase = .listening
        } catch { stopAudio(); reason = "Recording could not start. Your draft is retained. Keep typing or try again."; phase = .unavailable }
    }
    func finishRecording() { guard phase == .listening else { return }; stopAudio(); phase = .transcribing }
    private func stopAudio() {
        if engine.isRunning { engine.stop() }
        if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
        request?.endAudio(); level = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    func discard() { token = UUID(); stopAudio(); recognition?.cancel(); recognition = nil; request = nil; transcript = ""; startedAt = nil }
    func interrupt() { let received = transcript; discard(); transcript = received; reason = "Recording was interrupted. Your typed draft and any received transcript are retained."; phase = received.isEmpty ? .unavailable : .review }
}

/// A reviewed transcript is appended once, even when its retained save needs retry.
@MainActor struct AgentTranscriptReview {
    private(set) var hasApplied = false
    mutating func apply(_ transcript: String, to model: AgentModel) -> Bool {
        if !hasApplied {
            model.updateDraft(model.conversation.draft + (model.conversation.draft.isEmpty ? "" : "\n") + transcript)
            hasApplied = true
        }
        return model.persist()
    }
}
