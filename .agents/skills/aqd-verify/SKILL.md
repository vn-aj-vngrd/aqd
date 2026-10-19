---
name: aqd-verify
description: Run AQD unit, build and tooling checks on the physical iPhone before claiming a result. Use before reporting tests, builds or readiness.
---

# Verify AQD changes

## 1. Bind the evidence

Note HEAD, dirty inputs, the command and destination. Discover the phone with `xcrun devicectl list devices` (physical iPhone 17 Pro Max); never reuse old UUIDs or test counts. Ask the owner to connect and unlock it and wait for the answer; repeat after any lock or disconnect. Keep simulators shut down. Missing hardware blocks only device checks; Core, docs and Release-build work continues.

## 2. Run the checks

| Change | Check |
| --- | --- |
| Docs, skills, tooling | `pnpm check:agents`, `pnpm check`, `git diff --check` |
| Pure Core rule | `swift test --package-path apps/ios/Core --filter <test>` |
| Feature native check | `IOS_TEST_SCOPE=unit ./scripts/test-ios.sh` (command in [apps/ios/README.md](../../../apps/ios/README.md)) |
| Agent behavior (tools, intents, prompts, approval) | `AQD_DEVICE_UDID=<udid> IOS_DEVELOPMENT_TEAM=<team> scripts/eval-agent-live.sh` on the unlocked phone with Apple Intelligence on; it fails when a bar in `AgentEvalGate` is missed |
| UI change | Install on the phone, drive the flow by hand in light and dark, and check Dynamic Type |
| Release config or final build | `xcodebuild -project apps/ios/AQD.xcodeproj -scheme AQD -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/aqd-release -disableAutomaticPackageResolution CODE_SIGNING_ALLOWED=NO build` |

Use a dedicated derived-data directory per task and serialize native runs. End-to-end UI tests belong to issue #30. Fix failures your change caused and rerun; keep real failures visible, and mark unavailable checks Not run with the reason.

## 3. Report

Post each check's command, source revision, device and result as an issue comment. State what each result proves and does not: unit success, a manual phone check, a GitHub release and App Store distribution are different claims.
