import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import Observation

/// Editing state for the piece cutout: an automatic subject mask refined by erase, restore and trim.
/// The mask lives at a bounded working resolution; export applies it to the full-resolution original.
@MainActor @Observable
final class PieceCutoutModel {
    enum Tool: String, CaseIterable { case erase = "Erase", restore = "Restore", trim = "Trim", move = "Move" }
    /// `choosing`: nothing has run yet, the person picks Auto cut out or By hand. `unsupported`: this iPhone has no subject model.
    enum Phase: Equatable { case choosing, detecting, ready, noSubject, failed, unsupported }
    private struct Snapshot { let mask: CGImage; let trim: CGRect }

    static let fullTrim = CGRect(x: 0, y: 0, width: 1, height: 1)
    private static let workingSize = 1400
    private static let historyLimit = 24

    let source: BackgroundPhotoInput
    private(set) var phase = Phase.choosing
    private(set) var workImage: CGImage?
    private(set) var cutout: CGImage?
    private(set) var coverage = 1.0
    private(set) var edited = false
    var tool = Tool.erase
    var brushRadius: CGFloat = 20
    var zoom: CGFloat = 1
    var offset = CGSize.zero
    var showOriginal = false
    var fitToPiece = true
    var background = CutoutBackground.transparent
    /// Edge softness in working-resolution pixels.
    var feather: CGFloat = 0.8
    private(set) var trim = PieceCutoutModel.fullTrim

    private var mask: CutoutMask?
    private var autoMask: CGImage?
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []
    private var task: Task<Void, Never>?

    init(source: BackgroundPhotoInput) { self.source = source }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var maskSize: CGSize { CGSize(width: mask?.width ?? 1, height: mask?.height ?? 1) }
    var hasKeptPixels: Bool { coverage > 0.002 }
    var isTrimmed: Bool { trim != Self.fullTrim }

    /// Open the editor. A saved cutout reopens from its alpha channel; otherwise nothing runs until the person chooses.
    func start() {
        task?.cancel()
        phase = .choosing
        guard let image = Self.workingImage(from: source.data), let mask = CutoutMask(width: image.width, height: image.height) else {
            phase = .failed
            return
        }
        workImage = image
        self.mask = mask
        // A saved cutout already holds the mask in its alpha channel: reopen it instead of detecting again.
        if let existing = source.existingCutout, let cgImage = Self.decode(existing), let alpha = CutoutRenderer.alphaMask(of: cgImage) {
            autoMask = alpha
            mask.load(alpha)
            finishDetection(.ready)
            return
        }
        if !PhotoBackgroundRemover.isSupported { finishDetection(.unsupported); return }
        mask.fill(keeping: true)
        render()
    }

    /// Keep the whole photo and let the person erase the background themselves.
    func startByHand() {
        guard phase == .choosing || phase == .noSubject || phase == .failed || phase == .unsupported else { return }
        phase = .ready
    }

    /// Find the piece with on-device Vision, then refine by hand.
    func detectAutomatically() {
        guard let mask, phase != .detecting else { return }
        guard PhotoBackgroundRemover.isSupported else { finishDetection(.unsupported); return }
        task?.cancel()
        phase = .detecting
        let data = source.data
        task = Task { [weak self] in
            do {
                let detected = try await PhotoBackgroundRemover.shared.detectMask(data: data)
                guard !Task.isCancelled, let self else { return }
                self.autoMask = detected.image
                mask.load(detected.image)
                self.finishDetection(.ready)
            } catch BackgroundPhotoError.noForeground {
                guard !Task.isCancelled else { return }
                self?.finishDetection(.noSubject)
            } catch {
                guard !Task.isCancelled else { return }
                self?.finishDetection(.failed)
            }
        }
    }

    func cancel() { task?.cancel(); task = nil }

    private func finishDetection(_ result: Phase) {
        phase = result
        if result != .ready { mask?.fill(keeping: true) }
        undoStack.removeAll(); redoStack.removeAll()
        render()
    }

    // MARK: Editing

    func beginStroke() { pushUndo() }

    func stroke(from start: CGPoint, to end: CGPoint, radius: CGFloat) {
        guard tool == .erase || tool == .restore else { return }
        mask?.paint(from: start, to: end, radius: radius, keep: tool == .restore)
        edited = true
        render()
    }

    func setTrim(_ rect: CGRect, recording: Bool) {
        if recording { pushUndo() }
        trim = rect
        edited = true
        render()
    }

    func undo() {
        guard let previous = undoStack.popLast(), let current = snapshot() else { return }
        redoStack.append(current)
        restore(previous)
    }

    func redo() {
        guard let next = redoStack.popLast(), let current = snapshot() else { return }
        undoStack.append(current)
        restore(next)
    }

    /// Back to the automatic result (or the untouched photo when nothing was detected).
    func reset() {
        pushUndo()
        if let autoMask { mask?.load(autoMask) } else { mask?.fill(keeping: true) }
        trim = Self.fullTrim
        zoom = 1
        offset = .zero
        edited = false
        render()
    }

    private func pushUndo() {
        guard let current = snapshot() else { return }
        undoStack.append(current)
        if undoStack.count > Self.historyLimit { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    private func snapshot() -> Snapshot? { mask?.image.map { Snapshot(mask: $0, trim: trim) } }

    private func restore(_ snapshot: Snapshot) {
        mask?.load(snapshot.mask)
        trim = snapshot.trim
        edited = true
        render()
    }

    // MARK: Output

    private func effectiveMask() -> CGImage? { mask?.trimmed(to: trim) }

    private func render() {
        guard let work = workImage, let effective = effectiveMask() else { return }
        coverage = CutoutRenderer.coverage(of: effective)
        var result = CutoutRenderer.composite(CIImage(cgImage: work), mask: effective, feather: feather)
        if let color = background.color { result = result.composited(over: CIImage(color: color).cropped(to: result.extent)) }
        cutout = CutoutRenderer.context.createCGImage(result, from: result.extent)
    }

    /// Re-render the preview after a background or softness change.
    func refresh() { render() }

    /// The full-size cutout as a new draft photo plus its non-destructive fit-to-piece crop.
    func finish() async throws -> CutoutOutcome {
        guard let effective = effectiveMask() else { throw CutoutError.emptyResult }
        return try await CutoutPipeline.render(original: source.data, mask: effective, background: background, feather: feather, fitToPiece: fitToPiece)
    }

    var hasSavedCutout: Bool { source.existingCutout != nil }

    private static func decode(_ data: Data) -> CGImage? {
        CGImageSourceCreateWithData(data as CFData, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
    }

    private static func workingImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: workingSize,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary)
    }
}
