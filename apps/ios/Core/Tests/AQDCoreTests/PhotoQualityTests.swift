import Testing
@testable import AQDCore

struct PhotoQualityTests {
    private let centered = PhotoEditRecipe.NormalizedRect(x: 0.2, y: 0.15, width: 0.6, height: 0.7)

    @Test func aSharpWellFramedPhotoHasNoHints() {
        #expect(PhotoQuality.assess(pixelWidth: 3024, pixelHeight: 4032, subjectFound: true, keptBounds: centered, coverage: 0.4).isEmpty)
    }

    @Test func lowResolutionIsFlaggedFromTheShortSide() {
        #expect(PhotoQuality.assess(pixelWidth: 600, pixelHeight: 4000) == [.lowResolution])
        #expect(PhotoQuality.assess(pixelWidth: 800, pixelHeight: 800).isEmpty)
    }

    @Test func noPieceFoundStopsFurtherCutoutHints() {
        #expect(PhotoQuality.assess(pixelWidth: 2000, pixelHeight: 2000, subjectFound: false, keptBounds: centered, coverage: 0.5) == [.noPieceFound])
    }

    @Test func edgeContactSizeAndOverreachAreReported() {
        let edge = PhotoEditRecipe.NormalizedRect(x: 0, y: 0.1, width: 0.5, height: 0.6)
        #expect(PhotoQuality.assess(pixelWidth: 2000, pixelHeight: 2000, subjectFound: true, keptBounds: edge, coverage: 0.3) == [.pieceCutOff])
        #expect(PhotoQuality.assess(pixelWidth: 2000, pixelHeight: 2000, subjectFound: true, keptBounds: centered, coverage: 0.05) == [.pieceSmall])
        #expect(PhotoQuality.assess(pixelWidth: 2000, pixelHeight: 2000, subjectFound: true, keptBounds: centered, coverage: 0.95) == [.backgroundMostlyKept])
    }

    @Test func paddedCropGrowsTheBoxAndStaysInsideTheFrame() {
        let grown = PhotoQuality.paddedCrop(centered, padding: 0.1)
        #expect(grown.x < centered.x && grown.y < centered.y && grown.width > centered.width)
        let nearEdge = PhotoQuality.paddedCrop(.init(x: 0.02, y: 0.02, width: 0.96, height: 0.96), padding: 0.2)
        #expect(nearEdge.x == 0 && nearEdge.y == 0 && nearEdge.x + nearEdge.width <= 1 && nearEdge.y + nearEdge.height <= 1)
        #expect((try? PhotoEditRecipe(crop: nearEdge).validated()) != nil)
    }
}
