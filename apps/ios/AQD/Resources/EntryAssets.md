# Native entry assets

The logo is a smoked glass Q on the dark canvas (`#1C1C1B`). `AQDMark` shows the Q on a transparent ground (`BrandMark`, with a darker glass for light appearance) in the Welcome and saved-preferences screens. Launch.storyboard supplies the compiled launch counterpart.

`LaunchColors.xcassets` holds three renders of the same Q: `AppIcon` (opaque 1024-pixel icon; iOS supplies its Home Screen mask, so the PNG has no pre-rounded corners), `BrandMark` (a transparent Q with light and dark appearances, used in app) and `LaunchMark` (the Q on a flat `#1C1C1B` ground so its edges disappear into the launch canvas). Regenerate them by opening `scripts/ios-icon/render.html?look=icon` or `?look=launch` in Chrome with WebGL and saving a 1024 by 1024 screenshot at scale 1. `?look=mark-light` and `?look=mark-dark` write the transparent PNG into the page as a data URL; read it with `--dump-dom`. The native asset compiler derives device sizes through the AppIcon build setting.

The existing Welcome garment atlas and six Tour images are illustrative assets, never saved wardrobe or fit records. No network access is required to render entry screens.

`LaunchCanvas` is `#1C1C1B` in both appearances, so the launch is always the dark canvas. `LaunchSplash` continues from the static launch at the same size and position: a highlight crosses the glass while it turns slightly, then the mark lifts and dissolves as the app fades in. It holds for about a second (longer only if the closet is still opening); Reduce Motion and UI tests skip the hold and only cross-fade. The Welcome entrance starts after the splash leaves.
