import Foundation

/// One atomic, versioned metadata file; photographs stay outside JSON.
/// A failed read is never replaced with an empty writable store.
struct LocalCloset {
  let directory: URL
  private var stateURL: URL { directory.appendingPathComponent("closet-v1.json") }

  func load() throws -> ClosetState {
    guard FileManager.default.fileExists(atPath: stateURL.path) else { return ClosetState() }
    let state = try JSONDecoder().decode(ClosetState.self, from: Data(contentsOf: stateURL))
    guard state.version == 1 else { throw EntryError.unreadableStorage }
    return state
  }

  func save(_ state: ClosetState) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try JSONEncoder().encode(state).write(
      to: stateURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    var url = directory
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = false
    try url.setResourceValues(resourceValues)
  }

  func savePhoto(_ data: Data) throws -> String {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let filename = UUID().uuidString + ".jpg"
    try data.write(
      to: directory.appendingPathComponent(filename),
      options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    return filename
  }

  func photoURL(_ filename: String?) -> URL? {
    guard let filename, filename == (filename as NSString).lastPathComponent,
      filename.hasSuffix(".jpg")
    else { return nil }
    return directory.appendingPathComponent(filename)
  }
}
