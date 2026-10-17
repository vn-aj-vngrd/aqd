import AQDCore
import AVFoundation
import NaturalLanguage
import Observation

@MainActor @Observable final class AgentReadAloud: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var messageID: UUID?
    private(set) var errorMessageID: UUID?
    private(set) var error: String?
    private let synthesizer = AVSpeechSynthesizer()
    private var utteranceID: ObjectIdentifier?

    override init() {
        super.init()
        synthesizer.delegate = self
    }
    func toggle(_ message: AgentMessage) {
        if messageID == message.id { stop(); return }
        stop()
        let text = AgentMarkdownPolicy.spokenText(AgentMarkdownPolicy.conversationalText(message.source))
        guard !text.isEmpty else { return }
        let language = NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue ?? Locale.current.language.languageCode?.identifier ?? "en"
        guard let voice = AVSpeechSynthesisVoice(language: language) else {
            errorMessageID = message.id; error = "A reading voice isn’t available for this language on your iPhone."
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            let utterance = AVSpeechUtterance(string: (message.status == .complete ? "" : "Incomplete response. ") + text)
            utterance.voice = voice
            utteranceID = ObjectIdentifier(utterance); messageID = message.id
            synthesizer.speak(utterance)
        } catch {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            errorMessageID = message.id; self.error = "Read Aloud couldn’t start. Check your audio output and try again."
        }
    }
    func stop() {
        let hadUtterance = utteranceID != nil
        utteranceID = nil; messageID = nil; error = nil; errorMessageID = nil
        synthesizer.stopSpeaking(at: .immediate)
        if hadUtterance { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finished(ObjectIdentifier(utterance))
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finished(ObjectIdentifier(utterance))
    }
    private nonisolated func finished(_ id: ObjectIdentifier) {
        Task { @MainActor [weak self] in
            guard let self, self.utteranceID == id else { return }
            self.stop()
        }
    }
}
