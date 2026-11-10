import Foundation
import Testing
@testable import AQDCore

struct MannequinFigureTests {
    private func json(_ variants: String) -> Data { Data("{\"variants\":[\(variants)]}".utf8) }

    private func variantJSON(id: String = "standard", aspect: Double = 0.5, shoulderY: Double = 0.16) -> String {
        """
        {"id":"\(id)","imageName":"mannequin-\(id)","aspectRatio":\(aspect),"anchors":{
        "shoulderY":\(shoulderY),"shoulderLeftX":0.3,"shoulderRightX":0.7,
        "chest":{"y":0.24,"halfWidth":0.17},"waist":{"y":0.4,"halfWidth":0.13},
        "hips":{"y":0.48,"halfWidth":0.17},"knees":{"y":0.7,"halfWidth":0.1},
        "ankles":{"y":0.9,"halfWidth":0.07},"feet":{"y":0.97,"halfWidth":0.16}}}
        """
    }

    @Test("AC-9: a manifest decodes into variants whose anchors drive placement")
    func ac9ManifestVariantsDrivePlacement() throws {
        let manifest = try MannequinFigureManifest.decode(json(variantJSON() + "," + variantJSON(id: "tall", shoulderY: 0.1)))
        #expect(manifest.variants.map(\.id) == ["standard", "tall"])
        #expect(manifest.variants[0].imageName == "mannequin-standard")
        #expect(manifest.variants[0].aspectRatio == 0.5)
        let id = UUID()
        let standard = MannequinLayout.place([(id, .tops)], on: manifest.variant(id: "standard").anchors).placements[0].frame
        let tall = MannequinLayout.place([(id, .tops)], on: manifest.variant(id: "tall").anchors).placements[0].frame
        #expect(standard?.y == 0.16)
        #expect(tall?.y == 0.1)
    }

    @Test("AC-9: the built-in standard anchors match the shipped standard variant entry")
    func ac9StandardAnchorsMatchTheDecodedStandardVariant() throws {
        let manifest = try MannequinFigureManifest.decode(json(variantJSON()))
        #expect(manifest.variants[0].anchors == MannequinAnchors.standard)
    }

    @Test("AC-9: a malformed manifest yields a typed error")
    func ac9MalformedManifestThrows() {
        #expect(throws: MannequinManifestError.malformed) { try MannequinFigureManifest.decode(Data("nope".utf8)) }
        #expect(throws: MannequinManifestError.malformed) { try MannequinFigureManifest.decode(Data("{}".utf8)) }
    }

    @Test("AC-9: an empty manifest yields a typed error")
    func ac9EmptyManifestThrows() {
        #expect(throws: MannequinManifestError.empty) { try MannequinFigureManifest.decode(json("")) }
    }

    @Test("AC-9: a variant with out-of-order anchors or a bad aspect is rejected")
    func ac9InconsistentVariantThrows() {
        #expect(throws: MannequinManifestError.invalidVariant("bad")) {
            try MannequinFigureManifest.decode(json(variantJSON(id: "bad", shoulderY: 0.6)))
        }
        #expect(throws: MannequinManifestError.invalidVariant("flat")) {
            try MannequinFigureManifest.decode(json(variantJSON(id: "flat", aspect: 0)))
        }
    }

    @Test("AC-9: a failed decode falls back to the built-in standard anchors")
    func ac9FailedDecodeFallsBackToStandard() {
        for data in [nil, Data("nope".utf8), json("")] {
            let manifest = MannequinFigureManifest.decodedOrStandard(data)
            #expect(manifest.variants == [.standard])
            #expect(manifest.variants[0].anchors == .standard)
        }
        #expect(MannequinFigureManifest.decodedOrStandard(json(variantJSON(id: "x"))).variants[0].id == "x")
    }

    @Test("AC-9: an unknown variant id resolves to the first variant")
    func ac9UnknownVariantIDUsesTheFirst() throws {
        let manifest = try MannequinFigureManifest.decode(json(variantJSON()))
        #expect(manifest.variant(id: "missing").id == "standard")
    }

    @Test("AC-9: the standard anchors are themselves valid")
    func ac9StandardAnchorsAreValid() {
        #expect(MannequinAnchors.standard.isValid)
    }
}
