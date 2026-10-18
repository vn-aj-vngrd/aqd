import AQDCore
import Foundation
import UIKit
import Testing
@testable import AQD

/// Synthetic all-domain data shared by archive/restore/erase tests; never the ordinary closet.
@MainActor struct LocalDataFixture {
    let store: PieceStore
    let directory: URL
    let piece: WardrobePiece
    let outfit: Outfit
    let plan: PlanDefinition
    let original: PreparedPhoto
    let processed: PreparedPhoto
    let deletedCard: TodayCardDeletion
    let deletedSecret = "DELETED_PRIVATE_CARD_DO_NOT_EXPORT_7429"
    init() async throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        store = try PieceStore(directory: directory)
        func photo(_ color: UIColor) async throws -> PreparedPhoto {
            let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 32)).image { context in color.setFill(); context.fill(CGRect(x: 0, y: 0, width: 24, height: 32)) }
            return try await PhotoPreparer().prepare(data: #require(image.jpegData(compressionQuality: 0.9)))
        }
        original = try await photo(.blue); processed = try await photo(.white)
        _ = try store.acceptPhoto(original); _ = try store.acceptBackgroundPhoto(processed, originalID: original.id)
        let recipe = PhotoEditRecipe(quarterTurns: 1)
        try store.acceptPhotoEdit(await PhotoPreparer().render(data: processed.originalData, sourcePhotoID: processed.id, recipe: recipe))
        piece = try store.savePiece(PieceDraft(name: "Synthetic shirt", category: .tops, photoID: processed.id, photoRecipe: recipe), operationID: UUID())
        let owner = try store.todayConfiguration().ownerID
        var outfitDraft = OutfitDraft(ownerID: owner); outfitDraft.name = "Synthetic look"; outfitDraft.select(piece.id); try outfitDraft.reviewCurrentPieces([piece])
        try store.saveOutfitDraft(outfitDraft); outfit = try store.saveOutfit(outfitDraft); try store.acknowledgeOutfitReceipt(outfitDraft)
        var theme = ThemeDraft(ownerID: owner); theme.name = "Synthetic theme"; theme.outfitIDs = [outfit.id]
        try store.saveThemeDraft(theme); _ = try store.saveTheme(theme); try store.finishThemeDraft(theme)
        let day = LocalPlanDay(year: 2026, month: 1, day: 1, timeZoneID: "Asia/Manila")
        var trip = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: owner, name: "Synthetic trip", start: day, end: day, trip: TripConfiguration(destination: "Cebu", activities: ["Walk"])))
        trip.slots[0].outfit = outfit; trip.reviewing = true
        try store.savePlanAuthoringDraft(trip); plan = try store.savePlanAuthoring(trip).plan; try store.finishPlanAuthoring(trip)
        _ = try store.setPackingCheck(PackingCheckRequest(planID: plan.id, pieceID: piece.id, checked: true, expectedRevision: 0))
        let wear = OutfitWearDraft(ownerID: owner, outfitID: outfit.id, pieces: [piece], day: day)
        try store.saveWearDraft(wear); _ = try store.saveWear(wear); try store.finishWearDraft(wear)
        var identity = LocalIdentityDraft(ownerID: owner); identity.name = "Synthetic owner"; identity.photoID = original.id
        try store.saveIdentityDraft(identity); _ = try store.saveIdentity(identity); try store.finishIdentityDraft(identity)
        var fit = FitDraft(ownerID: owner); fit.value.photoID = original.id; fit.value.outfit = try FitOutfitSnapshot(outfit: outfit, pieces: [piece]); fit.value.note = "Synthetic fit"; fit.value.day = day
        try store.saveFitDraft(fit); _ = try store.saveFit(fit); try store.finishFitDraft(fit)
        var answers = StylePreferences(); for index in 0..<4 { answers.choose("No preference", at: index) }; answers.body.decline(); answers.colors.declined = true
        var style = StylePreferenceDraft(source: .settings, answers: answers); style.page = 6
        try store.saveStyleDraft(style); _ = try store.saveStylePreferences(style); try store.acknowledgeStyleReceipt(operationID: style.operationID)
        _ = try store.saveLocalSettings(LocalSettingsRequest(base: store.localSettings(), appearance: .dark))
        var conversation = AgentConversation(ownerID: owner); conversation.draft = "Synthetic chat draft"
        _ = try store.saveAgentConversation(conversation, operationID: UUID())
        let note = TodayPersonalCard(ownerID: owner, kind: .personalNote, text: deletedSecret)
        let photoCard = TodayPersonalCard(ownerID: owner, kind: .personalPhoto, title: "Synthetic private card", text: "Caption", photoID: original.id)
        var layout = TodayLayoutDraft(base: try store.todayConfiguration())
        layout.value.instances = [TodayWidgetInstance(kind: .personalNote, options: TodayWidgetOptions(personal: note)), TodayWidgetInstance(kind: .personalPhoto, options: TodayWidgetOptions(personal: photoCard))]
        try store.saveTodayDraft(layout); _ = try store.saveTodayLayout(layout); try store.finishTodayDraft(layout)
        var remove = TodayLayoutDraft(base: try store.todayConfiguration()); remove.value.instances.removeFirst()
        try store.saveTodayDraft(remove); _ = try store.saveTodayLayout(remove); try store.finishTodayDraft(remove)
        deletedCard = try store.reviewTodayCardDeletion(note); try store.deleteTodayCard(deletedCard); try store.finishTodayCardDeletion(deletedCard)
        var undoLayout = TodayLayoutDraft(base: try store.todayConfiguration()); undoLayout.value.instances.append(TodayWidgetInstance(kind: .fitJournal))
        try store.saveTodayDraft(undoLayout); _ = try store.saveTodayLayout(undoLayout); try store.finishTodayDraft(undoLayout)
        var pendingToday = TodayLayoutDraft(base: try store.todayConfiguration()); pendingToday.value.instances.reverse(); try store.saveTodayDraft(pendingToday)
        try store.saveDraft(PieceDraft(name: "Pending capture", category: .tops, photoID: original.id), operationID: UUID())
        var pendingFit = FitDraft(ownerID: owner); pendingFit.value.photoID = original.id; pendingFit.value.note = "Pending fit"; try store.saveFitDraft(pendingFit)
        try store.saveStyleDraft(StylePreferenceDraft(source: .settings, baseRevision: 1, answers: answers))
        var pendingIdentity = LocalIdentityDraft(ownerID: owner, base: try store.localIdentity()); pendingIdentity.name = "Pending identity"; try store.saveIdentityDraft(pendingIdentity)
        var pendingOutfit = OutfitDraft(editing: outfit); pendingOutfit.name = "Pending outfit"; try store.saveOutfitDraft(pendingOutfit)
        var pendingTheme = ThemeDraft(ownerID: owner); pendingTheme.name = "Pending theme"; try store.saveThemeDraft(pendingTheme)
        let place = WeatherPlace(name: "Cebu", latitude: 10.3, longitude: 123.9, timeZoneID: "Asia/Manila")
        let preference = try store.saveWeatherPreference(WeatherPreferenceRequest(operationID: UUID(), base: store.weatherState().preference, enabled: true, place: place))
        let now = Date(), weatherDay = LocalPlanDay(timeZone: TimeZone(identifier: place.timeZoneID)!)
        let reading = WeatherReading(day: weatherDay, symbol: "cloud", condition: "Synthetic unit weather", lowCelsius: 24, highCelsius: 30, precipitationChance: nil, providerDate: now, providerExpiry: now.addingTimeInterval(600), fetchedAt: now)
        let attribution = WeatherAttributionAssets(light: Data([1]), dark: Data([1]), legalURL: URL(string: "https://example.com/unit-fixture")!)
        try store.saveWeatherSnapshot(WeatherSnapshot(place: place, readings: [reading], attribution: attribution), expected: preference, now: now)
    }
}
