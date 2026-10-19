# Native entry assets

The logo is a smoked glass Q on the dark canvas (`#1C1C1B`). `AQDMark` shows it in the opening, Welcome and saved-preferences screens, clipped to the Home Screen icon's corner shape. LaunchScreen.storyboard supplies the compiled launch counterpart.

`LaunchColors.xcassets` holds three renders of the same Q: `AppIcon` (opaque 1024-pixel icon; iOS supplies its Home Screen mask, so the PNG has no pre-rounded corners), `BrandMark` (the same image, used in app) and `LaunchMark` (the Q on a flat `#1C1C1B` ground so its edges disappear into the launch canvas). Regenerate them by opening `scripts/ios-icon/render.html?look=icon` or `?look=launch` in Chrome with WebGL and saving a 1024 by 1024 screenshot at scale 1. The native asset compiler derives device sizes through the AppIcon build setting.

The existing Welcome garment atlas and six Tour images are illustrative assets, never saved wardrobe or fit records. No network access is required to render entry screens.

`LaunchCanvas` is `#1C1C1B` in both appearances, so the launch is always the dark canvas. The in-app opening screen shows the same canvas and mark for continuity. No artificial launch delay is added.
