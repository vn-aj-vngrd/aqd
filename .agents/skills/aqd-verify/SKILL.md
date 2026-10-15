---
name: aqd-verify
description: Verify AQD slice changes with unit/build and focused native E2E checks, or execute final iPhone 17 Pro Max hardening. Use before recording test, compatibility, or readiness claims.
---


Owner update, October16: feature delivery uses Core/native unit tests only. All E2E authoring/execution and integrated UI acceptance are deferred to #30, including feature-focused runs. Preserve existing tests and evidence for that ticket. No simulator is allowed locally or in hosted CI. The expensive native iOS CI workflow is removed; fast repository unit checks and existing protected delivery remain. Native unit checks use the connected, unlocked physical iPhone17ProMax. E2E/proof procedures below apply only to #30. Known product, data-loss and security defects still require fixes; deferred E2E is not a claim of full V1 acceptance.

# Verify AQD changes

Read the issue's `docs/plan/issue-<number>.md` and the [verification policy](../../../docs/delivery/implementation-plan.md#verification-policy--owner-approved-october15). Select checks for the changed behavior at the authorized stage. [Immediate MVP target](../../../docs/agents/autonomous-workflow.md#immediate-mvp-target) owns target-phone acceptance.

## 1. Bind the evidence

Record HEAD and relevant dirty inputs, toolchain, test selection, destination and artifact path. Prior results apply to their recorded source. Discover current scripts/config rather than borrowing historical UUIDs or test counts.

For local native checks, follow the device procedure above: discover the physical iPhone 17 Pro Max with `xcrun devicectl list devices`, read its actual OS, prompt for connected/unlocked readiness and wait for the response. Keep local simulators shut down. Missing/locked hardware blocks the physical check; independent Core/docs/generic Release work can continue. Signing stays in local configuration. Set `IOS_DEVICE_READY=1` only after readiness is confirmed, and repeat the prompt after an interruption.

Hosted native CI and simulator selection/seeding are removed. Use the physical iPhone only; routine verification is unit scope. E2E is reserved for #30.

Complete when each selected check has a known input revision, command and evidence destination. Device selection is not a native test.

## 2. Run the stage's checks

| Stage/change | Check |
| --- | --- |
| Agent docs/skills/tooling | `pnpm check:agents`, `pnpm check`, `git diff --check` |
| Pure Core rule during a slice | `swift test --package-path apps/ios/Core --filter <actual-test-name>` |
| Final feature native check | The existing runner with `IOS_TEST_SCOPE=unit` runs Core, AQDTests and a Debug build. |
| UI feature AC | Run `./scripts/prove-ios.sh <issue-number>` using its AC-mapped manifest, then inspect/publish actual results through [aqd-prove](../aqd-prove/SKILL.md). |
| Release configuration affected or final feature build | Generic unsigned Release build below, once after final source changes. |
| Authorized focused UI request or final #30 | Physical tests use an explicit case selection and declared fixtures; #30 owns the broad integrated/device matrix. |

From the repository root:

```sh
IOS_DESTINATION="platform=iOS,id=$AQD_DEVICE_UDID" \
  IOS_DEVELOPMENT_TEAM="$AQD_LOCAL_TEAM" IOS_DEVICE_READY=1 \
  IOS_DERIVED_DATA=/tmp/aqd-feature-derived \
  IOS_TEST_SCOPE=unit ./scripts/test-ios.sh
```

Resolve `AQD_DEVICE_UDID` from current physical-device discovery and `AQD_LOCAL_TEAM` from the existing local signing identity. The runner refuses absent/local simulator destinations and unconfirmed readiness before native tools. Use a dedicated derived-data directory per task; serialize native tests/builds.

```sh
xcodebuild -project apps/ios/AQD.xcodeproj -scheme AQD \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/aqd-feature-release \
  -disableAutomaticPackageResolution CODE_SIGNING_ALLOWED=NO build
```

For focused native tests, discover real identifiers in source and use the resolved physical destination, local signing, isolated derived data and a retained result bundle. Select every required issue case without silently omitting a failure. Physical UI tests require an explicit manifest and declared synthetic fixtures; automatic Photos seeding is hosted-CI-only. Preserve the ordinary closet/Photos library. Preserve assertions and failures. UI features require selected AC E2E proof in addition to unit/build checks; broad qualification waits for #30. Inspect actual scope, results, skips, failed setup and exported evidence.

Complete when selected checks finish and their actual exit status, results and artifacts are captured. Fix task-caused failures and rerun affected checks. Missing access/tooling stays Not run/Blocked; failed tests stay Failed.

## 3. Qualify and persist

Update plan acceptance rows with command, source revision, environment, result and artifact. Use [acceptance proof](../../../docs/agents/acceptance-proof.md) to distinguish local execution from inspected and published UI proof. Only genuinely broader runtime/device cases remain deferred to #30; a failed feature AC stays blocking. Add a concise receipt to [verification](../../../docs/delivery/verification.md) when evidence changes; update [status](../../../docs/delivery/implementation-status.md) for changed capability.

At final personal-MVP hardening, prove integrated journeys on the physical iPhone 17 Pro Max and its installed OS. Cover persistence/relaunch, offline/manual paths, permissions/media, visible editing, light/dark, accessibility and applicable capability/privacy/performance checks. Device-only protection, camera and model quality need physical-phone evidence. Obtain signing/device access through the lifecycle. Broader launch-matrix work remains a separate release requirement.

Complete when every required claim points to observed evidence at the right layer. Feature delivery, simulator success, personal-phone acceptance, GitHub release and native distribution are separate results.
