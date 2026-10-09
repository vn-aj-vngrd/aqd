import AQDCore
import SwiftUI

struct PieceDetailsView: View {
    let model: CaptureModel
    @Environment(\.dismiss) private var dismiss
    @State private var details: PieceDetails
    @State private var availability: PieceAvailability
    @State private var tagsText: String
    @State private var wearText: String
    @State private var discardDecision = false

    init(model: CaptureModel) {
        self.model = model
        _details = State(initialValue: model.draft.details)
        _availability = State(initialValue: model.draft.availability)
        _tagsText = State(initialValue: model.draft.details.tags.joined(separator: ", "))
        _wearText = State(initialValue: model.draft.details.priorWearCount.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Leave anything you don’t know blank. These details stay in the piece draft until you save it.")
                        .font(.subheadline).foregroundStyle(AppTheme.secondary)
                    field("Color", \.color)
                    field("Brand", \.brand)
                    field("Size", \.size)
                    field("Fit", \.fit)
                    field("Material", \.material)
                    field("Season", \.season)
                    field("Condition", \.condition)
                    field("Ownership age", \.ownershipAge)
                    CaptureField(title: "Tags, separated by commas", text: $tagsText)
                    CaptureField(title: "Prior wear estimate", text: $wearText)
                        .keyboardType(.numberPad)
                    Text("An estimate isn’t a dated wear record.").font(.footnote).foregroundStyle(AppTheme.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Availability").font(.subheadline)
                        Picker("Availability", selection: $availability) {
                            Text("Available").tag(PieceAvailability.available)
                            Text("Unavailable").tag(PieceAvailability.unavailable)
                            Text("Laundry").tag(PieceAvailability.laundry)
                        }
                        .pickerStyle(.menu).frame(minHeight: 52)
                    }
                    CaptureField(title: "Notes", text: $details.notes, multiline: true)
                    Text("Notes stay private and are not included in Agent context.")
                        .font(.footnote).foregroundStyle(AppTheme.secondary)
                    if !isValid {
                        Text("Use up to 80 characters per detail, 20 tags of 40 characters, and 2,000 characters in Notes. Prior wear is a whole-number estimate from 0 to 10,000.")
                            .font(.subheadline).foregroundStyle(AppTheme.error)
                    }
                }.padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.canvas)
            .navigationTitle("Details").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dirty ? (discardDecision = true) : dismiss() } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryAction(title: "Apply") {
                    model.applyDetails(editedDetails, availability: availability)
                    dismiss()
                }
                .disabled(!isValid).opacity(isValid ? 1 : 0.5)
                .padding(.horizontal, 20).padding(.vertical, 12).background(AppTheme.canvas)
            }
            .confirmationDialog("Discard these detail changes?", isPresented: $discardDecision, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            } message: {
                Text("Only this details edit will be discarded. The parent piece draft and saved piece are unchanged.")
            }
        }
        .tint(AppTheme.actionText)
        .interactiveDismissDisabled(dirty)
    }

    private var editedDetails: PieceDetails {
        var result = details
        result.tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        result.priorWearCount = wearText.isEmpty ? nil : Int(wearText)
        return result
    }

    private var dirty: Bool {
        details != model.draft.details || availability != model.draft.availability ||
        tagsText != model.draft.details.tags.joined(separator: ", ") ||
        wearText != (model.draft.details.priorWearCount.map(String.init) ?? "")
    }

    private var isValid: Bool {
        guard wearText.isEmpty || Int(wearText) != nil else { return false }
        return (try? editedDetails.validated()) != nil
    }

    private func field(_ title: String, _ path: WritableKeyPath<PieceDetails, String>) -> some View {
        CaptureField(title: title, text: Binding(get: { details[keyPath: path] }, set: { details[keyPath: path] = $0 }))
    }
}
