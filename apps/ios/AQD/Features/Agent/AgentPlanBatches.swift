import Foundation
import AQDCore

@MainActor extension AgentModel {
    /// Collects a ranged plan's days across batched calls. Returns guidance while days are missing; once the range is complete,
    /// `request` carries every day so one full preview is reviewed and applied all-or-nothing.
    func stagePlanBatch(_ request: inout AgentMutationRequest, attemptID: UUID) throws -> String? {
        guard request.kind == .createPlan, let start = request.rangeStart, let end = request.rangeEnd else { return nil }
        let key = start + "…" + end
        let added = Set(request.assignments.map(\.date))
        request.assignments = ((stagedPlanDays[key] ?? []).filter { !added.contains($0.date) } + request.assignments).sorted { $0.date < $1.date }
        do {
            guard let missing = try request.missingDays(), !missing.isEmpty else { stagedPlanDays[key] = nil; return nil }
            stagedPlanDays[key] = request.assignments
            let total = request.assignments.count + missing.count
            appendToolStep(AgentToolStep(tool: "proposePlan", summary: "Drafted \(request.assignments.count) of \(total) days", count: request.assignments.count), attemptID: attemptID)
            return "Staged \(request.assignments.count) of \(total) days; nothing is reviewable yet. Call proposePlan again with outfits for the missing days: " + missing.joined(separator: ", ")
        } catch {
            stagedPlanDays[key] = nil; throw AgentToolRejection.invalidArguments
        }
    }
}
