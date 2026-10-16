import SwiftUI
import UIKit

struct AgentVoiceView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Done") {
                            if transcriptReview.hasApplied || model.conversation.draft == base { useTranscript() } else { appendReview = true }
                        }.disabled(voice.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var model: AgentModel
    @State private var voice = AgentVoiceModel()
    @State private var base = ""
    @State private var transcriptReview = AgentTranscriptReview()
    @State private var discard = false
    @State private var appendReview = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch voice.phase {
                    case .permission:
                        Text("Use your voice").font(AppTypography.section)
                        Text("Speak, review the transcript, then send. Microphone and speech access are requested only after Continue. Recognition must run on this device; no cloud transcription.")
                        PrimaryAction(title: "Continue") { Task { await voice.begin() } }
                    case .listening:
                        Text("Listening…").font(AppTypography.section)
                        if let startedAt = voice.startedAt { Text(startedAt, style: .timer) }
                        ProgressView(value: min(Double(voice.level) * 10, 1)).accessibilityLabel("Measured microphone level")
                        Text(voice.transcript)
                        PrimaryAction(title: "Finish recording") { voice.finishRecording() }
                        SecondaryAction(title: "Discard recording") { voice.finishRecording(); discard = true }
                    case .transcribing:
                        ProgressView("Transcribing…")
                        Text("Your recording hasn’t been sent.")
                        SecondaryAction(title: "Cancel transcription") { voice.interrupt() }
                    case .review:
                        Text("Review your transcript").font(AppTypography.section)
                        TextField("Transcript", text: $voice.transcript, axis: .vertical).lineLimit(4...12).disabled(transcriptReview.hasApplied)

                        SecondaryAction(title: "Record again") { voice.discard(); Task { await voice.begin() } }.disabled(transcriptReview.hasApplied)
                        Text("Adds reviewed text to your draft. It never sends a message.").font(.footnote).foregroundStyle(AppTheme.secondary)
                    case .unavailable:
                        Text("Voice isn’t available").font(AppTypography.section)
                        Text(voice.reason)
                        if AgentVoiceModel.qualified { SecondaryAction(title: "Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }; SecondaryAction(title: "Record again") { Task { await voice.begin() } } }
                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                    if transcriptReview.hasApplied {
                        Text("Your transcript is in the chat draft. Retry saving it, or return to chat.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        SecondaryAction(title: "Retry saving transcript", action: useTranscript)
                    }
                    SecondaryAction(title: "Keep typing", action: safeExit)
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle("Voice input").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if voice.phase == .review { confirmation }
            } }
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(action: safeExit) { Image(systemName: "xmark") }.accessibilityLabel("Cancel") } }
                .alert("Discard this recording?", isPresented: $discard) {
                    Button("Cancel", role: .cancel) {}
                    Button("Discard recording", role: .destructive) { voice.discard(); dismiss() }
                } message: { Text("Discards only this unfinished recording and transcript. Your earlier typed draft stays.") }
                .alert("Your typed draft changed", isPresented: $appendReview) {
                    Button("Cancel", role: .cancel) {}
                    Button("Append transcript") { useTranscript() }
                } message: { Text("Keep your current text and append this reviewed transcript?") }
        }.tint(AppTheme.ink).onAppear { base = model.conversation.draft }
            .onChange(of: scenePhase) { _, phase in if phase != .active { voice.interrupt() } }
            .onDisappear { voice.discard() }
            .interactiveDismissDisabled(voice.phase == .listening || voice.phase == .transcribing || !voice.transcript.isEmpty)
    }
    private func safeExit() {
        if transcriptReview.hasApplied { voice.discard(); dismiss(); return }
        if voice.phase == .listening || voice.phase == .transcribing || !voice.transcript.isEmpty { voice.finishRecording(); discard = true }
        else { voice.discard(); dismiss() }
    }
    private func useTranscript() {
        if transcriptReview.apply(voice.transcript, to: model) { voice.discard(); dismiss() }
    }
}
