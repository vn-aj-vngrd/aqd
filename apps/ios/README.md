# AQD native iOS

Private V1 implementation in progress: epic [#6](https://github.com/vn-aj-vngrd/aqd/issues/6), baseline/capture [#7](https://github.com/vn-aj-vngrd/aqd/issues/7). This baseline is not the complete V1 release. Unimplemented root capabilities are explicitly labelled; no demonstration wardrobe or wear records are seeded.

## Build and test

Requires macOS, Xcode and an installed iOS Simulator. Current evidence uses Xcode26.5 / Swift6.3.2 / iOS26.5; deployment minimum is iOS18. SDK27 and physical-device certification remain release gates, not proven by this baseline.

From the repository root:

```sh
./scripts/test-ios.sh
```

The default simulator is the local iPhone17Pro `E5DAD2A0-6375-4737-B33D-3A08A4D9FDAA`. For another installed simulator:

```sh
IOS_DESTINATION='platform=iOS Simulator,id=<simulator-UUID>' ./scripts/test-ios.sh
```

The runner tests the Foundation core, builds the app and runs native SwiftData/photo and XCTest UI tests unsigned. It adds one **synthetic test image** to Simulator Photos for the real PhotosPicker flow; existing Photos are not deleted. Override derived data with `IOS_DERIVED_DATA`. Fixtures prove mechanics, not garment/media quality. Open `AQD.xcodeproj`, shared scheme **AQD**, for local development.

## Data boundary

SwiftData explicitly disables CloudKit. AQD-owned originals/derivatives and store files use complete protection and backup exclusion. Editing keeps metadata-minimized originals; crop/rotation confirms a draft before the separate piece Save. Deletion acknowledges record changes separately from reference-checked file cleanup and retries the same operation while cleanup remains pending. Unsupported/corrupt stores are retained, never replaced with an empty database.

Debug UI tests use `--aqd-ui-testing` plus a validated `AQD_TEST_STORE_ID` UUID for an isolated store retained across process relaunch. They never reset the ordinary closet. These hooks are absent from Release builds. Local signing/configuration is ignored, not required by the unsigned test runner and must not be committed.

The current native schema is version2, with a supported preserving migration from version1 for durable media-cleanup intents. Freeze delivered schema versions; subsequent structural changes require an explicit versioned migration preserving originals, identities, drafts and operation acknowledgments. The native test verifies version1 piece/draft/photo/Today identities survive migration and reopen; this is not complete legacy migration/export/restore acceptance.

[Implementation status](../../docs/delivery/implementation-status.md) and [verification](../../docs/delivery/verification.md) own actual evidence and remaining gates.
