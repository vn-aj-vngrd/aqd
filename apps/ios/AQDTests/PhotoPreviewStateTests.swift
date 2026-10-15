import XCTest
@testable import AQD

final class PhotoPreviewStateTests: XCTestCase {
    func testFailedRotationStopsProgressAndResetRecoversRetainedSource() {
        var preview = PhotoPreviewState()
        preview.beginPreparation()
        XCTAssertTrue(preview.isPreparing(quarterTurns: 1, applying: false))

        preview.failPreparation()
        XCTAssertNotNil(preview.error)
        XCTAssertEqual(preview.quarterTurns, 0, "Failure must retain the original preview, not mark the failed rotation as rendered")
        XCTAssertFalse(preview.isPreparing(quarterTurns: 1, applying: false), "A failed preview shows recovery feedback, not endless progress")

        // Reset requests the retained original orientation and starts a new preparation.
        preview.beginPreparation()
        XCTAssertNil(preview.error)
        preview.finishPreparation(quarterTurns: 0)
        XCTAssertEqual(preview.quarterTurns, 0)
        XCTAssertFalse(preview.isPreparing(quarterTurns: 0, applying: false))
        XCTAssertNil(preview.error)
    }

    func testResetAtZeroRotationCreatesANewPreparationIdentity() {
        var preview = PhotoPreviewState()
        XCTAssertTrue(preview.canUsePhoto(quarterTurns: 0, applying: false))
        preview.requestRetry()
        XCTAssertFalse(preview.canUsePhoto(quarterTurns: 0, applying: false), "Queued preparation blocks acceptance before task scheduling")
        preview.failPreparation()
        XCTAssertFalse(preview.canUsePhoto(quarterTurns: 0, applying: false))
        let failedIdentity = [0, preview.retryGeneration]

        // The real Reset control calls this even when quarterTurns stays zero.
        preview.requestRetry()
        XCTAssertNotEqual([0, preview.retryGeneration], failedIdentity)
        XCTAssertEqual(preview.quarterTurns, 0, "Retry must not change accepted orientation")
        preview.beginPreparation()
        XCTAssertNil(preview.error)
        XCTAssertTrue(preview.isPreparing(quarterTurns: 0, applying: false),
                      "A zero-rotation retry is real preparation work until it finishes")
        XCTAssertFalse(preview.canUsePhoto(quarterTurns: 0, applying: false))
        preview.finishPreparation(quarterTurns: 0)
        XCTAssertFalse(preview.isPreparing(quarterTurns: 0, applying: false))
        XCTAssertTrue(preview.canUsePhoto(quarterTurns: 0, applying: false))
        XCTAssertFalse(preview.canUsePhoto(quarterTurns: 0, applying: true), "Application owns its own pending operation")
    }

    func testRetryClearsFailureAndShowsOnlyPreviewOperationProgress() {
        var preview = PhotoPreviewState()
        preview.failPreparation()
        preview.beginPreparation()
        XCTAssertNil(preview.error)
        XCTAssertTrue(preview.isPreparing(quarterTurns: 1, applying: false))
        XCTAssertFalse(preview.isPreparing(quarterTurns: 1, applying: true), "Applying already has its own operation indicator")
        preview.finishPreparation(quarterTurns: 1)
        XCTAssertFalse(preview.isPreparing(quarterTurns: 1, applying: false))
        XCTAssertEqual(preview.quarterTurns, 1)
    }
}
