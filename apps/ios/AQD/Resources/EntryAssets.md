# Native entry assets

The MVP logo is the splash’s AQD wordmark: regular system font, 44 points and -1.1-point tracking. `AQDWordmark` shares it across the opening, Welcome and saved-preferences screens. LaunchScreen.storyboard supplies the compiled launch counterpart.

`LaunchColors.xcassets/AppIcon.appiconset` contains an opaque 1024-pixel icon using the same wordmark and light splash colors. iOS supplies its home-screen mask; the PNG has no pre-rounded corners. Reproduce it from the repository root with `swift scripts/render-ios-wordmark.swift` on macOS. The native asset compiler derives device sizes through the AppIcon build setting.

The existing Welcome garment atlas and six Tour images are illustrative assets, never saved wardrobe or fit records. [Welcome provenance](../../../../docs/design/assets/welcome/README.md) and [Tour provenance](Tour/README.md) own their sources. No network access is required to render entry screens.
