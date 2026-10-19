import AQDCore
import Foundation

/// Work the app starts before the model writes a word, because it needs an active attempt to attach its review or question to.
enum AgentPreflight {
    case suggest(occasion: String?, pins: [UUID])
    case command(AgentCommand)
    case trip(TripIntent)
}

@MainActor extension AgentModel {
    /// The call name recorded for work the router carried out itself, so the eval can tell it from a tool the model chose.
    static func routed(_ tool: String) -> String { tool + " (router)" }

    /// Reads the request the way a person would: a plain command, or a request for a look. Nil leaves everything to the model and its tools.
    func preflight(for intent: AgentIntent, request: String, index: AgentRecordIndex) -> AgentPreflight? {
        switch intent {
        case .editPiece, .relabel, .recordWear, .profile, .theme, .tidy, .editOutfit, .editTheme, .editPlan: return AgentCommand.parse(request).map(AgentPreflight.command)
        case .planDays: return AgentCommand.parse(request).map(AgentPreflight.command)
        case .planTrip:
            let recent = (conversation.messages.filter { $0.role == .user }.suffix(3).map(\.source) + [request]).joined(separator: ". ")
            // Trips with dates go to the model, which can place them on the Planner; plain ones are built by the app.
            return TripIntent.mentionsDates(recent) ? nil : TripIntent.parse(recent, requireTrigger: false).map(AgentPreflight.trip)
        case .suggestOutfit, .whatToWear: return .suggest(occasion: AgentShowQuery.occasion(in: request), pins: index.mentions(in: request, kinds: [.piece]).map(\.id))
        default: return nil
        }
    }

    func runPreflight(_ preflight: AgentPreflight, attempt: UUID, conversationID: UUID) async throws -> AgentFastPath? {
        switch preflight {
        case .suggest(let occasion, let pins): return try await runSuggestion(occasion: occasion, pins: pins, attempt: attempt, conversationID: conversationID)
        case .command(let command): return try runCommand(command, attempt: attempt, conversationID: conversationID)
        case .trip(let intent):
            return try prepareRouted(AgentMutationRequest(kind: .createTrip, name: intent.name, trip: AgentTripSpec(destination: intent.destination, days: intent.briefs)), tool: .proposeTrip, target: intent.destination, attempt: attempt, conversationID: conversationID)
        }
    }

    private func runSuggestion(occasion: String?, pins: [UUID], attempt: UUID, conversationID: UUID) async throws -> AgentFastPath? {
        calledTools.append(Self.routed("suggestOutfit"))
        let message: String
        do { message = try await suggestToolOutfit(occasion: occasion, mood: nil, pinnedIDs: pins, conversationID: conversationID, attemptID: attempt) }
        catch let rejection as AgentToolRejection { return AgentFastPath(note: "Nothing was prepared: " + rejection.reason + " Tell the owner briefly.", fallback: "I couldn’t put a look together from that.") }
        guard let proposal = conversation.proposals?.last(where: { $0.attemptID == attempt }), case .outfit(let draft) = proposal.action else {
            return AgentFastPath(note: message + " Tell the owner briefly what is missing.", fallback: "I couldn’t build a full outfit from your available pieces. Check what’s missing in your closet.")
        }
        let names = draft.pieceIDs.compactMap { id in ((try? store.pieces()) ?? []).first { $0.id == id }?.displayName }
        let why = occasion.map { "why it suits " + $0 } ?? "why it works"
        return AgentFastPath(note: "The app prepared an outfit review named “\(draft.displayName)” with " + names.joined(separator: ", ") + ", shown as a card to review. Write one short sentence on \(why). Do not list the pieces and do not say it is saved.",
                             fallback: "I put together “\(draft.displayName)” from your closet. Review it below; nothing is saved yet.")
    }

