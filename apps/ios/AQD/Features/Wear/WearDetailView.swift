import AQDCore
import SwiftUI

struct LocalWearDetailView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var confirmingUndo = false
    @State private var request: HistoryMutation?
    @State private var error: String?
    private var record: OutfitWearRecord? { state.wearRecords.first { $0.id == id } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let record {
                    Text(record.day.display(.full)).font(AppTypography.section)
                    HStack {
                        Text("\(record.pieces.count) pieces")
                        Spacer(minLength: 12)
                        Text(record.day.timeZoneID)
                    }.font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    OutfitComposition(pieceIDs: record.pieces.map(\.id))
                    NavigationLink("View recorded pieces") { RecordedWearPiecesView(record: record) }.frame(minHeight: 44)
                    HStack(spacing: AppSpacing.small) {
                        Button { state.openWear(correcting: record) } label: { Label("Edit wear", systemImage: AppSymbols.edit).compactControl(fullWidth: true) }.buttonStyle(.plain)
                        Button {
                            request = HistoryMutation(action: .undoWear(record)); confirmingUndo = true
                        } label: { Label("Undo wear", systemImage: "arrow.uturn.backward").compactControl(fullWidth: true, tint: AppTheme.error) }.buttonStyle(.plain)
                    }.disabled(request != nil || state.wearEditor != nil)
                    if state.wearEditor != nil {
                        Text("Finish or discard your open wear draft before editing or undoing this record.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }
                    Text("Editing updates this record without adding a new wear. If the day, timezone or pieces change, any linked plan entries go back to Planned. Your plan itself never moves.")
                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                } else { AppEmptyState("Wear record unavailable", systemImage: "clock") }
                if let error {
                    SemanticFeedback(role: .danger, message: error)
                    if request != nil { Button("Check Undo result", action: undo).frame(minHeight: 44) }
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Wear record").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
            .onAppear { state.reloadWear() }
            .appConfirmation("Undo this wear?", isPresented: $confirmingUndo) {
                Button("Undo wear", role: .destructive, action: undo)
                Button("Cancel", role: .cancel) { request = nil }
            } message: { Text("Removes this record and its counted wears. All existing linked plan entries return to Planned. Deleted plans stay deleted.") }
    }
    private func undo() {
        guard let request else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.applyHistoryMutation(request); state.reloadWear(); state.reloadPlanEntries(); dismiss()
        } catch PieceStore.StoreError.staleRevision {
            self.request = nil; self.error = "This record changed. Review the latest record before Undo."; state.reloadWear()
        } catch { self.error = "Undo is not acknowledged. Check this same operation before changing history." }
    }
}

private struct RecordedWearPiecesView: View {
    let record: OutfitWearRecord
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Names and categories as recorded. Photos are not stored in wear history.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                ForEach(record.pieces, id: \.id) { piece in
                    HStack(spacing: 12) {
                        Image(systemName: "tshirt").frame(width: 48, height: 56).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(piece.displayName).font(AppTypography.body)
                            Text(piece.category.rawValue.capitalized).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(14).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Recorded pieces").navigationBarTitleDisplayMode(.inline)
    }
}
