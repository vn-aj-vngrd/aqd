import AQDCore
import SwiftUI

struct OwnedPieceChooser: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: "Done") {
                    if apply(selected) { dismiss() }
                }.disabled(isLocked)
    }

    let pieces: [WardrobePiece]
    let initialSelection: [UUID]
    var pinnedIDs: [UUID] = []
    var error: String?
    var isLocked = false
    var actionTitle = "Add selected pieces"
    var showsComposition = false
    @Environment(AppState.self) private var state
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let apply: ([UUID]) -> Bool
    @State private var query = ""
    @State private var categoryID: String?
    @State private var selected: [UUID] = []
    @State private var initialized = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    static func visiblePieces(in pieces: [WardrobePiece], selected: [UUID], category: PieceCategory?, query: String) -> [WardrobePiece] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return pieces.filter {
            selected.contains($0.id) || ((category == nil || $0.category == category) &&
                (needle.isEmpty || "\($0.displayName) \($0.details.color) \($0.details.brand)".localizedCaseInsensitiveContains(needle)))
        }
    }
    private var filteredPieces: [WardrobePiece] {
        Self.visiblePieces(in: pieces, selected: selected, category: nil, query: query)
            .filter { selected.contains($0.id) || categoryID == nil || state.category(for: $0)?.id == categoryID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if showsComposition { liveComposition }
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        categoryButton(nil)
                        ForEach(state.pieceCategories) { categoryButton($0) }
                    }
                }.scrollIndicators(.hidden)
                if filteredPieces.isEmpty {
                    AppEmptyState("No matching pieces", systemImage: "tshirt",
                                           description: Text("Clear the search or choose another category. Your selection stays here."))
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 16) {
                    ForEach(filteredPieces) { piece in
                        let isSelected = selected.contains(piece.id)
                        Button {
                            if isSelected {
                                if !pinnedIDs.contains(piece.id) { selected.removeAll { $0 == piece.id } }
                            } else { selected.append(piece.id) }
                        } label: {
                            ClosetCard(title: piece.displayName, detail: [state.categoryName(for: piece), piece.details.color].filter { !$0.isEmpty }.joined(separator: " · ")) {
                                PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                    .frame(maxWidth: .infinity).frame(height: 134).clipped()
                                    .overlay(alignment: .topTrailing) {
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill").font(.title3)
                                                .symbolRenderingMode(.palette).foregroundStyle(AppTheme.onPrimary, AppTheme.ink)
                                                .padding(6)
                                        }
                                    }
                            }
                        }.buttonStyle(.plain)
                            .accessibilityLabel(piece.displayName)
                            .accessibilityValue(pinnedIDs.contains(piece.id) ? "Pinned and selected" : isSelected ? "Selected" : "Not selected")
                            .accessibilityHint(pinnedIDs.contains(piece.id) ? "Unpin in the outfit editor before removing this piece." : "")
                            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }
                ForEach(selected.filter { id in !pieces.contains(where: { $0.id == id }) }, id: \.self) { id in
                    Button("Remove unavailable piece") { selected.removeAll { $0 == id } }.frame(minHeight: 44)
                }
                Text("\(selected.count) selected · Kept when filters change")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                if let error { SemanticFeedback(role: .danger, message: error) }

            }.padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .sensoryFeedback(.selection, trigger: selected)
        .background(AppTheme.canvas)
        .navigationTitle("Choose pieces").navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: { Label("Cancel", systemImage: "xmark") }
                    .disabled(isLocked)
            } }
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                confirmation
            } }
            .tint(AppTheme.ink)
        .searchable(text: $query, prompt: "Search your pieces")
        .onAppear { if !initialized { selected = initialSelection; initialized = true } }
    }

    private var liveComposition: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("Your outfit").font(AppTypography.fieldLabel); Spacer(); Text("\(selected.count) selected").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
            if selected.isEmpty {
                Text("Tap pieces below to form your outfit.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).frame(minHeight: 92)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(selected, id: \.self) { id in
                            if let piece = pieces.first(where: { $0.id == id }) {
                                Button { selected.removeAll { $0 == id } } label: {
                                    PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                        .frame(width: 72, height: 92).clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(alignment: .topTrailing) { Image(systemName: "minus.circle.fill").foregroundStyle(AppTheme.ink, AppTheme.surface).accessibilityHidden(true) }
                                }.buttonStyle(.plain).accessibilityLabel("Remove \(piece.displayName)")
                                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                            }
                        }
                    }.padding(.vertical, 4)
                }.scrollIndicators(.hidden)
            }
        }.padding(16).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .animation(reduceMotion ? nil : AQDMotion.reflow, value: selected)
    }

    private func categoryButton(_ value: WardrobeCategory?) -> some View {
        Button { categoryID = value?.id } label: {
            HStack(spacing: 6) {
                if categoryID == value?.id { Image(systemName: "checkmark") }
                Text(value?.name ?? "All pieces")
            }.font(.subheadline).padding(.horizontal, 12).padding(.vertical, 6)
                .frame(minHeight: 44)
                .foregroundStyle(categoryID == value?.id ? AppTheme.onPrimary : AppTheme.ink)
                .background(categoryID == value?.id ? AppTheme.primaryFill : AppTheme.surface, in: Capsule())
        }.buttonStyle(.plain).accessibilityAddTraits(categoryID == value?.id ? [.isSelected] : [])
    }
}
