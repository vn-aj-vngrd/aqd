import XCTest

/// The mannequin view of an outfit, on the seeded preview closet in a UUID-isolated store.
@MainActor
final class MannequinFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--aqd-ui-testing", "-AppleInterfaceStyle", "Light"]
        app.launchEnvironment["AQD_TEST_STORE_ID"] = UUID().uuidString
        app.launchEnvironment["AQD_TEST_RETURNING_ENTRY"] = "1"
        app.launchEnvironment["AQD_TEST_SEED_SAMPLES"] = "1"
        app.launchEnvironment["AQD_TEST_RESET_VIEW_MODE"] = "1"
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
        app.tabBars.buttons["Closet"].tap()
        XCTAssertTrue(app.buttons["closet.scope.outfits"].waitForExistence(timeout: 10))
        app.buttons["closet.scope.outfits"].tap()
    }

    override func tearDown() async throws {
        if testRun?.failureCount ?? 0 > 0 { capture("Failure — \(name)") }
        app.terminate()
        try await super.tearDown()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    private func openOutfit(_ name: String) {
        let card = app.buttons.matching(NSPredicate(format: "identifier ENDSWITH %@", ".card.\(name)")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "outfit card \(name)")
        card.tapAfterSystemBannersClear(in: app)
        XCTAssertTrue(app.segmentedControls["outfit.viewMode"].waitForExistence(timeout: 10))
    }

    private func piece(_ name: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "mannequin.piece")
            .matching(NSPredicate(format: "label BEGINSWITH %@", "\(name), ")).firstMatch
    }

    private func goBack() { app.navigationBars.buttons.firstMatch.tap() }

    func testAC1AC8MannequinIsChosenDressedAndRemembered() {
        openOutfit("Office day")
        let control = app.segmentedControls["outfit.viewMode"]
        XCTAssertTrue(control.buttons["Collage"].isSelected, "AC-8: Collage is the default")
        XCTAssertFalse(app.otherElements["mannequin.canvas"].exists)
        capture("S1-collage-default")

        control.buttons["Mannequin"].tap()
        XCTAssertTrue(app.otherElements["mannequin.canvas"].waitForExistence(timeout: 5))
        for name in ["Blue cotton shirt", "Tailored trousers", "Oxblood loafers", "Black belt"] {
            XCTAssertTrue(piece(name).waitForExistence(timeout: 5), "AC-1: \(name) is on the mannequin")
        }
        capture("S1-mannequin")

        goBack()
        openOutfit("Coffee run")
        XCTAssertTrue(app.segmentedControls["outfit.viewMode"].buttons["Mannequin"].isSelected, "AC-8: choice remembered")
        XCTAssertTrue(app.otherElements["mannequin.canvas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "mannequin.piece").firstMatch.waitForExistence(timeout: 5))
        capture("S1-remembered")

        app.terminate()
        app.launchEnvironment["AQD_TEST_RESET_VIEW_MODE"] = nil
        app.launch()
        app.tabBars.buttons["Closet"].tap()
        app.buttons["closet.scope.outfits"].tap()
        openOutfit("Office day")
        XCTAssertTrue(app.segmentedControls["outfit.viewMode"].buttons["Mannequin"].isSelected, "AC-8: survives relaunch")
    }

    private func dragPiece(_ element: XCUIElement, byX dx: CGFloat, y dy: CGFloat) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: dx, dy: dy)))
    }

    private func openMannequin(_ outfit: String) {
        openOutfit(outfit)
        let mannequin = app.segmentedControls["outfit.viewMode"].buttons["Mannequin"]
        if !mannequin.isSelected { mannequin.tap() }
        XCTAssertTrue(app.otherElements["mannequin.canvas"].waitForExistence(timeout: 5))
        XCTAssertTrue(piece("Blue cotton shirt").waitForExistence(timeout: 5))
    }

    func testAC2AC11AC7DragResetAndReopenRestoreTheDefaults() {
        openMannequin("Office day")
        let shirt = piece("Blue cotton shirt"), belt = piece("Black belt"), trousers = piece("Tailored trousers")
        let shirtStart = shirt.frame, beltStart = belt.frame, trousersStart = trousers.frame
        XCTAssertFalse(app.buttons["mannequin.reset"].exists, "Reset appears only after an adjustment")
        capture("S1-mannequin-before-adjust")

        dragPiece(shirt, byX: 30, y: 40)
        XCTAssertTrue(app.buttons["mannequin.reset"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(piece("Blue cotton shirt").frame.minY, shirtStart.minY + 20, "AC-2: the shirt moved down")
        XCTAssertGreaterThan(piece("Blue cotton shirt").frame.minX, shirtStart.minX + 15, "AC-2: the shirt moved right")

        let waist = trousers.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        belt.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.05, thenDragTo: waist)
        XCTAssertNotEqual(piece("Black belt").frame.origin.x, beltStart.origin.x, "AC-11: the belt left the tray")
        let beltOnFigure = piece("Black belt").frame
        XCTAssertTrue(trousersStart.insetBy(dx: -40, dy: -40).contains(CGPoint(x: beltOnFigure.midX, y: beltOnFigure.midY)), "AC-11: the belt sits on the figure")
        capture("S2-adjusted")

        let reset = app.buttons["mannequin.reset"]
        XCTAssertGreaterThanOrEqual(reset.frame.height, 44, "AC-7: Reset has a 44 pt target")
        reset.tap()
        XCTAssertFalse(app.buttons["mannequin.reset"].waitForExistence(timeout: 1))
        XCTAssertEqual(piece("Blue cotton shirt").frame.origin.y, shirtStart.origin.y, accuracy: 2, "AC-2: shirt back in its slot")
        XCTAssertEqual(piece("Blue cotton shirt").frame.origin.x, shirtStart.origin.x, accuracy: 2)
        XCTAssertEqual(piece("Black belt").frame.origin.x, beltStart.origin.x, accuracy: 2, "AC-11: belt back in the tray")
        XCTAssertEqual(piece("Black belt").frame.origin.y, beltStart.origin.y, accuracy: 2)
        capture("S2-reset")

        dragPiece(piece("Tailored trousers"), byX: -30, y: 30)
        XCTAssertTrue(app.buttons["mannequin.reset"].waitForExistence(timeout: 5))
        XCTAssertNotEqual(piece("Tailored trousers").frame.origin.y, trousersStart.origin.y)
        goBack()
        openMannequin("Office day")
        XCTAssertFalse(app.buttons["mannequin.reset"].exists, "AC-2: nothing from the earlier drag remains")
        XCTAssertEqual(piece("Tailored trousers").frame.origin.y, trousersStart.origin.y, accuracy: 2)
        XCTAssertEqual(piece("Tailored trousers").frame.origin.x, trousersStart.origin.x, accuracy: 2)
        capture("S2-reopened")
    }

    func testAC2SwitchingToCollageAndBackRestoresTheDefaults() {
        openMannequin("Office day")
        let start = piece("Blue cotton shirt").frame
        dragPiece(piece("Blue cotton shirt"), byX: 0, y: 50)
        XCTAssertTrue(app.buttons["mannequin.reset"].waitForExistence(timeout: 5))
        let control = app.segmentedControls["outfit.viewMode"]
        control.buttons["Collage"].tap()
        control.buttons["Mannequin"].tap()
        XCTAssertTrue(piece("Blue cotton shirt").waitForExistence(timeout: 5))
        XCTAssertEqual(piece("Blue cotton shirt").frame.origin.y, start.origin.y, accuracy: 2)
        XCTAssertFalse(app.buttons["mannequin.reset"].exists)
    }
}
