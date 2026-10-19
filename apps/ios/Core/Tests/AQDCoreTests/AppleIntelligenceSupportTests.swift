import Testing
@testable import AQDCore

struct AppleIntelligenceSupportTests {
    @Test func listsEveryAppleIntelligenceIPhoneOnceInFamilyOrder() {
        let names = AppleIntelligenceSupport.phones.map(\.name)
        #expect(Set(names).count == names.count && names.count == 12)
        #expect(AppleIntelligenceSupport.families == ["iPhone 15", "iPhone 16", "iPhone 17"])
        #expect(AppleIntelligenceSupport.phones(in: "iPhone 15").map(\.name) == ["iPhone 15 Pro", "iPhone 15 Pro Max"])
        for name in ["iPhone 16e", "iPhone Air", "iPhone 17e", "iPhone 17 Pro Max"] { #expect(names.contains(name)) }
        #expect(!names.contains("iPhone 15") && !names.contains("iPhone 15 Plus"))
    }

    @Test func hardwareIdentifiersMapToEligibility() {
        for yes in ["iPhone16,1", "iPhone16,2", "iPhone17,1", "iPhone17,5", "iPhone18,2", "iPhone19,2"] { #expect(AppleIntelligenceSupport.isEligible(machine: yes), "\(yes)") }
        for no in ["iPhone15,4", "iPhone15,5", "iPhone15,2", "iPhone14,6", "iPhone12,1", "iPad16,3", "arm64", ""] { #expect(!AppleIntelligenceSupport.isEligible(machine: no), "\(no)") }
    }

    @Test func requirementsAreStated() {
        #expect(AppleIntelligenceSupport.languages.count == 16 && AppleIntelligenceSupport.languages.contains("English"))
        #expect(!AppleIntelligenceSupport.storage.isEmpty && !AppleIntelligenceSupport.region.isEmpty)
    }
}
