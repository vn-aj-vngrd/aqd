import AQDCore
import Foundation

@MainActor extension AgentModel {
    /// Saves a reviewed trip in a fixed order: each day's outfit, then the theme, then the Planner trip.
    /// Every step reads its own receipt first, so applying again after an interruption resumes instead of duplicating.
    func applyTrip(_ trip: AgentTripDraft) throws -> AgentActionReceipt {
        var saved: [Outfit] = []
        for day in trip.days {
            let draft = day.outfit
            if try store.savedOutfit(for: draft) == nil {
                guard try store.outfitDraft().map({ $0 == draft }) ?? true else { throw PieceStore.StoreError.staleDraft }
                try store.saveOutfitDraft(draft)
            }
            saved.append(try store.saveOutfit(draft))
            if try store.outfitDraft() == draft { try store.acknowledgeOutfitReceipt(draft) }
        }
        var recordID = saved[0].id
        if trip.includeTheme {
            let draft = trip.theme
            if try store.savedTheme(for: draft) == nil {
                guard try store.themeDraft().map({ $0 == draft }) ?? true else { throw PieceStore.StoreError.staleDraft }
                try store.saveThemeDraft(draft)
            }
            recordID = try store.saveTheme(draft).id
            if try store.themeDraft() == draft { try store.finishThemeDraft(draft) }
        }
        if let draft = try trip.resolvedPlan(saved: saved) {
            if try store.savedPlanAuthoring(draft) == nil {
                guard try store.planAuthoringDraft().map({ $0 == draft }) ?? true else { throw PieceStore.StoreError.staleDraft }
                try store.savePlanAuthoringDraft(draft)
            }
            recordID = try store.savePlanAuthoring(draft).plan.id
            if try store.planAuthoringDraft() == draft { try store.finishPlanAuthoring(draft) }
        }
        return AgentActionReceipt(recordID: recordID, kind: "trip")
    }

    /// Choosing what a trip review saves. Only an unapplied review can change.
    func setTripOptions(_ id: UUID, includeTheme: Bool? = nil, includePlan: Bool? = nil) {
        guard !hasPendingOperation, let i = conversation.proposals?.firstIndex(where: { $0.id == id }), conversation.proposals?[i].status == .proposed,
              case .trip(var trip) = conversation.proposals?[i].action else { return }
        if let includeTheme { trip.includeTheme = includeTheme }
        if let includePlan, trip.canPlan { trip.includePlan = includePlan }
        conversation.proposals?[i].action = .trip(trip); _ = persist()
    }

    /// A clear trip request always ends with looks to review. When the model answered in text without preparing them,
    /// the app prepares the same review itself from the request, so planning never depends on the model calling a tool.
    func ensureTripProposal(attemptID: UUID) {
        guard conversation.context.automatic == true, conversation.context.scope == .closet,
              !(conversation.proposals ?? []).contains(where: { $0.attemptID == attemptID }),
              let reply = conversation.messages.last(where: { $0.attemptID == attemptID && $0.role == .assistant }),
              reply.source.filter({ $0 == "?" }).count < 2,
              let prompt = conversation.messages.last(where: { $0.role == .user })?.source,
              let intent = TripIntent.parse(prompt),
              let preferences = try? store.localSettings().agentPreferences ?? AgentPreferences(),
              AgentMutationKind.createTrip.requiredSources.allSatisfy(preferences.allows),
              (conversation.proposals ?? []).filter({ $0.status == .proposed }).count < 4 else { return }
        let request = AgentMutationRequest(kind: .createTrip, name: intent.name, trip: AgentTripSpec(destination: intent.destination, days: intent.briefs))
        guard !(conversation.proposals ?? []).contains(where: { $0.toolRequest == request && $0.status == .proposed }),
              let action = try? request.prepare(ownerID: conversation.ownerID, pieces: store.pieces(), outfits: store.outfits(), themes: store.themes(),
                                                plans: store.planDefinitions(), entries: store.planEntries()) else { return }
        var proposal = AgentActionProposal(action: action)
        proposal.toolRequest = request; proposal.attemptID = attemptID; proposal.sources = []
        conversation.proposals = (conversation.proposals ?? []) + [proposal]
        calledTools.append("proposeTrip (app)")
        if let i = conversation.messages.lastIndex(where: { $0.attemptID == attemptID && $0.role == .assistant }) {
            conversation.messages[i].toolSteps = (conversation.messages[i].toolSteps ?? []) + [AgentToolStep(tool: "proposal", summary: "Prepared a review: \(action.title)", count: 1)]
        }
    }
}
