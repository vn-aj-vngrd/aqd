import AQDCore
import SwiftUI

struct ClosetView: View {
    @Environment(AppState.self) private var state
    @State private var query = ""
    @State private var category: PieceCategory?
    @State private var archived = false
    @State private var availability: PieceAvailability?
    @State private var sort = PieceSort.name
    @State private var results: [WardrobePiece] = []
    @State private var error: String?

    var body: some View {
        NavigationStack(path: Binding(get: { state.closetPath }, set: { state.closetPath = $0 })) {
            VStack(spacing: 0) {
                Picker("Closet collection", selection: Binding(get: { state.closetScope }, set: { state.closetScope = $0 })) {
                    Text("Pieces").tag("Pieces")
                    Text("Outfits").tag("Outfits")
                    Text("Themes").tag("Themes")
                }.pickerStyle(.segmented).padding(.horizontal, 20).padding(.bottom, 12)
                if state.closetScope == "Pieces" {
                    collection
                } else {
                    ContentUnavailableView("\(state.closetScope) aren’t implemented yet", systemImage: "square.stack",
                                           description: Text("This baseline currently supports pieces. Full private \(state.closetScope.lowercased()) remain part of V1 implementation."))
                }
            }
            .background(AppTheme.canvas)
            .navigationTitle("Closet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { state.addPiece() } label: { Label("Add piece", systemImage: "plus") }
                        .accessibilityIdentifier("closet.addPiece")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Category", selection: $category) {
                            Text("All categories").tag(Optional<PieceCategory>.none)
                            ForEach(PieceCategory.allCases, id: \.self) { Text($0.rawValue).tag(Optional($0)) }
                        }
                        Picker("Availability", selection: $availability) {
                            Text("All availability").tag(Optional<PieceAvailability>.none)
                            Text("Available").tag(Optional(PieceAvailability.available))
                            Text("Unavailable").tag(Optional(PieceAvailability.unavailable))
                            Text("Laundry").tag(Optional(PieceAvailability.laundry))
                        }
                        Toggle("Archived pieces", isOn: $archived)
                        Picker("Sort pieces", selection: $sort) {
                            Text("Name").tag(PieceSort.name)
                            Text("Recently added").tag(PieceSort.recentlyAdded)
                        }
                    } label: { Label("Filter pieces", systemImage: "line.3.horizontal.decrease") }
                    .disabled(state.closetScope != "Pieces")
                }
            }
            .searchable(text: $query, prompt: "Search pieces")
            .navigationDestination(for: UUID.self) { id in PieceDetailView(id: id) }
            .onAppear(perform: refresh)
            .onChange(of: query) { refresh() }
            .onChange(of: category) { refresh() }
            .onChange(of: archived) { refresh() }
            .onChange(of: availability) { refresh() }
            .onChange(of: sort) { refresh() }
            .onChange(of: state.pieces) { refresh() }
        }
        .tint(AppTheme.actionText)
    }

    @ViewBuilder private var collection: some View {
        if let error {
            ContentUnavailableView {
                Label("Pieces couldn’t load", systemImage: "externaldrive.badge.exclamationmark")
            } description: { Text(error) } actions: { Button("Retry", action: refresh) }
        } else if results.isEmpty {
            ContentUnavailableView {
                Label(query.isEmpty && category == nil && availability == nil ? (archived ? "No archived pieces" : "Your closet starts here") : "No matching pieces", systemImage: "tshirt")
            } description: {
                Text(query.isEmpty && category == nil && availability == nil ? "Add a photo and a few details. Everything stays on this device." : "Try another search or clear the filters.")
            } actions: {
                if query.isEmpty && category == nil && availability == nil && !archived {
                    Button("Add piece") { state.addPiece() }
                } else {
                    Button("Clear search and filters") { query = ""; category = nil; archived = false; availability = nil }
                }
            }
        } else {
            List(results) { piece in
                NavigationLink(value: piece.id) {
                    HStack(spacing: 14) {
                        PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                            .frame(width: 64, height: 80)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(piece.name).foregroundStyle(AppTheme.ink)
                            Text(piece.category.rawValue).font(.subheadline).foregroundStyle(AppTheme.secondary)
                            if piece.availability != .available {
                                Text(piece.availability == .laundry ? "Laundry" : "Unavailable")
                                    .font(.footnote).foregroundStyle(AppTheme.secondary)
                            }
                        }
                    }.padding(.vertical, 4)
                }.listRowBackground(AppTheme.surface)
            }.listStyle(.plain).scrollContentBackground(.hidden)
        }
    }

    private func refresh() {
        guard let store = state.store else { return }
        do { results = try store.pieces(query: query, category: category, archived: archived, availability: availability, sort: sort); error = nil }
        catch { self.error = "Your saved collection has not been cleared. Keep this data for recovery and retry." }
    }
}

struct PieceThumbnail: View {
    @Environment(AppState.self) private var state
    let photoID: UUID
    var recipe: PhotoEditRecipe = .fit
    @State private var image: UIImage?

    private struct Request: Equatable {
        let id: UUID
        let recipe: PhotoEditRecipe
    }

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFit() }
            else { Image(systemName: "photo").foregroundStyle(AppTheme.secondary).accessibilityLabel("Photo unavailable") }
        }
        .background(AppTheme.imageGround)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .task(id: Request(id: photoID, recipe: recipe)) {
            if let data = try? state.store?.photoThumbnail(id: photoID, recipe: recipe) { image = UIImage(data: data) }
            else { image = nil }
        }
    }
}

