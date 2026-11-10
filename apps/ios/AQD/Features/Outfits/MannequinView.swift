import AQDCore
import SwiftUI

/// One placed piece: a drag moves it and a pinch resizes it while the view is open. Nothing is saved.
private struct AdjustablePiece<Content: View>: View {
    let frame: MannequinFrame
    let canvas: CGSize
    let onDrag: (CGSize) -> Void
    let onPinch: (Double) -> Void
    @ViewBuilder let content: Content
    @GestureState private var live = CGSize.zero
    @GestureState private var pinch: CGFloat = 1

    var body: some View {
        content
            .frame(width: frame.width * canvas.width, height: frame.height * canvas.height)
            .scaleEffect(pinch)
            .offset(x: frame.x * canvas.width + live.width, y: frame.y * canvas.height + live.height)
            .gesture(DragGesture(minimumDistance: 4)
                .updating($live) { value, state, _ in state = value.translation }
                .onEnded { onDrag($0.translation) })
            .simultaneousGesture(MagnifyGesture()
                .updating($pinch) { value, state, _ in state = value.magnification }
                .onEnded { onPinch($0.magnification) })
    }
}

/// An outfit's pieces fitted to the anchors of a realistic 2D figure. Display only: nothing here is saved.
/// Adjustments live in a model owned by this view, so leaving it or changing the pieces restores the defaults.
struct MannequinView: View {
    @Environment(AppState.self) private var state
    let pieceIDs: [UUID]

    private var pieces: [WardrobePiece] { pieceIDs.compactMap { id in state.ownedPieces.first { $0.id == id } } }

    var body: some View {
        let current = pieces
        let variant = MannequinFigureCatalog.load().variant(id: "standard")
        MannequinCanvas(pieces: current, variant: variant)
            .id(current.map { "\($0.id)-\($0.category.rawValue)" } + [variant.id])
    }
}

private struct MannequinCanvas: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let pieces: [WardrobePiece]
    let variant: MannequinFigureVariant
    @State private var model: MannequinModel
    @State private var figureFrame = CGRect.zero
    @State private var trayDrag: (id: UUID, translation: CGSize)?

    private static let canvasSpace = "mannequin.canvas"
    private static let waistCentre = (x: 0.5, y: 0.45)

    init(pieces: [WardrobePiece], variant: MannequinFigureVariant) {
        self.pieces = pieces
        self.variant = variant
        _model = State(initialValue: MannequinModel(pieces: pieces.map { ($0.id, $0.category) }, variant: variant))
    }

    private var snap: Animation? { reduceMotion ? nil : .snappy }

    private func piece(_ id: UUID) -> WardrobePiece? { pieces.first { $0.id == id } }

    /// The cutout aspect-fits inside its slot: garments hang from the top, shoes stand on the bottom.
    private func thumbnail(_ piece: WardrobePiece, alignment: Alignment, placed: Bool) -> some View {
        PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe, ground: .clear,
                       placeholder: MannequinLayout.placeholderSymbol(for: piece.category))
            .shadow(color: placed ? AppTheme.controlShadow : .clear, radius: 3, y: 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(piece.displayName), \(state.categoryName(for: piece))")
            .accessibilityIdentifier("mannequin.piece")
    }

    private func alignment(of placement: MannequinPlacement) -> Alignment {
        guard placement.frame != nil else { return .center }
        return placement.alignment == .bottom ? .bottom : .top
    }

    private func adjustable(_ piece: WardrobePiece, placement: MannequinPlacement, frame: MannequinFrame, canvas: CGSize) -> some View {
        AdjustablePiece(frame: frame, canvas: canvas) { translation in
            withAnimation(snap) { model.commitDrag(piece.id, dx: translation.width / canvas.width, dy: translation.height / canvas.height) }
        } onPinch: { magnification in
            withAnimation(snap) { model.commitScale(piece.id, model.adjustments.scale(for: piece.id) * magnification) }
        } content: {
            thumbnail(piece, alignment: alignment(of: placement), placed: true)
        }
        .accessibilityAction(named: "Move up") { withAnimation(snap) { model.step(piece.id, .up) } }
        .accessibilityAction(named: "Move down") { withAnimation(snap) { model.step(piece.id, .down) } }
        .accessibilityAction(named: "Move left") { withAnimation(snap) { model.step(piece.id, .left) } }
        .accessibilityAction(named: "Move right") { withAnimation(snap) { model.step(piece.id, .right) } }
        .accessibilityAction(named: "Larger") { withAnimation(snap) { model.step(piece.id, .larger) } }
        .accessibilityAction(named: "Smaller") { withAnimation(snap) { model.step(piece.id, .smaller) } }
    }

    private var figure: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Image(variant.imageName).resizable().scaledToFit().accessibilityHidden(true)
                ForEach(model.layout.placements) { placement in
                    if let frame = model.frame(of: placement.id), let piece = piece(placement.id) {
                        adjustable(piece, placement: placement, frame: frame, canvas: geometry.size)
                            .zIndex(Double(placement.zIndex))
                    }
                }
            }
            .accessibilityElement(children: .contain).accessibilityLabel("Mannequin")
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.canvasSpace)) } action: { figureFrame = $0 }
        }.aspectRatio(variant.aspectRatio, contentMode: .fit).frame(maxHeight: 460)
    }

    private func dropTrayPiece(_ id: UUID, at location: CGPoint) {
        guard figureFrame.width > 0, figureFrame.height > 0, figureFrame.contains(location) else { return }
        withAnimation(snap) {
            model.drop(id, atX: (location.x - figureFrame.minX) / figureFrame.width, y: (location.y - figureFrame.minY) / figureFrame.height)
        }
    }

    private func trayItem(_ piece: WardrobePiece) -> some View {
        let live = trayDrag?.id == piece.id ? trayDrag?.translation ?? .zero : .zero
        return thumbnail(piece, alignment: .center, placed: false).frame(width: 72, height: 72)
            .offset(live)
            .zIndex(live == .zero ? 0 : 1)
            .gesture(DragGesture(minimumDistance: 4, coordinateSpace: .named(Self.canvasSpace))
                .onChanged { trayDrag = (piece.id, $0.translation) }
                .onEnded { value in
                    trayDrag = nil
                    dropTrayPiece(piece.id, at: value.location)
                })
            .accessibilityAction(named: "Place on figure") {
                withAnimation(snap) { model.drop(piece.id, atX: Self.waistCentre.x, y: Self.waistCentre.y) }
            }
    }

    @ViewBuilder private var tray: some View {
        if !model.layout.tray.isEmpty {
            VStack(spacing: AppSpacing.small) {
                Text("Accessories").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                ForEach(model.trayIDs, id: \.self) { id in
                    if let piece = piece(id) { trayItem(piece) }
                }
            }.padding(AppSpacing.medium).background(AppTheme.imageGround, in: RoundedRectangle(cornerRadius: AppRadius.group))
                .zIndex(1)
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(spacing: AppSpacing.large) { figure; tray }
                } else {
                    HStack(alignment: .center, spacing: AppSpacing.large) { figure; tray }
                }
            }.coordinateSpace(name: Self.canvasSpace)
            if model.isAdjusted {
                Button { withAnimation(snap) { model.reset() } } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise").compactControl()
                }.buttonStyle(.plain).accessibilityIdentifier("mannequin.reset")
            }
        }
        .padding(AppSpacing.large).frame(maxWidth: .infinity)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .accessibilityIdentifier("mannequin.canvas")
    }
}
