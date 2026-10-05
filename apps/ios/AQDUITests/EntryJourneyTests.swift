import XCTest

@MainActor
final class EntryJourneyTests: XCTestCase {
  private func application() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchEnvironment["AQD_UI_TEST_STORE"] = UUID().uuidString
    app.launch()
    return app
  }

  func testManualFirstPiecePersistsAfterRelaunch() {
    let app = application()
    XCTAssertTrue(app.buttons["entry.start"].waitForExistence(timeout: 10))
    attach(app, name: "E02 Welcome")
    app.buttons["entry.start"].tap()
    XCTAssertTrue(app.buttons["entry.manual"].waitForExistence(timeout: 5))
    attach(app, name: "E06 First piece")
    app.buttons["entry.manual"].tap()
    app.textFields["piece.name"].tap()
    app.textFields["piece.name"].typeText("Everyday shoes")
    app.buttons["piece.category"].tap()
    app.buttons["Shoes"].tap()
    app.buttons["piece.save"].tap()
    XCTAssertTrue(app.staticTexts["Your first piece is saved."].waitForExistence(timeout: 5))
    attach(app, name: "E12 Saved receipt")
    app.buttons["Open my closet"].tap()
    XCTAssertTrue(app.staticTexts["Everyday shoes"].waitForExistence(timeout: 5))
    app.terminate()
    app.launch()
    XCTAssertTrue(app.staticTexts["Everyday shoes"].waitForExistence(timeout: 10))
    XCTAssertFalse(app.buttons["entry.start"].exists)
  }

  func testInvalidEmailAndCancellationKeepPrivateEntryUsable() {
    let app = application()
    app.buttons["I already have an account"].tap()
    XCTAssertTrue(app.buttons["auth.emailMethod"].waitForExistence(timeout: 5))
    attach(app, name: "E03 Sign-in methods")
    app.buttons["auth.emailMethod"].tap()
    app.textFields["auth.email"].tap()
    app.textFields["auth.email"].typeText("invalid")
    app.buttons["auth.send"].tap()
    XCTAssertTrue(app.staticTexts["Enter a valid email address."].waitForExistence(timeout: 5))
    attach(app, name: "E10 Email validation")
    app.buttons["Cancel"].tap()
    XCTAssertTrue(app.buttons["entry.start"].waitForExistence(timeout: 5))
    app.buttons["entry.start"].tap()
    app.buttons["Skip"].tap()
    XCTAssertTrue(app.staticTexts["Your private closet."].waitForExistence(timeout: 5))
  }

  func testPreferencesRemainOptionalAndUnselected() {
    let app = application()
    app.buttons["entry.start"].tap()
    app.buttons["Skip"].tap()
    app.buttons["Profile"].tap()
    app.buttons["Style preferences"].tap()
    XCTAssertTrue(app.staticTexts["A little more you."].waitForExistence(timeout: 5))
    attach(app, name: "E05 Optional preferences")
    app.buttons["Skip"].tap()
    XCTAssertTrue(app.staticTexts["Your private closet."].waitForExistence(timeout: 5))
  }

  private func attach(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
