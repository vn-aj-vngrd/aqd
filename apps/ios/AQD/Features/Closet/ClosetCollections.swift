import AQDCore
import Foundation

extension AppState {
    func reloadThemes() {
        do { themes = try store?.themes() ?? []; themeError = nil }
        catch { themeError = "Your themes couldn’t be read. Existing data is retained; retry." }
    }
    func openTheme(editing theme: OutfitTheme? = nil, chooseOutfits: Bool = false) {
        guard todayEditor == nil, planAuthoringEditor == nil, themeEditor == nil, outfitEditor == nil, planEditor == nil, wearEditor == nil, capture == nil, styleEditor == nil else { return }
        do {
            guard let store else { throw PieceStore.StoreError.corruptStore }
            let retained = try store.themeDraft()
            let draft: ThemeDraft
            if let retained { draft = retained }
            else if let theme { draft = ThemeDraft(editing: theme) }
            else { draft = ThemeDraft(ownerID: try store.todayConfiguration().ownerID) }
            if retained == nil { try store.saveThemeDraft(draft) }
            let model = try ThemeEditorModel(store: store, draft: draft)
            model.startsWithOutfits = chooseOutfits && theme?.id == draft.themeID
            if retained != nil { model.notice = "Your unfinished theme is retained. Finish or discard it before starting another." }
            themeEditor = model
        } catch { collectionError = "A theme draft couldn’t open. Your existing themes and outfits haven’t changed." }
    }
    func resumeThemeDraft() {
        guard todayEditor == nil, planAuthoringEditor == nil, themeEditor == nil, outfitEditor == nil, planEditor == nil, wearEditor == nil, styleEditor == nil, capture == nil, entry.page == .main else { return }
        do {
            guard let store, let draft = try store.themeDraft() else { return }
            themeEditor = try ThemeEditorModel(store: store, draft: draft)
        } catch { themeError = "Your theme draft couldn’t be read. Keep the app data for recovery." }
    }
    func openClosetDestination(scope: String = "Pieces", route: ClosetRoute? = nil) {
        closetSearchRestoresSource = false
        closetSearchActive = false; closetSearchQuery = ""
        selection = 1; closetScope = scope; closetPath = route.map { [$0] } ?? []
    }
}
