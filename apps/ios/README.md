# AQD iOS

Open `AQD.xcodeproj`, select AQD and run on an iPhone. The committed project requires Xcode 26.5 or later; deployment starts at iOS 18. Native iOS 26 controls use system glass, with standard native controls on iOS 18. The Supabase Swift SDK is pinned to 2.55.3; commit `Package.resolved` when updating dependencies.

## Local backend

From the repository root, run `supabase start` with Docker running. Copy `Configuration/Local.xcconfig.example` to `Configuration/Local.xcconfig` and fill only the local publishable key from `supabase status`. Do not copy secret/service-role keys into the app. Local configuration is ignored by Git.

The URL escape `$()` preserves `//` inside xcconfig. Email cooldown must match the backend's `auth.email.max_frequency`; this local server uses one second. Run `python3 scripts/test-entry-backend.py` for real local auth/RLS/media/receipt checks. Local email opens in Mailpit at http://127.0.0.1:54324. Click the latest sign-in email on the same Simulator/device that initiated it. The callback is `com.aqd.ios://auth/callback?state=<transaction UUID>` with PKCE; the allowlist preserves that state.

The client uses Keychain for auth/session transactions. Simulator builds/tests need ad-hoc signing (`CODE_SIGN_IDENTITY=-`); disabling signing prevents Keychain access. The development app opens normally when the backend is unavailable and allows private work.

## Structure and boundaries

- App constructs the application dependencies once.
- Core owns typed records and the versioned atomic local store. Photos are separate bounded JPEG files.
- Design contains semantic adaptive tokens and native shared controls.
- Features/Entry owns the private and identity journeys.
- Services owns Supabase and native photo preparation/capture.

This is one app target, not a framework per feature. New wardrobe, Planner and social features should extend these boundaries when they need them. No UI view handles database credentials or authorization; ownership is enforced by Supabase RLS and a narrow transactional connection command. Association persists its reviewed snapshot and operation ID before sending; retries use the same payload. A server receipt must confirm every ID before local ownership changes. Collision keeps closets separate. Records from another account remain hidden after sign-out/account change.

## Checks

```sh
xcrun swift-format lint --strict --recursive apps/ios/AQD apps/ios/AQDTests apps/ios/AQDUITests
xcodebuild -project apps/ios/AQD.xcodeproj -scheme AQD -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGN_IDENTITY=-
supabase db lint --local --schema public,aqd_private --level warning --fail-on warning
python3 scripts/test-entry-backend.py
pnpm check
```

The tests use isolated temporary stores and temporary local-only Supabase users. They do not reset the user's closet. `generate-project.rb` is an optional maintenance helper requiring the xcodeproj Ruby gem; a fresh clone can build the committed project without it. Run the generator after adding source files if they are not added through Xcode.

## Deployment gates

No hosted AQD Supabase project has been provisioned. Hosting requires organization/cost confirmation; SMTP/domain delivery and Apple developer team/provider configuration must be supplied before live external-account acceptance. Enable the Apple provider with the actual bundle ID, Sign in with Apple entitlement and signing team; do not invent these credentials. Use HTTPS/publishable client configuration, matching redirect allowlist and server cooldown in both app configurations.

Launch legal/retention/deletion policies and licensed marketing imagery need owner review. The packaged photographs are exports of Paper's illustrative Unsplash references for this development handoff, with provenance in the design docs. They are never added to a user's inventory. E14 acquisition is V2 and absent. Full outfit composition, five-tab navigation, cloud restore of all later modules and App Store/TestFlight distribution are later slices.
