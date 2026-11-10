import AQDCore
import Foundation
import Testing
import UIKit
@testable import AQD

@MainActor
struct MannequinFigureCatalogTests {
    @Test("AC-1: the bundled manifest decodes to the standard variant with the shipped anchors")
    func bundledManifestDecodes() throws {
        let url = try #require(Bundle.main.url(forResource: MannequinFigureCatalog.manifestName, withExtension: "json"))
        let manifest = try MannequinFigureManifest.decode(Data(contentsOf: url))
        #expect(manifest.variants.map(\.id).contains("standard"))
        #expect(manifest.variant(id: "standard").anchors == MannequinAnchors.standard)
        #expect(MannequinFigureCatalog.load() == manifest)
    }

    @Test("AC-12: every variant's image exists in the asset catalog in light and dark")
    func everyVariantImageExists() {
        for variant in MannequinFigureCatalog.load().variants {
            for style in [UIUserInterfaceStyle.light, .dark] {
                let image = UIImage(named: variant.imageName, in: .main, compatibleWith: UITraitCollection(userInterfaceStyle: style))
                #expect(image != nil, "\(variant.imageName) \(style.rawValue)")
            }
        }
    }

    @Test("AC-1: a missing bundle manifest falls back to the standard figure")
    func missingManifestFallsBack() {
        #expect(MannequinFigureCatalog.load(bundle: Bundle(for: BundleToken.self)).variants == [MannequinFigureVariant.standard])
    }

    private final class BundleToken {}
}
