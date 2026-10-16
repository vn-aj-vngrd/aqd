import AQDCore
import SwiftUI

struct TodayCard: View {
    let instance: TodayWidgetInstance
    @Environment(AppState.self) private var state
    private var today: LocalPlanDay { LocalPlanDay() }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(instance.kind.title, systemImage: symbol)
                .font(AppTypography.detailTitle).foregroundStyle(AppTheme.ink)
            content.font(AppTypography.supporting)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityIdentifier("today.widget.\(instance.id.uuidString)")
    }
    private var symbol: String {
        switch instance.kind {
        case .todayLook: "tshirt"
        case .weekInWear: "calendar"
        case .closetInUse: "chart.bar"
        case .upcomingPlans: "calendar.badge.clock"
        case .wearAgain: "arrow.clockwise"
        case .favoriteOutfits: "heart"
        case .theme: "folder"
        case .fitJournal: "photo.stack"
        case .weatherContext: "cloud"
        case .quickActions: "bolt"
        case .personalNote: "note.text"
        case .personalPhoto: "photo"
        }
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
            TodayWeatherSummary()
        case .personalNote, .personalPhoto:
            if let card = instance.options?.personal {
                if !card.title.isEmpty { Text(card.title).font(AppTypography.section) }
                if card.kind == .personalPhoto { TodayPersonalPhoto(card: card).frame(maxHeight: 260) }
                Text(card.text).lineLimit(4).foregroundStyle(AppTheme.ink)
                NavigationLink("Read more") { TodayPersonalDetail(instanceID: instance.id) }.frame(minHeight: 44)
            } else { configure("Choose your own private content.") }
        }
    }
    @ViewBuilder private var look: some View {
        if let error = state.planError { failure(error) { state.reloadPlanEntries() } }
        else if let error = state.outfitError { failure(error) { state.reloadOutfits() } }
        else if let error = state.pieceReadError { failure(error) { state.reloadPieces() } }
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
                Text("Record a look to start your week. Plans stay separate from wear.").foregroundStyle(AppTheme.secondary)
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
        if let error = state.wearError ?? state.pieceReadError { failure(error) { state.reloadWear(); state.reloadPieces() } }
        else if let month = try? (instance.options?.period.map { $0 } ?? (try? TodaySources.completedMonth(before: today))),
                let summary = try? WearPeriodSummary(month: month, pieces: state.pieces, records: state.wearRecords) {
            if let value = summary.utilization {
                Text(value, format: .percent.precision(.fractionLength(0))).font(.largeTitle)
                Text("\(summary.usedActiveCount) of \(summary.activeCount) active pieces recorded").foregroundStyle(AppTheme.secondary)
                ProgressView(value: value).tint(AppTheme.actionText)
            } else { Text("Your wear story starts here. Record your looks to discover which pieces you reach for.").foregroundStyle(AppTheme.secondary) }
            Text("\(summary.start.key) – \(summary.end.key)").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            NavigationLink("View this month") { LocalWearInsightsView(initialMonth: month) }.frame(minHeight: 44)
        }
    }
    @ViewBuilder private var upcoming: some View {
        if let error = state.planError { failure(error) { state.reloadPlanEntries() } }
        else if let entries = try? TodaySources.upcoming(state.planEntries, days: instance.options?.upcomingDays ?? 7, planID: instance.options?.pinnedID) {
            let visible = entries
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
        if let error = state.wearError ?? state.pieceReadError { failure(error) { state.reloadWear(); state.reloadPieces() } }
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
    let instanceID: UUID
    @Environment(AppState.self) private var state
    private var instance: TodayWidgetInstance? { state.today?.instances.first { $0.id == instanceID } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let instance, let card = instance.options?.personal {
                    if !card.title.isEmpty { Text(card.title).font(AppTypography.section) }
                    if card.kind == .personalPhoto { TodayPersonalPhoto(card: card).frame(minHeight: 200) }
                    Text(card.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                    SecondaryAction(title: "Edit card") { state.openTodayEditor(); state.todayEditor?.begin(instance) }
                    Text("Private on this iPhone").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                } else {
                    AppEmptyState("This card is no longer on Today", systemImage: "square.stack", description: Text("Saved notes and photos remain available from the widget library."))
                    SecondaryAction(title: "Customize Today") { state.openTodayEditor() }
                }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle(instance?.kind.title ?? "Saved card").navigationBarTitleDisplayMode(.inline)
    }
}

/// Discoverable Weather setup and matching, attributed saved readings. The shared
/// client still owns consent, qualification, freshness and all network requests.
struct TodayWeatherSummary: View {
    @Environment(AppState.self) private var state
    @Environment(\.colorScheme) private var colorScheme
    @State private var setup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let client = state.weatherClient {
                if let error = client.error {
                    SemanticFeedback(role: .warning, message: error)
                    Button("Retry weather preferences") { client.reload() }.frame(minHeight: 44)
                } else if client.local?.enabled == true, let place = client.local?.place {
                    Text(place.name).font(AppTypography.body)
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        let day = LocalPlanDay(date: context.date, timeZone: TimeZone(identifier: place.timeZoneID) ?? .current)
                        let selection = WeatherSelection(place: place, day: day)
                        if let snapshot = client.cached(selection, now: context.date),
                           let reading = snapshot.reading(for: day, now: context.date, qualified: client.qualified),
                           let attribution = snapshot.attribution,
                           let mark = UIImage(data: colorScheme == .dark ? attribution.dark : attribution.light) {
                            WeatherReadingView(reading: reading, now: context.date)
                            Image(uiImage: mark).resizable().scaledToFit().frame(maxWidth: 160, maxHeight: 36)
                                .accessibilityLabel("Apple Weather")
                            Link("Data sources", destination: attribution.legalURL).frame(minHeight: 44)
                        } else {
                            Text(client.qualified ? "Open weather to refresh conditions for today." : "Live weather isn’t available in this build. Your saved city is retained.")
                                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                    }
                } else {
                    Text("A little context for what to wear.").font(AppTypography.body)
                    Text("Choose a city for optional Apple Weather. Your wardrobe stays private.")
                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    if !client.qualified {
                        Text("Live readings aren’t enabled in this build yet.")
                            .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    }
                }
                Button { setup = true } label: {
                    HStack {
                        Text(client.local?.enabled == true ? "Weather details" : "Set up weather")
                        Spacer()
                        Image(systemName: "chevron.forward").accessibilityHidden(true)
                    }.frame(minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).foregroundStyle(AppTheme.ink)
            } else {
                Text("Weather preferences are unavailable. Your plans still work without weather.")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }
        }
        .sheet(isPresented: $setup) {
            if let client = state.weatherClient {
                WeatherContextView(client: client, persistsPreference: true) { _ in true }
            }
        }
    }
}
