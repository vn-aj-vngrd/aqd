import Foundation

/// What the Agent needs from the iPhone. The Agent runs on Apple's on-device model, which only Apple Intelligence iPhones have;
/// everything else in the app works on any iPhone that runs iOS 18. The live answer for this iPhone always comes from the system.
public enum AppleIntelligenceSupport {
    public struct Phone: Equatable, Sendable, Identifiable {
        public let name: String
        public let family: String
        public var id: String { name }
    }

    /// Apple's list of Apple Intelligence iPhones, grouped by family.
    public static let phones: [Phone] = [
        Phone(name: "iPhone 15 Pro", family: "iPhone 15"), Phone(name: "iPhone 15 Pro Max", family: "iPhone 15"),
        Phone(name: "iPhone 16", family: "iPhone 16"), Phone(name: "iPhone 16 Plus", family: "iPhone 16"), Phone(name: "iPhone 16 Pro", family: "iPhone 16"),
        Phone(name: "iPhone 16 Pro Max", family: "iPhone 16"), Phone(name: "iPhone 16e", family: "iPhone 16"),
        Phone(name: "iPhone 17", family: "iPhone 17"), Phone(name: "iPhone 17 Pro", family: "iPhone 17"), Phone(name: "iPhone 17 Pro Max", family: "iPhone 17"),
        Phone(name: "iPhone Air", family: "iPhone 17"), Phone(name: "iPhone 17e", family: "iPhone 17")
    ]
    public static var families: [String] { phones.reduce(into: [String]()) { if !$0.contains($1.family) { $0.append($1.family) } } }
    public static func phones(in family: String) -> [Phone] { phones.filter { $0.family == family } }

    /// Languages Apple Intelligence works in. The device and Siri language must match one of them.
    public static let languages = ["English", "Chinese (Simplified)", "Chinese (Traditional)", "Danish", "Dutch", "French", "German", "Italian", "Japanese", "Korean",
                                   "Norwegian", "Portuguese", "Spanish", "Swedish", "Turkish", "Vietnamese"]

    /// Free storage Apple Intelligence asks for.
    public static let storage = "Up to 8 GB free, and up to 14 GB on iPhone 17 Pro, 17 Pro Max and iPhone Air."
    public static let region = "Not available on an iPhone bought in mainland China, or with an Apple Account set to mainland China."
    public static let minimumSystem = "iOS 26 or later"

    /// Whether a hardware identifier such as `iPhone16,2` belongs to an Apple Intelligence iPhone: the 15 Pro models and everything from the 16 on.
    public static func isEligible(machine identifier: String) -> Bool {
        guard identifier.hasPrefix("iPhone"), let major = Int(identifier.dropFirst("iPhone".count).prefix { $0.isNumber }) else { return false }
        return major >= 17 || identifier == "iPhone16,1" || identifier == "iPhone16,2"
    }
}
