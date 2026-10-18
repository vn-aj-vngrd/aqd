import Foundation
import AQDCore
#if canImport(FoundationModels)
import FoundationModels

/// Plans a trip as one reviewable set: a varied outfit for every day, built by the app from the owner's available pieces.
@available(iOS 26, *)
struct AgentProposeTripTool: Tool {
    let name = "proposeTrip"
    let description = "Prepare one review of a trip with a different outfit for each day, built from the owner's available pieces. The owner can save the days as outfits, group them in a theme and add them to the Planner. Needs the number of days; ask for it first if unknown. Pieces are chosen by the app, so do not send piece IDs unless the owner named a piece. Nothing is applied."
    let handlers: AgentToolHandlers
    @Generable struct Day {
        @Guide(description: "Short label such as Day 1 beach arrival, at most 40 characters") var label: String
        @Guide(description: "What the day involves, such as beach, dinner, island hopping or flight") var occasion: String
        @Guide(description: "Exact piece UUIDs the owner asked to include on this day", .maximumCount(3)) var pinnedIDs: [String]
    }
    @Generable struct Arguments {
        @Guide(description: "Trip name such as Boracay trip, at most 60 characters") var name: String
        var destination: String
        @Guide(description: "First day YYYY-MM-DD, only when the owner gave dates") var startDate: String?
        @Guide(description: "Activities such as snorkeling or nights out", .maximumCount(5)) var activities: [String]
        @Guide(description: "One entry per day, at most 7", .maximumCount(7)) var days: [Day]
    }
    func call(arguments: Arguments) async throws -> String {
        try await AgentToolbox.result {
            let spec = AgentTripSpec(destination: arguments.destination, activities: arguments.activities.filter { !$0.isEmpty }, startDate: arguments.startDate,
                days: try arguments.days.map { TripDayBrief(label: String($0.label.prefix(40)), occasion: $0.occasion, pinnedIDs: try $0.pinnedIDs.map(AgentToolbox.id)) })
            do { return try handlers.prepare(AgentMutationRequest(kind: .createTrip, name: String(arguments.name.prefix(60)), trip: spec), nil) }
            catch OutfitValidationError.piecesRequired {
                return "No trip prepared: the available closet cannot make a full outfit (needs tops and bottoms or a dress, plus shoes). Tell the owner what is missing and to add it from Closet."
            }
        }
    }
}
#endif