    /// Carries out a complete instruction. A name that fits several records asks the owner which; one that fits none is a quiet step.
    private func runCommand(_ command: AgentCommand, attempt: UUID, conversationID: UUID) throws -> AgentFastPath? {
        let index = recordIndex
        func find(_ reference: String, _ kinds: [AgentRecordKind]) throws -> AgentRecordIndex.Entry { try resolveToolReference(reference, kinds: kinds, index: index, attemptID: attempt) }
        var request: AgentMutationRequest
        var tool: AgentToolID
        var target = ""
        do {
            switch command {
            case .rename(let name, let new):
                target = name
                let entry = try find(name, [.piece, .outfit, .theme])
                (request, tool) = entry.kind == .piece ? (AgentMutationRequest(kind: .editPiece, targetID: entry.id, name: new), .editCloset) : (AgentMutationRequest(kind: .relabel, targetID: entry.id, name: new), .relabel)
                if entry.kind == .plan { return nil }
            case .setAvailability(let name, let value):
                target = name
                guard let availability = PieceAvailability(rawValue: value) else { return nil }
                request = AgentMutationRequest(kind: .setAvailability, targetID: try find(name, [.piece]).id, availability: availability); tool = .editCloset
            case .setPieceField(let name, let field, let value):
                target = name
                let id = try find(name, [.piece]).id
                request = AgentMutationRequest(kind: .editPiece, targetID: id, color: field == "color" ? value : nil, brand: field == "brand" ? value : nil); tool = .editCloset
            case .setOutfitField(let name, let field, let value):
                target = name
                let id = try find(name, [.outfit]).id
                request = AgentMutationRequest(kind: .relabel, targetID: id, occasion: field == "occasion" ? value : nil, mood: field == "mood" ? value : nil); tool = .relabel
            case .setProfile(let field, let value):
                request = AgentMutationRequest(kind: .updateProfile, name: field == "name" ? value : nil, caption: field == "caption" ? value : nil); tool = .editProfile
            case .recordWear(let subjects, let offset):
                guard let day = Calendar.current.date(byAdding: .day, value: offset, to: Date()) else { return nil }
                let entries = try subjects.map { target = $0; return try find($0, [.outfit, .piece]) }
                let outfits = entries.filter { $0.kind == .outfit }
                guard outfits.isEmpty || (outfits.count == 1 && entries.count == 1) else { return nil }
                request = AgentMutationRequest(kind: .recordWear, pieceIDs: outfits.isEmpty ? entries.map(\.id) : [], date: LocalPlanDay(date: day).key, wearOutfitID: outfits.first?.id); tool = .recordWear
            case .addTo(let subjects, let container):
                target = container
                (request, tool) = try membership(try find(container, [.outfit, .theme]), subjects: subjects, mode: .add, find: find)
            case .removeFrom(let subjects, let container):
                target = container
                (request, tool) = try membership(try find(container, [.outfit, .theme]), subjects: subjects, mode: .remove, find: find)
            case .swapIn(let old, let new, let container):
                target = container
                (request, tool) = try membership(try find(container, [.outfit, .theme]), subjects: [old], mode: .swap(new), find: find)
            case .setPlanDay(let planName, let word, let outfitName):
                target = planName
                let planEntry = try find(planName, [.plan]), outfit = try find(outfitName, [.outfit])
                guard let plan = try store.planDefinitions().first(where: { $0.id == planEntry.id }),
                      let key = AgentPlanDayWord.key(word, in: (try? plan.days()) ?? []) else { throw AgentToolRejection.notFound(word + " in " + planName) }
                request = AgentMutationRequest(kind: .editPlan, targetID: plan.id, assignments: [AgentPlanAssignment(date: key, outfitID: outfit.id)]); tool = .editPlan
            case .tidy(let op, let subjects):
                // An archived piece is named only to restore it; archiving or deleting one that is already archived finds nothing.
                let entries = try subjects.map { target = $0; return try find($0, [.piece]) }
                let archived = entries.map { $0.name.hasSuffix(AgentKnowledgeSource.archivedSuffix) }
                guard archived.allSatisfy({ $0 == (op == .unarchive) }) else { throw AgentToolRejection.notFound(target) }
                request = AgentMutationRequest(kind: .tidyPieces, pieceIDs: entries.reduce(into: [UUID]()) { if !$0.contains($1.id) { $0.append($1.id) } }, tidyOp: op); tool = .tidyCloset
            case .planDays(let count):
                guard let draft = planDraft(days: count) else { return nil }
                request = draft; tool = .proposePlan
            case .createTheme(let name, let about):
                guard let about else { return nil }
                let words = Set(AgentText.stems(about))
                let outfits = ((try? store.outfits()) ?? []).filter { outfit in
                    let own = Set(AgentText.stems([outfit.name, outfit.occasion ?? "", outfit.mood ?? ""].joined(separator: " ")))
                    return words.isSubset(of: own)
                }
                guard !outfits.isEmpty else { return nil }
                request = AgentMutationRequest(kind: .createTheme, name: name ?? about.prefix(1).uppercased() + about.dropFirst() + " looks", outfitIDs: outfits.map(\.id)); tool = .proposeTheme
            }
        } catch let rejection as AgentToolRejection {
            var path = rejectionPath(rejection, target: target)
            // A name that fits nothing or two things is answered by the app, never left for the model to describe.
            switch command { case .addTo, .removeFrom, .swapIn, .setPlanDay, .tidy: path.exact = true; default: break }
            return path
        }
        var path = try prepareRouted(request, tool: tool, target: target, attempt: attempt, conversationID: conversationID)
        switch command {
        case .addTo, .removeFrom, .swapIn, .setPlanDay:
            // The sentence is the app's own, so what it says always matches what approving does.
            if path != nil {
                path?.exact = true
                if let proposal = conversation.proposals?.last(where: { $0.attemptID == attempt }) {
                    path?.fallback = "I prepared a review. " + proposal.effectiveAction.savesSummary + " Review it below; nothing is saved yet."
                }
            }
        default: break
        }
        if case .tidy = command, path != nil {
            path?.exact = true
            if let proposal = conversation.proposals?.last(where: { $0.attemptID == attempt }), case .tidy(let change) = proposal.action { path?.fallback = Self.tidySentence(change) }
        }
        return path
    }

