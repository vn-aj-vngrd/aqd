import AQDCore
import Foundation
import Observation

/// The mannequin's layout plus the owner's transient adjustments. It takes no store or app state, so it cannot
/// save anything; the view recreates it whenever the pieces change, which starts again from the default slots.
@Observable
@MainActor
final class MannequinModel {
    let variant: MannequinFigureVariant
    private(set) var layout: MannequinLayout
    private(set) var adjustments = MannequinAdjustments()

    init(pieces: [(UUID, PieceCategory)], variant: MannequinFigureVariant = .standard) {
        self.variant = variant
        layout = MannequinLayout.place(pieces, on: variant.anchors)
    }

    var isAdjusted: Bool { adjustments.isAdjusted }
    var trayIDs: [UUID] { layout.trayIDs(adjustments: adjustments) }

    func frame(of id: UUID) -> MannequinFrame? { layout.frame(of: id, adjustments: adjustments) }
    func commitDrag(_ id: UUID, dx: Double, dy: Double) { adjustments.drag(id, dx: dx, dy: dy) }
    func commitScale(_ id: UUID, _ scale: Double) { adjustments.setScale(id, scale) }
    func drop(_ id: UUID, atX x: Double, y: Double) { adjustments.drop(id, atX: x, y: y) }
    func step(_ id: UUID, _ step: MannequinStep) { adjustments.step(id, step) }
    func reset() { adjustments.reset() }
}
