# AQD native iOS

Private V1 follows the [implementation and final-hardening plan](../../docs/delivery/implementation-plan.md): [Foundation#20](https://github.com/vn-aj-vngrd/aqd/issues/20), then one vertical-slice issue/PR per Paper V1 section01–09 (#21–29), then final E2E/hardening #30. Native baseline PR#9 is merged at `c5e11c4`; former #6–19 are closed historical work, not full-V1 acceptance. This baseline is not the complete V1 release. Unimplemented root capabilities are explicitly labelled; no demonstration wardrobe or wear records are seeded.

## Build and test

Requires macOS, Xcode and an installed simulator. The immediate personal-MVP target is iPhone 17 Pro Max. Keep existing deployment/availability settings; inspect the actual installed toolchain and runtime instead of copying historical version strings.

From the repository root:

```sh
AQD_DESTINATION="$(node scripts/ios-destination.mjs)" || exit
IOS_DESTINATION="$AQD_DESTINATION" IOS_TEST_SCOPE=unit ./scripts/test-ios.sh
```

The helper selects an available iPhone 17 Pro Max and reports its installed OS with `--json`. It fails without selecting another phone when the target is absent. The runner defaults to Core/native unit tests and a Debug build. `IOS_TEST_SCOPE=all` includes UI tests; `e2e` runs UI tests only. UI features additionally run selected native E2E identifiers and publish [AC proof](../../docs/agents/acceptance-proof.md); `e2e` alone runs the whole UI target. For a feature, persist `apps/ios/acceptance/issue-<number>.txt` and run `./scripts/prove-ios.sh <number>`; it retains exact results and exported visual attachments. Broad full-suite/device qualification remains in #30.

Use `IOS_DERIVED_DATA` for a task-owned build directory. Only UI scopes add a synthetic photo fixture to the selected test simulator; they preserve existing Photos. Fixtures prove mechanics, not garment quality. The Xcode project uses shared scheme **AQD** and unsigned automated simulator builds. [Verification](../../docs/delivery/verification.md) owns current test/build results, including the scoped Notes correction and retained older failures. Physical-phone acceptance remains separate.

## Data boundary

SwiftData explicitly disables CloudKit. AQD-owned originals/derivatives and store files use complete protection and backup exclusion. Editing keeps metadata-minimized originals; crop/rotation confirms a draft before the separate piece Save. Deletion acknowledges record changes separately from reference-checked file cleanup and retries the same operation while cleanup remains pending. Unsupported/corrupt stores are retained, never replaced with an empty database.

Debug UI tests use `--aqd-ui-testing` plus a validated `AQD_TEST_STORE_ID` UUID for an isolated store retained across process relaunch. They never reset the ordinary closet. These hooks are absent from Release builds. Local signing/configuration is ignored, not required by the unsigned test runner and must not be committed.

The current native schema is version2, with a supported preserving migration from version1 for durable media-cleanup intents. Freeze delivered schema versions; subsequent structural changes require an explicit versioned migration preserving originals, identities, drafts and operation acknowledgments. The native test verifies version1 piece/draft/photo/Today identities survive migration and reopen; this is not complete legacy migration/export/restore acceptance.

[Implementation status](../../docs/delivery/implementation-status.md) and [verification](../../docs/delivery/verification.md) own actual evidence and remaining gates.