    private enum Membership { case add, remove, swap(String) }

    /// Adds, removes or swaps members of a saved outfit (pieces) or theme (outfits), always sending the complete new list the review replaces.
    private func membership(_ container: AgentRecordIndex.Entry, subjects: [String], mode: Membership,
                            find: (String, [AgentRecordKind]) throws -> AgentRecordIndex.Entry) throws -> (AgentMutationRequest, AgentToolID) {
        let memberKind: AgentRecordKind = container.kind == .outfit ? .piece : .outfit
        let named = try subjects.map { try find($0, [memberKind]).id }
        var members: [UUID]
        switch container.kind {
        case .outfit: members = try store.outfit(id: container.id)?.pieceIDs ?? { throw AgentToolRejection.unknownRecord(container.id) }()
        case .theme: members = try store.themes().first { $0.id == container.id }?.outfitIDs ?? { throw AgentToolRejection.unknownRecord(container.id) }()
        default: throw AgentToolRejection.invalidArguments
        }
        let before = members
        switch mode {
        case .add: for id in named where !members.contains(id) { members.append(id) }
        case .remove: members.removeAll { named.contains($0) }
        case .swap(let replacement):
            let new = try find(replacement, [memberKind]).id
            guard let old = named.first, members.contains(old) else { throw AgentToolRejection.invalidArguments }
            members = members.map { $0 == old ? new : $0 }.reduce(into: [UUID]()) { if !$0.contains($1) { $0.append($1) } }
        }
        guard members != before, !members.isEmpty else { throw AgentToolRejection.invalidArguments }
        return container.kind == .outfit
            ? (AgentMutationRequest(kind: .editOutfit, targetID: container.id, pieceIDs: members), .editOutfit)
            : (AgentMutationRequest(kind: .editTheme, targetID: container.id, outfitIDs: members), .editTheme)
    }

