import AQDCore
import SwiftUI

struct WeatherContextView: View {
    @Bindable var client: WeatherClient
    let persistsPreference: Bool
    let onApply: (WeatherSelection?) -> Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var lookup = WeatherPlaceLookup()
    @State private var choosingLocation = false
    @State private var enabled: Bool
    @State private var place: WeatherPlace?
    @State private var day: LocalPlanDay
    @State private var snapshot: WeatherSnapshot?
    @State private var pending = false
    @State private var saving = false
    @State private var unknown = false
    @State private var error: String?
    @State private var request: WeatherPreferenceRequest?
    @State private var token = UUID()
    @State private var task: Task<Void, Never>?
    init(client: WeatherClient, initial: WeatherSelection? = nil, day: LocalPlanDay = LocalPlanDay(), persistsPreference: Bool = false, onApply: @escaping (WeatherSelection?) -> Bool) {
        self.client = client; self.persistsPreference = persistsPreference; self.onApply = onApply
        _enabled = State(initialValue: persistsPreference ? client.local?.enabled ?? false : initial != nil)
        _place = State(initialValue: initial?.place ?? client.local?.place)
        var initialDay = initial?.day ?? day
        if let zone = initial?.place.timeZoneID ?? client.local?.place?.timeZoneID { initialDay.timeZoneID = zone }
        _day = State(initialValue: initialDay)
    }
    private var hasPreferenceChanges: Bool {
        enabled != (client.local?.enabled ?? false) || place != client.local?.place
    }
    private var selection: WeatherSelection? { place.map { WeatherSelection(place: $0, day: day) } }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $enabled) {
                        AccessoryLabel("Use weather", systemImage: "cloud.sun")
                    }.disabled(saving || unknown)
                } footer: {
                    Text(enabled ? "Your city’s coordinates and forecast date go to Apple Weather. Your wardrobe stays private." : "Weather is off. Turning it on shares your chosen city’s coordinates and date with Apple Weather. Your wardrobe stays private.")
                }.listRowBackground(AppTheme.surface)
                if enabled {
                    Section {
                        Button { choosingLocation = true } label: {
                            HStack(spacing: AppSpacing.medium) {
                                Image(systemName: "mappin.and.ellipse").foregroundStyle(AppTheme.controlIcon).frame(width: 24)
                                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                    Text(place?.name ?? "Choose a city").foregroundStyle(AppTheme.ink).multilineTextAlignment(.leading)
                                    Text(place == nil ? "Search or use your current location" : "Weather location")
                                        .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                                }
                                Spacer(minLength: AppSpacing.small)
                                Image(systemName: "chevron.forward").font(AppTypography.disclosure).foregroundStyle(AppTheme.controlIcon)
                            }.frame(minHeight: 44).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityHint("Choose a different city")
                        if !persistsPreference {
                            ThemedDatePicker("Forecast date", selection: Binding(get: { (try? day.date()) ?? Date() }, set: { date in
                                cancelFetch(); day = LocalPlanDay(date: date, timeZone: TimeZone(identifier: day.timeZoneID) ?? .current)
                            }), displayedComponents: .date).environment(\.timeZone, TimeZone(identifier: day.timeZoneID) ?? .current)
                        }
                    }.disabled(saving || unknown).listRowBackground(AppTheme.surface)
                    if client.qualified, place != nil {
                        Section {
                            if pending {
                                ProgressView("Loading weather")
                                Button("Cancel weather request") { cancelFetch() }
                            }
                            TimelineView(.periodic(from: .now, by: 30)) { context in
                                if let snapshot, let reading = snapshot.reading(for: day, now: context.date, qualified: client.qualified), let attribution = snapshot.attribution,
                                   let image = UIImage(data: colorScheme == .dark ? attribution.dark : attribution.light) {
                                    WeatherReadingView(reading: reading, now: context.date)
                                    Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: 180, maxHeight: 44).accessibilityLabel("Apple Weather")
                                    Link("Data sources", destination: attribution.legalURL).frame(minHeight: 44)
                                }
                            }
                            Button { fetch(manual: true) } label: { AccessoryLabel("Refresh weather", systemImage: "arrow.clockwise") }
                                .disabled(selection == nil || pending || saving || unknown)
                        }.listRowBackground(AppTheme.surface)
                    }
                    if let error = client.error {
                        Section { SemanticFeedback(role: .warning, message: error) }.listRowBackground(AppTheme.surface)
                    }
                    Section {
                        DisclosureGroup("Weather and privacy") {
                            Text("City search sends your search text to Apple Maps. Weather sends the selected coordinates and date to Apple WeatherKit. Neither receives your wardrobe, photos, body details, journal or chat.")
                            Text("City search needs no location permission. Current location uses approximate, foreground access once.")
                        }.font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    } footer: {
                        if !client.qualified { Text("Live forecasts aren’t available in this build. You can still save your weather preferences.") }
                    }.listRowBackground(AppTheme.surface)
                }
                if let error {
                    Section { SemanticFeedback(role: .warning, message: error) }.listRowBackground(AppTheme.surface)
                }
            }.listSectionSpacing(AppSpacing.large).contentMargins(.top, AppSpacing.headerGap, for: .scrollContent).scrollContentBackground(.hidden).background(AppTheme.canvas)
                .navigationTitle("Weather").navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $choosingLocation) {
                    WeatherLocationPicker(lookup: lookup, current: place) { choosingLocation = false }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { cancelFetch(); lookup.cancel(); dismiss() } label: { Image(systemName: "xmark") }
                            .accessibilityLabel("Cancel weather context").disabled(saving || unknown)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(unknown ? "Check result" : persistsPreference ? "Save" : "Done") { apply() }
                            .tint(AppTheme.actionText)
                            .disabled(saving || (!unknown && ((persistsPreference && !hasPreferenceChanges) || (enabled && (selection == nil || (try? selection?.validated()) == nil)))))
                            .accessibilityValue(saving ? "Saving" : "")
                    }
                }
        }.tint(AppTheme.ink).interactiveDismissDisabled(saving || unknown)
            .onChange(of: lookup.selected) { _, selected in
                guard enabled, let selected else { return }; cancelFetch(); place = selected; day.timeZoneID = selected.timeZoneID; choosingLocation = false
                if client.qualified { fetch(manual: false) }
            }
            .onChange(of: enabled) { _, isEnabled in
                cancelFetch(); lookup.cancel(); choosingLocation = false
                if !unknown { error = nil }
                if isEnabled, client.qualified { fetch(manual: false) }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { cancelFetch(); lookup.cancel() }
                else if enabled, client.qualified { fetch(manual: false) }
            }
            .onChange(of: client.epoch) { _, _ in cancelFetch() }
            .onDisappear { cancelFetch(); lookup.cancel() }
            .onAppear { if enabled, client.qualified { fetch(manual: false) } }
    }
    private func cancelFetch() { token = UUID(); task?.cancel(); task = nil; pending = false; snapshot = nil }
    private func fetch(manual: Bool) {
        guard enabled, let selection, (try? selection.validated()) != nil else { return }
        cancelFetch(); let requestToken = token; pending = true; error = nil
        snapshot = client.cached(selection)
        task = Task {
            do {
                let value = try await client.fetch(selection, consent: true, manual: manual, foreground: scenePhase == .active)
                guard !Task.isCancelled, requestToken == token, self.selection == selection else { return }
                snapshot = value; pending = false
                if value.reading(for: day, now: Date(), qualified: client.qualified) == nil { error = "Weather attribution is unavailable. Numerical weather is withheld; continue without weather or retry." }
            } catch {
                guard !Task.isCancelled, requestToken == token, self.selection == selection else { return }
                pending = false
                switch error {
                case WeatherContextError.outsideForecast: self.error = "Forecast not available for this date. Your plan date is unchanged."
                case WeatherContextError.cooldown: self.error = "Weather was checked recently. Wait before refreshing, or continue without weather."
                default: self.error = "Live weather could not be loaded. Matching saved weather may remain available; your private tasks still work without it."
                }
            }
        }
    }
    private func apply() {
        guard !saving else { return }
        lookup.cancel(); cancelFetch()
        if !persistsPreference {
            if onApply(enabled ? selection : nil) { dismiss() } else { error = "The parent draft could not retain this context. Keep this task open and retry." }
            return
        }
        saving = true; defer { saving = false }
        do {
            if request == nil {
                request = WeatherPreferenceRequest(operationID: UUID(), base: try client.store.weatherState().preference, enabled: enabled, place: place)
            }
            guard let request else { return }
            _ = try client.store.saveWeatherPreference(request)
            unknown = false; client.invalidate(); dismiss()
        } catch {
            do {
                if let request, try client.store.savedWeatherPreference(request) != nil { unknown = false; client.invalidate(); dismiss() }
                else { unknown = false; self.request = nil; self.error = "Weather preferences were not saved. The previous preference remains; retry or cancel." }
            } catch { unknown = true; self.error = "The preference result is unknown. Check this operation before leaving." }
        }
    }
}
/// Search is submitted explicitly. Typing alone never sends a location query.
private struct WeatherLocationPicker: View {
    @Bindable var lookup: WeatherPlaceLookup
    let current: WeatherPlace?
    let keepCurrent: () -> Void
    @FocusState private var searchFocused: Bool
    var body: some View {
        List {
            Section {
                Button { searchFocused = false; lookup.useCurrentLocation() } label: {
                    AccessoryLabel("Use current location", systemImage: "location")
                        .frame(minHeight: 44)
                }.disabled(lookup.pending)
            } footer: { Text("Requests approximate location once. City search needs no location access.") }
                .listRowBackground(AppTheme.surface)
            if let current, lookup.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Selected city") {
                    Button(action: keepCurrent) {
                        HStack(spacing: AppSpacing.medium) {
                            Text(current.name).foregroundStyle(AppTheme.ink).multilineTextAlignment(.leading)
                            Spacer(minLength: AppSpacing.small)
                            Image(systemName: "checkmark").foregroundStyle(AppTheme.controlIcon)
                        }.frame(minHeight: 44)
                    }.accessibilityValue("Selected")
                }.listRowBackground(AppTheme.surface)
            }
            if lookup.pending {
                Section { ProgressView("Finding city…"); Button("Cancel search") { lookup.cancel() } }.listRowBackground(AppTheme.surface)
            } else if !lookup.results.isEmpty {
                Section("Search results") {
                    ForEach(Array(lookup.results.enumerated()), id: \.offset) { _, item in
                        Button { searchFocused = false; lookup.choose(item) } label: {
                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text(item.placemark.locality ?? item.name ?? "City").foregroundStyle(AppTheme.ink)
                                Text([item.placemark.administrativeArea, item.placemark.country].compactMap { $0 }.joined(separator: ", "))
                                    .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }.listRowBackground(AppTheme.surface)
            } else if !lookup.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, lookup.error == nil {
                Section {
                    Button { search() } label: { AccessoryLabel("Search cities", systemImage: "magnifyingglass").frame(minHeight: 44) }
                }.listRowBackground(AppTheme.surface)
            }
            if let error = lookup.error {
                Section { SemanticFeedback(role: .warning, message: error) }.listRowBackground(AppTheme.surface)
            }
            Section {} footer: { Text("Search sends the city or country you enter to Apple Maps.") }
        }.listStyle(.insetGrouped).listSectionSpacing(AppSpacing.large)
            .scrollContentBackground(.hidden).background(AppTheme.canvas)
            .navigationTitle("Choose city").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $lookup.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "City or country")
            .searchFocused($searchFocused)
            .onSubmit(of: .search) { search() }
            .onChange(of: lookup.query) { _, _ in lookup.cancel(); lookup.results = []; lookup.error = nil }
            .onAppear { lookup.cancel(); lookup.selected = nil; lookup.query = ""; lookup.results = []; lookup.error = nil }
            .onDisappear { lookup.cancel() }
    }
    private func search() {
        guard !lookup.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        searchFocused = false; lookup.searchCity()
    }
}

struct WeatherReadingView: View {
    let reading: WeatherReading
    let now: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reading.freshness(at: now) == .saved ? "Saved weather" : "Forecast for your day").font(AppTypography.section)
            Text(reading.day.key + " · " + reading.day.timeZoneID).font(AppTypography.supporting)
            Label(reading.condition, systemImage: reading.symbol)
            if let temperature = reading.temperatureCelsius, let date = reading.currentDate,
               let zone = TimeZone(identifier: reading.day.timeZoneID), LocalPlanDay(date: date, timeZone: zone) == reading.day {
                Text(Measurement(value: temperature, unit: UnitTemperature.celsius), format: .measurement(width: .abbreviated, usage: .weather))
            }
            Text("Low \(Measurement(value: reading.lowCelsius, unit: UnitTemperature.celsius).formatted(.measurement(width: .abbreviated, usage: .weather))) · High \(Measurement(value: reading.highCelsius, unit: UnitTemperature.celsius).formatted(.measurement(width: .abbreviated, usage: .weather)))")
            if let chance = reading.precipitationChance { Text("Rain chance \(chance.formatted(.percent))") }
            Text("Updated \(reading.fetchedAt.formatted())").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
        }
    }
}
