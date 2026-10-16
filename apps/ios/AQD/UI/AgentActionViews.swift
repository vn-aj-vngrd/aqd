import AQDCore
import SwiftUI

struct AgentActionComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var state
    @Bindable var model: AgentModel
    @State private var kind = "Theme"
    @State private var name = ""
    @State private var pieceIDs: Set<UUID> = []
    @State private var outfitIDs: Set<UUID> = []
    @State private var availability = PieceAvailability.available
    @State private var first = Date()
    @State private var last = Date()
    @State private var unassigned = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Text("Manual draft · Not saved. Choose exact records, then review before applying. Conversation text never approves a change.").font(.subheadline)
                Picker("Task", selection: $kind) { ForEach(["Theme", "Outfit", "Plan", "Wear", "Availability"], id: \.self) { Text($0) } }
                if ["Theme", "Outfit", "Plan"].contains(kind) { TextField("Name", text: $name) }
                if ["Outfit", "Wear", "Availability"].contains(kind) {
                    Section("Pieces") {
                        ForEach(state.pieces) { piece in
                            Toggle(piece.name, isOn: Binding(get: { pieceIDs.contains(piece.id) }, set: { value in
                                if value { if kind == "Availability" { pieceIDs = [] }; pieceIDs.insert(piece.id) } else { pieceIDs.remove(piece.id) }
                            }))
                        }
                    }
                } else {
                    Section("Outfits") { ForEach(state.outfits) { outfit in
                        Toggle(outfit.name, isOn: Binding(get: { outfitIDs.contains(outfit.id) }, set: { value in if value { if kind == "Plan" { outfitIDs = [] }; outfitIDs.insert(outfit.id) } else { outfitIDs.remove(outfit.id) } }))
                    } }
                }
                if kind == "Availability" { Picker("Availability", selection: $availability) { ForEach(PieceAvailability.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } } }
                if kind == "Plan" || kind == "Wear" { DatePicker(kind == "Plan" ? "First date" : "Recorded date", selection: $first, displayedComponents: .date) }
                if kind == "Plan" { DatePicker("Last date", selection: $last, displayedComponents: .date); Toggle("Leave dates without an outfit intentionally unassigned", isOn: $unassigned) }
                if let error { Text(error).foregroundStyle(AppTheme.error) }
            }.scrollContentBackground(.hidden).background(AppTheme.canvas).navigationTitle("Local tools").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { ToolbarSaveAction(title: "Review") { prepare() } } }
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button { dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("Cancel") } }
        }.tint(AppTheme.ink)
    }
    private func prepare() {
        do {
            let owner = model.conversation.ownerID
            let action: AgentReviewedAction
            switch kind {
            case "Theme":
                var draft = ThemeDraft(ownerID: owner); draft.name = name; draft.outfitIDs = outfitIDs.sorted { $0.uuidString < $1.uuidString }
                try draft.validatedForSave(themes: state.themes, outfits: state.outfits); action = .theme(draft)
            case "Outfit":
                var draft = OutfitDraft(ownerID: owner); draft.name = name
                try draft.applyManualSelection(pieceIDs.sorted { $0.uuidString < $1.uuidString }, pieces: state.pieces)
                try draft.validatedForSave(pieces: state.pieces); action = .outfit(draft)
            case "Plan":
                var draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: owner, name: name, start: LocalPlanDay(date: first), end: LocalPlanDay(date: last)))
                for i in draft.slots.indices { draft.slots[i].outfit = state.outfits.first { outfitIDs.contains($0.id) }; draft.slots[i].unassignedByChoice = unassigned }
                draft.reviewing = true; try draft.validatedForSave(outfits: state.outfits, existing: state.planEntries); action = .plan(draft)
            case "Wear":
                let draft = OutfitWearDraft(ownerID: owner, pieces: state.pieces.filter { pieceIDs.contains($0.id) }, day: LocalPlanDay(date: first))
                try draft.validatedForSave(pieces: state.pieces); action = .wear(draft)
            default:
                guard pieceIDs.count == 1, let piece = state.pieces.first(where: { pieceIDs.contains($0.id) }) else { throw PieceStore.StoreError.invalidRecord }
                action = .availability(AgentAvailabilityChange(piece: piece, value: availability))
            }
            model.propose(action); if model.error == nil { dismiss() } else { error = model.error }
        } catch { self.error = "Check the name, selected records and dates. Plans need reviewed, conflict-free assignments; wear needs actual pieces and a date through today." }
    }
}

