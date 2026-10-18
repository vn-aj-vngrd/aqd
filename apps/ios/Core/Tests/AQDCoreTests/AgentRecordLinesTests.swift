import Foundation
import Testing
@testable import AQDCore

struct AgentRecordLinesTests {
    @Test func linesLeadWithHandleAndNameAndDropEmptyFields() {
        #expect(AgentRecordLines.piece(handle: "p3", name: "Cream poplin blouse", category: "Tops", color: "Cream", status: "available", wears: 2) == "p3 Cream poplin blouse (Tops, cream, available, worn 2)")
        #expect(AgentRecordLines.piece(handle: "p4", name: "Tee", category: "Tops", color: "", status: "laundry", wears: 0) == "p4 Tee (Tops, laundry, no recorded wear)")
        #expect(AgentRecordLines.piece(handle: "p5", name: "Belt", category: "", color: "", status: "", wears: nil) == "p5 Belt")
        #expect(AgentRecordLines.outfit(handle: "o2", name: "Office day", occasion: "Work", mood: nil, members: ["Blouse", "Trousers"]) == "o2 Office day (Work, 2 pieces: Blouse, Trousers)")
        #expect(AgentRecordLines.theme(handle: "t1", name: "Beach", outfits: []) == "t1 Beach (no outfits yet)")
        #expect(AgentRecordLines.plan(handle: "pl1", name: "Trip", start: "2026-11-01", end: "2026-11-03", kind: "trip", destination: "Boracay") == "pl1 Trip (2026-11-01 to 2026-11-03, trip, Boracay)")
    }
    @Test func rejectionTextsNeverMentionIDsAndAmbiguityNamesTheChoices() {
        let id = UUID()
        for rejection in [AgentToolRejection.unknownRecord(id), .staleRevision(expected: 1, current: 2), .revisionRequired, .missingTarget, .malformedID("x"), .notFound("Linen top"), .ambiguous("blazer", ["A", "B"])] {
            #expect(!rejection.reason.contains(id.uuidString) && !rejection.reason.lowercased().contains("revision"))
        }
        #expect(AgentToolRejection.ambiguous("blazer", ["Black blazer", "Oatmeal blazer"]).reason.contains("Black blazer or Oatmeal blazer"))
        #expect(AgentToolRejection.notFound("Linen top").stepSummary == "Couldn’t find “Linen top” in your closet")
    }
}
