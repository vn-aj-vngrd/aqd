# Native weather-symbol reference

`cloud-sun-fill-macos.png` is a static Apple SF Symbols reference, exported on October 7, 2026 through macOS AppKit `NSImage(systemSymbolName: "cloud.sun.fill")`, regular weight. Transparent PNG; aspect ratio retained; ancillary metadata removed. No AI generation, hand tracing, weather request or AQD application implementation was involved.

Paper node `10LD-0` uses it in the enabled Today reference `10GK-0` at16points. The fixture shows partly cloudy conditions; it is not a retrieved forecast. Runtime uses the actual WeatherKit condition's `symbolName`, system rendering and semantic tint—not this fixed raster for every condition. iOS mapping/appearance/accessibility remains unverified.

SHA-256: `b8bcccc21bee2130cfbb8a69dda14e80e7c56eb453cb58c8c7ed28697858301b`.

## Secondary-grey variant

`cloud-sun-fill-macos-secondary.png` is the Today metadata variant at `#686C72`. Standard-library PNG processing replaces RGB with104/108/114 while preserving every original alpha byte, the64×64 dimensions, shape and counters. It is not a newly drawn symbol. Paper node `10LD-0` uses this variant; the original export remains unchanged.

Variant SHA-256: `6dfe388288ca99a9e24c29beb4205bef5c3a9fe7692a62e4425cb7224c22bee2`. Runtime should render the actual SF condition symbol with semantic `.foregroundStyle(.secondary)`, not a fixed light-appearance raster.

This is **not** an Apple Weather attribution mark. The actual mark/legal assets must come from WeatherService.attribution; Paper retains an explicitly unverified mark-layout reservation. See [weather context](../../weather-context.md).
