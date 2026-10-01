# Visual references and assets

Current redesign: [DESIGN.md](../DESIGN.md) supersedes earlier visual choices below. The design uses SF Pro and SF Symbols in native implementation; Helvetica Neue and schematic line icons are Paper substitutes. Photographs are remote Unsplash reference imagery, with provenance retained in [reference assets](design/REFERENCE-ASSETS.md) and imagery embedded in Paper. They are composition references, not evidence of user inventory or a cleared production asset library. Replace with licensed catalog assets or authorized user photos before release.

- [Alta public site](https://www.altadaily.com/): reference for clothing-led compositions and daily-outfit emphasis. No Alta branding, copy, or imagery is bundled in AQD.
- [Supplied Mobbin reference](https://mobbin.com/apps/alta-ios-a92b35a0-2cf3-4e78-94d4-07926ba73ccf/d204950b-63c4-49d9-b9fa-3d394cab3e92/screens): redirected to the login/marketing surface during this session; the full app-screen library was not inspected.
- `apps/ios/AQD/Assets.xcassets/SampleWardrobe.imageset/wardrobe.png`: original generated sample garment atlas, six objects in a 3×2 grid. Generated with the built-in image tool on 2026-09-30. The complete generation prompt is embedded in its PNG metadata. The image is split into six cells at runtime for sample pieces; it is not user wardrobe data or a product photograph of a purchasable item.
- SF Symbols provide interface icons. System typography provides native UI and the restrained serif headings.

## Historical implementation: Lucide icons and App Store reference

The earlier iOS prototype's authored interface icons use the [Lucide icon library](https://lucide.dev/), under its [ISC license](https://lucide.dev/license). Original SVG sources and the complete license are in `apps/ios/IconSources/lucide/`; native template PDFs are in the asset catalog. Source revision: `5a92b9ba262de5bf10e864219883267672c05db8`. Vector rendering preserves the original 24-unit grid and 2-unit rounded strokes. Native system-owned controls (back navigation, search field, disclosure indicators) retain their OS glyphs.

The user's eight App Store screenshots supplied on 2026-09-30 are the primary layout reference: bold leading titles, a trailing circular profile control, white icon chips with restrained shadows, compact capsule actions, content-led cards, and a grouped glass tab bar. The [Apple Store listing](https://apps.apple.com/us/app/apple-store/id375380948) was also visually inspected. AQD adapts the interface pattern to wardrobe content; no Apple or third-party app illustrations are bundled.

Selected tab assets are local adaptations of the bundled Lucide SVGs: filled silhouettes for Home, Closet, Agent, and Profile, and a heavier Search stroke. The `*-selected.svg` sources retain the same Lucide license.
