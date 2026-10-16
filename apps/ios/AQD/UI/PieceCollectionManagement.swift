import AQDCore
import SwiftUI

struct ArchivedPiecesView: View {
    @Environment(AppState.self) private var state
    @State private var query = ""
    @State private var pieces: [WardrobePiece] = []
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let error {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry", action: refresh).frame(minHeight: 44)
                } else if pieces.isEmpty {
                    AppEmptyState(query.isEmpty ? "No archived pieces" : "No matching pieces", systemImage: "archivebox",
                        description: Text("Archived pieces keep their outfits and history. Restore a piece from its options."))
                } else { PieceCollectionGrid(pieces: pieces) }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Archived pieces").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search archived pieces")
            .onAppear(perform: refresh).onChange(of: query) { refresh() }
            .onChange(of: state.collectionRefreshID) { refresh() }
    }
    private func refresh() {
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            pieces = try store.pieces(query: query, archived: true); error = nil
        } catch { self.error = "Archived pieces couldn’t be read. Their data is retained; retry." }
    }
}

struct PieceAvailabilityView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let piece: WardrobePiece
    @State private var pendingValue: PieceAvailability?
    @State private var operationID = UUID()
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Can you wear it now?").font(AppTypography.fieldLabel)
                    Text("Unavailable pieces stay in your closet and history. Affected future plans will need review.")
                        .foregroundStyle(AppTheme.secondary)
                }
                Section {
                    ForEach(PieceAvailability.allCases, id: \.self) { value in
                        Button { save(value) } label: {
                            HStack {
                                Text(value == .laundry ? "In the laundry" : value.rawValue.capitalized)
                                Spacer()
                                if piece.availability == value { Image(systemName: "checkmark").foregroundStyle(AppTheme.ink) }
                            }.frame(minHeight: 44).foregroundStyle(AppTheme.ink)
                        }.disabled(pendingValue != nil && pendingValue != value)
                    }
                }
                if let error {
                    Section {
                        SemanticFeedback(role: .danger, message: error)
                        if let pendingValue { Button("Retry availability") { save(pendingValue) } }
                    }
                }
            }.contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas).navigationTitle("Availability").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }.tint(AppTheme.ink)
                        .accessibilityLabel("Cancel availability").disabled(pendingValue != nil)
                } }
        }.interactiveDismissDisabled(pendingValue != nil)
    }
    private func save(_ value: PieceAvailability) {
        guard pendingValue == nil || pendingValue == value else { return }
        pendingValue = value
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            _ = try store.setAvailability(id: piece.id, value: value, expectedRevision: piece.revision, operationID: operationID)
            state.reloadPieces(); state.reloadPlanEntries(); dismiss()
        } catch PieceStore.StoreError.staleRevision {
            pendingValue = nil; operationID = UUID()
            self.error = "This piece changed. Close this task and reopen the latest piece before choosing availability."
        } catch {
            self.error = "The availability change isn’t acknowledged. Retry the same choice to reconcile it."
        }
    }
}
