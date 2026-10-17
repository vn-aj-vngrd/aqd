import SwiftUI
import UIKit

/// Inline dictation keeps recording controls in the same glass surface as the message draft.
struct AgentVoiceView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var model: AgentModel
    @Binding var isPresented: Bool
    @State private var voice = AgentVoiceModel()
    @State private var transcriptReview = AgentTranscriptReview()
    @State private var useWhenFinished = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if voice.phase == .review {
                TextField("Your message", text: $voice.transcript, axis: .vertical)
                    .lineLimit(1...6).disabled(transcriptReview.hasApplied)
                    .accessibilityLabel("Recorded transcript")
            } else if voice.phase == .unavailable {
                Text(voice.reason).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }
            HStack(spacing: AppSpacing.small) {
                Button { voice.discard(); isPresented = false } label: {
                    control("xmark", filled: false)
                }.accessibilityLabel(transcriptReview.hasApplied ? "Return to draft" : "Cancel recording")
                Group {
                    switch voice.phase {
                    case .permission:
                        HStack { ProgressView(); Text("Preparing microphone…").font(AppTypography.supporting) }
                    case .listening:
                        waveform
                    case .transcribing:
                        HStack { ProgressView(); Text("Finishing…").font(AppTypography.supporting) }
                    case .review:
                        Text(transcriptReview.hasApplied ? "Transcript kept in draft" : "Review before sending")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    case .unavailable:
                        HStack {
                            Button("Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                            Button("Try again") { Task { await voice.begin() } }
                        }.font(AppTypography.supporting)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                if voice.phase == .listening {
                    Button { voice.finishRecording() } label: { control("stop.fill", filled: false) }
                        .accessibilityLabel("Stop and review recording")
                } else if voice.phase == .review && !transcriptReview.hasApplied {
                    Button { voice.discard(); Task { await voice.begin() } } label: { control("mic", filled: false) }
                        .accessibilityLabel("Record again")
                }
                if voice.phase == .listening || voice.phase == .review || voice.phase == .transcribing {
                    Button {
                        if voice.phase == .listening { useWhenFinished = true; voice.finishRecording() }
                        else { useTranscript() }
                    } label: { control("arrow.up", filled: true) }
                        .accessibilityLabel(transcriptReview.hasApplied ? "Retry saving transcript" : "Use transcript in draft")
                        .disabled(voice.phase == .transcribing || (voice.phase == .review && voice.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                }
            }.buttonStyle(.plain)
            if voice.phase == .listening, let startedAt = voice.startedAt {
                HStack(spacing: AppSpacing.small) {
                    Text("Recording")
                    Text(startedAt, style: .timer).monospacedDigit()
                    Spacer()
                    Text("On this iPhone")
                }.font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).padding(.horizontal, AppSpacing.small)
            }
        }.task { await voice.begin() }
            .onChange(of: voice.phase) { _, phase in
                if phase == .review && useWhenFinished { useWhenFinished = false; useTranscript() }
                if phase == .unavailable { useWhenFinished = false }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active && (voice.phase == .listening || voice.phase == .transcribing) {
                    useWhenFinished = false; voice.interrupt()
                }
            }
            .onDisappear { voice.discard() }
    }

    private var waveform: some View {
        HStack(spacing: 3) {
            ForEach(voice.levels.indices, id: \.self) { index in
                Capsule().fill(AppTheme.controlIcon.opacity(0.4 + Double(index) / 60))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(3, CGFloat(voice.levels[index]) * 28))
            }
        }.frame(height: 32).accessibilityElement(children: .ignore)
            .accessibilityLabel("Live microphone level")
    }
    private func control(_ symbol: String, filled: Bool) -> some View {
        Image(systemName: symbol).font(.body.weight(.semibold))
            .foregroundStyle(filled ? AppTheme.onPrimary : AppTheme.ink)
            .frame(width: 32, height: 32)
            .background(filled ? AppTheme.primaryFill : AppTheme.segmentSelection, in: Circle())
            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
            .contentShape(Rectangle())
    }
    private func useTranscript() {
        guard !voice.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if transcriptReview.apply(voice.transcript, to: model) { voice.discard(); isPresented = false }
    }
}
