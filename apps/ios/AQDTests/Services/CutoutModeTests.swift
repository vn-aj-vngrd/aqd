import Foundation
import Testing
@testable import AQD

@Suite(.serialized) struct CutoutModeTests {
    @Test func automaticCutoutIsTheDefaultAndReviewIsOptIn() {
        let defaults = UserDefaults.standard
        let savedMode = defaults.object(forKey: CutoutMode.key), savedReview = defaults.object(forKey: CutoutMode.reviewKey)
        defer { defaults.set(savedMode, forKey: CutoutMode.key); defaults.set(savedReview, forKey: CutoutMode.reviewKey) }
        defaults.removeObject(forKey: CutoutMode.key); defaults.removeObject(forKey: CutoutMode.reviewKey)
        #expect(CutoutMode.current == .auto)
        #expect(!CutoutMode.reviewsAfterCutout)
        CutoutMode.current = .ask; CutoutMode.reviewsAfterCutout = true
        #expect(CutoutMode.current == .ask && CutoutMode.reviewsAfterCutout)
    }
}
