import Foundation
import XCTest

/// Real SDK-to-Supabase journey; requires the isolated local stack and Debug config.
@MainActor
final class LiveIdentityJourneyTests: XCTestCase {
  func testVerifiedEmailReturnsToNativeProfile() async throws {
    let inbox = URL(string: "http://127.0.0.1:54324")!
    do {
      _ = try await URLSession.shared.data(from: inbox.appendingPathComponent("api/v1/messages"))
    } catch {
      throw XCTSkip(
        "Local Supabase inbox is not running; run the documented local integration check.")
    }
    let email = "native-\(UUID().uuidString.lowercased())@example.test"
    let app = XCUIApplication()
    app.launchEnvironment["AQD_UI_TEST_STORE"] = UUID().uuidString
    app.launch()
    XCTAssertTrue(app.buttons["entry.start"].waitForExistence(timeout: 10))
    app.buttons["entry.start"].tap()
    app.buttons["Skip"].tap()
    app.buttons["Profile"].tap()
    app.buttons["Sign in"].tap()
    app.buttons["auth.emailMethod"].tap()
    app.textFields["auth.email"].tap()
    app.textFields["auth.email"].typeText(email)
    app.buttons["auth.send"].tap()
    XCTAssertTrue(app.staticTexts["Your sign-in link is on its way."].waitForExistence(timeout: 15))
    let data = try await URLSession.shared.data(
      from: inbox.appendingPathComponent("api/v1/messages")
    ).0
    let index = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let messages = try XCTUnwrap(index["messages"] as? [[String: Any]])
    let message = try XCTUnwrap(
      messages.first { item in
        (item["To"] as? [[String: Any]])?.contains { $0["Address"] as? String == email } == true
      })
    let id = try XCTUnwrap(message["ID"] as? String)
    let body = try await URLSession.shared.data(
      from: inbox.appendingPathComponent("api/v1/message/\(id)")
    ).0
    let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
    let html = try XCTUnwrap(payload["HTML"] as? String)
    let pattern = try NSRegularExpression(pattern: "href=\"([^\"]*/auth/v1/verify[^\"]+)\"")
    let match = try XCTUnwrap(
      pattern.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)))
    let range = try XCTUnwrap(Range(match.range(at: 1), in: html))
    let link = try XCTUnwrap(
      URL(string: String(html[range]).replacingOccurrences(of: "&amp;", with: "&")))
    let session = URLSession(
      configuration: .ephemeral, delegate: PreserveCallback(), delegateQueue: nil)
    defer { session.invalidateAndCancel() }
    let response = try await session.data(from: link).1
    let redirect = try XCTUnwrap(
      (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Location"))
    let callback = try XCTUnwrap(URL(string: redirect))
    XCTAssertEqual(callback.scheme, "com.aqd.ios")
    app.open(callback)
    XCTAssertTrue(app.staticTexts["How would you like to be known?"].waitForExistence(timeout: 20))
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "E07 Verified native email profile return"
    attachment.lifetime = .keepAlways
    add(attachment)
    // No profile or private record is published without the user's next explicit action.
  }
}

private final class PreserveCallback: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) { completionHandler(nil) }
}
