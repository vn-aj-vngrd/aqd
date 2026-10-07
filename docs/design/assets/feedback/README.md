# Feedback SF Symbol fixtures

These six PNGs are static Paper reference assets, not an iOS alert API, bundled app implementation, Apple wordmark or native-render certification.

| Role | Actual AppKit symbol | Paper tint |
| --- | --- | --- |
| Success | `checkmark.circle` | `#416451` |
| Warning | `exclamationmark.triangle` | `#795B2E` |
| Danger | `exclamationmark.octagon` | `#D4142A` |

The `*-macos.png` originals were exported locally from `NSImage(systemSymbolName:accessibilityDescription:)`, configured at18pt `.regular`. Each source was fitted proportionally into a72-point transparent square; Retina bitmap output is144×144 pixels. No hand-drawn symbol, emoji, generated image or screenshot tracing was used. The `*-light.png` variants replace RGB with the existing semantic foreground while preserving every alpha pixel and crop; source proportions are unchanged. Nonzero alpha pixel counts from the exports: success5155, warning4079, danger4496. Paper uses18-point image frames with `object-fit:contain`.

Info reuses registered `XCR-0` geometry; neutral uses that same geometry with secondary tint. Bare selected check `4QI-0` is not repurposed. Runtime uses genuine SF Symbols with semantic adaptive foregrounds, not these light-only rasters. Symbols are established names expected within deployment18; local macOS resolution verifies fixture export only, not an iOS18 SDK compile or18/26/27 rendering comparison. Native SDK availability, Night/contrast, Dynamic Type and VoiceOver still require implementation verification.

Apple sources: [SF Symbols guidance](https://developer.apple.com/design/human-interface-guidelines/sf-symbols), [SwiftUI Label](https://developer.apple.com/documentation/swiftui/label), [dialogIcon limitation](https://developer.apple.com/documentation/swiftui/view/dialogicon(_:)), [UIAlertController private-hierarchy boundary](https://developer.apple.com/documentation/uikit/uialertcontroller). Use system symbols only within permitted platform/design-resource terms; this reference is not independent artwork licensing or distribution approval.

[Portable feedback evidence](../../evidence/feedback-variants.json) records master IDs, current mappings, asset hashes and verification limits. Reproduction helpers remain temporary (`/tmp/aqd-feedback-symbols.swift`, `/tmp/aqd-feedback-retint.swift`), not product app source.
