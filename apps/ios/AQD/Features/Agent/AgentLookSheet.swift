import AQDCore
import SwiftUI

/// A look as a card: the pieces composed together, then each piece by name. Opened from a proposal before anything is saved.
struct AgentLookSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let title: String
    let subtitle: String
    let pieceIDs: [UUID]

    private var pieces: [WardrobePiece] { pieceIDs.compactMap { id in state.ownedPieces.first { $0.id == id } } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    AgentWidgetCard(title: title, subtitle: subtitle) {
                        OutfitComposition(pieceIDs: pieceIDs, pieceHeight: 150, limit: 6, ground: .clear).frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(pieces.enumerated()), id: \.element.id) { index, piece in
                            if index > 0 { Divider().overlay(AppTheme.divider) }
                            NavigationLink(value: ClosetRoute.piece(piece.id)) {
                                HStack(spacing: AppSpacing.medium) {
                                    PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe).frame(width: 48, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo)).accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(piece.displayName).font(AppTypography.body).foregroundStyle(AppTheme.ink).truncated()
                                        Text([piece.details.color, piece.category.rawValue].filter { !$0.isEmpty }.joined(separator: ", "))
                                            .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).truncated()
                                    }
                                    Spacer(minLength: AppSpacing.small)
                                    Image(systemName: "chevron.right").font(.footnote).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                                }.padding(.vertical, AppSpacing.small).frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal, AppSpacing.medium)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                }.padding(AppSpacing.screen)
            }.background(AppTheme.canvas).navigationTitle("Preview").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button { dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("Close") } }
                .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
        }
    }
}
