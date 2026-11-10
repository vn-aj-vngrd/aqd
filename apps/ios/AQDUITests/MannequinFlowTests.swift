import XCTest

/// The mannequin view of an outfit, on the seeded preview closet in a UUID-isolated store.
@MainActor
final class MannequinFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        launch(appearance: "Light", resetViewMode: true, storeID: UUID().uuidString)
    }

    override func tearDown() async throws {
        if testRun?.failureCount ?? 0 > 0 { capture("Failure - \(name)") }
        app.terminate()
        try await super.tearDown()
    }

    private func launch(appearance: String, resetViewMode: Bool, storeID: String) {
        app = XCUIApplication()
        app.launchArguments = ["--aqd-ui-testing", "-AppleInterfaceStyle", appearance]
        app.launchEnvironment["AQD_TEST_STORE_ID"] = storeID
        app.launchEnvironment["AQD_TEST_RETURNING_ENTRY"] = "1"
        app.launchEnvironment["AQD_TEST_SEED_SAMPLES"] = "1"
        app.launchEnvironment["AQD_TEST_RESET_VIEW_MODE"] = resetViewMode ? "1" : nil
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
        app.tabBars.buttons["Closet"].tap()
        XCTAssertTrue(app.buttons["closet.scope.outfits"].waitForExistence(timeout: 10))
        app.buttons["closet.scope.outfits"].tap()
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

    func testAC1AC10MannequinIsChosenDressedAndRemembered() {
        openOutfit("Office day")
        let control = app.segmentedControls["outfit.viewMode"]
        XCTAssertTrue(control.buttons["Collage"].isSelected, "AC-10: Collage is the default")
        XCTAssertFalse(app.otherElements["mannequin.canvas"].exists)
        capture("S2-collage-default")

        control.buttons["Mannequin"].tap()
        let canvas = app.otherElements["mannequin.canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        for name in ["Blue cotton shirt", "Tailored trousers", "Oxblood loafers", "Black belt"] {
            XCTAssertTrue(piece(name).waitForExistence(timeout: 5), "AC-1: \(name) is on the mannequin")
        }
        let shirt = piece("Blue cotton shirt").frame, trousers = piece("Tailored trousers").frame
        let loafers = piece("Oxblood loafers").frame, belt = piece("Black belt").frame
        XCTAssertLessThan(shirt.minY, trousers.minY, "AC-1: the shirt starts at the shoulders, above the trousers' waist")
        XCTAssertLessThan(shirt.minY, canvas.frame.minY + canvas.frame.height * 0.35, "AC-1: the shirt's top is near the shoulders")
        XCTAssertGreaterThan(loafers.maxY, trousers.maxY - 2, "AC-1: the loafers are at the feet")
        XCTAssertGreaterThan(loafers.minY, trousers.midY, "AC-1: the loafers sit below the trousers' middle")
        XCTAssertGreaterThan(belt.minX, shirt.maxX - 1, "AC-1: the belt waits in the tray beside the figure")
        capture("S2-mannequin")

        goBack()
        openOutfit("Coffee run")
        XCTAssertTrue(app.segmentedControls["outfit.viewMode"].buttons["Mannequin"].isSelected, "AC-10: choice remembered")
        XCTAssertTrue(app.otherElements["mannequin.canvas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "mannequin.piece").firstMatch.waitForExistence(timeout: 5))
        capture("S2-remembered")
    }

    func testAC10AC12MannequinSurvivesRelaunchInDark() {
        openOutfit("Office day")
        app.segmentedControls["outfit.viewMode"].buttons["Mannequin"].tap()
        XCTAssertTrue(app.otherElements["mannequin.canvas"].waitForExistence(timeout: 5))
        let store = app.launchEnvironment["AQD_TEST_STORE_ID"] ?? UUID().uuidString
        app.terminate()

        launch(appearance: "Dark", resetViewMode: false, storeID: store)
        openOutfit("Office day")
        XCTAssertTrue(app.segmentedControls["outfit.viewMode"].buttons["Mannequin"].isSelected, "AC-10: survives relaunch")
        XCTAssertTrue(app.otherElements["mannequin.canvas"].waitForExistence(timeout: 5))
        XCTAssertTrue(piece("Blue cotton shirt").waitForExistence(timeout: 5))
        capture("S2-dark")
    }
}
