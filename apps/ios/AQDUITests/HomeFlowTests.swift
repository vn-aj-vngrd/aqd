import XCTest

/// Today (Home) on a real phone: seeded preview closet in a UUID-isolated store, no Photos fixture.
@MainActor
final class HomeFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--aqd-ui-testing"]
        app.launchEnvironment["AQD_TEST_STORE_ID"] = UUID().uuidString
        app.launchEnvironment["AQD_TEST_RETURNING_ENTRY"] = "1"
        app.launchEnvironment["AQD_TEST_SEED_SAMPLES"] = "1"
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
    }

    override func tearDown() async throws {
        if testRun?.failureCount ?? 0 > 0 { shot("Failure — \(name)") }
        app.terminate()
        try await super.tearDown()
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.lifetime = .keepAlways
        attachment.name = name; add(attachment)
    }

    /// The one action that matters is reachable without scrolling, and the stack does not repeat itself.
    func testTodaysLookLeadsWithOnePrimaryAction() {
        app.tabBars.buttons["Today"].tap()
        let primary = app.buttons["Record wear"]
        XCTAssertTrue(primary.waitForExistence(timeout: 10))
        XCTAssertTrue(primary.isHittable, "visible on the first screen")
        XCTAssertFalse(app.buttons["View outfit"].exists, "the picture opens the outfit instead of a text row")
        shot("Today look")
        app.swipeUp(velocity: .slow); app.swipeUp(velocity: .slow)
        let today = app.staticTexts.matching(NSPredicate(format: "label CONTAINS ', 2026'"))
        XCTAssertTrue(today.allElementsBoundByIndex.isEmpty, "no long weekday dates in the stack")
        XCTAssertTrue(app.staticTexts["Tomorrow, Coffee and errands"].exists || !app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Tomorrow'")).allElementsBoundByIndex.isEmpty,
                      "upcoming plans use short relative days and skip today's look")
        shot("Today upcoming")
    }

    /// Evidence for review: the stack top to bottom with eyebrows above titles.
    func testStackReadsEyebrowThenTitle() {
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.buttons["Record wear"].waitForExistence(timeout: 10))
        for index in 0..<4 {
            shot("Today \(index)")
            app.swipeUp(velocity: .slow)
        }
        XCTAssertFalse(app.staticTexts["Oct 18"].exists, "the week eyebrow spans the whole week")
    }
}
