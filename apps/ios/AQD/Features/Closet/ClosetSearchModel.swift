import AQDCore
import Foundation
import Observation

struct ClosetSearchInput: Hashable {
    let query: String
    let scope: ClosetSearchScope
    var favoritesOnly = false
    var themeID: UUID?
    var themeQuery = ThemeCollectionQuery()
}

@MainActor @Observable
final class ClosetSearchModel {
    let store: PieceStore
    var input: ClosetSearchInput?
    var results: ClosetSearchResults?
    var error: String?
    var loading = false
    var closetEmpty = false
    private var requestID = UUID()
    private var cache: [ClosetSearchScope: (input: ClosetSearchInput, results: ClosetSearchResults)] = [:]

    init(store: PieceStore) { self.store = store }

    func search(_ input: ClosetSearchInput, debounce: Bool = true) async {
        let request = UUID(); requestID = request; self.input = input; error = nil
        if input.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            results = nil; loading = false
            do { closetEmpty = try store.closetIsEmpty() }
            catch { self.error = "Your closet couldn’t be read. Its data is retained; retry." }
            return
        }
        results = cache[input.scope].flatMap { $0.input == input ? $0.results : nil }
        loading = true
        defer { if requestID == request { loading = false } }
        do {
            if debounce { try await Task.sleep(for: .milliseconds(150)) }
            try Task.checkCancellation()
            guard requestID == request else { return }
            var value = try store.searchCloset(query: input.query, scope: input.scope,
                favoritesOnly: input.favoritesOnly, themeID: input.themeID)
            if case .themes(let themes) = value { value = .themes(input.themeQuery.apply(to: themes)) }
            try Task.checkCancellation()
            guard requestID == request else { return }
            cache[input.scope] = (input, value); results = value
        } catch is CancellationError { }
        catch {
            guard requestID == request else { return }
            self.error = results == nil ? "Search couldn’t finish. Your records are retained; retry." : "These results couldn’t refresh. Showing the previous results for this query; retry."
        }
    }
    func clearCache() { requestID = UUID(); input = nil; cache = [:]; results = nil; error = nil; loading = false }
}
