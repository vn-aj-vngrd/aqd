import AQDCore
import SwiftUI

struct OutfitWearEditorView: View {
    @Bindable var model: OutfitWearEditorModel
    @State private var discard = false
    @State private var choosing = false
    @State private var timezone = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let saved = model.saved {
                        Text(model.draft.baseRecord == nil ? "Wear recorded" : "Correction saved").font(AppTypography.section)
                        Text(saved.day.key).font(AppTypography.body)
                        ForEach(saved.pieces, id: \.id) { Text($0.name) }
                        NavigationLink("Open wear history") { LocalWearHistoryView() }.frame(minHeight: 44)
                        PrimaryAction(title: "Done") { model.finish() }
                    } else {
                        OutfitComposition(pieceIDs: model.draft.pieceIDs)
                        if model.draft.planEntry != nil {
                            Text("Recording for this planned date. Choose a different date to keep the plan unchanged.")
                                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                        LabeledControl(title: "Worn on") {
                            DatePicker("Worn on", selection: Binding(get: { (try? model.draft.day.date()) ?? Date() }, set: { value in
                                let zone = TimeZone(identifier: model.draft.day.timeZoneID) ?? .current
                                model.update { $0.day = LocalPlanDay(date: value, timeZone: zone); if $0.day != $0.planEntry?.day { $0.planEntry = nil } }
                            }), displayedComponents: .date)
                            .environment(\.timeZone, TimeZone(identifier: model.draft.day.timeZoneID) ?? .current)
                        }.disabled(model.pending || model.unknown)
                        DisclosureRow(title: "Pieces", value: "\(model.draft.pieceIDs.count) selected") { choosing = true }
                            .disabled(model.pending || model.unknown)
                        ForEach(model.draft.pieceIDs, id: \.self) { id in
                            Text(pieceName(id)).foregroundStyle(AppTheme.secondary)
                        }
                        DisclosureRow(title: "Timezone", value: model.draft.day.timeZoneID) { timezone = true }
                            .disabled(model.pending || model.unknown)
                        if let duplicate = model.duplicate {
                            Text("These pieces are already recorded on \(duplicate.day.key). Use that record to keep wear counted once.")
                                .foregroundStyle(AppTheme.secondary)
                            NavigationLink("View wear record") { LocalWearDetailView(id: duplicate.id) }.frame(minHeight: 44)
                            if model.draft.baseRecord == nil { PrimaryAction(title: "Use existing record", isPending: model.pending) { Task { await model.save(useExisting: true) } }
                                .disabled(!model.canSave || model.unknown) }
                            Text("Change the date or pieces above to record a different wear.").font(AppTypography.supporting)
                        }
                        if model.duplicate == nil || model.unknown {
                            PrimaryAction(title: model.unknown ? "Check save result" : model.draft.baseRecord == nil ? "Record wear" : "Save correction", isPending: model.pending) {
                                Task { await model.save() }
                            }.disabled(!model.unknown && !model.canSave)
                        }
                        Text("Planning a look does not record it as worn. Record only the pieces you actually wore, on that day.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }.background(AppTheme.canvas)
                .navigationTitle(model.saved == nil ? (model.draft.baseRecord == nil ? "Record wear" : "Correct wear") : "Wear saved").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if model.saved != nil { model.finish() } else { discard = true }
                    } label: { Image(systemName: model.saved == nil ? "xmark" : "checkmark") }
                        .tint(AppTheme.ink).accessibilityLabel(model.saved == nil ? "Cancel wear" : "Done")
                        .disabled(model.pending || model.unknown)
                } }
                .navigationDestination(isPresented: $timezone) {
                    TimezoneChooser(current: model.draft.day.timeZoneID) { zone in
                        model.update { $0.day.timeZoneID = zone; if $0.day != $0.planEntry?.day { $0.planEntry = nil } }
                        return model.error == nil
                    }
                }
                .navigationDestination(isPresented: $choosing) {
                    OwnedPieceChooser(pieces: model.pieces, initialSelection: model.draft.pieceIDs, error: model.error,
                                      isLocked: model.pending || model.unknown, actionTitle: "Use pieces") { ids in
                        model.update { draft in
                            draft.pieceIDs = ids
                            draft.reviewedRevisions = Dictionary(uniqueKeysWithValues: model.pieces.filter { ids.contains($0.id) }.map { ($0.id, $0.revision) })
                        }
                        return model.error == nil
                    }
                }
        }.interactiveDismissDisabled()
            .sheet(isPresented: $discard) {
                DraftDiscardSheet(title: "Discard wear draft?", message: "No wear is recorded by discarding this draft. Your existing history stays unchanged.") {
                    model.finish(discarding: true)
                    if model.state.wearEditor == nil { discard = false }
                }
            }
    }
    private func pieceName(_ id: UUID) -> String {
        if let snapshot = model.draft.baseRecord?.pieces.first(where: { $0.id == id }) { return snapshot.name }
        return model.pieces.first(where: { $0.id == id })?.name ?? "Unavailable piece"
    }

}

struct LocalWearHistoryView: View {
    var pieceID: UUID? = nil
    @Environment(AppState.self) private var state
    private var records: [OutfitWearRecord] {
        state.wearRecords.filter { record in pieceID.map { id in record.pieces.contains { $0.id == id } } ?? true }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error = state.wearError {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry history") { state.reloadWear() }
                } else if records.isEmpty {
                    ContentUnavailableView("No recorded wear yet", systemImage: "clock",
                                           description: Text("Record what you wore from an outfit. Plans never become wear automatically."))
                }
                ForEach(records) { record in
                    NavigationLink { LocalWearDetailView(id: record.id) } label: { VStack(alignment: .leading, spacing: 8) {
                        Text(record.day.key).font(AppTypography.fieldLabel)
                        Text(record.pieces.map(\.name).joined(separator: ", ")).font(AppTypography.body)
                        Text(record.day.timeZoneID).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12)) }.buttonStyle(.plain)
                }
            }.padding(20)
        }.background(AppTheme.canvas)
            .navigationTitle("Wear history").navigationBarTitleDisplayMode(.inline)
            .onAppear { state.reloadWear() }
    }
}
