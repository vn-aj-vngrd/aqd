import Supabase
import SwiftUI

@main
struct AQDApp: App {
  @State private var flow: EntryFlow
  @State private var identity: IdentityFlow

  init() {
    var directory = URL.documentsDirectory.appendingPathComponent("AQD", isDirectory: true)
    var namespace = "com.aqd.ios"
    #if DEBUG
      if let identifier = ProcessInfo.processInfo.environment["AQD_UI_TEST_STORE"],
        UUID(uuidString: identifier) != nil
      {
        directory = URL.documentsDirectory.appendingPathComponent(
          "AQDUITests/" + identifier, isDirectory: true)
        namespace = "com.aqd.ios.tests." + identifier
      }
    #endif
    let flow = EntryFlow(directory: directory)
    _flow = State(initialValue: flow)
    _identity = State(
      initialValue: IdentityFlow(
        flow: flow, service: SupabaseIdentityService(namespace: namespace),
        transactionStorage: KeychainLocalStorage(service: namespace + ".entry")))
  }
  var body: some Scene {
    WindowGroup { EntryRoot(flow: flow, identity: identity) }
  }
}
