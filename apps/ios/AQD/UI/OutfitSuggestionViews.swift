import AQDCore
import SwiftUI

struct OutfitReadinessContent: View {
    @Bindable var model: OutfitEditorModel
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(model.readiness.isReady ? "Ready to build an outfit." : "A look around this piece.")
                .font(AppTypography.section)
            Text(model.readiness.isReady ? "Your available pieces can make a complete look. Keep your pinned piece at the center." : "Add the missing categories, or build a partial look manually.")
                .foregroundStyle(AppTheme.secondary)
            if !model.readiness.unavailablePins.isEmpty {
                Text("Your pinned piece is unavailable. Restore its availability, unpin it or build manually.")
                    .foregroundStyle(AppTheme.secondary)
            }
            ForEach(model.readiness.form.categories, id: \.self) { category in
                Label("\(category.rawValue) · \(model.readiness.missingCategories.contains(category) ? "Needed" : "Available")",
                      systemImage: model.readiness.missingCategories.contains(category) ? "plus.circle" : "checkmark.circle")
                    .frame(minHeight: 44)
            }
            ForEach(model.readiness.missingCategories, id: \.self) { category in
                PrimaryAction(title: "Add \(category.rawValue.lowercased())") { model.addMissingPiece(category) }
            }
            if model.readiness.isReady {
                PrimaryAction(title: "Suggest an outfit") { model.update { $0.stage = .suggest } }
            }
            SecondaryAction(title: "Build manually") { model.update { $0.stage = .builder } }
            if let error = model.error { SemanticFeedback(role: .danger, message: error) }
        }
    }
}

struct OutfitSuggestionContent: View {
    @Bindable var model: OutfitEditorModel
    @State private var weather = false
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabeledField(title: "Occasion", text: Binding(get: { model.draft.occasion ?? "" }, set: { value in model.update { $0.occasion = value } }))
                .disabled(model.generating)
            LabeledField(title: "Mood", text: Binding(get: { model.draft.mood ?? "" }, set: { value in model.update { $0.mood = value } }))
                .disabled(model.generating)
            DisclosureRow(title: "Weather context", value: model.draft.weather?.place.name ?? "Off") { weather = true }.disabled(model.generating || model.pending || model.unknown)
            Text(model.suggestionAvailability.message).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            if model.generating {
                ProgressView("Preparing an on-device draft…")
                SecondaryAction(title: "Stop") { model.stopGeneration() }
            } else {
                if model.suggestionAvailability == .available {
                    PrimaryAction(title: "Suggest outfit") { model.suggestOnDevice() }
                        .disabled(!model.readiness.isReady)
                } else {
                    SecondaryAction(title: "Check again") { model.suggestionAvailability = OutfitSuggestions.availability() }
                }
                PrimaryAction(title: "Use a rule-based combination") { model.useRules() }
                    .disabled(!model.readiness.isReady)
                Text("Rules use available categories and your pins; they don’t use AI.")
                    .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                SecondaryAction(title: "Build manually") { model.update { $0.stage = .builder } }
            }
            if let error = model.error { SemanticFeedback(role: .danger, message: error) }
        }
        .sheet(isPresented: $weather) {
            if let client = model.state.weatherClient {
                WeatherContextView(client: client, initial: model.draft.weather) { selection in model.update { $0.weather = selection }; return model.draft.weather == selection && model.error == nil }
            }
        }
        .onAppear { model.suggestionAvailability = OutfitSuggestions.availability() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.suggestionAvailability = OutfitSuggestions.availability() }
            else { model.stopGeneration() }
        }
    }
}

struct OutfitReplacementView: View {
    @Bindable var model: OutfitEditorModel
    let pieceID: UUID
    @State private var selected: UUID?
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    private var replacements: [WardrobePiece] {
        guard let original = model.state.pieces.first(where: { $0.id == pieceID }) else { return [] }
        return model.state.pieces.filter {
            $0.category == original.category && !$0.isArchived && $0.availability == .available && !model.draft.pieceIDs.contains($0.id)
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Replace only this piece. Your pinned pieces, outfit name and other selections stay in place.")
                    .foregroundStyle(AppTheme.secondary)
                if replacements.isEmpty {
                    AppEmptyState("No available replacement", systemImage: "tshirt", description: Text("Add another piece in this category, or keep your current selection."))
                }
                ForEach(replacements) { piece in
                    Button { selected = piece.id } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(height: 170)
                            Label(piece.name, systemImage: selected == piece.id ? "checkmark.circle.fill" : "circle")
                        }
                    }.buttonStyle(.plain).accessibilityValue(selected == piece.id ? "Selected replacement" : "Not selected")
                }
                if let error { SemanticFeedback(role: .danger, message: error) }
                PrimaryAction(title: "Use replacement") {
                    do {
                        guard let selected else { return }
                        var updated = model.draft
                        try updated.replace(pieceID, with: selected, pieces: model.state.pieces)
                        model.update { $0 = updated }
                        if model.error == nil { dismiss() }
                    } catch { self.error = "The selection changed. Keep the current draft and review its pieces again." }
                }.disabled(selected == nil || model.pending || model.unknown || model.generating)
            }.padding(20)
        }.background(AppTheme.canvas)
            .navigationTitle("Replace a piece").navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.ink)
    }
}
