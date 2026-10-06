# Applying the AQD design

Read [DESIGN.md](../../DESIGN.md) before adding a screen, changing a shared control, selecting an icon, or reviewing an interface. It is the authority for the intended app; the old prototype is migration evidence.

Apply [quality criteria](quality-criteria.md) during every review and handoff; record checked inventory and distinguish static findings from native acceptance.

## Design workflow

1. Locate the route in [the screen map](screens.md) and its Paper artboard. Read the relevant feature specification for access and data behavior.
2. Reuse the logical component in [Components](components.md). Change visual tokens and component masters in Paper page 00, then update affected Paper screen instances. Do not recreate a parallel local design gallery or renderer.
3. Apply shared changes across the affected Paper nodes, rather than adjusting each screen independently. Paper tokens control color/type/spacing references. Cloned geometry is not a live linked component; regeneration or a batched node update is required after a structural component change.
4. Review rendered screens, including content fit, native safe areas, keyboard, accessibility text, light/dark, and Reduce Transparency. Record the scope in [Verification](../delivery/verification.md). A static design pass does not establish native behavior or performance.

## Foundations ownership

Foundations contains reusable tokens, type/spacing/shape rules, the labelled app-icon catalog, native navigation/control primitives and generic component states. Full phone screens and feature-specific journeys, menus, feeds and accessibility examples belong to V1/V2 reference areas. Preserve registered primitive IDs when moving product examples; update their page ownership and links rather than inventing canonical routes. A feature-specific reusable component is documented in Components, but its complete product walkthrough is not a foundation.

## Native controls

Use system navigation, TabView/UITabBarController, toolbar Button/Menu, searchable/UISearchController, grouped forms, sheets, alerts, Photos picker, share sheet, and date pickers. Allow the OS to supply Liquid Glass and scroll-edge behavior. The Paper representation is a visual reference, not instructions to implement a custom glass tab bar.

Keep Add and search in the relevant toolbar. V1 search is local Pieces/Outfits/Themes; Planner keeps its local date/agenda controls. V2 search exposes its owner/community scope, clear, cancel, loading and no-result behavior; focusing it accommodates the system keyboard. Group related toolbar actions and keep destructive actions in their relevant menu or confirmation. Provide labels for every icon button and at least 44-point targets.

Both phases use five equal-width icon-only native slots with destination accessibility names: Home · Closet · Planner · Agent · Profile, full nonoverlapping hit areas of at least 44 × 44 pt. Closet has only Pieces / Outfits / Themes; Planner is its own root (Week default, Month alternate). Home plan links and outfit Plan actions retain date context, and Back restores origin/selection. Agent's fourth-slot launch presents a native full-screen task; dismissal restores origin, scroll and accessibility focus. V1 Profile has one More toolbar icon containing Add fit, Edit profile, Style, Wear insights and Settings; remove duplicate body/toolbar entries. Its native menu restores focus and journal position on dismissal. V2 alone adds a persistent 44-point Inbox root-toolbar entry → I01 → conversation, preserving origin root/scroll/selected tab on Back and startup/incoming intents; never fabricate unread. Account controls belong in V2 Profile and never gate Planner/private core. V1 has no Inbox or online/social controls.

Use native material for navigation controls, including Back, and flat opaque semantic surfaces for editable fields, following [the control matrix](liquid-glass.md). Preserve native inline/content controls and approved Apple sign-in styling. Use SF Symbols for implementation, semantic system fonts, and operating-system adaptations. Brand tint belongs to selected controls and primary actions. Ordinary content uses opaque neutral surfaces and photographic clothing.

## State and quality rules

Native-first applies to every platform-capable control, including Toggle/Picker, alert, confirmationDialog/action sheet, Menu/contextMenu, adaptive popover/sheet, keyboard/edit menu, progress, media selection and sharing. Follow [global open states and per-page contracts](native-presentations.md). Apply AQD tint only where supported; keep OS-owned material, spacing, corner geometry, accessibility and gesture behavior.

- Preserve input and selections through loading, error, filter changes and cancellation. Distinguish saved receipts from draft content.
- Indeterminate loading uses the shared Agent circular spinner everywhere. Destructive commits use native destructive semantics with a neutral safe cancel action; do not style Delete as a blue primary action. [Components](components.md#shared-loading-indicator) defines both contracts.
- Product permissions and actual service availability control what is enabled. Reference people/counts/messages never become fake production activity.
- Native chrome and content styling have different ownership: the OS owns material geometry and animation; AQD owns semantic tint, information hierarchy, content, and action labels.
- An implementation task is complete only after its relevant build checks and rendered navigation checks pass. The design task records static review separately from device, service, security and model evidence.

For navigation, custom transitions, loading/feedback, onboarding or animation review, apply [Global motion](motion.md) and the screen assignment in [Motion coverage](motion-coverage.md). Native transitions take precedence. Define timing once in the global policy, synchronize page 00, and verify standard/Reduce Motion paths before native completion.

## Navigation exits

Use one exit per outcome: Back for pushed destinations/nested steps, leading glass Back for standalone forms and setup, Close/Done for read-only sheets, and trailing Cancel for search. Remove equivalent body dismissal actions. Keep native discard protection for unsaved edits and retain parent drafts when stepping back. See [Native presentations](native-presentations.md#one-exit-per-screen) for each existing flow.
