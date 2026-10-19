import Foundation

/// A wear question answered in plain words from recorded wear, never from the model's arithmetic.
public enum AgentWearAnswer {
    public enum Focus: Equatable, Sendable { case unworn, mostWorn, named, overview }

    public static func focus(_ prompt: String, namesPiece: Bool) -> Focus {
        let text = prompt.lowercased()
        if ["unworn", "rediscover", "least", "never", "haven t", "haven't", "havent", "not worn", "forgotten", "neglected", "ignored"].contains(where: text.contains) { return .unworn }
        if namesPiece { return .named }
        if ["most", "favorite", "favourite", "often", "top", "reach for"].contains(where: text.contains) { return .mostWorn }
        return .overview
    }

    public static func period(_ lastMonth: Bool) -> String { lastMonth ? "last month" : "this month" }

    public static func unworn(count: Int, active: Int, period: String) -> String {
        if count == 0 { return "You’ve worn every one of your \(active) pieces \(period). That’s a great rotation." }
        let lead = count == 1 ? "There’s 1 piece you haven’t worn \(period)." : "You haven’t worn \(count) of your \(active) pieces \(period)."
        return lead + " Here " + (count == 1 ? "it is" : "are a few to bring back, starting with the ones you’ve gone longest without") + "."
    }

    public static func mostWorn(_ ranked: [(name: String, wears: Int)], period: String) -> String {
        guard let first = ranked.first, first.wears > 0 else { return "You haven’t recorded any wear \(period) yet. Log a look and I’ll keep count." }
        let rest = ranked.dropFirst().filter { $0.wears > 0 }.prefix(2).map(\.name)
        let times = first.wears == 1 ? "once" : "\(first.wears) times"
        return "Your most worn piece \(period) is \(first.name), \(times)." + (rest.isEmpty ? "" : " Close behind: " + (rest.count == 2 ? "\(rest[0]) and \(rest[1])" : rest[0]) + ".")
    }

    public static func named(_ name: String, count: Int, period: String) -> String {
        count == 0 ? "You haven’t worn \(name) \(period)." : "You’ve worn \(name) \(count == 1 ? "once" : "\(count) times") \(period)."
    }

    public static func overview(looks: Int, used: Int, active: Int, period: String) -> String {
        looks == 0 ? "You haven’t recorded any wear \(period) yet. Log what you wear and I’ll show your patterns."
            : "\(period.prefix(1).uppercased() + period.dropFirst()) you’ve recorded \(looks) \(looks == 1 ? "look" : "looks") and worn \(used) of your \(active) pieces."
    }
}
