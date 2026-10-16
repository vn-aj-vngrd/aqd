import AQDCore
import Foundation
import Observation

@MainActor @Observable
final class ThemeEditorModel: Identifiable {
    nonisolated let id: UUID
    let store: PieceStore
    var draft: ThemeDraft
    var saved: OutfitTheme?
    var error: String?
    var pending = false
    var unknown = false
    var startsWithOutfits = false
    var notice: String?

    init(store: PieceStore, draft: ThemeDraft) throws {
        self.store = store; self.draft = draft; id = draft.id
        saved = try store.savedTheme(for: draft)
    }

    var hasUnsavedChanges: Bool {
        if saved != nil { return false }
        if pending || unknown || error != nil { return true }
        if draft.baseRevision == 0 {
            return !draft.name.isEmpty || !draft.description.isEmpty || !draft.outfitIDs.isEmpty
        }
        guard let themes = try? store.themes(), let base = themes.first(where: { $0.id == draft.themeID }),
              base.revision == draft.baseRevision else { return true }
        return draft.name != base.name || draft.description != base.description || Set(draft.outfitIDs) != Set(base.outfitIDs)
    }

    var canSave: Bool {
        guard !pending, !unknown, saved == nil,
              let themes = try? store.themes(), let outfits = try? store.outfits() else { return false }
        return (try? draft.validatedForSave(themes: themes, outfits: outfits)) != nil
    }

    func update(_ change: (inout ThemeDraft) -> Void) {
        guard !pending, !unknown, saved == nil else { return }
        var changed = draft; change(&changed); draft = changed
        do { try store.saveThemeDraft(draft); error = nil }
        catch { self.error = "These edits couldn’t be retained. Keep this screen open and retry. Your saved theme hasn’t changed." }
    }

    func save() async {
        guard !pending, saved == nil else { return }
        pending = true
        defer { pending = false }
        await Task.yield()
        do {
            if !unknown { try store.saveThemeDraft(draft) }
            saved = try store.saveTheme(draft); unknown = false; error = nil
        } catch {
            do {
                saved = try store.savedTheme(for: draft)
                unknown = false
                self.error = saved == nil ? "The theme wasn’t saved. Use a unique name of up to 40 characters and current outfits, then retry." : nil
            } catch { unknown = true; self.error = "The result is unknown. Check this same save before making further changes." }
        }
    }

    func finish(discarding: Bool = false) -> Bool {
        guard !pending, !unknown else { return false }
        do { try store.finishThemeDraft(draft, discarding: discarding); return true }
        catch { self.error = "This task couldn’t be closed. Your data is retained; retry."; return false }
    }
}
