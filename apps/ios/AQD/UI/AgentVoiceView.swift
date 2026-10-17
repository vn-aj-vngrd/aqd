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
    @State private var detent = PresentationDetent.medium
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch voice.phase {
                    case .permission:
                        VStack(spacing: AppSpacing.section) {
                            VStack(spacing: AppSpacing.small) {
                                Text("Speak your message").font(.title2.weight(.semibold))
                                Text("Review the transcript before adding it to chat.")
                                    .font(AppTypography.body).foregroundStyle(AppTheme.secondary)
                            }
                            recordControl(symbol: "mic.fill", title: "Start recording") { Task { await voice.begin() } }
                            Text("Tap to record").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                            Text("Transcribed on this iPhone. Nothing sends automatically.")
                                .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                        }.multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.vertical, AppSpacing.section)
                    case .listening:
                        VStack(spacing: AppSpacing.section) {
                            Text("Listening…").font(.title2.weight(.semibold))
                            if let startedAt = voice.startedAt { Text(startedAt, style: .timer).font(.title3.monospacedDigit()).foregroundStyle(AppTheme.secondary) }
                            recordControl(symbol: "stop.fill", title: "Finish recording") { voice.finishRecording() }
                            ProgressView(value: min(Double(voice.level) * 10, 1))
                                .tint(AppTheme.ink).accessibilityLabel("Measured microphone level")
                            Text("Tap to finish").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }.frame(maxWidth: .infinity).padding(.vertical, AppSpacing.large)
                        if !voice.transcript.isEmpty {
                            Text(voice.transcript).frame(maxWidth: .infinity, alignment: .leading)
                                .padding(AppSpacing.large).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                        }
                    case .transcribing:
                        VStack(spacing: AppSpacing.large) {
                            ProgressView()
                            Text("Finishing your transcript…").font(AppTypography.section)
                            Text("Nothing has been sent.").foregroundStyle(AppTheme.secondary)
                            Button("Stop transcription") { voice.interrupt() }.frame(minHeight: AppControlMetrics.minimumTarget)
                        }.frame(maxWidth: .infinity).padding(.vertical, AppSpacing.section)
                    case .review:
                        LabeledControl(title: "Transcript") {
                            TextField("Your message", text: $voice.transcript, axis: .vertical)
                                .lineLimit(4...12).disabled(transcriptReview.hasApplied)
                        }
                        AccessoryButton("Record again", systemImage: "arrow.counterclockwise") { voice.discard(); Task { await voice.begin() } }
                            .frame(minHeight: AppControlMetrics.minimumTarget).disabled(transcriptReview.hasApplied)
                        Text("Done adds this text to your draft. Send when you’re ready.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    case .unavailable:
                        VStack(spacing: AppSpacing.large) {
                            Image(systemName: "mic.slash").font(.largeTitle).foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                            Text("Voice isn’t available").font(AppTypography.section)
                            Text(voice.reason).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                            if AgentVoiceModel.qualified {
                                HStack(spacing: AppSpacing.large) {
                                    Button("Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                                    Button("Try again") { Task { await voice.begin() } }
                                }.frame(minHeight: AppControlMetrics.minimumTarget)
                            }
                        }.multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.vertical, AppSpacing.section)
                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                    if transcriptReview.hasApplied {
                        Text("Your transcript is in the chat draft. Retry saving it, or return to chat.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        SecondaryAction(title: "Retry saving transcript", action: useTranscript)
                    }
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
            .onChange(of: scenePhase) { _, phase in
                if phase != .active && (voice.phase == .listening || voice.phase == .transcribing) { voice.interrupt() }
            }
            .onChange(of: voice.phase == .review) { _, reviewing in if reviewing { detent = .large } }
            .presentationDetents([.medium, .large], selection: $detent)
            .presentationDragIndicator(.visible)
            .onDisappear { voice.discard() }
            .interactiveDismissDisabled(voice.phase == .listening || voice.phase == .transcribing || !voice.transcript.isEmpty)
    }
    private func recordControl(symbol: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.largeTitle).frame(width: 72, height: 72)
        }.neutralToolbarGlass().buttonBorderShape(.circle).tint(AppTheme.ink).accessibilityLabel(title)
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
