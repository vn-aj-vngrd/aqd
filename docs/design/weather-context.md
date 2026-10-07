# Optional Apple weather — shared V1/V2

Owner-approved October 7, 2026: basic native WeatherKit moves into V1. This is a Paper/specification change, not a working service integration. [V1 release](../product/v1-release.md#optional-live-weather-contract) owns launch scope and complete weather budgets/privacy/freshness/attribution policy; [architecture](../architecture/v1.md#optional-native-weather-boundary) owns request/cache mechanics; this document owns interaction states, composition and source returns. [Apple research](../references/weatherkit-v1.md) records dated API facts. Weather extends the local private app with an **optional Apple network service**, not an AQD backend or account.

## Direction and placement

Extend AQD's existing native weather-context task, not a new visual identity. Operate mode: Today's date line uses the owner's iPhone-style pattern, **Wed7 · condition symbol ·29°**, rather than a separate weather card. These are example values; retain the actual fixture date and locale-format the short weekday/day. A compact source-aware context target leads to one native place/date task; weather never competes with the main outfit or plan action. Use approved opaque grouped surfaces, system text, registered disclosure roles, growing rows and safe-area actions. Weather is off until the user chooses it. Today shows numerical weather only after activation and successful attributed retrieval; the off-state need not add a dashboard card.

- Settings, reached through Profile More, exposes Weather and its selected place/off state.
- Outfit suggestions, dated planning and Agent context can open the same weather task with their current date and actual return/draft. No additional tab or Today Settings shortcut.
- Enabled Today places a native condition symbol and localized temperature beside the short date, with a44-point accessible weather-details target. Off/unavailable states keep the date alone. Saved readings need an explicit Saved/updated qualifier, not the same fresh presentation. Details show selected place, full date/timezone, freshness and source; the owner removed the Today attribution row/placeholder; mark and legal references remain in weather details. Details-only attribution compliance is unverified, not assumed satisfied; resolve Apple's display requirements before shipping numerical Today weather. No separate Today weather card. Current conditions are for the selected place, not a forecast invented from the phone's date; future outfit/plan context uses the destination's selected local forecast day. Never pair current conditions from a different destination-local day with Today's date: preserve Today's plan/journal date, omit the compact numerical reading on mismatch and expose the actual place/day in weather details. Do not silently shift Today's day when changing weather city.
- V2 inherits the same local client and manual fallback. Broader providers, calendar integrations, alerts, background notifications and research remain separate V2 enhancements.

## Setup, choice and permission

1. Explain before activation that WeatherKit receives the selected location/query and that Apple city search receives entered search text. Wardrobe photos, pieces, body details, journal notes and chat are not sent to either service.
2. Choose a city through native Apple search/geocoding; selecting a city does **not** request device-location permission. Search/resolution needs internet; previously resolved coordinates may be retained locally.
3. **Use current location** is an explicit alternative: request When In Use only then, make one foreground lookup and accept approximate location. No Always permission, movement tracking or background-location access. Denial/restriction/timeout preserves manual city choice and all private tasks.
4. Choose the outfit/plan day in its recorded destination timezone. Show unresolved timezone honestly rather than substituting the phone's timezone.
5. **Use weather** enables/accepts the scoped context; it does not save an outfit, plan or Agent proposal. Back/Cancel preserves the original caller and its prior committed weather preference. Opening or cancelling a selector alone never enables weather.
6. **Continue without weather** removes weather from the pending request and returns to the same task. This is distinct from turning off the device-wide preference in Settings.

WeatherKit does not require Apple Intelligence, a language-model download or an AQD user account. Native access requires the developer's signed entitlement/App ID service setup and Apple Developer Program membership. The API supports iOS16+, but this does not lower AQD's existing iOS18 manual-path planning target.

## Shared Today header style

Today references use one header grammar: title32/38 Medium in primary ink; date, condition symbol and temperature14/20 Regular in semantic secondary grey (`#686C72` for these light references). Title/date line-box tops are70/116 with20-point leading inset and8-point title-to-date gap. Metadata uses8 points before weather and4 between symbol/temperature; the weather target remains44×44. Visible fixtures use **Mon 5** in V1 and **Thu 1** in V2; full actual dates remain recorded for runtime localized accessibility announcements. Default-off views remain date-only. Thirteen matching references were normalized without moving cards or canvas roots.

[Header evidence](evidence/home-header-style.json) records exact nodes, original styles, static-only transforms and limits. The condition fixture uses the alpha-preserving secondary-grey [native symbol variant](assets/weather/cloud-sun-fill-macos-secondary.png); runtime uses the actual SF symbol with `.foregroundStyle(.secondary)`, not a fixed raster or fixed dark-appearance colour. Paper translations preserve existing snapshot body geometry; native implementation must compose semantic header/date/scope layout rather than copy those offsets.

## States and information hierarchy

| State | Required behavior |
| --- | --- |
| Off/setup | Weather is optional; explain Apple service boundaries, choose place/day, Use weather, continue without. No weather numbers or automatic permission prompt. |
| City selection | Search query disclosure; identifiable city/region results with timezone when known; explicit current-location alternative. Cancel retains the old place. Offline search offers the saved place or weather-free continuation. |
| Loading | Native indeterminate progress; retain caller/date/place and prior matching cache. Cancel invalidates the pending request. No invented percentages or blocking of manual Save. |
| Fresh | Place and Now or exact forecast date: current conditions may show a scalar temperature, whereas a date-only daily forecast shows condition plus returned low/high and precipitation chance. Do not assign current temperature or an invented daily average to a future day; an hourly scalar requires an explicit matching hour. Provider/fetch timestamps stay distinct. Appropriate Apple Weather mark and legal link accompany data. Use applies context only. |
| Saved/offline | Same place/day only, clearly “Saved weather — updated [time]”. Never call stale data current or silently use it as fresh Agent input. Continue without weather remains available. |
| Outside forecast | “Forecast not available for this date”; keep the plan/date and weather-free route. Never replace missing future/historical data with current conditions or a nearby day. |
| Permission denied | Explain location access is unavailable; Choose city remains usable. Settings guidance only when applicable, never a forced permission/account gate. |
| Unavailable/no cache | Honest service/connectivity/entitlement recovery, explicit Retry and weather-free continuation. No false weather numbers or automatic alternate provider. |

Forecast coverage is bounded by the returned dataset: Apple's current offering reaches approximately ten days, not every date in AQD's two-week plans or three-calendar-month routines. Minute precipitation, severe alerts and historical comparisons are not part of the minimal V1 integration. Unknown precipitation is not zero rain. Units are localized and can change without refetching.

## Attribution and demo truth

**Owner layout override:** Today row `10LL-0` is hidden, including its grey mark placeholder and Data sources link. Today’s look now starts at160 rather than250, with date/weather styling and44-point target preserved. Details retain attribution references. This mockup change is not permission to omit required Apple attribution in a shipped app; details-only placement needs legal/platform verification.

Obtain `WeatherService.attribution`; display its appearance-appropriate combined Apple Weather mark and legal destination alongside both fresh and saved numerical data. Cache the supplied attribution assets for cached display. A handcrafted Apple logo, generic cloud or text-only label is not a substitute for Apple's mark. If required attribution cannot load and has no valid cached asset, withhold numerical weather and offer recovery.

Paper weather numbers/timestamps are illustrative fixtures, not retrieved conditions. The section-02 canvas header explicitly discloses illustrative weather, unverified Apple attribution and unverified iOS rendering. Enabled Today, Fresh and Saved retain short visible external labels above the phone: “Illustrative weather · SDK mark unverified”. Nine detailed technical notes retain their original IDs and full text in hidden Paper layers and [portable Weather grid evidence](evidence/weather-grid-spacing.json), rather than occupying wide columns beside phones; [original Weather evidence](evidence/weatherkit-v1.json) remains preserved. These are canvas annotations, not app UI or substitutes for runtime attribution. If the official runtime attribution asset cannot be obtained for Paper, clearly annotate its reserved layout outside the phone. That demonstrates placement only and is **not certified attribution**. Never treat a static card as proof of entitlement, weather retrieval, permission behavior or current conditions.

## Shared fetching, cache and cancellation

Apply the complete [approved budgets/cache/freshness policy](../product/v1-release.md#optional-live-weather-contract); its numerical limits are AQD choices, not Apple per-device quotas or verified performance. Request identity, timestamp storage and resume expiry mechanics belong to architecture. UI must expose pending/cooldown/unavailable/Saved states honestly, prevent duplicate actions and hide expired numbers according to that policy. Turning Weather off clears cache and cancels requests.
- Debounce city search and cancel/ignore superseded queries; resolve only the selected result. Rapid city/date changes must not let a late response overwrite a newer selection or show city A's cache as city B.
- Preserve caller/draft/selection/focus on cancellation or failure. Accept/apply requires current request identity and matching location, date, timezone and dataset. Cached stale context is excluded from fresh automated suggestions; explicit user-entered conditions remain separately labelled.
- Store the weather preference locally; data export disclosures must cover any included selected-place setting. Numerical cache is disposable, not a durable wardrobe fact. Weather never changes wear, plan assignment, body-use consent or publication state.

Apple's included500,000 calls/month allowance is per Developer Program membership, not per phone or user. Validate aggregate demand and entitlement/quota failures before launch; optional paid capacity is separate from AQD backend costs. Do not embed REST signing credentials in the app or introduce a weather proxy merely to use the native API.

## Native release acceptance

Verify signed-device access, feature off/on, no AQD sign-in, no Foundation Models gate, attribution light/dark/legal/cached assets, city lookup offline/empty/error, approximate/denied/restricted location, true destination timezone/DST/date boundaries, actual returned forecast limits and absent precipitation. Test coalescing/expiry/cooldown/cache deletion, no background traffic, rapid-selection/cancel races and no wardrobe payloads sent to Apple. All private manual journeys must still work in airplane mode when weather is unavailable.

Dynamic Type, VoiceOver state/source/time announcements, source focus return,44-point targets, keyboard-safe city search, short phones, landscape/iPad adaptations and semantic appearances remain native acceptance. No implementation, service or permission check is established by this design task.
