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
    private var selection: WeatherSelection? { place.map { WeatherSelection(place: $0, day: day) } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Weather", isOn: $enabled).disabled(saving || unknown)
                    Text("Weather is optional").font(AppTypography.section)
                    Text("City search sends your search text to Apple Maps. Weather sends the selected coordinates and date to Apple WeatherKit. Neither receives your wardrobe, photos, body details, journal or chat.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    if let error = client.error { SemanticFeedback(role: .warning, message: error) }
                    if let place {
                        Text(place.name).font(AppTypography.body)
                        Text(place.timeZoneID).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledField(title: "City and country", text: $lookup.query)
                        SecondaryAction(title: "Search cities") { cancelFetch(); lookup.searchCity() }.disabled(lookup.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        SecondaryAction(title: "Use current location") { cancelFetch(); lookup.useCurrentLocation() }
                        Text("City search needs internet and no location permission. Use current location requests approximate, foreground access once. No account or Apple Intelligence required.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        if lookup.pending { ProgressView("Finding place"); Button("Cancel lookup") { lookup.cancel() }.frame(minHeight: 44) }
                        if let error = lookup.error { SemanticFeedback(role: .warning, message: error) }
                        ForEach(Array(lookup.results.enumerated()), id: \.offset) { _, item in
                            Button(item.name ?? item.placemark.locality ?? "Choose city") { cancelFetch(); lookup.choose(item) }.frame(minHeight: 44)
                        }
                    }.disabled(saving || unknown)
                    DatePicker("Weather date", selection: Binding(get: { (try? day.date()) ?? Date() }, set: { date in
                        cancelFetch(); day = LocalPlanDay(date: date, timeZone: TimeZone(identifier: day.timeZoneID) ?? .current)
                    }), displayedComponents: .date).environment(\.timeZone, TimeZone(identifier: day.timeZoneID) ?? .current).disabled(saving || unknown)
                    if enabled {
                        if !client.qualified { Text("Live weather isn’t available in this build. Your outfit and plans still work without it.").foregroundStyle(AppTheme.secondary) }
                        if pending { ProgressView("Loading weather"); Button("Cancel weather request") { cancelFetch() }.frame(minHeight: 44) }
                        TimelineView(.periodic(from: .now, by: 30)) { context in
                            if let snapshot, let reading = snapshot.reading(for: day, now: context.date, qualified: client.qualified), let attribution = snapshot.attribution,
                               let image = UIImage(data: colorScheme == .dark ? attribution.dark : attribution.light) {
                                WeatherReadingView(reading: reading, now: context.date)
                                Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: 180, maxHeight: 44).accessibilityLabel("Apple Weather")
                                Link("Data sources", destination: attribution.legalURL).frame(minHeight: 44)
                            }
                        }
                        SecondaryAction(title: "Refresh weather") { fetch(manual: true) }.disabled(selection == nil || pending || saving || unknown || !client.qualified)
                    }
                    if let error { SemanticFeedback(role: .warning, message: error) }
                    PrimaryAction(title: unknown ? "Check preference result" : persistsPreference ? "Save weather preference" : "Use weather", isPending: saving) { apply() }
                        .disabled(!unknown && (enabled && (selection == nil || (try? selection?.validated()) == nil)))
                    SecondaryAction(title: "Continue without weather") {
                        cancelFetch(); lookup.cancel()
                        if persistsPreference || onApply(nil) { dismiss() }
                    }.disabled(saving || unknown)
                }.padding(20)
            }.background(AppTheme.canvas).navigationTitle("Weather context").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarLeading) { Button { cancelFetch(); lookup.cancel(); dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel("Cancel weather context").disabled(saving || unknown) } }
        }.tint(AppTheme.ink).interactiveDismissDisabled(saving || unknown)
            .onChange(of: lookup.selected) { _, selected in
                guard let selected else { return }; cancelFetch(); place = selected; day.timeZoneID = selected.timeZoneID
            }
            .onChange(of: enabled) { _, _ in cancelFetch() }
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
