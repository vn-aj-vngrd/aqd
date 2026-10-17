import XCTest

/// The Closet on a real phone: seeded preview closet in a UUID-isolated store, no Photos fixture.
/// Sample data: 12 pieces (Ivory ribbed knit is in the laundry, Olive overshirt unavailable),
/// 6 outfits (Office day, Coffee run, …) and 4 themes (Weekday, Off duty, Evening, Ideas to collect).
@MainActor
final class ClosetFlowTests: XCTestCase {
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
        app.tabBars.buttons["Closet"].tap()
        XCTAssertTrue(app.buttons["closet.scope.pieces"].waitForExistence(timeout: 10))
    }

    override func tearDown() async throws {
        if testRun?.failureCount ?? 0 > 0 {
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.lifetime = .keepAlways
            shot.name = "Failure — \(name)"; add(shot)
        }
        app.terminate()
        try await super.tearDown()
    }

    /// Cards carry `piece.card.<name>`, `outfit.card.<name>` or `theme.card.<name>`; the first match wins per screen.
    private func card(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier ENDSWITH %@", ".card.\(name)")).firstMatch
    }
    /// Context-menu rows are matched by their visible title once the long press finishes.
    private func menuItem(_ title: String) -> XCUIElement {
        let item = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", title)).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "menu item \(title)")
        return item
    }
    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.lifetime = .keepAlways
        attachment.name = name; add(attachment)
    }

    func testPiecesShowCategoryChipsAndStatusFilter() {
        XCTAssertTrue(app.staticTexts["12 pieces"].waitForExistence(timeout: 10))
        shot("Pieces")
        app.buttons["Shirts"].tap()
        XCTAssertTrue(app.staticTexts["2 pieces"].waitForExistence(timeout: 5), "Shirts has two sample pieces")
        shot("Shirts chip")
        app.buttons["All"].tap()
        XCTAssertTrue(app.staticTexts["12 pieces"].waitForExistence(timeout: 5))

        app.buttons["Filter pieces"].tap()
        menuItem("Laundry").tap()
        XCTAssertTrue(app.staticTexts["1 piece"].waitForExistence(timeout: 5))
        XCTAssertTrue(card("Ivory ribbed knit").exists)
        shot("Laundry filter")
    }

    func testBulkSelectMovesPiecesToLaundryAndBack() {
        XCTAssertTrue(app.staticTexts["12 pieces"].waitForExistence(timeout: 10))
        app.buttons["closet.select"].tap()
        XCTAssertTrue(app.buttons["closet.bulk.laundry"].waitForExistence(timeout: 5), "selection bar appears")
        XCTAssertFalse(app.buttons["closet.bulk.laundry"].isEnabled, "nothing chosen yet")
        shot("Select mode")
        XCTAssertEqual(card("Black belt").value as? String, "Not selected", "cards are selectable in select mode: \(card("Black belt").debugDescription)")
        card("Black belt").tap()
        shot("After first tap")
        XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: 5), "the tap chooses the piece instead of opening it")
        card("Blue cotton shirt").tap()
        XCTAssertTrue(app.staticTexts["2 selected"].waitForExistence(timeout: 5))
        shot("Selecting")
        app.buttons["closet.bulk.laundry"].tap()
        XCTAssertTrue(app.buttons["closet.select"].waitForExistence(timeout: 5), "selection mode ends after a clean change")

        app.buttons["Filter pieces"].tap(); menuItem("Laundry").tap()
        XCTAssertTrue(app.staticTexts["3 pieces"].waitForExistence(timeout: 5), "knit plus the two just moved")

        app.buttons["closet.select"].tap()
        card("Blue cotton shirt").tap()
        app.buttons["closet.bulk.available"].tap()
        XCTAssertTrue(app.staticTexts["2 pieces"].waitForExistence(timeout: 5))
        XCTAssertFalse(card("Blue cotton shirt").exists)
    }

    /// The system hosts root context menus outside the accessibility tree, so these are screenshots for review;
    /// the actions themselves are covered by ClosetActionTests.
    func testCardMenusShowQuickActions() {
        card("Blue cotton shirt").press(forDuration: 1.2)
        sleep(1); shot("Piece card menu")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap()
        app.buttons["closet.scope.outfits"].tap()
        card("Office day").press(forDuration: 1.2)
        sleep(1); shot("Outfit card menu")
    }

    func testPieceDetailLeadsWithStatusAndStyleThis() {
        card("Ivory ribbed knit").tap()
        XCTAssertTrue(app.buttons["Availability: In the laundry"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Style this"].isEnabled, "a piece in the laundry can't be styled")
        shot("Piece detail in laundry")
        app.navigationBars.buttons.firstMatch.tap()
        card("Blue cotton shirt").tap()
        XCTAssertTrue(app.buttons["Style this"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Style this"].isEnabled)
        XCTAssertTrue(app.buttons["Style this"].isHittable, "visible without scrolling")
    }

    func testRemovingAnOutfitFromAThemeKeepsTheOutfit() {
        app.buttons["closet.scope.themes"].tap()
        card("Weekday").tap()
        XCTAssertTrue(card("Office day").waitForExistence(timeout: 5))
        card("Office day").press(forDuration: 1.2)
        menuItem("Remove from Weekday").tap()
        XCTAssertFalse(card("Office day").waitForExistence(timeout: 3))
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["closet.scope.outfits"].tap()
        XCTAssertTrue(card("Office day").waitForExistence(timeout: 5), "the outfit itself stays")
    }

    func testAddPieceOffersDirectPhotoSources() {
        app.buttons["closet.addPiece"].tap()
        sleep(1)
        // The menu's first row, Add a piece, sits under the + button.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.29, dy: 0.097)).tap()
        XCTAssertTrue(app.buttons["Take photo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Photos"].exists)
        shot("Add piece")
    }
}
