import AQDCore
import SwiftUI

struct AgentContextView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var state
    @Bindable var model: AgentModel
    @State private var draft: AgentContext
    @State private var weather = false
    @State private var query = ""
    @State private var category = "Pieces"
    init(model: AgentModel) { self.model = model; _draft = State(initialValue: model.conversation.context) }
    var body: some View {
        NavigationStack {
            Form {
                if let error = model.error { Text(error).foregroundStyle(AppTheme.error) }
                Section("Choose your context") {
                    Picker("Included scope", selection: $draft.scope) {
                        Text("My closet").tag(AgentContextScope.closet)
                        Text("Selected pieces").tag(AgentContextScope.selected)
                        Text("Without closet").tag(AgentContextScope.general)
                    }
                    if draft.scope != .general { Toggle("Recorded wear history", isOn: $draft.includesWear) }
                    Toggle("Style", isOn: $draft.includesStyle)
                    Button(draft.weather.map { "Weather · " + $0.place.name + " · " + $0.day.key } ?? "Weather · Off") { weather = true }
                    Text("Only fresh matching weather you explicitly select can inform a new request. Saved or unavailable weather is not current fact.").font(.footnote).foregroundStyle(AppTheme.secondary)
                    Text("Only allowed saved answers are included. Body details also need their separate use permission. Photos and private notes are excluded.").font(.footnote).foregroundStyle(AppTheme.secondary)
                }
                if draft.scope == .selected {
                    Section("Select local context") {
                        Picker("Category", selection: $category) { ForEach(["Pieces", "Outfits", "Themes"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
                        TextField("Search your closet", text: $query)
                        if let error = state.pieceReadError ?? state.outfitError ?? state.themeError {
                            Text(error); Button("Retry") { state.reloadPieces(); state.reloadOutfits(); state.reloadThemes() }
                        }
                        if category == "Pieces" {
                            ForEach(state.pieces.filter { matches($0.name) }) { value in row(value.name, record: AgentSelectedRecord(id: value.id, kind: .piece, revision: value.revision)) }
                        } else if category == "Outfits" {
                            ForEach(state.outfits.filter { matches($0.name) }) { value in row(value.name, record: AgentSelectedRecord(id: value.id, kind: .outfit, revision: value.revision)) }
                        } else {
                            ForEach(state.themes.filter { matches($0.name) }) { value in row(value.name, record: AgentSelectedRecord(id: value.id, kind: .theme, revision: value.revision)) }
                        }
                        Text("\(draft.selected.count) selected. Changed or unavailable records must be reviewed before sending.").font(.footnote)
                        if !draft.selected.isEmpty { Button("Clear selections") { draft.selected = [] } }
                        if state.pieces.isEmpty && state.outfits.isEmpty && state.themes.isEmpty { Text("Your closet is empty. Add a piece or choose Without closet.") }
                    }
                }
            }.navigationTitle("Agent context").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button { if !model.hasPendingOperation { dismiss() } } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Cancel") }
                    ToolbarItem(placement: .confirmationAction) { Button {
                        model.conversation.context = draft
                        if model.persist() { dismiss() }
                    } label: { Text("Done").frame(minWidth: 44, minHeight: 44) }.accessibilityLabel("Done") }
                }
        }.sheet(isPresented: $weather) { if let client = state.weatherClient { WeatherContextView(client: client, initial: draft.weather) { value in draft.weather = value; return true } } }
        .tint(AppTheme.ink).interactiveDismissDisabled(model.hasPendingOperation)
    }
    private func matches(_ name: String) -> Bool { query.isEmpty || name.localizedStandardContains(query) }
    private func row(_ name: String, record: AgentSelectedRecord) -> some View {
        let selected = draft.selected.contains { $0.kind == record.kind && $0.id == record.id }
        return Button {
            if selected { draft.selected.removeAll { $0.kind == record.kind && $0.id == record.id } }
            else {
                do {
                    let reviewed = try AgentContextSnapshot.selection(id: record.id, kind: record.kind, pieces: state.pieces, outfits: state.outfits, themes: state.themes)
                    draft.selected.append(reviewed)
                } catch { model.error = "This context changed or includes unavailable records. Refresh your closet and select it again." }
            }
        } label: { HStack { Text(name).foregroundStyle(AppTheme.ink); Spacer(); Image(systemName: selected ? "checkmark.circle.fill" : "circle").foregroundStyle(selected ? AppTheme.actionText : AppTheme.secondary) }.frame(minHeight: 44) }.accessibilityValue(selected ? "Selected" : "Not selected")
    }
}
