import AQDCore
import SwiftUI

struct TodayCard: View {
    let instance: TodayWidgetInstance
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    private var today: LocalPlanDay { LocalPlanDay() }
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                if let eyebrow = header.eyebrow {
                    Text(eyebrow).font(AppTypography.metadata.weight(.semibold)).tracking(0.5).textCase(.uppercase)
                        .foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
                }
                Text(header.title).font(AppTypography.section).foregroundStyle(AppTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel(header.eyebrow.map { "\(header.title), \($0)" } ?? header.title)
            }
            content.font(AppTypography.supporting).buttonStyle(.plain)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(AppSpacing.screen)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.field))
            .accessibilityIdentifier("today.widget.\(instance.id.uuidString)")
    }

    /// Plan entries Today's look follows: today's, or the pinned one.
    private var lookEntries: [OutfitPlanEntry] {
        state.planEntries.filter { entry in
            if let pin = instance.options?.pinnedID { return entry.id == pin }
            guard let zone = TimeZone(identifier: entry.day.timeZoneID) else { return false }
            return entry.day.key == LocalPlanDay(timeZone: zone).key
        }.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    /// Label, title and the eyebrow's context, decided per kind by `TodayPresentation.header`.
    private var header: TodayPresentation.Header {
        var own: String?
        var context: String?
        switch instance.kind {
        case .personalNote, .personalPhoto: own = instance.options?.personal?.title
        case .theme: own = instance.options?.pinnedID.flatMap { pin in state.themes.first { $0.id == pin }?.displayName }
        case .weatherContext: own = state.weatherClient?.local?.enabled == true ? state.weatherClient?.local?.place?.name : nil
        case .todayLook:
            if let entry = lookEntries.first { own = state.outfits.first { $0.id == entry.outfitID }?.displayName }
        case .wearAgain:
            own = instance.options?.pinnedID.map { pin in state.pieces.first { $0.id == pin }?.displayName }
                ?? TodaySources.wearAgain(pieces: state.pieces, records: state.wearRecords, through: today)?.displayName
        case .weekInWear:
            if let bounds = try? TodaySources.week(containing: instance.options?.period ?? today, through: today), let first = try? bounds.start.date() {
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: bounds.start.timeZoneID) ?? .current
                if let last = calendar.date(byAdding: .day, value: 6, to: first) {
                    context = LocalPlanDay.displayRange(bounds.start, LocalPlanDay(date: last, timeZone: calendar.timeZone))
                }
            }
        case .closetInUse:
            if let month = try? (instance.options?.period ?? TodaySources.completedMonth(before: today)), let date = try? month.date() {
                context = date.formatted(Date.FormatStyle(timeZone: TimeZone(identifier: month.timeZoneID) ?? .current).month(.wide).year())
            }
        case .upcomingPlans:
            context = instance.options?.pinnedID != nil ? nil : "Next \(instance.options?.upcomingDays ?? 7) days"
        default: break
        }
        return TodayPresentation.header(kind: instance.kind.title, contentTitle: own, context: context,
                                        personal: instance.kind == .personalNote || instance.kind == .personalPhoto)
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
                NavigationLink { FitMemoryDetailView(id: memory.id).secondaryPage() } label: { TodayCardActionLabel(title: memory.day.display(.relative)) }.frame(minHeight: 44)
            } else if instance.options?.pinnedID != nil { configure("The selected memory is unavailable.") }
            else {
                Text("Keep a private memory of a fit. This does not record wear.").foregroundStyle(AppTheme.secondary)
                Button { state.openFit() } label: { TodayCardActionLabel(title: "Add fit") }.frame(minHeight: 44)
            }
        case .quickActions:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.small), count: typeSize.isAccessibilitySize ? 1 : 2),
                          alignment: .leading, spacing: AppSpacing.small) {
                ForEach(instance.options?.actions ?? TodayAction.defaults, id: \.self) { action in
                    Button { perform(action) } label: {
                        Label(action.title, systemImage: Self.symbol(for: action)).minimumScaleFactor(0.85).compactControl(fullWidth: true)
                    }.accessibilityIdentifier("today.action.\(action.title)")
                }
            }
        case .weatherContext:
            TodayWeatherSummary(showsPlace: false)
        case .personalNote, .personalPhoto:
            if let card = instance.options?.personal {
                NavigationLink { TodayPersonalDetail(instanceID: instance.id) } label: {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        if card.kind == .personalPhoto { TodayPersonalPhoto(card: card, fillsWidth: true) }
                        if !card.text.isEmpty { TodayCaption(text: card.text) }
                    }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityHint("Opens the full card")
            } else { configure("Choose your own private content.") }
        }
    }
    @ViewBuilder private var look: some View {
        if let error = state.planError { failure(error) { state.reloadPlanEntries() } }
        else if let error = state.outfitError { failure(error) { state.reloadOutfits() } }
        else if let error = state.pieceReadError { failure(error) { state.reloadPieces() } }
        else {
            let entries = lookEntries
            if entries.isEmpty, instance.options?.pinnedID != nil { configure("The selected plan entry is unavailable. Choose another entry or follow Today.") }
            else if entries.isEmpty {
                let look = TodayPresentation.look(entry: nil, outfitRevision: nil, hasPieces: !state.pieces.isEmpty)
                if !state.pieces.isEmpty { closetPreview }
                Text(look.status).foregroundStyle(AppTheme.secondary)
                lookActions(look, entry: nil, outfit: nil)
            }
            ForEach(entries) { entry in lookEntry(entry) }
        }
    }

    /// One planned look: the outfit opens from its picture, and one button does the next thing.
    @ViewBuilder private func lookEntry(_ entry: OutfitPlanEntry) -> some View {
        let outfit = state.outfits.first { $0.id == entry.outfitID }
        let look = TodayPresentation.look(entry: entry, outfitRevision: outfit?.revision, hasPieces: !state.pieces.isEmpty)
        if let outfit {
            NavigationLink(value: ClosetRoute.outfit(outfit.id)) {
                OutfitComposition(pieceIDs: outfit.pieceIDs, pieceHeight: 110, limit: 4, ground: AppTheme.imageGround)
            }.buttonStyle(.plain).accessibilityLabel("Open outfit \(outfit.displayName)")
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                if !entry.occasion.isEmpty { Text(entry.occasion).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary) }
                Text(look.status).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }
        } else {
            Text(look.status).foregroundStyle(AppTheme.secondary)
        }
        lookActions(look, entry: entry, outfit: outfit)
    }

    @ViewBuilder private func lookActions(_ look: TodayPresentation.Look, entry: OutfitPlanEntry?, outfit: Outfit?) -> some View {
        if look.primary == .recordWear, let entry, let outfit {
            // Two compact glass pills sharing the card width, like the App Store card footer.
            HStack(spacing: AppSpacing.small) {
                NavigationLink { LocalPlanEntryView(id: entry.id).secondaryPage() } label: { Text("Plan details").compactControl(fullWidth: true) }.buttonStyle(.plain)
                Button { state.openWear(outfitID: outfit.id, day: entry.day, entry: entry) } label: {
                    Label("Record wear", systemImage: "checkmark.circle").compactControl(fullWidth: true)
                }.buttonStyle(.plain).accessibilityIdentifier("today.look.primary")
            }
        } else {
            lookActionStack(look, entry: entry, outfit: outfit)
        }
    }

    @ViewBuilder private func lookActionStack(_ look: TodayPresentation.Look, entry: OutfitPlanEntry?, outfit: Outfit?) -> some View {
        switch look.primary {
        case .recordWear:
            if let entry, let outfit { TodayGlassAction(title: "Record wear", systemImage: "checkmark.circle") { state.openWear(outfitID: outfit.id, day: entry.day, entry: entry) }.accessibilityIdentifier("today.look.primary") }
        case .reviewPlan:
            if let entry { TodayGlassAction(title: "Review plan", systemImage: "doc.text.magnifyingglass") { state.openPlan(editing: entry) }.accessibilityIdentifier("today.look.primary") }
        case .chooseOutfit:
            if let entry { TodayGlassAction(title: "Choose outfit", systemImage: "tshirt") { state.openPlan(editing: entry) }.accessibilityIdentifier("today.look.primary") }
        case .buildOutfit: TodayGlassAction(title: "Build outfit", systemImage: "plus.circle") { state.buildOutfit() }.accessibilityIdentifier("today.look.primary")
        case .addPiece: TodayGlassAction(title: "Add piece", systemImage: "plus.circle") { state.addPiece() }.accessibilityIdentifier("today.look.primary")
        case nil: EmptyView()
        }
        if let entry {
            NavigationLink { LocalPlanEntryView(id: entry.id).secondaryPage() } label: { TodayCardActionLabel(title: "Plan details") }.frame(minHeight: 44)
        } else if !state.pieces.isEmpty {
            Button { state.openPlan() } label: { TodayCardActionLabel(title: "Plan a look") }.frame(minHeight: 44)
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
                Text("\(Set(records.map(\.day.key)).count) days, \(Set(records.flatMap { $0.pieces.map(\.id) }).count) pieces")
                if records.isEmpty { Text("No wear recorded in this week yet.").foregroundStyle(AppTheme.secondary) }
                NavigationLink { LocalWearHistoryView(periodStart: bounds.start, periodEnd: bounds.end).secondaryPage() } label: { TodayCardActionLabel(title: "View this week") }.frame(minHeight: 44)
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
            } else { Text("Record a few looks to see which pieces you reach for.").foregroundStyle(AppTheme.secondary) }
            NavigationLink { LocalWearInsightsView(initialMonth: month).secondaryPage() } label: { TodayCardActionLabel(title: "View this month") }.frame(minHeight: 44)
        }
    }
    @ViewBuilder private var upcoming: some View {
        if let error = state.planError { failure(error) { state.reloadPlanEntries() } }
        else if let entries = try? TodaySources.upcoming(state.planEntries, days: instance.options?.upcomingDays ?? 7, planID: instance.options?.pinnedID) {
            let hasLook = state.today?.instances.contains { $0.isVisible && $0.kind == .todayLook && $0.options?.pinnedID == nil } == true
            let visible = TodayPresentation.upcoming(entries, today: today, hidingToday: hasLook)
            if let pin = instance.options?.pinnedID, !state.planDefinitions.contains(where: { $0.id == pin }) { configure("The selected plan is unavailable.") }
            else if visible.isEmpty {
                Text("No upcoming plan entries in this selection.").foregroundStyle(AppTheme.secondary)
                Button { state.openPlanAuthoring(day: today) } label: { TodayCardActionLabel(title: "Plan your week") }.frame(minHeight: 44)
            }
            ForEach(visible) { entry in
                NavigationLink { LocalPlanEntryView(id: entry.id).secondaryPage() } label: { TodayAgendaRow(entry: entry, today: today) }.buttonStyle(.plain)
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
            if let date = PieceWearSummary(piece: piece, records: state.wearRecords).lastWorn {
                Text("Last recorded \(date.display(.standard))").foregroundStyle(AppTheme.secondary)
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

    private static func symbol(for action: TodayAction) -> String {
        switch action {
        case .addPiece: "tshirt"
        case .buildOutfit: "square.stack"
        case .planner: "calendar"
        case .recordWear: "checkmark.circle"
        case .addFit: "photo"
        case .openCloset: "hanger"
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
                               description: Text("Saved notes and photos remain available from the widget library."))
            } else {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let instance, let card = instance.options?.personal {
                    if card.kind == .personalPhoto { TodayPersonalPhoto(card: card).frame(minHeight: 200) }
                    Text(card.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                }
            }.padding(20)
        }
            }
        }.background(AppTheme.canvas).navigationTitle(TodayPresentation.title(kind: instance?.kind.title ?? "Saved card", contentTitle: instance?.options?.personal?.title)).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let instance, instance.options?.personal != nil {
                    Button { state.openTodayEditor(); state.todayEditor?.directEdit = true; state.todayEditor?.begin(instance) } label: { Image(systemName: AppSymbols.edit) }.accessibilityLabel("Edit card")
                }
            }
        }
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
                    Button { setup = true } label: {
                        Image(systemName: "chevron.forward").font(AppTypography.disclosure)
                            .foregroundStyle(AppTheme.ink).frame(width: 44, height: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Open Weather setup")
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
    /// A weather card already names the place in its title; the standalone notice keeps it here.
    var showsPlace = true
    @Environment(AppState.self) private var state
    @Environment(\.colorScheme) private var colorScheme
    @State private var setup = false
    @State private var loading = false
    @State private var loadFailed = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let client = state.weatherClient {
                if let error = client.error {
                    SemanticFeedback(role: .warning, message: error)
                    Button { client.reload() } label: { TodayCardActionLabel(title: "Retry weather preferences") }.frame(minHeight: 44)
                } else if client.local?.enabled == true, let place = client.local?.place {
                    if showsPlace { Text(place.name).font(AppTypography.body).truncated() }
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        let day = LocalPlanDay(date: context.date, timeZone: TimeZone(identifier: place.timeZoneID) ?? .current)
                        let selection = WeatherSelection(place: place, day: day)
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            if let snapshot = client.cached(selection, now: context.date),
                               let reading = snapshot.reading(for: day, now: context.date, qualified: client.qualified),
                               let attribution = snapshot.attribution,
                               let mark = UIImage(data: colorScheme == .dark ? attribution.dark : attribution.light) {
                                HStack {
                                    Label(reading.condition, systemImage: reading.symbol)
                                    Spacer(minLength: AppSpacing.small)
                                    if let temperature = reading.temperatureCelsius, let date = reading.currentDate,
                                       let zone = TimeZone(identifier: day.timeZoneID),
                                       LocalPlanDay(date: date, timeZone: zone) == day {
                                        Text(Measurement(value: temperature, unit: UnitTemperature.celsius), format: .measurement(width: .abbreviated, usage: .weather))
                                            .font(.title2.weight(.semibold))
                                    }
                                }
                                Text("Low \(Measurement(value: reading.lowCelsius, unit: UnitTemperature.celsius).formatted(.measurement(width: .abbreviated, usage: .weather))), High \(Measurement(value: reading.highCelsius, unit: UnitTemperature.celsius).formatted(.measurement(width: .abbreviated, usage: .weather)))")
                                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                                if reading.freshness(at: context.date) == .saved {
                                    Text("Saved weather at \(reading.fetchedAt.formatted(date: .omitted, time: .shortened))")
                                        .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                                }
                                Image(uiImage: mark).resizable().scaledToFit().frame(maxWidth: 160, maxHeight: 36)
                                    .accessibilityLabel("Apple Weather")
                                Link(destination: attribution.legalURL) { TodayCardActionLabel(title: "Data sources") }
                            } else {
                                if loading { ProgressView("Loading weather…") }
                                if !loading {
                                    Text(loadFailed ? "Weather couldn’t load. Open details to retry." : "Weather is unavailable right now.")
                                        .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                                }
                            }
                        }
                        .task(id: "\(selection.key)|\(client.epoch)|\(scenePhase)|\(Int(context.date.timeIntervalSince1970 / 1800))") {
                            guard scenePhase == .active, client.qualified else { return }
                            loading = true; loadFailed = false
                            defer { loading = false }
                            do { _ = try await client.fetch(selection, consent: true, foreground: scenePhase == .active) }
                            catch { if !Task.isCancelled { loadFailed = true } }
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

/// A note or caption clamped to four lines; the quiet "Read more" appears only when text is actually cut off.
private struct TodayCaption: View {
    let text: String
    @State private var shown: CGFloat = 0
    @State private var full: CGFloat = 0
    private var isTruncated: Bool { full > shown + 1 }
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(text).font(AppTypography.supporting).foregroundStyle(AppTheme.ink).lineLimit(4)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { shown = $0 }
                .background(alignment: .topLeading) {
                    Text(text).font(AppTypography.supporting).fixedSize(horizontal: false, vertical: true).hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { full = $0 }
                }
            if isTruncated {
                Text("Read more").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

/// One upcoming plan: picture, outfit, a short relative day and its occasion.
private struct TodayAgendaRow: View {
    @Environment(AppState.self) private var state
    let entry: OutfitPlanEntry
    let today: LocalPlanDay
    private var outfit: Outfit? { state.outfits.first { $0.id == entry.outfitID } }
    private var dayLabel: String {
        switch TodayPresentation.relativeDay(entry.day, to: today) {
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .yesterday, .other: return entry.day.display(.standard)
        }
    }
    private var needsReview: Bool { entry.requiresReview || (outfit != nil && outfit?.revision != entry.outfitRevision) }
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            if let outfit { OutfitComposition(pieceIDs: outfit.pieceIDs, pieceHeight: 48, limit: 2, ground: AppTheme.imageGround).frame(width: 56, height: 64).clipped() }
            VStack(alignment: .leading, spacing: 2) {
                Text(outfit?.displayName ?? "Outfit not chosen").font(AppTypography.body).foregroundStyle(AppTheme.ink).truncated()
                Text([dayLabel, entry.occasion].filter { !$0.isEmpty }.joined(separator: ", "))
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).truncated()
                if needsReview { Text("Needs review").font(AppTypography.metadata).foregroundStyle(AppTheme.warning) }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.secondary).accessibilityHidden(true)
        }.frame(minHeight: AppControlMetrics.minimumTarget).contentShape(Rectangle())
    }
}

/// The card's one quiet action: trailing text, 44 pt target, no chevron row.
/// Every Today card link is the same compact glass pill, full width of the card.
private struct TodayCardActionLabel: View {
    let title: String
    var body: some View { Text(title).compactControl(fullWidth: true) }
}

/// A compact glass pill with an icon for a card's main action.
private struct TodayGlassAction: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Label(title, systemImage: systemImage).compactControl(fullWidth: true) }.buttonStyle(.plain)
    }
}
