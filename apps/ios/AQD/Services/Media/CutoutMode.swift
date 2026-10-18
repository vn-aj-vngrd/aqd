import Foundation

/// Whether a photo is cut out automatically when it is added. A device preference, not a record.
enum CutoutMode: String, CaseIterable {
    case auto, ask, off

    var title: String {
        switch self {
        case .auto: "Automatic"
        case .ask: "Ask each time"
        case .off: "Off"
        }
    }

    static let key = "aqd.cutoutMode"
    static let reviewKey = "aqd.cutoutReview"

    /// Open the cutout editor right after an automatic cutout so it can be refined before saving. Off by default.
    static var reviewsAfterCutout: Bool {
        get { UserDefaults.standard.bool(forKey: reviewKey) }
        set { UserDefaults.standard.set(newValue, forKey: reviewKey) }
    }
    static var current: CutoutMode {
        get { UserDefaults.standard.string(forKey: key).flatMap(CutoutMode.init(rawValue:)) ?? .auto }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }
}
