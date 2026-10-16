import AQDCore
import SwiftUI

struct TodayCard: View {
    let instance: TodayWidgetInstance
    @Environment(AppState.self) private var state
    private var today: LocalPlanDay { LocalPlanDay() }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                Text(instance.kind.title)
                    .font(instance.kind == .todayLook || instance.kind == .personalPhoto || instance.kind == .fitJournal ? .title2.weight(.semibold) : AppTypography.detailTitle)
                    .foregroundStyle(AppTheme.ink)
            }
            content.font(AppTypography.supporting).buttonStyle(.plain)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityIdentifier("today.widget.\(instance.id.uuidString)")
    }
    private var eyebrow: String {
        switch instance.kind {
        case .todayLook: "For today"
        case .weekInWear: "This week"
        case .closetInUse: "Your wardrobe"
        case .upcomingPlans: "Coming up"
        case .wearAgain: "Rediscover"
        case .favoriteOutfits: "Your favorites"
        case .theme: "Your collection"
        case .fitJournal: "Your memories"
        case .weatherContext: "Before you head out"
        case .quickActions: "Make it yours"
        case .personalNote: "A note for you"
        case .personalPhoto: "Your inspiration"
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
                Text(theme.displayName).font(AppTypography.body)
                Text("\(theme.outfitIDs.count) outfits").foregroundStyle(AppTheme.secondary)
                NavigationLink(value: ClosetRoute.theme(theme.id)) { TodayCardActionLabel(title: theme.outfitIDs.isEmpty ? "Add outfits" : "Open theme") }.frame(minHeight: 44)
            } else { configure("Choose an available theme to keep its outfits here.") }
        case .fitJournal:
            if let error = state.fitError { failure(error) { state.reloadFits() } }
            else if let memory = instance.options?.pinnedID.map({ pin in state.fitMemories.first { $0.id == pin } }) ?? state.fitMemories.first {
                if memory.photoID != nil {
                    FitMemoryArtwork(memory: memory).frame(height: 180).clipped()
                } else if let outfit = memory.outfit {
                    CollectionArtwork(pieceIDs: outfit.pieces.map(\.id))
                }
                NavigationLink { FitMemoryDetailView(id: memory.id) } label: { TodayCardActionLabel(title: memory.day.key) }.frame(minHeight: 44)
            } else if instance.options?.pinnedID != nil { configure("The selected memory is unavailable.") }
            else {
                Text("Keep a private memory of a fit. This does not record wear.").foregroundStyle(AppTheme.secondary)
                Button { state.openFit() } label: { TodayCardActionLabel(title: "Add fit") }.frame(minHeight: 44)
            }
        case .quickActions:
            ForEach(instance.options?.actions ?? TodayAction.defaults, id: \.self) { action in
                Button { perform(action) } label: { TodayCardActionLabel(title: action.title) }.frame(minHeight: 44)
            }
        case .weatherContext:
            TodayWeatherSummary()
        case .personalNote, .personalPhoto:
            if let card = instance.options?.personal {
                if !card.title.isEmpty { Text(card.title).font(AppTypography.section) }
                if card.kind == .personalPhoto { TodayPersonalPhoto(card: card).frame(maxHeight: 260) }
                Text(card.text).lineLimit(4).foregroundStyle(AppTheme.ink)
                NavigationLink { TodayPersonalDetail(instanceID: instance.id) } label: { TodayCardActionLabel(title: "Read more") }.frame(minHeight: 44)
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
                if !state.pieces.isEmpty {
                    Text("From your closet").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    closetPreview
                }
                Text(state.pieces.isEmpty ? "Start with a photo of a piece you love." : "Choose a look for today. Plans and recorded wear stay separate.").foregroundStyle(AppTheme.secondary)
                Button {
                    if state.pieces.isEmpty { state.addPiece() } else { state.buildOutfit() }
                } label: { TodayCardActionLabel(title: state.pieces.isEmpty ? "Add piece" : "Build outfit") }
                if !state.pieces.isEmpty { Button { state.openPlan() } label: { TodayCardActionLabel(title: "Plan a look") }.frame(minHeight: 44) }
            }
            ForEach(entries) { entry in
                if let outfit = state.outfits.first(where: { $0.id == entry.outfitID }) {
                    OutfitComposition(pieceIDs: outfit.pieceIDs, pieceHeight: 160, limit: 4)
                    Text(outfit.displayName).font(AppTypography.body)
                    Text(entry.occasion.isEmpty ? entry.day.timeZoneID : entry.occasion).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    Text(entry.state == .worn ? "Recorded wear" : entry.state == .skipped ? "Skipped" : "Planned · Not recorded as worn")
                        .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    NavigationLink(value: ClosetRoute.outfit(outfit.id)) { TodayCardActionLabel(title: "View outfit") }.frame(minHeight: 44)
                    if entry.requiresReview || outfit.revision != entry.outfitRevision {
                        Text("This outfit changed. Review the plan before recording wear.").foregroundStyle(AppTheme.secondary)
                    } else if entry.state == .planned {
                        Button { state.openWear(outfitID: outfit.id, day: entry.day, entry: entry) } label: { TodayCardActionLabel(title: "Record wear") }
                    }
                } else { Text("This occasion has no available outfit.").foregroundStyle(AppTheme.secondary) }
                NavigationLink { LocalPlanEntryView(id: entry.id) } label: { TodayCardActionLabel(title: "Review plan") }.frame(minHeight: 44)
            }
        }
    }
    @ViewBuilder private var week: some View {
        if let error = state.wearError { failure(error) { state.reloadWear() } }
        else if let bounds = try? TodaySources.week(containing: instance.options?.period ?? today, through: today) {
            let records = state.wearRecords.filter { $0.day.key >= bounds.start.key && $0.day.key <= bounds.end.key }
            weekTimeline(start: bounds.start, records: records)
            if state.wearRecords.isEmpty {
                Text("Record a look to start your week. Plans stay separate from wear.").foregroundStyle(AppTheme.secondary)
                Button { state.openWear() } label: { TodayCardActionLabel(title: "Record a look") }.frame(minHeight: 44)
            } else {
                Text("\(Set(records.map(\.day.key)).count) days · \(Set(records.flatMap { $0.pieces.map(\.id) }).count) pieces")
                if records.isEmpty { Text("No wear recorded in this week yet.").foregroundStyle(AppTheme.secondary) }
                Text("\(bounds.start.displayDate) – \(bounds.end.displayDate)").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                NavigationLink { LocalWearHistoryView(periodStart: bounds.start, periodEnd: bounds.end) } label: { TodayCardActionLabel(title: "View this week") }.frame(minHeight: 44)
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
                ProgressView(value: value).tint(AppTheme.ink)
            } else { Text("Your wear story starts here. Record your looks to discover which pieces you reach for.").foregroundStyle(AppTheme.secondary) }
            Text("\(summary.start.displayDate) – \(summary.end.displayDate)").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            NavigationLink { LocalWearInsightsView(initialMonth: month) } label: { TodayCardActionLabel(title: "View this month") }.frame(minHeight: 44)
        }
    }
    @ViewBuilder private var upcoming: some View {
        if let error = state.planError { failure(error) { state.reloadPlanEntries() } }
        else if let entries = try? TodaySources.upcoming(state.planEntries, days: instance.options?.upcomingDays ?? 7, planID: instance.options?.pinnedID) {
            let visible = entries
            if let pin = instance.options?.pinnedID, !state.planDefinitions.contains(where: { $0.id == pin }) { configure("The selected plan is unavailable.") }
            else if visible.isEmpty {
                Text("No upcoming plan entries in this selection.").foregroundStyle(AppTheme.secondary)
                Button { state.openPlanAuthoring(day: today) } label: { TodayCardActionLabel(title: "Plan your week") }.frame(minHeight: 44)
            }
            ForEach(visible) { entry in
                NavigationLink { LocalPlanEntryView(id: entry.id) } label: { PlanAgendaRow(entry: entry, showDate: true) }.buttonStyle(.plain)
            }
        }
    }
    @ViewBuilder private var wearAgain: some View {
        if let error = state.wearError ?? state.pieceReadError { failure(error) { state.reloadWear(); state.reloadPieces() } }
        else if let piece = instance.options?.pinnedID.map({ pin in state.pieces.first { $0.id == pin && $0.availability == .available } }) ?? TodaySources.wearAgain(pieces: state.pieces, records: state.wearRecords, through: today) {
            NavigationLink(value: ClosetRoute.piece(piece.id)) {
                PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                    .frame(maxWidth: .infinity).frame(height: 220)
                    .accessibilityLabel("View \(piece.displayName)")
            }.buttonStyle(.plain)
            Text(piece.displayName).font(AppTypography.body)
            if let date = PieceWearSummary(piece: piece, records: state.wearRecords).lastWorn {
                Text("Last recorded \(date.key)").foregroundStyle(AppTheme.secondary)
            } else { Text("No dated wear recorded for this piece.").foregroundStyle(AppTheme.secondary) }
            Button { state.buildOutfit(pieceID: piece.id) } label: { TodayCardActionLabel(title: "Build with this piece") }.frame(minHeight: 44)
        } else if instance.options?.pinnedID != nil { configure("The selected piece is unavailable.") }
        else {
            Text("No available pieces to suggest.").foregroundStyle(AppTheme.secondary)
            Button { state.selection = 1 } label: { TodayCardActionLabel(title: "Open Closet") }.frame(minHeight: 44)
        }
    }
    @ViewBuilder private var favorites: some View {
        if let error = state.outfitError { failure(error) { state.reloadOutfits() } }
        else {
            let favorites = state.outfits.filter { outfit in instance.options?.pinnedID.map { outfit.id == $0 } ?? outfit.isFavorite }
            if favorites.isEmpty, instance.options?.pinnedID != nil { configure("The selected outfit is unavailable.") }
            else if favorites.isEmpty {
                Text("Favorite an outfit to keep it close.").foregroundStyle(AppTheme.secondary)
                Button { state.closetScope = "Outfits"; state.selection = 1 } label: { TodayCardActionLabel(title: "Open Outfits") }.frame(minHeight: 44)
            }
            ForEach(favorites) { outfit in
                NavigationLink(value: ClosetRoute.outfit(outfit.id)) {
                    HStack(spacing: 12) {
                        if let piece = state.pieces.first(where: { outfit.pieceIDs.contains($0.id) }) {
                            PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                                .frame(width: 56, height: 72).accessibilityHidden(true)
                        }
                        TodayCardActionLabel(title: outfit.displayName)
                    }
                }.frame(minHeight: 44)
            }
        }
    }
    private var closetPreview: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(Array(state.pieces.prefix(3))) { piece in
                NavigationLink(value: ClosetRoute.piece(piece.id)) {
                    VStack(alignment: .leading, spacing: 6) {
                        PieceThumbnail(photoID: piece.photoID, recipe: piece.photoRecipe)
                            .frame(maxWidth: .infinity).frame(height: 156)
                        Text(piece.displayName).font(AppTypography.metadata).foregroundStyle(AppTheme.ink).lineLimit(2)
                    }
                }.buttonStyle(.plain)
            }
        }
    }

    private func weekTimeline(start: LocalPlanDay, records: [OutfitWearRecord]) -> some View {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: start.timeZoneID) ?? .current
        let days = (0..<7).compactMap { offset in
            (try? start.date()).flatMap { calendar.date(byAdding: .day, value: offset, to: $0) }
        }
        let recorded = Set(records.map(\.day.key))
        return HStack(spacing: 4) {
            ForEach(days, id: \.self) { date in
                let day = LocalPlanDay(date: date, timeZone: calendar.timeZone)
                let hasWear = recorded.contains(day.key)
                VStack(spacing: 8) {
                    Text(date, format: Date.FormatStyle(timeZone: calendar.timeZone).weekday(.narrow))
                        .font(AppTypography.metadata)
                    Text(date, format: Date.FormatStyle(timeZone: calendar.timeZone).day())
                        .font(AppTypography.supporting.weight(hasWear ? .semibold : .regular))
                    Circle().fill(hasWear ? AppTheme.ink : AppTheme.divider).frame(width: 5, height: 5)
                }
                .foregroundStyle(hasWear ? AppTheme.ink : AppTheme.secondary)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.displayDate), \(hasWear ? "wear recorded" : "no wear recorded")")
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
            Button { state.openTodayEditor(); state.todayEditor?.begin(instance)            } label: { TodayCardActionLabel(title: "Configure widget") }.frame(minHeight: 44)
        }
    }
    private func failure(_ message: String, retry: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SemanticFeedback(role: .danger, message: message)
            Button(action: retry) { TodayCardActionLabel(title: "Retry") }
        }
    }
}

