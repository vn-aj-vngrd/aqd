import Foundation
import Testing
@testable import AQDCore

struct TodayConfigurationTests {
    @Test func firstUseHasExactlyTheStockOrderAndIndependentIdentities() throws {
        let layout = TodayConfiguration(ownerID: UUID())
        #expect(layout.instances.map(\.kind) == TodayWidgetKind.allCases)
        #expect(Set(layout.instances.map(\.id)).count == TodayWidgetKind.allCases.count)
        #expect(layout.instances.allSatisfy { $0.isVisible })
        try layout.validated()
        var draft = TodayLayoutDraft(base: layout)
        draft.value.instances[0].isHidden = true
        #expect(try draft.result().instances[0].isVisible == false)
    }

    @Test func existingLayoutRoundTripsWithoutReseedingOrChangingIDs() throws {
        var layout = TodayConfiguration(ownerID: UUID())
        layout.instances = [TodayWidgetInstance(kind: .wearAgain)]
        let restored = try JSONDecoder().decode(TodayConfiguration.self, from: JSONEncoder().encode(layout))
        #expect(restored == layout)
        #expect(restored.instances.count == 1)
    }

    @Test func minimumOneAndDuplicateIdentityAreRejectedWithoutMutation() {
        var layout = TodayConfiguration(ownerID: UUID())
        layout.instances = []
        #expect(throws: TodayConfiguration.ValidationError.emptyLayout) { try layout.validated() }
        #expect(layout.instances.isEmpty)
        let instance = TodayWidgetInstance(kind: .todayLook)
        layout.instances = [instance, instance]
        #expect(throws: TodayConfiguration.ValidationError.duplicateInstance) { try layout.validated() }
        #expect(layout.instances == [instance, instance])
    }

    @Test func repeatedKindsHaveNoArbitraryLimit() throws {
        var layout = TodayConfiguration(ownerID: UUID())
        layout.instances = (0..<300).map { _ in TodayWidgetInstance(kind: .todayLook) }
        try layout.validated()
        #expect(Set(layout.instances.map(\.id)).count == 300)
    }

    @Test func newerSchemaIsNotOverwrittenWithStockDefaults() {
        var layout = TodayConfiguration(ownerID: UUID())
        layout.schemaVersion = 2
        #expect(throws: TodayConfiguration.ValidationError.unsupportedSchema) { try layout.validated() }
        #expect(layout.schemaVersion == 2)
    }
}
