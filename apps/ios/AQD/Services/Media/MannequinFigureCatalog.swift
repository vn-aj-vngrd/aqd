import AQDCore
import Foundation

/// Loads the bundled figure manifest. New art plus a manifest entry is a drop-in: no code change.
enum MannequinFigureCatalog {
    static let manifestName = "mannequin-figures"

    /// The bundled manifest, or the built-in standard figure when it is missing or malformed, so the view never fails.
    static func load(bundle: Bundle = .main) -> MannequinFigureManifest {
        let data = bundle.url(forResource: manifestName, withExtension: "json").flatMap { try? Data(contentsOf: $0) }
        return MannequinFigureManifest.decodedOrStandard(data)
    }
}
