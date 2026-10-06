# Native iOS handoff

Phase scope: shared native/visual rules apply to both phases. Both phases share Home · Closet · Planner · Agent · Profile as five equal-width native slots with visible labels and full hit areas ≥44 × 44 pt. Full-app E/W/P/S/A/I/U routes, identity and connected states are V2 references; V2 alone adds persistent Inbox root-toolbar access. Complete private themes/planning/Agent are retained in V1. V1 uses only its [dedicated local flow](v1-flow.md) and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

Research checked October 1, 2026 against Apple's current documentation. This is an implementation contract for the redesign, not proof that the existing app adopts it.

## Component selection

| Design role | Use | Behavior to verify |
| --- | --- | --- |
| Destinations | `TabView` / `UITabBarController` | Named tabs, selected state, restored per-tab stack, automatic material, scroll minimization only where appropriate. |
| Screen navigation | `NavigationStack` / `UINavigationController` | System Back gesture/title, large-to-inline title collapse, native scroll-edge treatment. |
| Search | `searchable` / `UISearchController` | Scoped prompt, clear/cancel, focus, keyboard-aware position, search suggestions and retained query. |
| Add and icon controls | `ToolbarItem`, `Button`, `Menu` / `UIBarButtonItem` | Native glass grouping, SF Symbols, 44-point minimum interaction area, accessible labels. |
| Context actions | `Menu` / context menu | Actions anchored to source; avoid duplicate custom overflow UI. |
| Primary action | Standard `Button` / `UIButton` | AQD tint; standalone primary actions use `.glassProminent`, standalone secondary actions use `.glass`. Inline content actions keep native plain styles. |
| Modal editing | `sheet` and presentation detents | Grabber when resizable, sensible height, swipe-dismiss with dirty-draft protection, restored focus. |
| Destructive choices | Native alert / `confirmationDialog` | Explicit target and impact; system destructive role; cancel is safe. |
| Data entry | Form, TextField, Picker, Toggle | Native keyboard, autofill/content type, focus order, dynamic rows, inline validation. Every editable field has one regular-glass functional shell; do not layer glass on the inner editor. |
| Dates | Native date picker + accessible agenda | Date-only semantics in plan timezone; preserve intent across device-zone changes. |
| Media and sharing | PhotosPicker/PHPicker, camera UI, ShareLink/UIActivityViewController | Request only selected media, correct cancel/denied paths, file availability before share. |
| Sign in with Apple | `SignInWithAppleButton` | Official label, logo and permitted native style. The generic Paper button is an intent reference, not the production Apple control. |
| Segmented views | Picker with segmented style / UISegmentedControl | OS-owned glass selection, selected trait, system Reduce Transparency and Increase Contrast adaptations; no custom nested glass. |
| Filter rail | Horizontal ScrollView with native buttons | No wrap, 44 pt targets, conditional trailing scroll-edge cue, RTL and selected-item visibility. |
| Symbols | SF Symbols | Symbol appropriate to action, consistent rendering/weight, localized accessibility name. |

## Liquid Glass decisions

Use regular native Liquid Glass for navigation, Back, standalone actions, filters, every editable input shell and floating composers. Leave the content layer opaque. Use clear only over rich media where content remains legible. Native Back, menus, popovers, tabs, search and sheet chrome keep their system-owned material; do not add another glass layer. For an input without automatic native glass, apply one glass effect to its shell, preserving a transparent native editor inside. Group adjacent custom effects with GlassEffectContainer where needed. Let system Reduce Transparency, Increase Contrast and appearance adapt controls. Regular/clear variants and tint are native choices; alpha in Paper is illustrative, not a portable material transparency percentage. See [control audit](liquid-glass.md).

Search is scoped: Home searches the public community; Closet searches owned records. A toolbar search affordance preserves the five product destinations. On focus, use the native field/keyboard transition and actual keyboard-safe viewport. Field placement follows the native search API and supported OS; do not hard-code a mockup position. Cancel returns to the original content and scroll position. X07 illustrates the active state; its bottom-docked keyboard is an authored layout approximation and the actual keyboard is OS-owned.

