# Native entry assets

The MVP logo is the splash’s AQD wordmark: regular system font, 44 points with a half-point tracking, charcoal A/D and a gold Q (light appearance). `AQDWordmark` shares it across the opening, Welcome and saved-preferences screens. LaunchScreen.storyboard supplies the compiled launch counterpart.

`LaunchColors.xcassets/AppIcon.appiconset` contains an opaque 1024-pixel icon using the same charcoal/gold wordmark on white. iOS supplies its home-screen mask; the PNG has no pre-rounded corners. Reproduce it from the repository root with `swift scripts/render-ios-wordmark.swift` on macOS (or pass `-module-cache-path /tmp/aqd-icon-module-cache` when the default Swift cache is unavailable). The native asset compiler derives device sizes through the AppIcon build setting.

The existing Welcome garment atlas and six Tour images are illustrative assets, never saved wardrobe or fit records. [Welcome provenance](../../../../docs/design/assets/welcome/README.md) and [Tour provenance](Tour/README.md) own their sources. No network access is required to render entry screens.

LaunchCanvas/LaunchInk/LaunchGold have explicit light/dark partners matching AppTheme.surface/ink/accent. The compiled launch uses one centered attributed native label; in-app opening uses the shared AQDWordmark on semantic surface. No artificial launch delay is added.
