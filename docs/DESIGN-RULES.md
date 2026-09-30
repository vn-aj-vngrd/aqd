# UI implementation rules

Apply these rules when adding an AQD screen, editing a shared component, choosing an icon, or reviewing a UI change. [DESIGN.md](../DESIGN.md) describes the current visual system; source owns exact values.

## Change workflow

1. Inspect the affected screen and `apps/ios/AQD/Design/Components.swift`. Identify the existing header, action, row, and image component before adding code.
2. Change the shared component when the behavior belongs to every use. Keep feature state and business actions in the feature view. Extract a component when two real uses share the same behavior; avoid frameworks for hypothetical screens.
3. Build, then inspect the changed screens on the simulator. Check default and accessibility text, light and dark appearance, labels, touch targets, and the affected navigation path. Completion requires rendered evidence; disclose any untested state.
4. Update this document only when a decision changes. Update DESIGN.md when the implemented visual system changes.

## Headers and hierarchy

- Use `screenHeader(title, prominent: true)` for root destinations: a bold left title. Target Home uses a compact community feed header; the prototype currently uses a time-based greeting. Detail and modal titles use the compact variant. Account settings are accessed only from Profile. Bottom navigation is icon-only with accessible labels, targeting Home, Closet, Agent, Inbox, Profile (current build still uses Search). Selected navigation icons use filled variants (a heavier outline for the current Search icon) alongside the native selection pill. The center Agent item opens a full-screen cover with Back and no bottom navigation; dismissing returns to the previous tab. Keep contextual actions with their content.
- Use `ScreenHeading` only when a screen genuinely needs an in-content heading. Use `SectionHeading` for sections. Keep one obvious hierarchy; avoid a slogan beneath a navigation title.
- Write concrete task language: “Edit outfit”, “Wear today”, “Recently added”. Put explanatory text beside the decision it supports.
- Use semantic system typography. Let garment images provide the visual character.

## Actions and icons

- Use `PrimaryButton` for the primary content action and `ActionButtonStyle(primary: false)` for its secondary peer. Native toolbar, form, and destructive controls retain their native behavior.
- Keep actions at least 44 points tall, with content-driven growth at larger text sizes. Use the shared style’s padding; adding vertical padding or large control size on top creates oversized buttons.
- Use `FilterChip` inside `ChipRail` for categories and occasions. Each chip has a compact monochrome icon, capsule surface, subtle downward shadow, and explicit selected state; its action must actually filter or navigate. Use one primary action per task area. Use words when the action is already clear; add an icon only when it improves recognition.
- Use `AppSymbol` for recurring destinations and the assistant. The assistant uses Lucide’s `message-circle`, with the accessible name “Ask AQD”. Sparkles are explicitly excluded by the product owner.
- Use bundled Lucide vector assets through `AppIcon` / `IconLabel`; native system-owned controls keep their OS glyphs. Preserve one stroke family and retain source/license attribution when adding icons.

## Product surfaces

Use [PRODUCT.md](PRODUCT.md) for intended information architecture and [feature specifications](features/README.md) for behavior: Home All / Following feeds with discovery search, Closet personal management and Planner, Inbox human chats, app-level manual/assisted creation, and full-screen Agent. The existing build still has Personal / Community Home and Agent-only assistance; refinement is documented before implementation. Profile presents social identity and public collections; account settings remain a separate sheet. Show unavailable social services honestly rather than fabricating connections or public URLs.

## In-page tabs

Use `SegmentedTabs` for mutually exclusive views or modes (Closet sections, assistant mode, account mode). Match the supplied App Store structure while preserving AQD’s monochrome palette: white capsule container with a 4-point inset, a pale-gray selected capsule, equal-width dark text, and 44-point minimum targets. Selected state is communicated to accessibility. Filter chips remain separate because they represent scrollable categories; bottom navigation remains the native glass tab bar. Selection changes only view state, never submits a form.

## Surfaces and layout

- Read spacing and radii from `AppLayout`; read colors from the asset catalog through `Color` helpers. Reuse `GarmentTile` and `OutfitComposition` instead of rebuilding clothing cards.
- Keep clothing surfaces neutral and flat. Glass belongs to native navigation chrome. Preserve the native iOS 26 tab bar, grouped five-tab arrangement, and OS accessibility adaptations.
- Use deep charcoal for primary action fills, soft gray for secondary surfaces, and adaptive monochrome navigation tint, one consistent corner treatment for content controls, and system backgrounds. Preserve meaningful destructive/error colors.
- Root headers use a shared safe-area layout so long greetings retain their width. Use `SearchField` for root search; navigation-bar search is hidden with the root toolbar.
- Keep scroll content inside native safe areas. Allow wrapping and scrolling instead of shrinking text or clipping labels.

## States and acceptance

- Visible labels, accessible names, disabled states, loading, empty, and error behavior belong to the component’s contract. A decorative icon never substitutes for an action label.
- On-device AI and Quick rules must remain clearly distinguished. Device/model availability is visible. AI results are editable drafts and saving requires a user action.
- Review for duplicate styles, repeated view structure, accidental hierarchy changes, and leftover promotional copy. A screen is consistent when the shared components behave the same across it and its neighbors, not merely when colors match.
