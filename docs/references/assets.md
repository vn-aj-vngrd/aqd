# Visual references and assets

Current redesign: [DESIGN.md](../../DESIGN.md) supersedes earlier visual choices below. The design uses SF Pro and SF Symbols in native implementation; Helvetica Neue and schematic line icons are Paper substitutes. Current garment demos reuse the original generated Welcome atlas; retained public-post and person photographs use the Unsplash references below. They are composition references, not evidence of user inventory or a cleared production asset library. Replace with licensed catalog assets or authorized user photos before release.

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

Names are fixtures, not claims about the photographed people. Production uses authorized user-selected images. These are design references, not a cleared production asset library. Private wardrobe and outfit demos use the canonical garment mapping below; retain these person and public-post images where their labels match.

### Official iOS 27 component reference

[Apple’s iOS and iPadOS 27 kit](https://www.figma.com/community/file/1651309003795292092/ios-and-ipados-27) is the native component reference alongside [Apple Design Resources](https://developer.apple.com/design/resources/). Listing checked October 1, 2026: published by Apple, updated September 15, 2026, with controls/views, templates, text/color styles and materials; notes identify Liquid Glass, layout, sidebar and scroll-edge updates. No kit import or detailed component measurement was performed in this pass. Do not infer SDK support from the visual asset alone.

## V1 and V2 demo wardrobe — October 6, 2026

Reuse the original 12-piece [Welcome atlas](../design/assets/welcome/README.md) and its [crop map](../design/assets/welcome/atlas-layout.json). These are generated fictional garments for static demonstrations, not real inventory or new application seed data. No images were generated in this pass.

| Fixture key | Matching visual |
| --- | --- |
| `shirt` | Powder-blue cotton shirt |
| `knit` | Ivory ribbed knit |
| `coat` | Navy trench coat |
| `overshirt` | Olive overshirt |
| `trousers` | Charcoal tailored trousers |
| `linen` | Sand linen trousers |
| `dress` | Cream midi dress |
| `jeans` | Indigo jeans |
| `loafers` | Oxblood loafers |
| `sneakers` | Ivory sneakers |
| `bag` | Tan crossbody |
| `belt` | Black belt |

Visible short labels use Cotton shirt (blue), Straight jeans (indigo), Ivory sneakers (ivory), and Tan crossbody (tan). Keep the same garment identity across capture, saved piece, selection, outfit, Agent proposal, planner and review copies. Do not substitute a different shoe or bag while retaining the original label.

| Named look or theme cover | Included visuals |
| --- | --- |
| An easy afternoon | Shirt, jeans, ivory sneakers, tan crossbody |
| Coffee, then a walk / Easy weekend | Ivory knit, sand linen trousers, ivory sneakers |
| Easy layers | Olive overshirt, charcoal trousers, blue shirt, oxblood loafers |
| Work week / Office days | Blue shirt, charcoal trousers, oxblood loafers, black belt |
| Quiet evenings | Cream dress, oxblood loafers, tan crossbody |
| Everyday | Ivory knit, jeans, ivory sneakers |
| Blue layers / Blue weekends cover | Navy coat, charcoal trousers, blue shirt, oxblood loafers |

Theme covers are representative compositions, not theme outfit counts. Outfit covers show their included pieces. Reuse a composition when it represents the same outfit; use different combinations for different looks. Preserve existing public-post photography where it matches the post. Empty states remain genuinely empty.

Piece previews fit the complete atlas cell with uniform scaling and clipping to that cell, preserving proportions and avoiding adjacent-cell bleed. Selected photo previews use the same portrait viewport; the explicit 3:4 editor demonstrates a reviewed 1.2× crop. This supersedes the earlier portrait-shirt/landscape-shoe reference media in the historical photo-flow review, without changing the Fit-by-default contract for user media.