struct AgentActionReviewView: View {
    @Environment(AppState.self) private var state
    @Bindable var model: AgentModel
    let id: UUID
    private var proposal: AgentActionProposal? { model.conversation.proposals?.first { $0.id == id } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let proposal {
                    Text(proposal.action.title).font(AppTypography.section)
                    Text(proposal.status == .succeeded ? "Saved locally" : "Draft · Not confirmed saved").foregroundStyle(AppTheme.secondary)
                    preview(proposal.action)
                    if let error = model.error { Text(error).foregroundStyle(AppTheme.error); Button("Check conversation save") { model.retryPending() }.frame(minHeight: 44) }
                    if let receipt = proposal.receipt, proposal.status == .succeeded {
                        Text("Saved receipt · \(receipt.acknowledgedAt.formatted())").font(.footnote)
                        if receipt.kind == "outfit" { NavigationLink("Open outfit", value: ClosetRoute.outfit(receipt.recordID)) }
                        else if receipt.kind == "theme" { NavigationLink("Open theme", value: ClosetRoute.theme(receipt.recordID)) }
                        else if receipt.kind == "piece" { NavigationLink("Open piece", value: ClosetRoute.piece(receipt.recordID)) }
                        else { Text("Open Planner or wear history to review the acknowledged records.") }
                    } else if proposal.status == .proposed || proposal.status == .executing {
                        if proposal.status == .proposed { SecondaryAction(title: "Keep current records") { model.cancelProposal(id) } }
                        Text("Approval applies only to this exact version. Changed records require a new review. Check an unconfirmed operation before making another draft.").font(.footnote).foregroundStyle(AppTheme.secondary)
                    }
                } else { Text("This proposal is unavailable. Your saved records are retained.") }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Review changes").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if let proposal, proposal.status == .proposed || proposal.status == .executing {
                    ToolbarSaveAction(title: proposal.status == .executing ? "Check result" : "Apply") {
                        model.approveProposal(id, version: proposal.version)
                        state.reloadPieces(); state.reloadOutfits(); state.reloadThemes(); state.reloadPlanEntries(); state.reloadWear()
                    }.disabled(model.hasPendingOperation)
                        .accessibilityLabel(proposal.status == .executing ? "Check reviewed operation" : "Apply reviewed change")
                }
            } }
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
    }
    @ViewBuilder private func preview(_ action: AgentReviewedAction) -> some View {
        switch action {
        case .theme(let draft): Text(draft.name).font(.headline); ForEach(draft.outfitIDs, id: \.self) { id in Text(state.outfits.first { $0.id == id }?.name ?? "Unavailable outfit") }
        case .outfit(let draft): Text(draft.name).font(.headline); ForEach(draft.pieceIDs, id: \.self) { id in Text(state.ownedPieces.first { $0.id == id }?.name ?? "Unavailable piece") }
        case .plan(let draft):
            Text(draft.plan.name).font(.headline)
            ForEach(draft.slots) { slot in VStack(alignment: .leading) { Text(slot.day.key + " · " + slot.day.timeZoneID); Text(slot.outfit?.name ?? "Intentionally unassigned") } }
        case .wear(let draft): Text(draft.day.key + " · " + draft.day.timeZoneID); ForEach(draft.pieceIDs, id: \.self) { id in Text(state.ownedPieces.first { $0.id == id }?.name ?? "Unavailable piece") }; Text("Records actual wear. This is separate from a plan or fit memory.")
        case .availability(let change): Text(change.pieceName).font(.headline); Text("Availability → " + change.value.rawValue.capitalized); Text("Affected future plans will require review; actual wear stays.")
        }
    }
}
