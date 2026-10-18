import Foundation

/// The corrective prompt for the one regeneration after a reply fails the grounding check.
public enum AgentGroundingRepair {
    public static let note = "Some items mentioned aren’t in your closet."
    static let nameCharacters = 1500

    public static func prompt(request: String, previousReply: String, violations: [AgentGroundingViolation], catalog: AgentNameCatalog, cardsShown: Int) -> AgentPromptParts {
        var problems: [String] = []
        let invented = violations.compactMap { v -> String? in if case .invented(let name) = v { name } else { nil } }
        if !invented.isEmpty { problems.append("It named things that are not in the owner's closet: " + invented.joined(separator: ", ") + ".") }
        if violations.contains(where: { $0.isLeak }) { problems.append("It showed internal codes. Never show codes such as p3 or ids; use names only.") }
        let counts = violations.compactMap { v -> String? in if case .count(let c) = v { c } else { nil } }
        if !counts.isEmpty { problems.append("These numbers disagree with the closet: " + counts.joined(separator: ", ") + ". Use the totals in the facts, or give no number.") }
        if violations.contains(where: { $0.isContradiction }) { problems.append("The app is showing \(cardsShown) matching cards, so do not say nothing was found.") }
        if violations.contains(where: { $0.isFalseClaim }) { problems.append("It said a change was made. Nothing is changed until the owner reviews and saves it: say a review is ready, or that nothing was prepared.") }
        var names: [String] = []
        var size = 0
        for name in catalog.allNames where size + name.count + 2 <= nameCharacters { names.append(name); size += name.count + 2 }
        let allowed = names.isEmpty ? "Name no specific pieces." : "Use only these names: " + names.joined(separator: ", ") + "."
        let context = "Your last reply to the owner had a problem. " + problems.joined(separator: " ") + " Rewrite it in one to three short sentences. " + allowed
            + "\nLast reply: " + String(previousReply.prefix(500))
        return AgentPromptParts(context: context, userTurn: request)
    }
}
