import AQDCore
import SwiftUI

struct OwnedPieceChooser: View {
    let pieces: [WardrobePiece]
    let initialSelection: [UUID]
    var pinnedIDs: [UUID] = []
    var error: String?
    var isLocked = false
    var actionTitle = "Add selected pieces"
    let apply: ([UUID]) -> Bool
    @State private var query = ""
    @State private var category: PieceCategory?
    @State private var selected: [UUID] = []
    @State private var initialized = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    static func visiblePieces(in pieces: [WardrobePiece], selected: [UUID], category: PieceCategory?, query: String) -> [WardrobePiece] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return pieces.filter {
            selected.contains($0.id) || ((category == nil || $0.category == category) &&
                (needle.isEmpty || "\($0.name) \($0.details.color) \($0.details.brand)".localizedCaseInsensitiveContains(needle)))
        }
    }
    private var filteredPieces: [WardrobePiece] {
        Self.visiblePieces(in: pieces, selected: selected, category: category, query: query)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        categoryButton(nil)
                        ForEach(PieceCategory.allCases, id: \.self) { categoryButton($0) }
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
                            VStack(alignment: .leading, spacing: 8) {
                                PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                    .frame(height: 134)
                                    .overlay(alignment: .topTrailing) {
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill").font(.title3)
                                                .symbolRenderingMode(.palette).foregroundStyle(AppTheme.onAccent, AppTheme.accent)
                                                .padding(8)
                                        }
                                    }
                                Text(piece.name).font(AppTypography.fieldLabel).foregroundStyle(AppTheme.ink)
                                Text([piece.category.rawValue, piece.details.color].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(.plain)
                            .accessibilityLabel(piece.name)
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
                PrimaryAction(title: actionTitle) {
                    if apply(selected) { dismiss() }
                }.disabled(isLocked)
            }.padding(20)
        }
        .background(AppTheme.canvas)
        .navigationTitle("Choose pieces").navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.ink)
        .searchable(text: $query, prompt: "Search your pieces")
        .onAppear { if !initialized { selected = initialSelection; initialized = true } }
    }

    private func categoryButton(_ value: PieceCategory?) -> some View {
        Button { category = value } label: {
            HStack(spacing: 6) {
                if category == value { Image(systemName: "checkmark") }
                Text(value?.rawValue ?? "All pieces")
            }.font(.subheadline).padding(.horizontal, 12).padding(.vertical, 6)
                .frame(minHeight: 44)
                .foregroundStyle(category == value ? AppTheme.onAccent : AppTheme.ink)
                .background(category == value ? AppTheme.accent : AppTheme.surface, in: Capsule())
        }.buttonStyle(.plain).accessibilityAddTraits(category == value ? [.isSelected] : [])
    }
}
