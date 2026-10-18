import Foundation
import AQDCore
#if canImport(FoundationModels)
import FoundationModels

/// Plans saved outfits across consecutive days. Long plans arrive in batches of seven days; nothing is reviewable until every day is covered.
@available(iOS 26, *)
struct AgentProposePlanTool: Tool {
    let name = "proposePlan"
    let description = "Prepare a review that plans saved outfits for consecutive days, at most 14 in total. Send at most 7 days per call and call again with the remaining days until every day from start to end is covered. Use weatherFor first for weather-aware plans and never guess weather. Only when the user asks. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Arguments {
        var name: String
        @Guide(description: "First day of the whole plan, YYYY-MM-DD in the user's timezone") var start: String
        @Guide(description: "Last day of the whole plan, YYYY-MM-DD, at most 14 days after start") var end: String
        @Guide(description: "Days and saved outfits (handle or name) for this call, at most 7", .maximumCount(7)) var assignments: [AgentEditPlanTool.Assignment]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let request = AgentMutationRequest(kind: .createPlan, name: arguments.name,
                assignments: try arguments.assignments.map { AgentPlanAssignment(date: $0.date, outfitID: try handlers.resolve($0.outfit, [.outfit]).id) },
                rangeStart: arguments.start, rangeEnd: arguments.end)
            return try handlers.prepare(request, .proposePlan)
        }
    }
}
#endif
