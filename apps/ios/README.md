# AQD iOS

The native SwiftUI app. Shared scheme **AQD**, bundle `com.aqd.private`, deployment target iOS 18, built with Xcode 27.

```text
AQD/            The app, in layers: App, Features, DesignSystem, Services, Persistence, Resources
Core/           Swift package of pure rules, validation and value types, with its own tests
AQDTests/       Unit and persistence tests, mirroring the app's layers
AQDUITests/     UI tests (end-to-end runs are deferred to issue #30)
Configuration/  Shared build settings; your signing lives in the ignored Local.xcconfig
```

Layer rules, naming and safety conventions are in [AGENTS.md](AGENTS.md); UI tokens and components in [DESIGN.md](../../DESIGN.md).

## Before you start

- macOS with Xcode 27, Node 24 and pnpm 10.12.1 (for the hooks and repo checks).
- `brew install swiftlint swiftformat`, then `pnpm install --frozen-lockfile` at the repository root to install the Git hooks.
- The physical iPhone 17 Pro Max, connected and unlocked. Native checks run on that phone only; simulators stay shut down.
- Local signing: put your team in `Configuration/Local.xcconfig` (ignored, never committed). Find the phone's UDID with `xcrun devicectl list devices`.

## Test

Core rules run anywhere:

```sh
cd apps/ios/Core && swift test
```

The app's unit suite runs on the phone. From the repository root:

```sh
IOS_DESTINATION="platform=iOS,id=$AQD_DEVICE_UDID" \
  IOS_DEVELOPMENT_TEAM="$AQD_LOCAL_TEAM" IOS_DEVICE_READY=1 \
  IOS_TEST_SCOPE=unit ./scripts/test-ios.sh
```

- Set `IOS_DEVICE_READY=1` only after confirming the phone is connected and unlocked. The runner refuses simulators and unconfirmed readiness.
- Use `IOS_DERIVED_DATA` for a task-owned build directory, and run native work one job at a time.

Lint and checks (the pre-commit hook runs these too):

```sh
cd apps/ios
swiftlint lint --quiet                 # errors fail the commit
swiftformat --lint .                   # whitespace only
node ../../scripts/check-ios-layers.mjs   # import and folder rules
node ../../scripts/check-ios-colors.mjs   # every color is an AppTheme token
```

## Run on the phone

```sh
cd apps/ios
xcodebuild -project AQD.xcodeproj -scheme AQD -configuration Debug \
  -destination "platform=iOS,id=$AQD_DEVICE_UDID" -derivedDataPath build/dd \
  DEVELOPMENT_TEAM="$AQD_LOCAL_TEAM" -allowProvisioningUpdates build
xcrun devicectl device install app --device "$AQD_DEVICE_UDID" build/dd/Build/Products/Debug-iphoneos/AQD.app
xcrun devicectl device process launch --terminate-existing --device "$AQD_DEVICE_UDID" com.aqd.private
```

Command-line builds can reformat `AQD.xcodeproj/project.pbxproj`; restore it with `git checkout` before committing.

### Debug launch arguments

Append these to the launch command. They exist only in Debug builds and are ignored under `--aqd-ui-testing`. Anything that changes your closet writes a backup archive to the app's Documents first.

| Argument | What it does |
| --- | --- |
| `--aqd-seed-week-of-use` | Replaces the closet with Angelika Domingo's sample life: about 136 pieces, 66 outfits, 21 themes, routines and trips, two months of wear, fits, profile and style preferences. Settings → Development → Seed sample data runs the same seed. |
| `--aqd-add-preview-samples` | Adds the bundled preview closet. |
| `--aqd-add-all-widgets` | Shows every Today card, with Wear insights under Your week in wear. |
| `--aqd-preview-welcome` | Shows the welcome screens again. |
| `--aqd-agent-eval` | Runs the Agent eval (below). |

### Agent eval

`--aqd-agent-eval --aqd-agent-eval-label <name>` runs the golden prompts through the real on-device Agent against the sample closet in a throwaway store, so your own closet is never touched. It writes `Documents/AQD-agent-eval-<name>.json` with pass rates for the tool chosen, invented names, identifier leaks, counts and reply length.

- `--aqd-agent-eval-suite <name>` picks another prompt set; `--aqd-agent-eval-rescore <earlier-name>` scores an earlier run's replies with today's checks.
- Copy the report with `xcrun devicectl device copy from --device "$AQD_DEVICE_UDID" --domain-type appDataContainer --domain-identifier com.aqd.private --source Documents/AQD-agent-eval-<name>.json --destination .`
- Keep the phone unlocked and AQD in the foreground while it runs.
- `scripts/eval-agent-live.sh` does the whole release gate: install, run the golden, held-out and tidy suites three times each, copy the reports and fail when a bar in `AgentEvalGate` is missed. The `tidy` suite covers archive and delete requests.

## Data boundary

SwiftData with CloudKit off. AQD files use complete protection and are excluded from backup. Deleting a record is acknowledged separately from the reference-checked file cleanup, which retries. Corrupt or newer stores are kept, never replaced, and frozen schemas migrate forward without reseeding your content. Debug UI tests use `--aqd-ui-testing` with an isolated `AQD_TEST_STORE_ID`; none of these hooks ship in Release builds.