    /// The one sentence under a tidy review, written by the app so its wording always matches what approving does.
    nonisolated static func tidySentence(_ change: AgentTidyChange) -> String {
        let names = change.items.map(\.name)
        let list = names.count > 1 ? names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "") : names.first ?? ""
        switch change.op {
        case .archive: return "Ready to archive \(list). Untick any you want to keep. Nothing changes until you approve, and you can undo it."
        case .unarchive: return "Ready to restore \(list) to your closet. Nothing changes until you approve."
        case .delete: return "Ready to permanently delete \(list). You’ll see what it affects before anything is deleted, and it can’t be undone."
        }
    }

    private func rejectionPath(_ rejection: AgentToolRejection, target: String) -> AgentFastPath {
        switch rejection {
        case .ambiguous: AgentFastPath(note: "The app is asking the owner which “\(target)” they mean, with tappable answers. Reply with one short sentence and wait; do not repeat the answers.", fallback: "Which one do you mean?")
        case .notFound: AgentFastPath(note: "Nothing in the closet matches “\(target)”. Say so in one short sentence and ask the owner to check the name.", fallback: "I couldn’t find “\(target)” in your closet.")
        default: AgentFastPath(note: "Nothing was prepared: " + rejection.reason + " Tell the owner briefly.", fallback: "I couldn’t prepare that change. \(rejection.stepSummary).")
        }
    }

    /// Validates and drafts the review. The owner still has to open it and save; nothing is written here.
    private func prepareRouted(_ request: AgentMutationRequest, tool: AgentToolID, target: String, attempt: UUID, conversationID: UUID) throws -> AgentFastPath? {
        do {
            calledTools.append(Self.routed(tool.rawValue))
            _ = try prepareToolChange(request, conversationID: conversationID, attemptID: attempt)
        } catch let rejection as AgentToolRejection {
            return rejectionPath(rejection, target: target)
        } catch is CancellationError {
            throw CancellationError()
        } catch OutfitValidationError.piecesRequired {
            return AgentFastPath(note: "No review was prepared: the available closet cannot make a full outfit (it needs tops and bottoms or a dress, plus shoes). Tell the owner what to add from Closet.",
                                 fallback: "Your available pieces can’t make a full outfit yet. Add the missing pieces from Closet and ask again.")
        } catch {
            return AgentFastPath(note: "The change could not be validated (the record, name or date did not fit). Tell the owner briefly and suggest the manual editor.", fallback: "I couldn’t prepare that change. You can make it by hand in the app.")
        }
        guard let proposal = conversation.proposals?.last(where: { $0.attemptID == attempt }) else { return nil }
        return AgentFastPath(note: "The app prepared a review: \(proposal.action.savesSummary) It is shown as a card; nothing is saved until the owner reviews and saves it. Write one short sentence saying so. Do not say it is saved.",
                             fallback: "I prepared a review. " + proposal.action.savesSummary + " Review it below; nothing is saved yet.")
    }

    /// Consecutive days from today, each with a saved outfit that is fully available. Work days prefer work looks, weekends prefer easy ones, and no outfit repeats until all are used.
    private func planDraft(days count: Int) -> AgentMutationRequest? {
        guard let pieces = try? store.pieces(), let outfits = try? store.outfits() else { return nil }
        let usable = outfits.filter { outfit in !outfit.pieceIDs.isEmpty && outfit.pieceIDs.allSatisfy { id in pieces.contains { $0.id == id && !$0.isArchived && $0.availability == .available } } }
        guard !usable.isEmpty else { return nil }
        let calendar = Calendar.current
        var unused = usable, assignments: [AgentPlanAssignment] = []
        for offset in 0..<count {
            guard let date = calendar.date(byAdding: .day, value: offset, to: Date()) else { return nil }
            let weekend = calendar.isDateInWeekend(date)
            let preferred = weekend ? ["weekend", "sunday", "casual", "brunch", "event", "beach"] : ["work", "casual"]
            if unused.isEmpty { unused = usable }
            let match = unused.firstIndex { outfit in preferred.contains { (outfit.occasion ?? "").lowercased().contains($0) } } ?? 0
            assignments.append(AgentPlanAssignment(date: LocalPlanDay(date: date).key, outfitID: unused.remove(at: match).id))
        }
        guard let first = assignments.first?.date, let last = assignments.last?.date else { return nil }
        return AgentMutationRequest(kind: .createPlan, name: count == 7 ? "This week" : "Next \(count) days", assignments: assignments, rangeStart: first, rangeEnd: last)
    }
}
