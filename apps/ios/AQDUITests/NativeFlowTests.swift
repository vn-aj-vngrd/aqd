import XCTest
import UIKit

/// Tests the delivered native baseline, not the unfinished full V1 journey.
/// No photo, persistence, network or permission substitute is injected.
@MainActor
final class NativeFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            continueAfterFailure = false
            app = XCUIApplication()
            app.launchArguments = ["--aqd-ui-testing"]
            // Stable for every relaunch within this test; unique across tests/runs.
            app.launchEnvironment["AQD_TEST_STORE_ID"] = UUID().uuidString
            app.launch()
            XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            if let run = testRun, run.failureCount > 0, app != nil {
                attachScreenshot("Failure state — \(name)")
            }
            app?.terminate()
            app = nil
        }
        try await super.tearDown()
    }

    func testNativeRootTabsExposeDestinationsTargetsAndSelection() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertEqual(tabBar.buttons.count, 5)
        for name in ["Today", "Closet", "Planner", "Agent", "Profile"] {
            let button = tab(name)
            XCTAssertTrue(button.exists, "Missing native tab: \(name)")
            XCTAssertEqual(button.label, name)
            XCTAssertGreaterThanOrEqual(button.frame.width, 44)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
            XCTAssertTrue(button.isHittable)
        }
        XCTAssertTrue(tab("Today").isSelected)
        for name in ["Closet", "Planner", "Profile", "Today"] {
            tab(name).tap()
            XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5))
            XCTAssertTrue(tab(name).isSelected, "UIKit must expose selected state for \(name)")
            for other in ["Today", "Closet", "Planner", "Profile"] where other != name {
                XCTAssertFalse(tab(other).isSelected)
            }
        }
        // XCUI labels intentionally include accessible destination names. It has
        // no public UITabBarItem.title API: nil titles need source/manual review.
        attachScreenshot("Native icon-only root tabs")
    }

    func testUnreadableRetainedDraftShowsRecoveryRefusalWithoutOpeningCapture() {
        app.terminate()
        app.launchEnvironment["AQD_TEST_CORRUPT_DRAFT"] = "1"
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        tab("Closet").tap()
        app.buttons["closet.addPiece"].tap()
        let refusal = app.alerts["Saved data unavailable"]
        XCTAssertTrue(refusal.waitForExistence(timeout: 5))
        XCTAssertTrue(refusal.staticTexts["The saved draft couldn’t open. It hasn’t been replaced."].exists)
        XCTAssertFalse(app.textFields["capture.field.name"].exists)
        attachScreenshot("Malformed retained draft remains preserved with visible recovery refusal")
        refusal.buttons["OK"].tap()
        XCTAssertTrue(app.staticTexts["Your closet starts here"].exists)
        app.buttons["closet.addPiece"].tap()
        XCTAssertTrue(refusal.waitForExistence(timeout: 5), "Retry must refuse the same retained bytes, not reset to an empty draft")
    }

    func testPieceAvailabilityAndSortControlsKeepTheEmptyCollectionHonest() {
        tab("Closet").tap()
        app.buttons["Filter pieces"].tap()
        if app.buttons["Availability"].exists { app.buttons["Availability"].tap() }
        app.buttons["Laundry"].tap()
        XCTAssertTrue(app.staticTexts["No matching pieces"].waitForExistence(timeout: 5))
        app.buttons["Clear search and filters"].tap()
        XCTAssertTrue(app.staticTexts["Your closet starts here"].waitForExistence(timeout: 5))
        app.buttons["Filter pieces"].tap()
        if app.buttons["Sort pieces"].exists { app.buttons["Sort pieces"].tap() }
        app.buttons["Recently added"].tap()
        XCTAssertTrue(app.staticTexts["Your closet starts here"].waitForExistence(timeout: 5))
        attachScreenshot("Piece availability and recently-added controls without fabricated records")
    }

    func testAgentFullScreenBackRestoresCloset() {
        tab("Closet").tap()
        XCTAssertTrue(app.navigationBars["Closet"].waitForExistence(timeout: 5))
        tab("Agent").tap()
        let agentNavigation = app.navigationBars["Agent"]
        XCTAssertTrue(agentNavigation.waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.isHittable, "Agent task must cover native root chrome")
        attachScreenshot("Full-screen Agent baseline")
        agentNavigation.buttons["Back"].tap()
        XCTAssertTrue(app.navigationBars["Closet"].waitForExistence(timeout: 5))
        XCTAssertTrue(tab("Closet").isSelected)
        XCTAssertTrue(tab("Closet").isHittable)
    }

    func testCaptureSourceClosePreservesDraftAndPhotoIsRequired() {
        tab("Closet").tap()
        app.buttons["closet.addPiece"].tap()
        let name = app.textFields["capture.field.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("UI test shoes")
        // The photo source control stays above the keyboard and opens the real
        // app source sheet. Do not invent PhotosPicker selections or photo data.
        app.buttons["capture.addPhoto"].tap()
        XCTAssertTrue(app.navigationBars["Add photo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Choose from Photos"].exists)
        XCTAssertTrue(app.buttons["Take photo"].exists)
        app.navigationBars["Add photo"].buttons["Close"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "UI test shoes")
        XCTAssertFalse(app.buttons["capture.save"].isEnabled)

        let category = app.buttons["capture.category"]
        if !category.isHittable { app.swipeUp() }
        XCTAssertTrue(category.isHittable)
        category.tap()
        let shoes = app.buttons["Shoes"]
        XCTAssertTrue(shoes.waitForExistence(timeout: 5))
        shoes.tap()
        XCTAssertTrue(category.label.contains("Shoes"))
        XCTAssertFalse(app.buttons["capture.save"].isEnabled, "Name/category alone must not save without a photo")
        attachScreenshot("Capture draft without photo")

        app.buttons["capture.back"].tap()
        XCTAssertTrue(app.navigationBars["Closet"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch() // Same launchEnvironment UUID; reopen the actual persisted draft.
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        tab("Closet").tap()
        app.buttons["closet.addPiece"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "UI test shoes")
        XCTAssertTrue(app.buttons["capture.category"].label.contains("Shoes"))
        XCTAssertFalse(app.buttons["capture.save"].isEnabled)
    }

    func testCategorySelectionWhileNameKeyboardIsActivePreservesDraft() {
        tab("Closet").tap()
        app.buttons["closet.addPiece"].tap()
        let name = app.textFields["capture.field.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Keyboard category regression")
        app.buttons["capture.category"].tap()
        let shoes = app.buttons["Shoes"]
        XCTAssertTrue(shoes.waitForExistence(timeout: 5))
        shoes.tap()
        XCTAssertTrue(app.buttons["capture.category"].label.contains("Shoes"))
        XCTAssertEqual(name.value as? String, "Keyboard category regression")
        XCTAssertFalse(app.buttons["capture.save"].isEnabled)
    }

    /// Requires scripts/seed-ios-test-photo.sh immediately before the run.
    /// Fixture pixels are synthetic, not garment-quality or production demo media.
    func testPhotosPickerSaveSearchEditAndRelaunch() {
        let originalName = "Picker shoes \(UUID().uuidString.prefix(8))"
        let editedName = originalName + " edited"
        tab("Closet").tap()
        app.segmentedControls.buttons["Outfits"].tap()
        XCTAssertTrue(app.staticTexts["Outfits aren’t implemented yet"].waitForExistence(timeout: 5))
        tab("Today").tap()
        let todayAdd = app.buttons["Add piece"]
        if !todayAdd.isHittable { app.swipeUp() }
        XCTAssertTrue(todayAdd.isHittable)
        todayAdd.tap()
        let name = app.textFields["capture.field.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["capture.save"].isEnabled)
        // Select the photo before opening the keyboard. Do not use a blind
        // downward gesture that can dismiss the native task sheet at its top.
        app.buttons["capture.addPhoto"].tap()
        XCTAssertTrue(app.navigationBars["Add photo"].waitForExistence(timeout: 5))
        app.buttons["Choose from Photos"].tap()
        // System PhotosPicker accessibility, not an app media injection.
        let photo = app.images.matching(NSPredicate(format: "identifier == 'LibraryPhoto' OR identifier == 'PXGGridLayout-Info'")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 15), app.debugDescription)
        attachScreenshot("Real Photos picker with seeded synthetic fixture")
        // iOS26 PhotosPicker exposes visible grid images without an XCUI hit point.
        // Tap the observed image center using public coordinates, never an app media hook.
        if photo.isHittable { photo.tap() }
        else { photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
        let done = app.buttons["Done"]
        if done.waitForExistence(timeout: 2) { done.tap() }
        XCTAssertTrue(app.buttons["capture.editPhoto"].waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(app.images["Selected piece photo, entire image fitted"].exists)
        XCTAssertFalse(app.buttons["capture.save"].isEnabled, "A photo alone must not save without name/category")
        name.tap()
        name.typeText(originalName)
        let category = app.buttons["capture.category"]
        if !category.isHittable { app.swipeUp() }
        category.tap()
        app.buttons["Shoes"].tap()
        XCTAssertTrue(app.buttons["capture.save"].isEnabled)
        attachScreenshot("Imported photo Fit preview")
        app.buttons["capture.editPhoto"].tap()
        XCTAssertTrue(app.navigationBars["Edit photo"].waitForExistence(timeout: 5))
        app.buttons["Rotate"].tap()
        app.buttons["Portrait 3:4"].tap()
        app.buttons["photo.editor.back"].tap()
        XCTAssertTrue(app.staticTexts["Discard photo edits?"].waitForExistence(timeout: 5))
        let keepEditing = app.buttons["Cancel"]
        if keepEditing.exists { keepEditing.tap() }
        else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap() }
        XCTAssertTrue(app.navigationBars["Edit photo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Portrait 3:4"].isSelected, "Cancellation must preserve provisional framing")
        app.buttons["photo.editor.back"].tap()
        app.buttons["Discard edits"].tap()
        XCTAssertTrue(app.images["Selected piece photo, entire image fitted"].waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, originalName)

        app.buttons["capture.editPhoto"].tap()
        XCTAssertTrue(app.navigationBars["Edit photo"].waitForExistence(timeout: 5))
        app.buttons["Rotate"].tap()
        app.buttons["Portrait 3:4"].tap()
        let zoom = app.sliders["Zoom"]
        XCTAssertTrue(zoom.exists)
        zoom.adjust(toNormalizedSliderPosition: 0.15)
        app.buttons["Move crop left"].tap()
        app.buttons["Reset"].tap()
        XCTAssertTrue(app.buttons["Fit entire photo"].isSelected)
        app.buttons["Rotate"].tap()
        app.buttons["Portrait 3:4"].tap()
        attachScreenshot("Explicit crop and rotation preview")
        let editorPreview = app.descendants(matching: .any)["photo.editor.preview"]
        XCTAssertTrue(editorPreview.exists)
        let previewViewport = portraitViewportScreenshot(editorPreview, size: CGSize(width: 240, height: 320))
        attachImage(previewViewport, name: "Crop preview viewport")
        let previewLandmark = syntheticWhiteLandmark(previewViewport)
        XCTAssertNotNil(previewLandmark, "The explicit crop preview must retain the fixture's central white landmark")
        app.buttons["Use photo"].tap()
        let selectedCrop = app.images["Selected piece photo, portrait crop"]
        XCTAssertTrue(selectedCrop.waitForExistence(timeout: 15))
        let acceptedViewport = portraitViewportScreenshot(selectedCrop, size: CGSize(width: 168, height: 224))
        attachImage(acceptedViewport, name: "Accepted crop viewport")
        let acceptedLandmark = syntheticWhiteLandmark(acceptedViewport)
        XCTAssertNotNil(acceptedLandmark)
        if let previewLandmark, let acceptedLandmark {
            XCTAssertEqual(previewLandmark.x, acceptedLandmark.x, accuracy: 0.06, "Preview and accepted rendition must show the same crop")
            XCTAssertEqual(previewLandmark.y, acceptedLandmark.y, accuracy: 0.06, "Preview and accepted rendition must show the same crop")
        }
        XCTAssertEqual(name.value as? String, originalName)
        XCTAssertTrue(app.buttons["capture.category"].label.contains("Shoes"))
        app.buttons["capture.save"].tap()
        XCTAssertTrue(app.navigationBars["Piece saved"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[originalName].exists)
        attachScreenshot("Actual save receipt")
        app.buttons["capture.openCloset"].tap()
        searchAndOpen(originalName)
        XCTAssertTrue(app.staticTexts["Shoes"].exists)
        XCTAssertFalse(app.staticTexts["Photo unavailable"].exists)
        app.buttons["piece.edit"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: originalName.count))
        name.typeText(editedName)
        XCTAssertEqual(name.value as? String, editedName)
        XCTAssertTrue(app.buttons["capture.category"].label.contains("Shoes"))
        // Leaving and reopening Edit must resume this piece's durable draft,
        // not create competing drafts that permanently block Save.
        app.buttons["capture.back"].tap()
        XCTAssertTrue(app.buttons["piece.edit"].waitForExistence(timeout: 5))
        app.navigationBars["Piece"].buttons["Closet"].tap()
        let searchCancel = app.buttons["Cancel"]
        if searchCancel.exists { searchCancel.tap() }
        else if app.buttons["Close"].exists { app.buttons["Close"].tap() }
        app.buttons["closet.addPiece"].tap()
        XCTAssertTrue(app.navigationBars["Add piece"].waitForExistence(timeout: 5), "Add must not reopen an unrelated saved-item edit")
        XCTAssertNotEqual(name.value as? String, editedName)
        XCTAssertFalse(app.buttons["capture.save"].isEnabled)
        app.buttons["capture.back"].tap()
        let existingPiece = app.staticTexts[originalName].firstMatch
        XCTAssertTrue(existingPiece.waitForExistence(timeout: 5))
        existingPiece.tap()
        app.buttons["piece.edit"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, editedName, "Creating a new draft must not replace this piece’s retained edit")
        app.swipeUp()
        app.buttons["More details"].tap()
        let color = app.textFields["capture.field.color"]
        XCTAssertTrue(color.waitForExistence(timeout: 5))
        color.tap()
        color.typeText("Synthetic blue")
        app.buttons["Apply"].tap()
        XCTAssertTrue(app.buttons["capture.save"].isEnabled)
        app.buttons["capture.save"].tap()
        XCTAssertTrue(app.navigationBars["Piece saved"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[editedName].exists)
        app.terminate()
        app.launch() // Retains this test's isolated store UUID, not a fresh store.
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        tab("Closet").tap()
        searchAndOpen(editedName)
        XCTAssertTrue(app.staticTexts[editedName].exists)
        XCTAssertTrue(app.staticTexts["Shoes"].exists)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Synthetic blue"].exists)
        XCTAssertFalse(app.staticTexts["Photo unavailable"].exists)
        attachScreenshot("Saved edited record after process relaunch")
        app.buttons["More piece options"].tap()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Delete this piece?"].waitForExistence(timeout: 5))
        attachScreenshot("Source-associated native piece deletion decision")
        let cancel = app.buttons["Cancel"]
        if cancel.exists {
            cancel.tap() // iOS18 compact action-sheet cancellation.
        } else {
            // Source-adaptive iOS26 inline choices omit visible Cancel. Tap the
            // observed blank owner area below the popover, not a command/tab.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap()
        }
        XCTAssertTrue(app.buttons["piece.edit"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[editedName].exists, "Cancel must preserve the reviewed piece")

        // Retained edits may become stale after archive/restore. Recovery must
        // preserve them until the user explicitly reviews and discards them.
        app.buttons["piece.edit"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(" pending")
        let pendingName = name.value as? String ?? ""
        XCTAssertTrue(pendingName.contains("pending"))
        app.buttons["capture.back"].tap()
        app.buttons["More piece options"].tap()
        app.buttons["Archive"].tap()
        app.buttons["Archive"].tap()
        XCTAssertTrue(app.buttons["Undo archive"].waitForExistence(timeout: 5))
        app.buttons["Undo archive"].tap()
        app.buttons["piece.edit"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, pendingName)
        app.buttons["capture.save"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'This piece changed after your draft began.'")).firstMatch.waitForExistence(timeout: 5))
        app.buttons["capture.discard"].tap()
        let keepDraft = app.buttons["Keep editing"]
        if keepDraft.exists { keepDraft.tap() }
        else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap() }
        XCTAssertEqual(name.value as? String, pendingName)
        app.buttons["capture.discard"].tap()
        app.buttons.matching(NSPredicate(format: "label == 'Discard draft' AND identifier != 'capture.discard'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["piece.edit"].waitForExistence(timeout: 5))
        app.buttons["piece.edit"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, editedName)
        app.buttons["capture.save"].tap()
        XCTAssertTrue(app.navigationBars["Piece saved"].waitForExistence(timeout: 10))
        app.buttons["capture.openCloset"].tap()
        XCTAssertTrue(app.navigationBars["Closet"].waitForExistence(timeout: 5))
        let savedResult = app.staticTexts[editedName].firstMatch
        XCTAssertTrue(savedResult.waitForExistence(timeout: 5), "Open Closet must retain the existing search and show the saved piece")
        savedResult.tap()
        app.buttons["More piece options"].tap()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Delete this piece?"].waitForExistence(timeout: 5))
        // Outside dismissal must cancel an unsubmitted review on both compact
        // and source-inline native choices, without invoking a background action.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["piece.edit"].isHittable)
        app.buttons["More piece options"].tap()
        app.buttons["Archive"].tap()
        app.buttons["Archive"].tap()
        app.buttons["Undo archive"].tap()
        app.buttons["More piece options"].tap()
        app.buttons["Delete"].tap()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.navigationBars["Closet"].waitForExistence(timeout: 10), "A cancelled review must not retain Archive’s operation or an old revision")
        XCTAssertFalse(app.staticTexts[editedName].exists)
    }

    /// Compare rendered output at the public UI seam, not implementation geometry.
    /// Only the seeder's synthetic blue field/white landmark is meaningful here.
    private func syntheticWhiteLandmark(_ image: UIImage) -> CGPoint? {
        guard let source = image.cgImage else { return nil }
        let width = source.width, height = source.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        var minX = width, minY = height, maxX = -1, maxY = -1
        var whiteCount = 0, whiteX = 0.0, whiteY = 0.0
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = pixels[offset], g = pixels[offset + 1], b = pixels[offset + 2]
                if r < 60 && g > 75 && b > 180 {
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
                if r > 250 && g > 250 && b > 250 {
                    whiteCount += 1; whiteX += Double(x); whiteY += Double(y)
                }
            }
        }
        guard whiteCount > 5, maxX > minX, maxY > minY else { return nil }
        // Both portrait targets have exact 3:4 viewports. Normalize against that
        // viewport, not inferred blue-color bounds: native blurred chrome can
        // desaturate an obscured edge without changing the actual crop geometry.
        return CGPoint(x: (whiteX / Double(whiteCount)) / Double(width),
                       y: (whiteY / Double(whiteCount)) / Double(height))
    }

    private func portraitViewportScreenshot(_ element: XCUIElement, size: CGSize) -> UIImage {
        let frame = element.frame
        let screenshot = element.screenshot().image
        guard let image = screenshot.cgImage, frame.width > 0 else {
            XCTFail("The rendered photo viewport must be measurable")
            return screenshot
        }
        // SwiftUI can expose the centered preview's full-width accessibility
        // wrapper. Inspect its actual fixed portrait viewport, not side padding.
        let scale = CGFloat(image.width) / frame.width
        let width = size.width * scale, height = size.height * scale
        let viewport = CGRect(x: (CGFloat(image.width) - width) / 2,
                              y: (CGFloat(image.height) - height) / 2,
                              width: width, height: height).integral
        guard let cropped = image.cropping(to: viewport),
              abs(CGFloat(cropped.width) - width) <= 2,
              abs(CGFloat(cropped.height) - height) <= 2 else {
            XCTFail("The full expected portrait viewport must be captured")
            return screenshot
        }
        return UIImage(cgImage: cropped, scale: screenshot.scale, orientation: screenshot.imageOrientation)
    }

    private func attachImage(_ image: UIImage, name: String) {
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func searchAndOpen(_ name: String) {
        XCTAssertTrue(app.navigationBars["Closet"].waitForExistence(timeout: 5))
        let search = app.searchFields["Search pieces"]
        if !search.isHittable { app.swipeDown() }
        XCTAssertTrue(search.waitForExistence(timeout: 5), app.debugDescription)
        search.tap()
        search.typeText(name)
        let result = app.staticTexts[name].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), app.debugDescription)
        attachScreenshot("Closet search result")
        result.tap()
        XCTAssertTrue(app.navigationBars["Piece"].waitForExistence(timeout: 5))
    }

    private func tab(_ name: String) -> XCUIElement {
        let buttons = app.tabBars.firstMatch.buttons
        let identified = buttons["root.tab.\(name.lowercased())"]
        return identified.exists ? identified : buttons[name]
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
