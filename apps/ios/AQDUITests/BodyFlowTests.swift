import XCTest

@MainActor
final class BodyFlowTests: XCTestCase {
    private var app: XCUIApplication!
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--aqd-ui-testing", "-AppleInterfaceStyle", "Light"]
        app.launchEnvironment["AQD_TEST_STORE_ID"] = UUID().uuidString
        app.launchEnvironment["AQD_TEST_RETURNING_ENTRY"] = "1"
        app.launch()
    }
    override func tearDown() async throws {
        if testRun?.failureCount ?? 0 > 0 { capture("Body input failure — \(name)") }
        app.terminate()
        try await super.tearDown()
    }

    func testHeightUnitsCustomUseCancelDoneAndSavedSettingsRelaunch() {
        openStyle(settings: true)
        reachBody(selectAnswers: true, comfort: "Avoid wool")
        let height = app.textFields["style.height.cm"]
        height.tap(); height.typeText("173.125")
        app.buttons["Done editing height"].tap()
        app.buttons["style.height.units"].tap(); app.buttons["ft/in"].tap()
        XCTAssertEqual(app.textFields["style.height.feet"].value as? String, "5")
        XCTAssertTrue((app.textFields["style.height.inches"].value as? String ?? "").hasPrefix("8.159"))
        capture("E3 explicit feet and inches reflect the canonical height")
        app.buttons["style.height.units"].tap(); app.buttons["cm"].tap()
        XCTAssertEqual(height.value as? String, "173.125")
        app.buttons["style.body.shape"].tap()
        app.buttons["Straight"].tap(); app.buttons["style.body.picker.done"].tap()
        XCTAssertTrue(app.buttons["style.body.picker.done"].waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.buttons["style.body.shape"].value as? String, "Straight")
        app.buttons["style.body.shape"].tap(); app.buttons["style.body.custom"].tap()
        let description = descriptionField()
        let text = "My shoulders are broader than my hips."
        description.tap(); description.typeText(text)
        assertKeyboardSafeUse()
        capture("E3 custom description is visible while typing above the keyboard")
        app.buttons["Cancel"].tap()
        XCTAssertEqual(app.buttons["Straight"].value as? String, "Selected")
        app.buttons["style.body.custom"].tap()
        XCTAssertEqual(descriptionField().value as? String, text)
        app.buttons["Use description"].tap()
        XCTAssertTrue(app.staticTexts["Pending custom description, \(text)"].exists)
        capture("E3 Use description returns a pending picker selection")
        app.buttons["style.body.picker.done"].tap()
        XCTAssertTrue(app.buttons["style.body.picker.done"].waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.buttons["style.body.shape"].value as? String, text)
        XCTAssertEqual(app.switches["Use body details for suggestions"].value as? String, "0")
        app.terminate(); app.launch()
        XCTAssertTrue(app.navigationBars["Body details"].waitForExistence(timeout: 10))
        XCTAssertEqual(height.value as? String, "173.125")
        XCTAssertEqual(app.buttons["style.body.shape"].value as? String, text)
        app.buttons["Continue"].tap()
        app.textFields["Preferred colors"].tap(); app.textFields["Preferred colors"].typeText("Blue")
        app.textFields["Colors to avoid"].tap(); app.textFields["Colors to avoid"].typeText("Red")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["style.review.3"].label.contains("Avoid wool"))
        XCTAssertTrue(app.buttons["style.review.5"].label.contains("Preferred colors: Blue"))
        XCTAssertTrue(app.buttons["style.review.5"].label.contains("Colors to avoid: Red"))
        capture("E3 mixed review retains height description comfort and labelled colors with body use Off")
        saveAndFinish()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        openStyle(settings: true); reachBody(selectAnswers: false)
        XCTAssertEqual(height.value as? String, "173.125")
        XCTAssertEqual(app.buttons["style.body.shape"].value as? String, text)
        XCTAssertEqual(app.switches["Use body details for suggestions"].value as? String, "0")
        capture("E4 saved optional body answers reopen from the actual Settings caller")
    }

    func testOverLimitCustomDescriptionAndKeyboardSurviveRestartWithoutTruncation() {
        openStyle(settings: false); reachBody(selectAnswers: true)
        app.buttons["style.body.shape"].tap(); app.buttons["Not sure"].tap()
        app.buttons["style.body.custom"].tap()
        let text = String(repeating: "Broad shoulders, room to move. ", count: 5) + "Own..."
        XCTAssertEqual(text.count, 161)
        let field = descriptionField()
        field.tap(); field.typeText(text)
        XCTAssertEqual(field.value as? String, text)
        XCTAssertTrue(app.staticTexts["161 / 160"].exists)
        XCTAssertFalse(app.buttons["Use description"].isEnabled)
        assertKeyboardSafeUse()
        capture("E3 161 characters remain visible with error and disabled Use above the keyboard")
        app.terminate(); app.launch()
        XCTAssertTrue(descriptionField().waitForExistence(timeout: 10))
        XCTAssertEqual(descriptionField().value as? String, text)
        XCTAssertFalse(app.buttons["Use description"].isEnabled)
        descriptionField().tap(); descriptionField().typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssertEqual((descriptionField().value as? String)?.count, 160)
        XCTAssertTrue(app.buttons["Use description"].isEnabled)
        capture("E3 removing one character restores Use without enabling body consent")
        app.buttons["Cancel"].tap()
        XCTAssertEqual(app.buttons["Not sure"].value as? String, "Selected")
        app.buttons["Cancel"].tap()
        XCTAssertEqual(app.buttons["style.body.shape"].value as? String, "Not added")
        XCTAssertFalse(app.buttons["Continue"].isEnabled)
        XCTAssertEqual(app.switches["Use body details for suggestions"].value as? String, "0")
        capture("E4 picker cancellation leaves the preference answer untouched")
    }

    func testDarkBodyPickerSavedReceiptAndProfileReturnRemainReadable() {
        app.terminate()
        app.launchArguments = ["--aqd-ui-testing"]
        app.launchEnvironment["AQD_TEST_APPEARANCE"] = "dark"
        app.launch()
        openStyle(settings: false); reachBody(selectAnswers: true)
        app.buttons["style.body.shape"].tap()
        capture("E6 dark native body picker with ink X and checkmark actions")
        app.buttons["Not sure"].tap(); app.buttons["style.body.picker.done"].tap()
        XCTAssertTrue(app.buttons["style.body.picker.done"].waitForNonExistence(timeout: 5))
        capture("E6 dark body details keep optional use Off")
        app.buttons["Continue"].tap()
        app.buttons["No color or pattern preference"].tap(); app.buttons["Continue"].tap()
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.staticTexts["Preferences saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["style.saved.continue"].label, "Back to Profile")
        capture("E6 dark saved receipt uses the splash wordmark and complete actions")
        app.buttons["style.saved.continue"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        capture("E6 dark actual Profile caller restored")
    }

    func testProfileFailedBodySaveAndDiscardKeepThePriorSavedAnswerAndCaller() {
        openStyle(settings: false); reachBody(selectAnswers: true)
        app.buttons["Prefer not to share body details"].tap()
        app.buttons["Continue"].tap(); app.buttons["No color or pattern preference"].tap(); app.buttons["Continue"].tap()
        saveAndFinish()
        app.terminate(); app.launchEnvironment["AQD_TEST_DENIED_STYLE_SAVE"] = "1"; app.launch()
        openStyle(settings: false); reachBody(selectAnswers: false)
        app.buttons["style.body.shape"].tap(); app.buttons["Rounded"].tap(); app.buttons["style.body.picker.done"].tap()
        app.buttons["Continue"].tap(); app.buttons["Continue"].tap()
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.buttons["Retry save"].waitForExistence(timeout: 5))
        capture("E4 Profile failed body save preserves the prior saved preferences")
        app.terminate(); app.launch()
        XCTAssertTrue(app.navigationBars["Review preferences"].waitForExistence(timeout: 10))
        for _ in 0..<7 { app.buttons["style.back"].tap() }
        app.buttons["Discard draft"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["profile.identity"].exists || app.staticTexts["Your profile"].exists)
        XCTAssertTrue(app.staticTexts["A little space for your style"].exists)
        XCTAssertFalse(app.staticTexts["Your closet, privately"].exists)
        capture("E4 current actual Profile identity and empty fit layout")
        app.terminate(); app.launchEnvironment.removeValue(forKey: "AQD_TEST_DENIED_STYLE_SAVE"); app.launch()
        openStyle(settings: false); reachBody(selectAnswers: false)
        XCTAssertEqual(app.buttons["Prefer not to share body details"].value as? String, "Selected")
        XCTAssertEqual(app.buttons["style.body.shape"].value as? String, "Not added")
        XCTAssertEqual(app.switches["Use body details for suggestions"].value as? String, "0")
        capture("E4 Profile source cancellation retains the actual previous saved refusal")
    }

    func testInvalidHeightBlocksRestoredReviewAndRefusalClearsBodyUse() {
        openStyle(settings: false); reachBody(selectAnswers: true)
        let height = app.textFields["style.height.cm"]
        height.tap(); height.typeText("173")
        app.buttons["Done editing height"].tap()
        app.buttons["style.body.shape"].tap(); app.buttons["Rounded"].tap(); app.buttons["style.body.picker.done"].tap()
        app.switches["Use body details for suggestions"].tap()
        app.buttons["Continue"].tap(); app.buttons["No color or pattern preference"].tap(); app.buttons["Continue"].tap()
        app.buttons["style.review.4"].tap()
        height.tap(); height.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "173..5")
        app.buttons["Done editing height"].tap()
        XCTAssertFalse(app.buttons["Back to review"].isEnabled)
        app.buttons["style.back"].tap()
        XCTAssertFalse(app.buttons["Save preferences"].isEnabled)
        XCTAssertTrue(app.staticTexts["5 of 6 questions answered"].exists)
        capture("E3 invalid restored Review retains input and disables atomic Save")
        app.terminate(); app.launch()
        XCTAssertTrue(app.navigationBars["Review preferences"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Save preferences"].isEnabled)
        app.buttons["style.review.4"].tap()
        XCTAssertEqual(height.value as? String, "173..5")
        XCTAssertEqual(app.buttons["style.body.shape"].value as? String, "Rounded")
        app.buttons["Prefer not to share body details"].tap()
        XCTAssertEqual(height.value as? String ?? "", "")
        XCTAssertEqual(app.buttons["style.body.shape"].value as? String, "Not added")
        XCTAssertEqual(app.switches["Use body details for suggestions"].value as? String, "0")
        app.buttons["Back to review"].tap()
        saveAndFinish()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        openStyle(settings: false); reachBody(selectAnswers: false)
        XCTAssertEqual(app.switches["Use body details for suggestions"].value as? String, "0")
        XCTAssertEqual(app.buttons["Prefer not to share body details"].value as? String, "Selected")
        capture("E3 explicit refusal clears optional details and revokes body use after save/relaunch")
    }

    private func openStyle(settings: Bool) {
        let profile = app.buttons["root.tab.profile"]
        XCTAssertTrue(profile.wait(for: \.isHittable, toEqual: true, timeout: 10)); profile.tap()
        app.buttons["More"].tap()
        if settings {
            app.buttons["Settings"].tap()
            let style = app.buttons["Style, Edit preferences"]
            XCTAssertTrue(style.wait(for: \.isHittable, toEqual: true, timeout: 5)); style.tap()
        } else { app.buttons["Style"].tap() }
        XCTAssertTrue(app.navigationBars["Your goals"].waitForExistence(timeout: 5))
    }
    private func reachBody(selectAnswers: Bool, comfort: String? = nil) {
        for step in 0..<4 {
            if selectAnswers { app.buttons["No preference"].tap() }
            if step == 3, let comfort {
                app.textFields["Comfort preferences"].tap(); app.textFields["Comfort preferences"].typeText(comfort)
            }
            app.buttons["Continue"].tap()
        }
        XCTAssertTrue(app.navigationBars["Body details"].waitForExistence(timeout: 5))
    }
    private func saveAndFinish() {
        app.buttons["Save preferences"].tap()
        XCTAssertTrue(app.staticTexts["Preferences saved"].waitForExistence(timeout: 5)); app.buttons["style.saved.continue"].tap()
    }
    private func descriptionField() -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "style.body.description").firstMatch
    }
    private func assertKeyboardSafeUse() {
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))
        XCTAssertTrue(keyboard.keys["space"].isHittable)
        let use = app.buttons["Use description"]
        XCTAssertLessThanOrEqual(use.frame.maxY, keyboard.frame.minY + 1)
        XCTAssertTrue(app.frame.contains(use.frame))
    }
    private func capture(_ title: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = title; attachment.lifetime = .keepAlways; add(attachment)
    }
}
