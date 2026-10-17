import Foundation

/// A plain-language reason a piece photo may not look its best in a listing.
public enum PhotoQualityHint: String, CaseIterable, Equatable, Sendable {
    case lowResolution, pieceCutOff, pieceSmall, backgroundMostlyKept, noPieceFound

    public var message: String {
        switch self {
        case .lowResolution: "Low resolution. Retake closer or in better light for a sharper listing."
        case .pieceCutOff: "The piece touches the edge of the photo. Leave a little space around it."
        case .pieceSmall: "The piece is small in the frame. Move closer or crop in."
        case .backgroundMostlyKept: "Most of the photo was kept. Refine the edges, or try a plain background."
        case .noPieceFound: "No piece was detected. Try a plain background, or erase it by hand."
        }
    }
}

public enum PhotoQuality {
    public static let minimumShortSide = 800
    private static let edgeTolerance = 0.005
    private static let smallCoverage = 0.10
    private static let largeCoverage = 0.90

    /// Hints for a photo, in the order a person should fix them. `subjectFound` is nil until a cutout has run;
    /// `keptBounds` is the normalized (top-left origin) box of the kept piece and `coverage` the kept fraction of the frame.
    public static func assess(pixelWidth: Int, pixelHeight: Int, subjectFound: Bool? = nil,
                              keptBounds: PhotoEditRecipe.NormalizedRect? = nil, coverage: Double? = nil) -> [PhotoQualityHint] {
        var hints: [PhotoQualityHint] = []
        if min(pixelWidth, pixelHeight) > 0, min(pixelWidth, pixelHeight) < minimumShortSide { hints.append(.lowResolution) }
        if subjectFound == false { return hints + [.noPieceFound] }
        if let box = keptBounds {
            let touches = box.x <= edgeTolerance || box.y <= edgeTolerance
                || box.x + box.width >= 1 - edgeTolerance || box.y + box.height >= 1 - edgeTolerance
            if touches { hints.append(.pieceCutOff) }
        }
        if let coverage {
            if coverage < smallCoverage { hints.append(.pieceSmall) } else if coverage > largeCoverage { hints.append(.backgroundMostlyKept) }
        }
        return hints
    }

    /// The kept box grown by `padding` of its own size, clamped to the frame. Used as the non-destructive "fit to piece" crop.
    public static func paddedCrop(_ box: PhotoEditRecipe.NormalizedRect, padding: Double) -> PhotoEditRecipe.NormalizedRect {
        let padX = box.width * padding, padY = box.height * padding
        let x = max(0, box.x - padX), y = max(0, box.y - padY)
        let right = min(1, box.x + box.width + padX), bottom = min(1, box.y + box.height + padY)
        return .init(x: x, y: y, width: right - x, height: bottom - y)
    }
}
