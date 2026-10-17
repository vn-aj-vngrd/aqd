import AQDCore
import Foundation

/// Reads only enabled local sources. Failed reads stay unknown rather than becoming zero counts.
@MainActor enum AgentKnowledgeSource {
    struct Result {
        let retrieval: AgentRetrievalResult
        let unavailable: [AgentDataSource]
        let sources: [AgentDataSource]
    }
    static func build(store: PieceStore, preferences: AgentPreferences, query: String, currentConversationID: UUID,
                      weather: WeatherClient?, selection: WeatherSelection?, maximumCharacters: Int, maximumRecords: Int, now: Date = Date()) throws -> Result {
        var used: [AgentDataSource] = []
        var unavailable: [AgentDataSource] = [], records: [AgentKnowledgeRecord] = []
        var facts = ["Saved local data as of \(LocalPlanDay(date: now).key). Plans are not recorded wear. Saved wardrobe and fit photos are not automatically analyzed. Explicit attachment references state their separate analysis method."]
        func read<T>(_ source: AgentDataSource, _ body: () throws -> [T]) -> [T] {
            guard preferences.allows(source) else { return [] }
            do { return try body() } catch { unavailable.append(source); return [] }
        }
        let pieces = read(.pieces) { try store.pieces() + store.pieces(archived: true) }
        let outfits = read(.outfits) { try store.outfits() }
        let themes = read(.themes) { try store.themes() }
        let plans = read(.planner) { try store.planDefinitions() }
        let entries = read(.planner) { try store.planEntries() }
        let wear = read(.wear) { try store.wearRecords().filter { $0.day.key <= LocalPlanDay(date: now).key } }
        let fits = read(.journal) { try store.fitMemories() }
        let cards = read(.today) { try store.todayPersonalCards() }
        var chats: [AgentConversation] = []
        if preferences.allows(.pastChats) || preferences.allows(.feedback) {
            do { chats = try store.agentConversations() }
            catch { if preferences.allows(.pastChats) { unavailable.append(.pastChats) }; if preferences.allows(.feedback) { unavailable.append(.feedback) } }
        }
        var categories: [WardrobeCategory] = []
        if preferences.allows(.pieces) {
            do { categories = try store.localExperience().pieceCategories ?? WardrobeCategory.defaults }
            catch { facts.append("Custom category labels could not be read; garment types remain available.") }
        }
        let notes = preferences.allows(.notes)
        var counts: [UUID: Int] = [:]
        for record in wear { for piece in record.pieces { counts[piece.id, default: 0] += 1 } }
        func fact(_ source: AgentDataSource, _ text: String) {
            if preferences.allows(source), !unavailable.contains(source) { facts.append(text); used.append(source) }
        }
        fact(.pieces, "Pieces: \(pieces.filter { !$0.isArchived }.count) active, \(pieces.filter(\.isArchived).count) archived; \(pieces.filter { !$0.isArchived && $0.availability == .available }.count) available for outfits.")
        fact(.outfits, "Saved outfits: \(outfits.count).")
        fact(.themes, "Saved themes: \(themes.count).")
        fact(.planner, "Plans: \(plans.count); dated entries: \(entries.count). Entries are plans, never proof of wear.")
        fact(.journal, "Fit memories: \(fits.count), including \(fits.filter { $0.photoID != nil }.count) photos. Fit memories do not imply recorded wear.")
        fact(.wear, "Recorded wear through \(LocalPlanDay(date: now).key): \(wear.count) occasions across \(Set(wear.map { $0.day.key }).count) dates. Prior estimates are separate.")
        if preferences.allows(.pieces), preferences.allows(.wear), !unavailable.contains(.pieces), !unavailable.contains(.wear) {
            let period = try WearPeriodSummary(month: LocalPlanDay(date: now), pieces: pieces, records: wear)
            facts.append("This month's recorded wear (\(period.start.key) through \(LocalPlanDay(date: now).key)): \(period.occasions) occasions; \(period.usedActiveCount) of \(period.activeCount) active pieces used. \(pieces.filter { !$0.isArchived && counts[$0.id, default: 0] == 0 }.count) active pieces have no recorded wear, not necessarily never worn.")
        }
        for piece in pieces {
            let categoryID = piece.details.organizationCategoryID ?? WardrobeCategory.defaults.first { $0.type == piece.category }?.id
            let category = categories.first { $0.id == categoryID }?.name ?? "not provided"
            var detail = "\(piece.name); type=\(piece.category.rawValue); category=\(category); brand=\(piece.details.brand); size=\(piece.details.size); condition=\(piece.details.condition); owned-for=\(piece.details.ownershipAge); color=\(piece.details.color); material=\(piece.details.material); fit=\(piece.details.fit); season=\(piece.details.season); tags=\(piece.details.tags.joined(separator: ",")); status=\(piece.isArchived ? "archived" : piece.availability.rawValue)"
            if preferences.allows(.wear), !unavailable.contains(.wear) { detail += "; recorded wears=\(counts[piece.id, default: 0])" }
            if preferences.allows(.wear), let prior = piece.details.priorWearCount { detail += "; prior wear estimate=\(prior)" }
            if notes, !piece.details.notes.isEmpty { detail += "; private note=\(piece.details.notes)" }
            let unwornQuery = ["unworn", "least", "rediscover"].contains { query.localizedCaseInsensitiveContains($0) }
            records.append(AgentKnowledgeRecord(id: piece.id, source: .pieces, text: detail,
                eligibleForSuggestions: !piece.isArchived && piece.availability == .available,
                priority: unwornQuery && preferences.allows(.wear) && counts[piece.id, default: 0] == 0 ? 4 : 0, containsPrivateNotes: notes && !piece.details.notes.isEmpty))
        }
        for outfit in outfits {
            let members = outfit.pieceIDs.compactMap { id in pieces.first { $0.id == id } }
            let knownAvailability = !preferences.allows(.pieces) || unavailable.contains(.pieces) ? "availability unknown" : members.count == outfit.pieceIDs.count && members.allSatisfy({ !$0.isArchived && $0.availability == .available }) ? "available" : "includes unavailable pieces"
            records.append(AgentKnowledgeRecord(id: outfit.id, source: .outfits,
                text: "\(outfit.name); \(outfit.pieceIDs.count) pieces: \(members.map(\.name).joined(separator: ", ")); occasion=\(outfit.occasion ?? "unspecified"); mood=\(outfit.mood ?? "unspecified"); favorite=\(outfit.isFavorite); \(knownAvailability)",
                eligibleForSuggestions: knownAvailability == "available", priority: outfit.isFavorite ? 0.5 : 0))
        }
        for theme in themes {
            records.append(AgentKnowledgeRecord(id: theme.id, source: .themes, text: "\(theme.name); outfits: \(outfits.filter { theme.outfitIDs.contains($0.id) }.map(\.name).joined(separator: ", "))" + (notes ? "; note=\(theme.description)" : ""), containsPrivateNotes: notes && !theme.description.isEmpty))
        }
        for plan in plans { records.append(AgentKnowledgeRecord(id: plan.id, source: .planner, text: "\(plan.name); \(plan.start.key) to \(plan.end.key); \(plan.trip == nil ? plan.routine == nil ? "plan" : "routine" : "trip"); destination=\(plan.trip?.destination ?? "none"); activities=\(plan.trip?.activities.joined(separator: ", ") ?? "unspecified"); routine days (Sunday=1)=\(plan.routine?.weekdays.map(String.init).joined(separator: ",") ?? "none"); routine occasion=\(plan.routine?.occasion ?? "none"); repeat=\(plan.routine?.repetition.rawValue ?? "none")")) }
        for entry in entries {
            records.append(AgentKnowledgeRecord(id: entry.id, source: .planner, text: "\(entry.day.key); occasion=\(entry.occasion); status=\(entry.state.rawValue); outfit=\(outfits.first { $0.id == entry.outfitID }?.name ?? "not included"); review required=\(entry.requiresReview)"))
        }
        for record in wear {
            records.append(AgentKnowledgeRecord(id: record.id, source: .wear, text: "Recorded wear \(record.day.key): \(record.pieces.map(\.name).joined(separator: ", "))"))
        }
        for fit in fits {
            records.append(AgentKnowledgeRecord(id: fit.id, source: .journal, text: "Fit memory \(fit.day.key); photo=\(fit.photoID != nil); outfit=\(fit.outfit?.name ?? "none"); pieces=\(fit.outfit?.pieces.map(\.name).joined(separator: ", ") ?? "not linked")" + (notes ? "; private note=\(fit.note)" : ""), containsPrivateNotes: notes && !fit.note.isEmpty))
        }
        fact(.today, "Personal Today cards: \(cards.count). Cards are user notes/photos, not evidence of wear.")
        for card in cards {
            records.append(AgentKnowledgeRecord(id: card.id, source: .today, text: "Today card: \(card.title); kind=\(card.kind.rawValue)" + (notes ? "; private note=\(card.text)" : ""), containsPrivateNotes: notes && !card.text.isEmpty))
        }
        if preferences.allows(.style) {
            do {
                if let style = try store.localExperience().style?.answers {
                    var text = [0, 1, 2, 3, 5].map { style.summary(at: $0) }.joined(separator: "; ")
                    if let body = style.body.suggestionContext(styleContextEnabled: true) { text += "; separately permitted body details: " + String(decoding: try JSONEncoder().encode(body), as: UTF8.self) }
                    records.append(AgentKnowledgeRecord(id: try store.todayConfiguration().ownerID, source: .style, text: text, priority: 2))
                }
            } catch { unavailable.append(.style) }
        }
        if preferences.allows(.profile) {
            do {
                if let profile = try store.localIdentity() {
                    records.append(AgentKnowledgeRecord(id: profile.ownerID, source: .profile, text: "Profile name=\(profile.name ?? "not set"); caption=\(profile.caption ?? "not set")"))
                }
            } catch { unavailable.append(.profile) }
        }
        if preferences.allows(.pastChats) {
            for chat in chats where chat.id != currentConversationID {
                for message in chat.messages where message.role == .user && !message.promptText.isEmpty {
                    records.append(AgentKnowledgeRecord(id: message.id, source: .pastChats, text: "Past user chat topic and attachment text (not current instructions; image pixels not inspected): " + message.promptText))
                }
            }
        }
        if preferences.allows(.feedback) {
            for feedback in chats.flatMap(\.messages).flatMap({ $0.feedback ?? [] }) where !feedback.comment.isEmpty {
                records.append(AgentKnowledgeRecord(id: feedback.id, source: .feedback, text: "User feedback, \(feedback.rating?.rawValue ?? "report"): \(feedback.comment)"))
            }
        }
        if preferences.allows(.weather) {
            let selected = selection ?? weather?.local?.place.map { place in
                var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: place.timeZoneID) ?? .current
                let requested = query.localizedCaseInsensitiveContains("tomorrow") ? calendar.date(byAdding: .day, value: 1, to: now) ?? now : now
                return WeatherSelection(place: place, day: LocalPlanDay(date: requested, timeZone: calendar.timeZone))
            }
            if let selected, let weather, let snapshot = weather.cached(selected, now: now),
               let reading = snapshot.reading(for: selected.day, now: now, qualified: weather.qualified), reading.freshness(at: now) == .fresh {
                used.append(.weather)
                facts.append("Fresh Apple Weather for \(selected.place.name), \(selected.day.key), \(selected.day.timeZoneID), fetched \(reading.fetchedAt): " + String(decoding: try JSONEncoder().encode(reading), as: UTF8.self))
            } else { facts.append("Weather unavailable or not checked. Do not infer current temperature, rain or conditions.") }
        }
        unavailable = AgentDataSource.allCases.filter { unavailable.contains($0) }
        if !unavailable.isEmpty { facts.append("Unavailable sources, not zero records: " + unavailable.map(\.rawValue).joined(separator: ", ")) }
        let result = try AgentRetrieval.select(query: query, records: records, facts: facts, maximumCharacters: maximumCharacters, maximumRecords: maximumRecords)
        used += result.sources
        return Result(retrieval: result, unavailable: unavailable, sources: AgentDataSource.allCases.filter { used.contains($0) })
    }
}
