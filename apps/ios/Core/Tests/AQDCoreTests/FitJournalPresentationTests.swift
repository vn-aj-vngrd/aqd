import Foundation
import Testing
@testable import AQDCore

struct FitJournalPresentationTests {
    private let owner = UUID()
    private func fit(_ y: Int, _ m: Int, _ d: Int, note: String = "", photo: Bool = false, outfit: String? = nil) -> FitMemory {
        var memory = FitMemory(ownerID: owner)
        memory.day = LocalPlanDay(year: y, month: m, day: d, timeZoneID: "Asia/Manila")
        memory.note = note
        if photo { memory.photoID = UUID() }
        if let outfit {
            memory.outfit = Self.snapshot(named: outfit, owner: owner)
        }
        return memory
    }

    @Test func contentFilterAndSortOrderFits() {
        let a = fit(2026, 10, 3, photo: true), b = fit(2026, 10, 9, outfit: "Linen set"), c = fit(2026, 9, 28, photo: true, outfit: "Office")
        let all = [a, b, c]
        #expect(FitJournalQuery().apply(to: all).map(\.id) == [b.id, a.id, c.id])
        #expect(FitJournalQuery(sort: .oldest).apply(to: all).map(\.id) == [c.id, a.id, b.id])
        #expect(FitJournalQuery(content: .photos).apply(to: all).map(\.id) == [a.id, c.id])
        #expect(FitJournalQuery(content: .outfitOnly).apply(to: all).map(\.id) == [b.id])
        #expect(FitJournalQuery().isDefault && !FitJournalQuery(content: .photos).isDefault)
    }

    @Test func searchMatchesNotesAndOutfitNames() {
        let a = fit(2026, 10, 3, note: "Café brunch", photo: true), b = fit(2026, 10, 9, outfit: "Linen set")
        #expect(FitJournalQuery(text: " CAFE ").apply(to: [a, b]).map(\.id) == [a.id])
        #expect(FitJournalQuery(text: "linen").apply(to: [a, b]).map(\.id) == [b.id])
        #expect(FitJournalQuery(content: .outfitOnly, text: "cafe").apply(to: [a, b]).isEmpty)
    }

    @Test func sectionsGroupConsecutiveMonthsKeepingOrder() {
        let list = [fit(2026, 10, 9, photo: true), fit(2026, 10, 3, photo: true), fit(2026, 9, 28, photo: true), fit(2025, 10, 1, photo: true)]
        let sections = FitJournalPresentation.sections(list)
        #expect(sections.map(\.id) == ["2026-10", "2026-09", "2025-10"])
        #expect(sections.map { $0.memories.count } == [2, 1, 1])
        #expect(FitJournalPresentation.sections([]).isEmpty)
    }

    @Test func plannedOutfitPrefersPlannedOverWornAndIgnoresSkippedAndGaps() {
        let day = LocalPlanDay(year: 2026, month: 10, day: 18, timeZoneID: "Asia/Manila")
        let other = LocalPlanDay(year: 2026, month: 10, day: 19, timeZoneID: "Asia/Manila")
        func entry(_ state: PlanEntryState, _ outfit: UUID?, on d: LocalPlanDay) -> OutfitPlanEntry {
            OutfitPlanEntry(id: UUID(), planID: UUID(), ownerID: owner, day: d, occasion: "", outfitID: outfit, outfitRevision: outfit == nil ? nil : 1, state: state)
        }
        let worn = UUID(), planned = UUID()
        #expect(FitJournalPresentation.plannedOutfitID(on: day, entries: [entry(.worn, worn, on: day), entry(.planned, planned, on: day)]) == planned)
        #expect(FitJournalPresentation.plannedOutfitID(on: day, entries: [entry(.worn, worn, on: day)]) == worn)
        #expect(FitJournalPresentation.plannedOutfitID(on: day, entries: [entry(.skipped, UUID(), on: day), entry(.unassigned, nil, on: day), entry(.planned, UUID(), on: other)]) == nil)
    }

    @Test func guidanceNamesWhatIsMissing() {
        #expect(FitJournalPresentation.guidance(for: fit(2026, 10, 1)) == .needsContent)
        #expect(FitJournalPresentation.guidance(for: fit(2026, 10, 1, photo: true)) == .ready)
        #expect(FitJournalPresentation.guidance(for: fit(2026, 10, 1, outfit: "Set")) == .ready)
        #expect(FitJournalPresentation.guidance(for: fit(2026, 10, 1, note: String(repeating: "a", count: 501), photo: true)) == .noteTooLong)
    }

    private static func snapshot(named name: String, owner: UUID) -> FitOutfitSnapshot {
        let json: [String: Any] = ["id": UUID().uuidString, "ownerID": owner.uuidString, "name": name, "revision": 1,
                                   "pieces": [["id": UUID().uuidString, "name": "Shirt", "category": "Tops"]]]
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(FitOutfitSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
    }
}
