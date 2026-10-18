# AQD iOS

Native SwiftUI app: `AQD/` (UI, persistence, media), `Core/` (pure rules, a Swift package), `AQDTests/`, `AQDUITests/`. Shared scheme **AQD**, bundle `com.aqd.private`.

## Build and test

Needs macOS, Xcode 27, the owner's iPhone 17 Pro Max (connected and unlocked) and local signing. From the repository root:

```sh
IOS_DESTINATION="platform=iOS,id=$AQD_DEVICE_UDID" \
  IOS_DEVELOPMENT_TEAM="$AQD_LOCAL_TEAM" IOS_DEVICE_READY=1 \
  IOS_TEST_SCOPE=unit ./scripts/test-ios.sh
```

- `AQD_DEVICE_UDID`: from `xcrun devicectl list devices`. `AQD_LOCAL_TEAM`: the existing local signing identity (kept in the ignored `Configuration/Local.xcconfig`, never committed). Set `IOS_DEVICE_READY=1` only after confirming the phone is ready.
- Use `IOS_DERIVED_DATA` for a task-owned build directory and run native work serially.
- Install and launch for a manual check: `xcrun devicectl device install app --device <udid> <AQD.app>` then `xcrun devicectl device process launch --terminate-existing --device <udid> com.aqd.private`.
- Command-line builds reformat `AQD.xcodeproj/project.pbxproj`; restore it with `git checkout` before committing.
- Agent quality eval (Debug, on the phone): `xcrun devicectl device process launch --terminate-existing --device <udid> com.aqd.private --aqd-agent-eval --aqd-agent-eval-label <name>` runs the golden prompts through the real Agent against the sample closet in a throwaway store and writes `Documents/AQD-agent-eval-<name>.json`; copy it with `xcrun devicectl device copy from --domain-type appDataContainer --domain-identifier com.aqd.private`. Add `--aqd-agent-eval-rescore <earlier-name>` to score an earlier run's replies with today's checks. Keep the phone unlocked; it never touches your own closet.
- The runner refuses simulators and unconfirmed readiness. End-to-end UI tests are deferred to issue #30.

## Data boundary

SwiftData with CloudKit off. AQD files use complete protection and backup exclusion. Deleting records is acknowledged separately from reference-checked file cleanup, which retries. Corrupt or newer stores are kept, never replaced. Debug UI tests use `--aqd-ui-testing` with an isolated `AQD_TEST_STORE_ID`; these hooks are absent from Release builds. Frozen schemas migrate forward without reseeding user content.
