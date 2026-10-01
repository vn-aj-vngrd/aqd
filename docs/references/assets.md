# Visual references and assets

Current redesign: [DESIGN.md](../../DESIGN.md) supersedes earlier visual choices below. The design uses SF Pro and SF Symbols in native implementation; Helvetica Neue and schematic line icons are Paper substitutes. Photographs are remote Unsplash reference imagery, with provenance retained below and imagery embedded in Paper. They are composition references, not evidence of user inventory or a cleared production asset library. Replace with licensed catalog assets or authorized user photos before release.

- [Alta public site](https://www.altadaily.com/): reference for clothing-led compositions and daily-outfit emphasis. No Alta branding, copy, or imagery is bundled in AQD.
- [Supplied Mobbin reference](https://mobbin.com/apps/alta-ios-a92b35a0-2cf3-4e78-94d4-07926ba73ccf/d204950b-63c4-49d9-b9fa-3d394cab3e92/screens): redirected to the login/marketing surface during this session; the full app-screen library was not inspected.
- `apps/ios/AQD/Assets.xcassets/SampleWardrobe.imageset/wardrobe.png`: original generated sample garment atlas, six objects in a 3×2 grid. Generated with the built-in image tool on 2026-09-30. The complete generation prompt is embedded in its PNG metadata. The image is split into six cells at runtime for sample pieces; it is not user wardrobe data or a product photograph of a purchasable item.
- SF Symbols provide interface icons. System typography provides native UI and the restrained serif headings.

## Historical implementation: Lucide icons and App Store reference

The earlier iOS prototype's authored interface icons use the [Lucide icon library](https://lucide.dev/), under its [ISC license](https://lucide.dev/license). Original SVG sources and the complete license are in `apps/ios/IconSources/lucide/`; native template PDFs are in the asset catalog. Source revision: `5a92b9ba262de5bf10e864219883267672c05db8`. Vector rendering preserves the original 24-unit grid and 2-unit rounded strokes. Native system-owned controls (back navigation, search field, disclosure indicators) retain their OS glyphs.

The user's eight App Store screenshots supplied on 2026-09-30 are the primary layout reference: bold leading titles, a trailing circular profile control, white icon chips with restrained shadows, compact capsule actions, content-led cards, and a grouped glass tab bar. The [Apple Store listing](https://apps.apple.com/us/app/apple-store/id375380948) was also visually inspected. AQD adapts the interface pattern to wardrobe content; no Apple or third-party app illustrations are bundled.

Selected tab assets are local adaptations of the bundled Lucide SVGs: filled silhouettes for Home, Closet, Agent, and Profile, and a heavier Search stroke. The `*-selected.svg` sources retain the same Lucide license.

## Reference photographs

Paper owns placement, crops and sizing. These Unsplash identifiers preserve provenance from the retired local renderer. They are design references, not a production licensing claim.

- [Reference photograph](https://images.unsplash.com/photo-1483985988355-763728e1935b)
- [Reference photograph](https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77)
- [Reference photograph](https://images.unsplash.com/photo-1539109136881-3be0616acf4b)
- [Reference photograph](https://images.unsplash.com/photo-1595777457583-95e059d581b8)
- [Reference photograph](https://images.unsplash.com/photo-1596755094514-f87e34085b2c)

### Shared person photos

Page 00 **Components · People and avatar images** is the visual source for these fictional sample identities. Reuse the same source and crop across all appearances.

| Sample identity | Source | Paper crop |
| --- | --- | --- |
| Camille Reyes | Existing [blue-coat photograph](https://images.unsplash.com/photo-1539109136881-3be0616acf4b) | Circular, background size 380%, position 50% 22% |
| Noah Lim | Existing [red-coat photograph](https://images.unsplash.com/photo-1483985988355-763728e1935b) | Circular, background size 240%, position 50% 15% |
| Maya Santos | [Callum Blacoe portrait](https://unsplash.com/photos/woman-in-black-turtleneck-shirt-Id6U55AZMpg), image photo-1593529467220-9d721ceb9a78 | Face-cropped square, cover, centered |
| Lina Cruz | [Portrait reference](https://images.unsplash.com/photo-1494790108377-be9c29b29330) | Face-cropped square, cover, centered |

Names are fixtures, not claims about the photographed people. Production uses authorized user-selected images. These are design references, not a cleared production asset library. Clothing and outfit photos continue to reuse the existing Paper assets.

### Official iOS 27 component reference

[Apple’s iOS and iPadOS 27 kit](https://www.figma.com/community/file/1651309003795292092/ios-and-ipados-27) is the native component reference alongside [Apple Design Resources](https://developer.apple.com/design/resources/). Listing checked October 1, 2026: published by Apple, updated September 15, 2026, with controls/views, templates, text/color styles and materials; notes identify Liquid Glass, layout, sidebar and scroll-edge updates. No kit import or detailed component measurement was performed in this pass. Do not infer SDK support from the visual asset alone.
