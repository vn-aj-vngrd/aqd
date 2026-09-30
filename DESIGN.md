# AQD design system

This records the implemented prototype. Target navigation and feature placement live in [Product definition](docs/PRODUCT.md) and [feature specifications](docs/features/README.md). The current Home selector and Search tab below describe existing code, not requirements for future modules.

Minimal, native, clothing-first. The user requested compact controls, clean consistent headers, restrained icons, and reusable components. This supersedes the earlier serif/cobalt direction.

## Source of truth

- `apps/ios/AQD/Design/Components.swift`: `AppLayout`, `AppSymbol`, `screenHeader`, `ScreenHeading`, `SectionHeading`, `ActionButtonStyle`, `PrimaryButton`, `AssistantButton`, clothing imagery, empty and error states.
- `apps/ios/AQD/Assets.xcassets`: adaptive monochrome tint, charcoal action fill, and secondary text colors.
- [UI implementation rules](docs/DESIGN-RULES.md): how agents apply and verify this system.

## Typography and hierarchy

System semantic fonts throughout. Root screens use bold leading titles; account controls belong only in Profile. Compact centered titles establish detail and modal screens. Content headings use title2 semibold when necessary; section headings use title2 semibold; body, subheadline, and caption carry supporting information. Home starts with a greeting and Personal / Community feed selector, followed by wardrobe posts. Promotional headers and duplicate titles are removed.

## Controls and navigation

Content actions share a 44-point minimum touch target, capsule shapes, subheadline semibold text, and one padding policy. They grow with content and Dynamic Type. Primary content actions use a deep charcoal capsule with white text; secondary actions use dark text on a soft-gray capsule. Dark mode uses a lighter charcoal primary fill and light secondary text. Submit controls share the primary fill. Toolbars and forms use native controls.

The tab order is Home, Closet, Agent, Search, Profile. iOS 26 supplies Liquid Glass with five icon-only tabs grouped, retaining accessible labels and scroll minimization. Active icons use filled silhouettes, with a heavier Search outline, alongside the native selection pill. iOS 18 uses translucent system material. Agent uses a conversation icon and opens the on-device assistant full screen, without bottom navigation. The center icon and community inspiration open the same presentation. Back returns to the prior tab. Account access lives in Profile’s settings control and opens a rounded, grouped settings sheet with a close control. Authored icons use the bundled Lucide vector family through AppIcon, with native glyphs retained only for OS-owned controls. FilterChip and ChipRail provide horizontal category and occasion filters with monochrome icons and a soft downward shadow.

## Layout and imagery

A 20-point screen inset and 24-point section spacing anchor scroll layouts. GarmentTile and OutfitComposition retain the flat neutral clothing surfaces and original cutout images. Grids collapse for accessibility text. Color belongs primarily to the clothes, with native semantic colors reserved for error/destructive states.

## Verification boundary

A successful build is required, followed by screenshots and navigation checks for changed surfaces. Current evidence and limitations are recorded in [verification](docs/VERIFICATION.md). Design documentation does not imply live community availability or complete model-quality testing.

## In-page segmented tabs

`SegmentedTabs` implements the supplied Free Apps / Paid Apps reference across Closet, assistant mode, and account mode: white capsule track, inset light-gray selected capsule, equal-width labels, dark text, accessible selection, and content-driven height. It is distinct from scrolling filter chips and the glass bottom navigation.

## AQD palette boundary

The App Store references govern component structure, not AQD’s brand palette. AQD uses monochrome navigation, chips, and controls: deep charcoal primary actions, soft-gray secondary surfaces, and neutral selected pills. Photographed clothing supplies the color. Preserve native destructive/error colors for meaning.

## Closet and social identity

The Add sheet contains two manual paths: clothing upload and outfit building. Profile uses an avatar, wardrobe and connection counts, edit/share actions, and Pieces / Outfits / Themes collections. Settings stay in a separate sheet. AI work lives only in the full-screen Agent. Unconnected social counts display an unavailable state, never invented numbers.
