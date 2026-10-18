import AQDCore
import Foundation

/// Shared review wording for single-date and bulk assignment conflicts.
enum PlanningAvailability {
    static func message(outfit: Outfit?, day: LocalPlanDay, pieces: [WardrobePiece]) -> String? {
        guard let outfit else { return nil }
        let conflicts = outfit.pieceIDs.compactMap { id -> String? in
            guard let piece = pieces.first(where: { $0.id == id }) else { return "Removed piece" }
            if piece.isArchived { return "\(piece.name) (Archived)" }
            if piece.availability != .available { return "\(piece.name) (\(piece.availability.rawValue.capitalized))" }
            return nil
        }
        guard !conflicts.isEmpty else { return nil }
        return "\(day.displayDate), \(outfit.name): \(conflicts.joined(separator: ", ")). Choose another outfit or leave this date unassigned."
    }
}
