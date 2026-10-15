---
name: aqd-verify
description: Verify AQD slice changes, choose native unit/build checks, or execute authorized final iPhone 17 Pro Max hardening. Use before recording test, compatibility, or readiness claims.
---

# Verify AQD changes

Read the issue's `docs/pan/issue-<number>.md` and the [verification policy](../../../docs/delivery/implementation-plan.md#verification-policy--owner-approved-october15). Select checks for the changed behavior at the authorized stage. [Immediate MVP target](../../../docs/agents/autonomous-workflow.md#immediate-mvp-target) owns target-phone acceptance.

## 1. Bind the evidence

Record HEAD and relevant dirty inputs, toolchain, test selection, destination and artifact path. Prior results apply to their recorded source. Discover current scripts/config rather than borrowing historical UUIDs or test counts.

For simulator tests, run `node scripts/ios-destination.mjs --json` to select an available **iPhone 17 Pro Max** on the newest installed available iOS runtime. Inspect the reported OS against the task's target. Missing matching devices or unavailable simulator services block only simulator checks; Core/docs/generic Release checks can continue. A different phone cannot silently substitute. The helper never boots or creates a simulator.

Complete when each selected check has a known input revision, command and evidence destination. Device selection is not a native test.

## 2. Run the stage's checks

| Stage/change | Check |
| --- | --- |
| Agent docs/skills/tooling | `pnpm check:agents`, `pnpm check`, `git diff --check` |
| Pure Core rule during a slice | `swift test --package-path apps/ios/Core --filter <actual-test-name>` |
| Final feature native check | The existing runner with `IOS_TEST_SCOPE=unit` runs Core, AQDTests and a Debug build. |
| Release configuration affected or final feature build | Generic unsigned Release build below, once after final source changes. |
| Authorized focused UI request or final #30 | Relevant existing UI tests; use `IOS_TEST_SCOPE=all` for the complete runner, then physical-phone checks. |

From the repository root:

```sh
AQD_DESTINATION="$(node scripts/ios-destination.mjs)" || exit
IOS_DESTINATION="$AQD_DESTINATION" IOS_DERIVED_DATA=/tmp/aqd-feature-derived \
  IOS_TEST_SCOPE=unit ./scripts/test-ios.sh
```

The explicit failure guard stops this command when no target destination exists. The runner also resolves that target when `IOS_DESTINATION` is absent. Use a dedicated derived-data directory per task; serialize tests/builds sharing native resources.

```sh
xcodebuild -project apps/ios/AQD.xcodeproj -scheme AQD \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/aqd-feature-release \
  -disableAutomaticPackageResolution CODE_SIGNING_ALLOWED=NO build
```

For focused native tests, discover real identifiers in source and use `xcodebuild test -only-testing:<target>/<suite>/<test>` with the resolved destination and isolated derived data. UI tests requiring Photos fixtures use `scripts/seed-ios-test-photo.sh` on the selected test simulator. Preserve existing assertions and failures. Routine features use unit/build checks; broad simulator/device/E2E work waits for #30 unless requested. Inspect the runner's actual scope and result bundle/log, including skips and failed setup.

Complete when selected checks finish and their actual exit status, results and artifacts are captured. Fix task-caused failures and rerun affected checks. Missing access/tooling stays Not run/Blocked; failed tests stay Failed.

## 3. Qualify and persist

Update plan acceptance rows with command, source revision, environment, result and artifact. Retain exact deferred runtime/keyboard/accessibility/media cases for #30. Add a concise receipt to [verification](../../../docs/delivery/verification.md) when evidence changes; update [status](../../../docs/delivery/implementation-status.md) for changed capability.

At final personal-MVP hardening, prove integrated journeys on the physical iPhone 17 Pro Max and its installed OS. Cover persistence/relaunch, offline/manual paths, permissions/media, visible editing, light/dark, accessibility and applicable capability/privacy/performance checks. Device-only protection, camera and model quality need physical-phone evidence. Obtain signing/device access through the lifecycle. Broader launch-matrix work remains a separate release requirement.

Complete when every required claim points to observed evidence at the right layer. Feature delivery, simulator success, personal-phone acceptance, GitHub release and native distribution are separate results.
