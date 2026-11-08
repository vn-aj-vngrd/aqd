import AQDCore
import SwiftUI

/// A neutral figure drawn from shapes, with no photo, face or likeness, in unit coordinates of its canvas.
private struct MannequinFigure: Shape {
    func path(in rect: CGRect) -> Path {
        func box(_ x: Double, _ y: Double, _ width: Double, _ height: Double) -> CGRect {
            CGRect(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height, width: width * rect.width, height: height * rect.height)
        }
        var path = Path()
        path.addEllipse(in: box(0.42, 0.01, 0.16, 0.10))
        path.addRoundedRect(in: box(0.46, 0.10, 0.08, 0.05), cornerSize: CGSize(width: 6, height: 6))
        path.addRoundedRect(in: box(0.28, 0.14, 0.44, 0.34), cornerSize: CGSize(width: 22, height: 22))
        path.addRoundedRect(in: box(0.17, 0.15, 0.09, 0.32), cornerSize: CGSize(width: 12, height: 12))
        path.addRoundedRect(in: box(0.74, 0.15, 0.09, 0.32), cornerSize: CGSize(width: 12, height: 12))
        path.addRoundedRect(in: box(0.31, 0.46, 0.17, 0.44), cornerSize: CGSize(width: 12, height: 12))
        path.addRoundedRect(in: box(0.52, 0.46, 0.17, 0.44), cornerSize: CGSize(width: 12, height: 12))
        return path
    }
}

/// An outfit's pieces snapped to their category slots on a 2D mannequin. Display only: nothing here is saved.
struct MannequinView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    let pieceIDs: [UUID]

    private static let canvasAspect: CGFloat = 0.5

    private var pieces: [WardrobePiece] { pieceIDs.compactMap { id in state.ownedPieces.first { $0.id == id } } }
    private var layout: MannequinLayout { MannequinLayout.place(pieces.map { ($0.id, $0.category) }) }

    private func piece(_ id: UUID) -> WardrobePiece? { pieces.first { $0.id == id } }

    private func thumbnail(_ piece: WardrobePiece) -> some View {
        PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe, ground: .clear, placeholder: MannequinLayout.placeholderSymbol(for: piece.category))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(piece.displayName), \(state.categoryName(for: piece))")
            .accessibilityIdentifier("mannequin.piece")
    }

    private var figure: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                MannequinFigure().fill(AppTheme.imageGround)
                MannequinFigure().stroke(AppTheme.divider, lineWidth: 1)
                ForEach(layout.placements.filter { $0.frame != nil }) { placement in
                    if let frame = placement.frame, let piece = piece(placement.id) {
                        thumbnail(piece)
                            .frame(width: frame.width * geometry.size.width, height: frame.height * geometry.size.height)
                            .offset(x: frame.x * geometry.size.width, y: frame.y * geometry.size.height)
                            .zIndex(Double(placement.zIndex))
                    }
                }
            }.accessibilityElement(children: .contain).accessibilityLabel("Mannequin")
        }.aspectRatio(Self.canvasAspect, contentMode: .fit).frame(maxHeight: 440)
    }

    @ViewBuilder private var tray: some View {
        let ids = layout.tray
        if !ids.isEmpty {
            VStack(spacing: AppSpacing.small) {
                Text("Accessories").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                ForEach(ids, id: \.self) { id in
                    if let piece = piece(id) { thumbnail(piece).frame(width: 72, height: 72) }
                }
            }.padding(AppSpacing.medium).background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.group))
        }
    }

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(spacing: AppSpacing.large) { figure; tray }
            } else {
                HStack(alignment: .center, spacing: AppSpacing.large) { figure; tray }
            }
        }
        .padding(AppSpacing.large).frame(maxWidth: .infinity)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .accessibilityIdentifier("mannequin.canvas")
    }
}
