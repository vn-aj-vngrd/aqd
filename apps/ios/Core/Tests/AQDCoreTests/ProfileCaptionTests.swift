import Foundation
import Testing
@testable import AQDCore

struct ProfileCaptionTests {
    @Test func captionRoundTripsThroughDraftResultAndLegacyIdentityStillDecodes() throws {
        let owner = UUID()
        let legacy = LocalProfileIdentity(ownerID: owner, name: "Van", photoID: nil, revision: 1)
        let legacyData = try JSONEncoder().encode(legacy)
        #expect(try JSONDecoder().decode(LocalProfileIdentity.self, from: legacyData) == legacy)
        let original = LocalIdentityDraft(ownerID: owner, base: legacy)
        var bytes = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        bytes["caption"] = "  Getting dressed, my way.  "
        let draft = try JSONDecoder().decode(LocalIdentityDraft.self, from: JSONSerialization.data(withJSONObject: bytes))
        let result = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(draft.result())) as? [String: Any])
        #expect(result["caption"] as? String == "Getting dressed, my way.")
        bytes["caption"] = ""
        let cleared = try JSONDecoder().decode(LocalIdentityDraft.self, from: JSONSerialization.data(withJSONObject: bytes))
        let clearedResult = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(cleared.result())) as? [String: Any])
        #expect(clearedResult["caption"] as? String == "")
    }

    @Test func overlongCaptionCannotBecomeASavedProfile() throws {
        var bytes = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(LocalIdentityDraft(ownerID: UUID()))) as? [String: Any])
        bytes["caption"] = String(repeating: "a", count: 161)
        let draft = try JSONDecoder().decode(LocalIdentityDraft.self, from: JSONSerialization.data(withJSONObject: bytes))
        try draft.validatedForRetention()
        #expect(throws: (any Error).self) { try draft.result() }
    }
}
