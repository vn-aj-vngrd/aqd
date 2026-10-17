import AQDCore
import SwiftUI

struct PieceDetailsView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Done") {
                            model.applyDetails(editedDetails, availability: availability)
                            dismiss()
                        }.disabled(!isValid)
    }

    let model: CaptureModel
    @Environment(\.dismiss) private var dismiss
    @State private var details: PieceDetails
    @State private var availability: PieceAvailability
    @State private var tagsText: String
    @State private var wearText: String
    @State private var discardDecision = false
    @FocusState private var notesFocused: Bool
    private let notesAnchor = "details.notes"

    init(model: CaptureModel) {
        self.model = model
        _details = State(initialValue: model.draft.details)
        _availability = State(initialValue: model.draft.availability)
        _tagsText = State(initialValue: model.draft.details.tags.joined(separator: ", "))
        _wearText = State(initialValue: model.draft.details.priorWearCount.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroll in
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
                        LabeledField(title: "Tags, separated by commas", text: $tagsText,
                                     accessibilityID: "capture.field.tags, separated by commas")
                        LabeledField(title: "Prior wear estimate", text: $wearText,
                                     accessibilityID: "capture.field.prior wear estimate")
                            .keyboardType(.numberPad)
                        Text("An estimate isn’t a dated wear record.").font(.footnote).foregroundStyle(AppTheme.secondary)
                        LabeledControl(title: "Availability") {
                            Menu {
                                Picker("Availability", selection: $availability) {
                                    Text("Available").tag(PieceAvailability.available)
                                    Text("Unavailable").tag(PieceAvailability.unavailable)
                                    Text("Laundry").tag(PieceAvailability.laundry)
                                }
                            } label: { MenuSelectionLabel(title: availability.rawValue.capitalized) }
                            .menuIndicator(.hidden).buttonStyle(.plain)
                            .accessibilityLabel("Availability")
                            .accessibilityValue(availability.rawValue.capitalized)
                        }
                        LabeledField(title: "Notes", text: $details.notes, multiline: true,
                                     accessibilityID: "capture.field.notes", editingFocus: $notesFocused)
                            .id(notesAnchor)
                        Text("Notes stay private and are not included in Agent context.")
                            .font(.footnote).foregroundStyle(AppTheme.secondary)
                        if !isValid {
                            Text("Use up to 80 characters per detail, 20 tags of 40 characters, and 2,000 characters in Notes. Prior wear is a whole-number estimate from 0 to 10,000.")
                                .font(.subheadline).foregroundStyle(AppTheme.error)
                        }
                    }.padding(20)
                }
                .scrollDismissesKeyboard(.immediately)
                // Keep the editor's end above the footer when the keyboard or
                // rotation shrinks the viewport. Top alignment hides later lines.
                .onChange(of: notesFocused) { _, focused in
                    if focused { scroll.scrollTo(notesAnchor, anchor: .bottom) }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { _ in
                    if notesFocused { scroll.scrollTo(notesAnchor, anchor: .bottom) }
                }
                .background(AppTheme.canvas)
                .navigationTitle("Details").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                confirmation
            } }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dirty ? (discardDecision = true) : dismiss() } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                    }
                }

                .appConfirmation("Discard these detail changes?", isPresented: $discardDecision) {
                    Button("Discard changes", role: .destructive) { dismiss() }
                    Button("Keep editing", role: .cancel) {}
                } message: {
                    Text("Only this details edit will be discarded. The parent piece draft and saved piece are unchanged.")
                }
            }
        }
        .tint(AppTheme.ink)
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
        LabeledField(title: title, text: Binding(get: { details[keyPath: path] }, set: { details[keyPath: path] = $0 }),
                     accessibilityID: "capture.field.\(title.lowercased())")
    }
}