private struct TodayPersonalDetail: View {
    let instanceID: UUID
    @Environment(AppState.self) private var state
    private var instance: TodayWidgetInstance? { state.today?.instances.first { $0.id == instanceID } }
    var body: some View {
        Group {
            if instance?.options?.personal == nil {
                EmptyStatePage(title: "This card is no longer on Today", systemImage: "square.stack",
                               description: Text("Saved notes and photos remain available from the widget library.")) {
                    PrimaryAction(title: "Customize Today") { state.openTodayEditor() }
                }
            } else {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let instance, let card = instance.options?.personal {
                    if !card.title.isEmpty { Text(card.title).font(AppTypography.section) }
                    if card.kind == .personalPhoto { TodayPersonalPhoto(card: card).frame(minHeight: 200) }
                    Text(card.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                    SecondaryAction(title: "Edit card") { state.openTodayEditor(); state.todayEditor?.begin(instance) }
                    Text("Private on this iPhone").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }
            }.padding(20)
        }
            }
        }.background(AppTheme.canvas).navigationTitle(instance?.kind.title ?? "Saved card").navigationBarTitleDisplayMode(.inline)
    }
}

/// A setup/details notice, separate from the configurable weather widget.
struct TodayWeatherNotice: View {
    @Environment(AppState.self) private var state
    @State private var setup = false
    var body: some View {
        if let client = state.weatherClient {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack(spacing: 0) {
                    Button { setup = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "cloud.sun").font(.system(size: 20)).foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                            Text(client.error != nil ? "Review weather settings" : "Set up optional weather")
                                .font(AppTypography.supporting).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.forward").font(AppTypography.disclosure).accessibilityHidden(true)
                        }.foregroundStyle(AppTheme.ink).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .padding(.leading, 14).padding(.vertical, 8).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityHint("Apple Weather preferences. Your wardrobe stays private.")
                    Menu {
                        AccessoryButton("Hide until next launch", systemImage: "clock") { client.hideSetupNotice(permanently: false) }
                        AccessoryButton("Don’t show again", systemImage: "eye.slash") { client.hideSetupNotice(permanently: true) }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 13)).foregroundStyle(AppTheme.controlIcon)
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    }.tint(AppTheme.ink).accessibilityLabel("Dismiss weather reminder")
                }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
                if let error = client.setupNoticeError { SemanticFeedback(role: .danger, message: error) }
            }.sheet(isPresented: $setup) {
                WeatherContextView(client: client, persistsPreference: true) { _ in true }
            }
        }
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
                    Button { client.reload() } label: { TodayCardActionLabel(title: "Retry weather preferences") }.frame(minHeight: 44)
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
                            Link(destination: attribution.legalURL) { TodayCardActionLabel(title: "Data sources") }
                        } else {
                            Text(client.qualified ? "Open weather to refresh conditions for today." : "Live weather isn’t available in this build. Your saved city is retained.")
                                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                    }
                } else {
                    Text("Choose a city for optional Apple Weather.")
                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                }
                Button { setup = true } label: {
                    TodayCardActionLabel(title: client.local?.enabled == true ? "Weather details" : "Set up weather")
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

/// Consistent compact action rows retain their actual Button/NavigationLink owner.
private struct TodayCardActionLabel: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Text(title).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 12)
            Image(systemName: "chevron.forward").font(AppTypography.disclosure).accessibilityHidden(true)
        }
        .font(AppTypography.supporting)
        .foregroundStyle(AppTheme.ink)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
    }
}