Add and Search in Closet are related toolbar controls. Add opens native contextual choices for piece, outfit, theme, or focused assistance. Keep data actions out of a new tab. AQD's pre-existing requirement for a full-screen Agent from the fourth tab is a documented tab-model exception; validate accessibility focus and return-state restoration during implementation.

## Native acceptance matrix

Verify on the minimum supported and current target iOS versions, a compact and a large iPhone, light/dark, largest accessibility text, VoiceOver, keyboard, Reduce Motion, Reduce Transparency and Increase Contrast. Use actual OS components; a screenshot of CSS blur is insufficient.

- Tab switching and Back preserve destination, query, selection, drafts and scroll position. Planner is its own root (Week default/Month alternate); Closet segments are only Pieces/Outfits/Themes. Home plan/outfit Plan links carry date context and preserve return selection; no account gates private core.
- V2's persistent labelled 44-point Inbox root-toolbar entry opens I01 then conversations; Back restores origin root/scroll/selected tab. Startup/incoming intents preserve origin; no fake unread or V1 Inbox. Fourth-slot Agent dismissal restores origin and accessibility focus.
- Search focus/cancel, keyboard dismissal and interactive Back leave no covered controls.
- Sheets present from the correct trigger, avoid stacked unrelated modals, and return accessibility focus.
- Icon actions have spoken labels; selected and disabled states are communicated beyond color.
- Toolbar geometry and hit targets stay valid with long localized labels and larger text.
- Slow image loads, offline paging, failed saves, unavailable model/service and unknown send results retain useful work.
- Smoothness is measured with Instruments on physical hardware; motion timings in DESIGN.md are targets.

## Sources

- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials): functional glass layer, regular/clear variants, content separation and system adaptations.
- [Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields): toolbar/tab/inline entry and native keyboard placement. Updated June 8, 2026.
- [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars): navigation rather than actions, labels and stable destinations.
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars): logical grouping of commands and navigation.
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass): native frameworks, navigation and search behavior.
- [glassProminent](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glassprominent): context-sensitive native prominent button style.
- [Alta](https://www.altadaily.com/): capture, owned-wardrobe styling, planning and community experience benchmark. Virtual try-on and shopping remain outside AQD's initial scope.

Apple’s official [iOS and iPadOS 27 Figma kit](https://www.figma.com/community/file/1651309003795292092/ios-and-ipados-27) listing was verified October 1, 2026. It identifies a September 15, 2026 update for Liquid Glass, layout, sidebar colors and scroll-edge effects. Use its components as visual references; this pass reviewed the listing, not a full imported component library. Native API/deployment availability must still be checked against the selected SDK.

Additional references: [Segmented controls](https://developer.apple.com/design/human-interface-guidelines/segmented-controls), [SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols), and [Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views).

[Native presentations](native-presentations.md) defines Closet More as a native anchored Menu popup, Add as a native bottom sheet, adaptive wide-layout popovers, editor sheets, confirmations and the full-screen Agent exception. Use native presentation ownership and safe dismissal throughout.

Every native-capable control follows the [global open-state grammar, per-page mapping and native primitive matrix](native-presentations.md). Page 00 contains the shared references. Toggles use native switch styling without another glass effect; platform-owned keyboard, permission and share UI keep their system appearance.

## Agent input acceptance

A34–A55 and [Agent input](agent-input.md) add native multiline editing, one-time autofocus, keyboard-safe docking, selected-media/file/camera flows, private closet context and reviewed on-device dictation targets. Test real denial/cancel/interruption, unavailable image/speech capability, retained drafts, attachment readiness, explicit Send, Stop acknowledgement and scrolled-up streaming. Verify the status-label shimmer and static Reduce Motion/VoiceOver variants. OS keyboard/media/permission surfaces are static approximations in Paper; no native build or runtime validation was performed.
