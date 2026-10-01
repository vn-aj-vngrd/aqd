# Applying the AQD design

Read [DESIGN.md](../DESIGN.md) before adding a screen, changing a shared control, selecting an icon, or reviewing an interface. It is the authority for the intended app; the old prototype is migration evidence.

## Design workflow

1. Locate the route in [the screen map](design/SCREENS.md) and its Paper artboard. Read the relevant feature specification for access and data behavior.
2. Reuse the logical component in [COMPONENTS.md](COMPONENTS.md). Change visual tokens and component masters in Paper page 00, then update affected Paper screen instances. Do not recreate a parallel local design gallery or renderer.
3. Apply shared changes across the affected Paper nodes, rather than adjusting each screen independently. Paper tokens control color/type/spacing references. Cloned geometry is not a live linked component; regeneration or a batched node update is required after a structural component change.
4. Review rendered screens, including content fit, native safe areas, keyboard, accessibility text, light/dark, and Reduce Transparency. Record the scope in [VERIFICATION.md](VERIFICATION.md). A static design pass does not establish native behavior or performance.

## Native controls

Use system navigation, TabView/UITabBarController, toolbar Button/Menu, searchable/UISearchController, grouped forms, sheets, alerts, Photos picker, share sheet, and date pickers. Allow the OS to supply Liquid Glass and scroll-edge behavior. The Paper representation is a visual reference, not instructions to implement a custom glass tab bar.

Keep Add and search in the relevant toolbar. Search exposes its owner/community scope, clear, cancel, loading and no-result behavior; focusing it accommodates the system keyboard. Group related toolbar actions and keep destructive actions in their relevant menu or confirmation. Provide labels for every icon button and at least 44-point targets.

Home, Closet, Agent, Inbox, Profile remain the five product destinations. Native tab labels are visible in the redesign. The full-screen center Agent entry is an explicit exception to the usual persistent-tab model; verify selection restoration and accessibility focus. Account controls belong in Profile.

Use native glass for functional controls, including Back and every editable input shell, following [the control matrix](design/LIQUID-GLASS.md). Preserve native inline/content controls and approved Apple sign-in styling. Use SF Symbols for implementation, semantic system fonts, and operating-system adaptations. Brand tint belongs to selected controls and primary actions. Ordinary content uses opaque neutral surfaces and photographic clothing.

## State and quality rules

Native-first applies to every platform-capable control, including Toggle/Picker, alert, confirmationDialog/action sheet, Menu/contextMenu, adaptive popover/sheet, keyboard/edit menu, progress, media selection and sharing. Follow [global open states and per-page contracts](design/NATIVE-PRESENTATIONS.md). Apply AQD tint only where supported; keep OS-owned material, spacing, corner geometry, accessibility and gesture behavior.

- Preserve input and selections through loading, error, filter changes and cancellation. Distinguish saved receipts from draft content.
- Indeterminate loading uses the shared Agent circular spinner everywhere. Destructive commits use native destructive semantics with a neutral safe cancel action; do not style Delete as a green primary action. [Components](COMPONENTS.md#shared-loading-indicator) defines both contracts.
- Product permissions and actual service availability control what is enabled. Reference people/counts/messages never become fake production activity.
- Native chrome and content styling have different ownership: the OS owns material geometry and animation; AQD owns semantic tint, information hierarchy, content, and action labels.
- An implementation task is complete only after its relevant build checks and rendered navigation checks pass. The design task records static review separately from device, service, security and model evidence.

For navigation, custom transitions, loading/feedback, onboarding or animation review, apply [Global motion](design/MOTION.md) and the screen assignment in [Motion coverage](design/MOTION-COVERAGE.md). Native transitions take precedence. Define timing once in the global policy, synchronize page 00, and verify standard/Reduce Motion paths before native completion.

## Navigation exits

Use one exit per outcome: Back for pushed destinations/nested steps, leading glass Back for standalone forms and setup, Close/Done for read-only sheets, and trailing Cancel for search. Remove equivalent body dismissal actions. Keep native discard protection for unsaved edits and retain parent drafts when stepping back. See [Native presentations](design/NATIVE-PRESENTATIONS.md#one-exit-per-screen) for each existing flow.