struct PieceDetailView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var piece: WardrobePiece?
    @State private var error: String?
    @State private var deleteDecision = false
    @State private var archiveDecision = false
    @State private var archiveOperationID = UUID()
    @State private var undoArchiveRevision: Int?
    @State private var reviewedDelete: DeleteReview?
    @State private var reviewedArchive: WardrobePiece?

    private struct DeleteReview {
        let piece: WardrobePiece
        let operationID: UUID
        var submitted = false
    }

    private var deleteInFlight: Bool { reviewedDelete?.submitted == true }

    var body: some View {
        ScrollView {
            if let piece {
                VStack(alignment: .leading, spacing: 24) {
                    PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(maxWidth: .infinity).frame(height: 300)
                    Text(piece.name).font(.title2.weight(.medium))
                    Text(piece.category.rawValue).foregroundStyle(AppTheme.secondary)
                    if !piece.details.color.isEmpty { detail("Color", piece.details.color) }
                    if !piece.details.brand.isEmpty { detail("Brand", piece.details.brand) }
                    if !piece.details.size.isEmpty { detail("Size", piece.details.size) }
                    if !piece.details.fit.isEmpty { detail("Fit", piece.details.fit) }
                    if !piece.details.material.isEmpty { detail("Material", piece.details.material) }
                    if !piece.details.notes.isEmpty { detail("Notes", piece.details.notes) }
                    if let estimate = piece.details.priorWearCount {
                        detail("Prior wear estimate", String(estimate))
                        Text("This is an estimate, not recorded wear.").font(.footnote).foregroundStyle(AppTheme.secondary)
                    }
                    if piece.isArchived { Text("Archived").font(.subheadline) }
                    if let revision = undoArchiveRevision {
                        Button("Undo archive") { setArchive(false, expectedRevision: revision, operation: UUID()) }
                            .frame(minHeight: 44).disabled(deleteInFlight)
                    }
                    if let error {
                        Text(error).foregroundStyle(AppTheme.error)
                        if reviewedDelete != nil { Button("Retry reviewed delete") { delete() }.frame(minHeight: 44) }
                    }
                }.padding(20)
            } else {
                ContentUnavailableView("Piece unavailable", systemImage: "tshirt", description: Text(error ?? "The record is no longer here."))
            }
        }
        .background(AppTheme.canvas)
        .navigationTitle("Piece").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let piece {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { state.editPiece(piece) } label: { Label("Edit piece", systemImage: "square.and.pencil") }
                        .tint(AppTheme.ink).accessibilityIdentifier("piece.edit")
                        .disabled(deleteInFlight)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if piece.isArchived {
                            Button("Restore", systemImage: "arrow.uturn.backward") {
                                setArchive(false, expectedRevision: piece.revision, operation: UUID())
                            }.disabled(deleteInFlight)
                        } else {
                            Button("Archive", systemImage: "archivebox") {
                                archiveOperationID = UUID(); reviewedArchive = piece; archiveDecision = true
                            }.disabled(deleteInFlight)
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            if reviewedDelete == nil {
                                reviewedDelete = DeleteReview(piece: piece, operationID: UUID())
                            }
                            deleteDecision = true
                        }
                    } label: { Label("More piece options", systemImage: "ellipsis") }
                    .confirmationDialog("Delete this piece?", isPresented: $deleteDecision, titleVisibility: .visible) {
                        Button("Cancel", role: .cancel) { cancelDeleteReview() }
                        Button("Delete", role: .destructive) { delete() }
                    } message: {
                        Text("Delete \(reviewedDelete?.piece.name ?? "this piece"), its recovery drafts, and its unreferenced AQD photos. Original Photos are unchanged. This cannot be undone.")
                    }
                }
            }
        }
        .onAppear(perform: refresh)
        .onChange(of: state.pieces) { refresh() }
        .onChange(of: deleteDecision) { _, presented in
            if !presented { cancelDeleteReview() }
        }
        .confirmationDialog("Archive \(reviewedArchive?.name ?? "this piece")?", isPresented: $archiveDecision, titleVisibility: .visible) {
            Button("Archive") {
                if let reviewedArchive { setArchive(true, expectedRevision: reviewedArchive.revision, operation: archiveOperationID) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("The piece keeps its identity and can be restored.") }
    }

    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).foregroundStyle(AppTheme.secondary)
            Text(value)
        }
    }

    private func refresh() {
        do { piece = try state.store?.piece(id: id) }
        catch { self.error = "The saved piece couldn’t be read. Its data has not been replaced." }
    }

    private func setArchive(_ value: Bool, expectedRevision: Int, operation: UUID) {
        guard !deleteInFlight else {
            error = "Reconcile the reviewed deletion before changing this piece."
            return
        }
        do {
            try state.store?.setArchived(id: id, archived: value, expectedRevision: expectedRevision, operationID: operation)
            state.reloadPieces()
            refresh()
            undoArchiveRevision = value ? piece?.revision : nil
            error = nil
        } catch { self.error = "The piece wasn’t changed. Reopen the latest record and retry." }
    }

    private func cancelDeleteReview() {
        // Supported outside dismissal equals Cancel only before submission.
        // A failed/unknown operation retains its exact review for reconciliation.
        if !deleteInFlight { reviewedDelete = nil }
    }

    private func delete() {
        guard var review = reviewedDelete, let store = state.store else { return }
        review.submitted = true
        reviewedDelete = review
        do {
            try store.deletePiece(id: review.piece.id, expectedRevision: review.piece.revision,
                                  operationID: review.operationID)
            state.reloadPieces()
            dismiss()
        } catch { self.error = "Delete didn’t finish. Keep this record open and retry the same reviewed operation." }
    }
}
