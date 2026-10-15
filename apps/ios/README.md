# AQD native iOS

Private V1 follows the [implementation and final-hardening plan](../../docs/delivery/implementation-plan.md): [Foundation#20](https://github.com/vn-aj-vngrd/aqd/issues/20), then one vertical-slice issue/PR per Paper V1 section01–09 (#21–29), then final E2E/hardening #30. Native baseline PR#9 is merged at `c5e11c4`; former #6–19 are closed historical work, not full-V1 acceptance. This baseline is not the complete V1 release. Unimplemented root capabilities are explicitly labelled; no demonstration wardrobe or wear records are seeded.

## Build and test

Requires macOS, Xcode, the owner's physical iPhone 17 Pro Max and existing local development signing. [The device procedure](../../docs/agents/autonomous-workflow.md#immediate-mvp-target) requires a connected/unlocked readiness prompt before on-device execution. Keep local simulators shut down. Preserve deployment/availability settings; discover the current phone/OS instead of copying historical identifiers.

From the repository root:

```sh
IOS_DESTINATION="platform=iOS,id=$AQD_DEVICE_UDID" \
  IOS_DEVELOPMENT_TEAM="$AQD_LOCAL_TEAM" IOS_DEVICE_READY=1 \
  IOS_TEST_SCOPE=unit ./scripts/test-ios.sh
```

Resolve `AQD_DEVICE_UDID` with `xcrun devicectl list devices` and `AQD_LOCAL_TEAM` from the existing local signing identity. Confirm readiness before setting its flag. Local missing/simulator destinations and unconfirmed readiness fail before native tools. The runner defaults to Core/native unit tests and a Debug build. Physical UI runs require an explicit selection. Persist `apps/ios/acceptance/issue-<number>.txt` and run `./scripts/prove-ios.sh <number>` with the same physical/signing/readiness environment; it retains exact results and exported attachments for [AC proof](../../docs/agents/acceptance-proof.md). Broad full-suite/device qualification remains in #30.

Use `IOS_DERIVED_DATA` for a task-owned build directory and serialize native work. Physical test stores are isolated; physical Photos scenarios require a declared safe fixture and never reset the ordinary library. GitHub-hosted CI alone uses unsigned simulator checks and automatic synthetic Photos seeding on GitHub's machine. Its evidence stays separate from physical acceptance. The shared scheme is **AQD**. [Verification](../../docs/delivery/verification.md) owns actual test/build results.

## Data boundary

SwiftData explicitly disables CloudKit. AQD-owned originals/derivatives and store files use complete protection and backup exclusion. Editing keeps metadata-minimized originals; crop/rotation confirms a draft before the separate piece Save. Deletion acknowledges record changes separately from reference-checked file cleanup and retries the same operation while cleanup remains pending. Unsupported/corrupt stores are retained, never replaced with an empty database.

Debug UI tests use `--aqd-ui-testing` plus a validated `AQD_TEST_STORE_ID` UUID for an isolated store retained across process relaunch. They never reset the ordinary closet. These hooks are absent from Release builds. Local signing/configuration is ignored, not required by the unsigned test runner and must not be committed.

The current native schema is version2, with a supported preserving migration from version1 for durable media-cleanup intents. Freeze delivered schema versions; subsequent structural changes require an explicit versioned migration preserving originals, identities, drafts and operation acknowledgments. The native test verifies version1 piece/draft/photo/Today identities survive migration and reopen; this is not complete legacy migration/export/restore acceptance.

[Implementation status](../../docs/delivery/implementation-status.md) and [verification](../../docs/delivery/verification.md) own actual evidence and remaining gates.
