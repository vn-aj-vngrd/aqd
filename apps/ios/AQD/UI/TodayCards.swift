import AQDCore
import SwiftUI

struct TodayCard: View {
    let instance: TodayWidgetInstance
    @Environment(AppState.self) private var state
    @State private var weather = false
    private var today: LocalPlanDay { LocalPlanDay() }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(instance.kind.title).font(AppTypography.section)
            content
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityIdentifier("today.widget.\(instance.id.uuidString)")
            .sheet(isPresented: $weather) { if let client = state.weatherClient { WeatherContextView(client: client, persistsPreference: true) { _ in true } } }
    }
    @ViewBuilder private var content: some View {
        switch instance.kind {
        case .todayLook: look
        case .weekInWear: week
        case .closetInUse: utilization
        case .upcomingPlans: upcoming
        case .wearAgain: wearAgain
        case .favoriteOutfits: favorites
        case .theme:
            if let error = state.themeError { failure(error) { state.reloadThemes() } }
            else if let pin = instance.options?.pinnedID, let theme = state.themes.first(where: { $0.id == pin }) {
                Text(theme.name).font(AppTypography.body)
                Text("\(theme.outfitIDs.count) outfits").foregroundStyle(AppTheme.secondary)
                NavigationLink(theme.outfitIDs.isEmpty ? "Add outfits" : "Open theme", value: ClosetRoute.theme(theme.id)).frame(minHeight: 44)
            } else { configure("Choose an available theme to keep its outfits here.") }
        case .fitJournal:
            if let error = state.fitError { failure(error) { state.reloadFits() } }
            else if let memory = instance.options?.pinnedID.map({ pin in state.fitMemories.first { $0.id == pin } }) ?? state.fitMemories.first {
                FitMemoryArtwork(memory: memory).frame(height: 180)
                NavigationLink(memory.day.key) { FitMemoryDetailView(id: memory.id) }.frame(minHeight: 44)
            } else if instance.options?.pinnedID != nil { configure("The selected memory is unavailable.") }
            else {
                Text("Keep a private memory of a fit. This does not record wear.").foregroundStyle(AppTheme.secondary)
                Button("Add fit") { state.openFit() }.frame(minHeight: 44)
            }
        case .quickActions:
            ForEach(instance.options?.actions ?? TodayAction.defaults, id: \.self) { action in
                Button(action.title) { perform(action) }.frame(minHeight: 44)
            }
        case .weatherContext:
            if let client = state.weatherClient, let error = client.error { failure(error) { client.reload() } }
            else { Text(state.weatherClient?.local?.enabled == true ? "Weather · \(state.weatherClient?.local?.place?.name ?? "Place unavailable")" : "Weather is off. Your plans work without it.").foregroundStyle(AppTheme.secondary) }
            Button("Weather setup and details") { weather = true }.frame(minHeight: 44)
        case .personalNote, .personalPhoto:
            if let card = instance.options?.personal {
                if !card.title.isEmpty { Text(card.title).font(AppTypography.section) }
                if card.kind == .personalPhoto { TodayPersonalPhoto(card: card).frame(maxHeight: 260) }
                Text(card.text).lineLimit(4).foregroundStyle(AppTheme.ink)
                NavigationLink("Read more") { TodayPersonalDetail(instance: instance) }.frame(minHeight: 44)
            } else { configure("Choose your own private content.") }
        }
    }
    @ViewBuilder private var look: some View {
        if let error = state.planError { failure(error) { state.reloadPlanEntries() } }
        else if let error = state.outfitError { failure(error) { state.reloadOutfits() } }
        else {
            let entries = state.planEntries.filter { entry in
                if let pin = instance.options?.pinnedID { return entry.id == pin }
                guard let zone = TimeZone(identifier: entry.day.timeZoneID) else { return false }
                return entry.day.key == LocalPlanDay(timeZone: zone).key
            }.sorted { $0.id.uuidString < $1.id.uuidString }
            if entries.isEmpty, instance.options?.pinnedID != nil { configure("The selected plan entry is unavailable. Choose another entry or follow Today.") }
            else if entries.isEmpty {
                Text(state.pieces.isEmpty ? "Start with a photo of a piece you love." : "Choose a look for today. Plans and recorded wear stay separate.").foregroundStyle(AppTheme.secondary)
                PrimaryAction(title: state.pieces.isEmpty ? "Add piece" : "Build outfit") {
                    if state.pieces.isEmpty { state.addPiece() } else { state.buildOutfit() }
                }
                if !state.pieces.isEmpty { Button("Plan a look") { state.openPlan() }.frame(minHeight: 44) }
            }
            ForEach(entries) { entry in
                if let outfit = state.outfits.first(where: { $0.id == entry.outfitID }) {
                    OutfitComposition(pieceIDs: outfit.pieceIDs).frame(height: 150)
                    Text(outfit.name).font(AppTypography.body)
                    Text(entry.occasion.isEmpty ? entry.day.timeZoneID : entry.occasion).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    Text(entry.state == .worn ? "Recorded wear" : entry.state == .skipped ? "Skipped" : "Planned · Not recorded as worn")
                        .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    NavigationLink("View outfit", value: ClosetRoute.outfit(outfit.id)).frame(minHeight: 44)
                    if entry.requiresReview || outfit.revision != entry.outfitRevision {
                        Text("This outfit changed. Review the plan before recording wear.").foregroundStyle(AppTheme.secondary)
                    } else if entry.state == .planned {
                        PrimaryAction(title: "Record wear") { state.openWear(outfitID: outfit.id, day: entry.day, entry: entry) }
                    }
                } else { Text("This occasion has no available outfit.").foregroundStyle(AppTheme.secondary) }
                NavigationLink("Review plan") { LocalPlanEntryView(id: entry.id) }.frame(minHeight: 44)
            }
        }
    }
    @ViewBuilder private var week: some View {
        if let error = state.wearError { failure(error) { state.reloadWear() } }
        else if let bounds = try? TodaySources.week(containing: instance.options?.period ?? today, through: today) {
            let records = state.wearRecords.filter { $0.day.key >= bounds.start.key && $0.day.key <= bounds.end.key }
            if state.wearRecords.isEmpty {
                Text("Your week starts with a recorded look. Plans do not count as wear.").foregroundStyle(AppTheme.secondary)
                Button("Record a look") { state.openWear() }.frame(minHeight: 44)
            } else {
                Text("\(Set(records.map(\.day.key)).count) days · \(Set(records.flatMap { $0.pieces.map(\.id) }).count) pieces")
                if records.isEmpty { Text("No wear recorded in this week yet.").foregroundStyle(AppTheme.secondary) }
                Text("\(bounds.start.key) – \(bounds.end.key)").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                NavigationLink("View this week") { LocalWearHistoryView(periodStart: bounds.start, periodEnd: bounds.end) }.frame(minHeight: 44)
            }
        }
    }
    @ViewBuilder private var utilization: some View {
        if let error = state.wearError ?? state.collectionError { failure(error) { state.reloadWear(); state.reloadPieces() } }
        else if let month = try? (instance.options?.period.map { $0 } ?? (try? TodaySources.completedMonth(before: today))),
                let summary = try? WearPeriodSummary(month: month, pieces: state.pieces, records: state.wearRecords) {
            if let value = summary.utilization {
                Text(value, format: .percent.precision(.fractionLength(0))).font(.largeTitle)
                Text("\(summary.usedActiveCount) of \(summary.activeCount) active pieces recorded").foregroundStyle(AppTheme.secondary)
                ProgressView(value: value).tint(AppTheme.actionText)
            } else { Text("Record wear to see how much of your Closet you use. This completed month has insufficient history.").foregroundStyle(AppTheme.secondary) }
            Text("\(summary.start.key) – \(summary.end.key)").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            NavigationLink("View this month") { LocalWearInsightsView(initialMonth: month) }.frame(minHeight: 44)
        }
    }
    @ViewBuilder private var upcoming: some View {
        if let error = state.planError { failure(error) { state.reloadPlanEntries() } }
        else if let entries = try? TodaySources.upcoming(state.planEntries, days: instance.options?.upcomingDays ?? 7) {
            let visible = instance.options?.pinnedID.map { pin in state.planEntries.filter { $0.planID == pin }.sorted { $0.day.key < $1.day.key } } ?? entries
            if let pin = instance.options?.pinnedID, !state.planDefinitions.contains(where: { $0.id == pin }) { configure("The selected plan is unavailable.") }
            else if visible.isEmpty {
                Text("No upcoming plan entries in this selection.").foregroundStyle(AppTheme.secondary)
                Button("Plan your week") { state.openPlanAuthoring(day: today) }.frame(minHeight: 44)
            }
            ForEach(visible) { entry in
                NavigationLink { LocalPlanEntryView(id: entry.id) } label: { PlanAgendaRow(entry: entry, showDate: true) }.buttonStyle(.plain)
            }
        }
    }
    @ViewBuilder private var wearAgain: some View {
        if let error = state.wearError ?? state.collectionError { failure(error) { state.reloadWear(); state.reloadPieces() } }
        else if let piece = instance.options?.pinnedID.map({ pin in state.pieces.first { $0.id == pin && $0.availability == .available } }) ?? TodaySources.wearAgain(pieces: state.pieces, records: state.wearRecords, through: today) {
            Text(piece.name).font(AppTypography.body)
            if let date = PieceWearSummary(piece: piece, records: state.wearRecords).lastWorn {
                Text("Last recorded \(date.key)").foregroundStyle(AppTheme.secondary)
            } else { Text("No dated wear recorded for this piece.").foregroundStyle(AppTheme.secondary) }
            Button("Build with this piece") { state.buildOutfit(pieceID: piece.id) }.frame(minHeight: 44)
        } else if instance.options?.pinnedID != nil { configure("The selected piece is unavailable.") }
        else {
            Text("No available pieces to suggest.").foregroundStyle(AppTheme.secondary)
            Button("Open Closet") { state.selection = 1 }.frame(minHeight: 44)
        }
    }
    @ViewBuilder private var favorites: some View {
        if let error = state.outfitError { failure(error) { state.reloadOutfits() } }
        else {
            let favorites = state.outfits.filter { outfit in instance.options?.pinnedID.map { outfit.id == $0 } ?? outfit.isFavorite }
            if favorites.isEmpty, instance.options?.pinnedID != nil { configure("The selected outfit is unavailable.") }
            else if favorites.isEmpty {
                Text("Favorite an outfit to keep it close.").foregroundStyle(AppTheme.secondary)
                Button("Open Outfits") { state.closetScope = "Outfits"; state.selection = 1 }.frame(minHeight: 44)
            }
            ForEach(favorites) { outfit in
                NavigationLink(outfit.name, value: ClosetRoute.outfit(outfit.id)).frame(minHeight: 44)
            }
        }
    }
    private func perform(_ action: TodayAction) {
        switch action {
        case .addPiece: state.addPiece()
        case .buildOutfit: state.buildOutfit()
        case .planner: state.selection = 2
        case .recordWear: state.openWear()
        case .addFit: state.openFit()
        case .openCloset: state.selection = 1
        }
    }
    private func configure(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message).foregroundStyle(AppTheme.secondary)
            Button("Configure widget") { state.openTodayEditor(); state.todayEditor?.begin(instance) }.frame(minHeight: 44)
        }
    }
    private func failure(_ message: String, retry: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SemanticFeedback(role: .danger, message: message)
            Button("Retry", action: retry).frame(minHeight: 44)
        }
    }
}

private struct TodayPersonalDetail: View {
    let instance: TodayWidgetInstance
    @Environment(AppState.self) private var state
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let card = instance.options?.personal {
                    if !card.title.isEmpty { Text(card.title).font(AppTypography.section) }
                    if card.kind == .personalPhoto { TodayPersonalPhoto(card: card).frame(minHeight: 200) }
                    Text(card.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                    SecondaryAction(title: "Edit card") { state.openTodayEditor(); state.todayEditor?.begin(instance) }
                    Text("Private on this iPhone").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle(instance.kind.title).navigationBarTitleDisplayMode(.inline)
    }
}
