# Native iOS handoff

Phase scope: shared native/visual rules apply to both phases. Both phases share Home · Closet · Planner · Agent · Profile as five equal-width icon-only native slots with destination accessibility names and full hit areas ≥44 × 44 pt. Full-app E/W/P/S/A/I/U routes, identity and connected states are V2 references; V2 alone adds persistent Inbox root-toolbar access. Complete private themes/planning/Agent are retained in V1. V1 uses only its [dedicated local flow](v1-flow.md) and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

Research checked October 1, 2026 against Apple's current documentation. This is an implementation contract for the redesign, not proof that the existing app adopts it.

## Component selection

| Design role | Use | Behavior to verify |
| --- | --- | --- |
| Destinations | `TabView` / `UITabBarController` | Named tabs, selected state, restored per-tab stack, automatic material, scroll minimization only where appropriate. |
| Screen navigation | `NavigationStack` / `UINavigationController` | System Back gesture/title, large-to-inline title collapse, native scroll-edge treatment. |
| Search | `searchable` / `UISearchController` | Scoped prompt, clear/cancel, focus, keyboard-aware position, search suggestions and retained query. |
| Add and icon controls | `ToolbarItem`, `Button`, `Menu` / `UIBarButtonItem` | Native glass grouping, SF Symbols, 44-point minimum interaction area, accessible labels. |
| Context actions | `Menu` / context menu | Actions anchored to source; avoid duplicate custom overflow UI. |
| Primary action | Standard `Button` / `UIButton` | Solid semantic accent for primary content actions; plain regular-weight action-text for secondary content actions, without decorative glass, border or shadow. Navigation/toolbar chrome remains system-owned. |
| Modal editing | `sheet` and presentation detents | Grabber when resizable, sensible height, swipe-dismiss with dirty-draft protection, restored focus. |
| Destructive choices | `confirmationDialog` / UIKit action sheet for intentional bounded choices; native alert for critical final loss | Contextual overlay on actual caller, never a pushed confirmation screen. Exact target/revision/impact; safe Cancel preserves source/draft. Device/size-class adaptation and permitted dismissal are OS-owned. Keep typed/impact/auth reviews as real tasks. See [risk policy](native-presentations.md#confirmation-states-not-pushed-screens). |
| Data entry | Form, TextField, Picker, Toggle | Native keyboard, autofill/content type, focus order, dynamic rows, inline validation. Ordinary editable fields use one opaque semantic surface shell, 16-point corners and 14-point padding, without decorative blur, shadow or border. Preserve native focus and validation. Search and floating composers retain their explicitly scoped native material. |
| Dates | Native date picker + accessible agenda | Date-only semantics in plan timezone; preserve intent across device-zone changes. |
| Media and sharing | PhotosPicker/PHPicker, camera UI, ShareLink/UIActivityViewController | Request only selected media, correct cancel/denied paths, file availability before share. |
| Sign in with Apple | `SignInWithAppleButton` | Official label, logo and permitted native style. The generic Paper button is an intent reference, not the production Apple control. |
| Segmented views | Picker with segmented style / UISegmentedControl | Native selection behavior and selected trait; flat reference with 36-point track, 2-point inset and one 32-point opaque selected pill with medium label. Preserve system accessibility adaptations; no nested custom glass. |
| Filter rail | Horizontal ScrollView with native buttons | No wrap, 44 pt targets, conditional trailing scroll-edge cue, RTL and selected-item visibility. |
| Symbols | SF Symbols | Symbol appropriate to action, consistent rendering/weight, localized accessibility name. |

## Liquid Glass decisions

Use system-owned Liquid Glass for navigation, Back, menus, popovers, tabs, search, presentation chrome and the explicitly scoped floating composer. Ordinary content stays opaque: solid accent primary actions, plain secondary actions, flat compact filters/segments and opaque field shells. Do not apply custom glass to those content roles or add a second layer to native chrome. Clear is reserved for floating controls over rich media when legible. Composer editors remain transparent within their one material shell; group adjacent custom effects only where needed. Let system Reduce Transparency, Increase Contrast and appearance adapt controls. Regular/clear variants and tint are native choices; alpha in Paper is illustrative, not a portable material transparency percentage. See [control audit](liquid-glass.md).

Search is scoped by phase and Home mode: V1 Home and V2 Today search private owned Closet records; V2 All/Following search public community snapshots. Closet always searches owned records. Preserve the actual originating root/mode, query and scroll position; private search never changes to public scope. A toolbar search affordance preserves the five product destinations. On focus, use the native field/keyboard transition and actual keyboard-safe viewport. Field placement follows the native search API and supported OS; do not hard-code a mockup position. Cancel returns to the original content and scroll position. X07 illustrates the active state; its bottom-docked keyboard is an authored layout approximation and the actual keyboard is OS-owned.

Add and Search in Closet are related toolbar controls. Add opens native contextual choices for piece, outfit, theme, or focused assistance. Keep data actions out of a new tab. AQD's pre-existing requirement for a full-screen Agent from the fourth tab is a documented tab-model exception; validate accessibility focus and return-state restoration during implementation.

## Native acceptance matrix

Verify on the minimum supported and current target iOS versions, a compact and a large iPhone, light/dark, largest accessibility text, VoiceOver, keyboard, Reduce Motion, Reduce Transparency and Increase Contrast. Use actual OS components; a screenshot of CSS blur is insufficient.

- Tab switching and Back preserve destination, query, selection, drafts and scroll position. Planner is its own root (Week default/Month alternate); Closet segments are only Pieces/Outfits/Themes. Home plan/outfit Plan links carry date context and preserve return selection; no account gates private core.
- V2's persistent labelled 44-point Inbox root-toolbar entry opens I01 then conversations; Back restores origin root/scroll/selected tab. Startup/incoming intents preserve origin; no fake unread or V1 Inbox. Fourth-slot Agent dismissal restores origin and accessibility focus.
- Search focus/cancel, keyboard dismissal and interactive Back leave no covered controls.
- Sheets and confirmation states present from the actual trigger, dismiss command menus first, avoid stacked unrelated modals, and restore accessibility focus/selection/scroll/draft. Retained canonical confirmation IDs describe STATE references, not compulsory pushes.
- Bounded delete/archive/remove/sign-out/block/draft choices use native action sheets (adaptive popover where appropriate), separate Cancel group and supported system dismissal = Cancel. Global local erase, replacing restore and account deletion use critical final alerts with safe Cancel and deliberate destructive action; no outside-tap confirmation. V2 YKL-0 must overlay real shared L16 after valid typed ERASE (host clone ZKW-0 / field ZL3-0), holding U09 origin, never present directly from U09. Reference geometry keeps validated input above centered YMF-0 alert; OS owns runtime layout. Forms, typed ERASE/deletion, authentication and unknown-result reconciliation stay real tasks.
- Exercise exact authorized target/count/revision changes while presented; reject stale impact and duplicate commits. Cancel/interruption leaves prior records unchanged; confirmed failure retains records/drafts, unknown completion reconciles one operation ID before retry. Verify transactional restore rollback and account access acknowledgement, not merely dialog dismissal.
- Changed L77/W31 crop exits discard only their photo recipe through Z3U-0, never the whole parent draft. Critical unsaved-loss requires substantial actual dirty diff AND unavailable draft recovery/retention (including autosave/Undo) AND no in-flight/unknown write. V1 ZAS-0 illustrates 10 unsaved date changes October 5–16; V2 XZQ-0 illustrates 12 new dated assignments/12 edited notes October 7–18, Asia/Manila. Counts are examples, not numeric global thresholds; otherwise routine action sheet or direct clean exit. Native behavior remains unverified. Test safe recording interruption without automatic microphone restart or late transcription insertion.
- Linked-publication outfit deletion must present a real [impact review](v2-coverage.md#outfit-deletion-linked-publication-review) with explicit held Keep published / Unpublish choice bound to exact post IDs/revisions in ZMA-0 before Continue ZNK-0 opens XSH-0 over retained review clone ZNN-0. Keep published ZNB-0 / Unpublish ZNF-0 are Paper reference controls, not production keys. Test Cancel preserving review, stale-scope renewal, and unknown local/public reconciliation.
- Unblock uses the selected blocked-record/account association even when identity is unavailable; no invented name/avatar and no confirmation without a resolved stable association. W07 Remove photo is direct draft mutation/YW9-0 result, not another confirmation: retain metadata/prior accepted media, disable Save until valid photo, test dirty exit separately. Memory-media cleanup occurs only after successful commit/reference checks and preserves other memories' media.
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

Every native-capable control follows the [global open-state grammar, per-page mapping and native primitive matrix](native-presentations.md). Foundations `4GB-0` contains generic critical-alert `FJ2-1` and action-sheet `ZGG-0` grammar only, not feature UI. Phase-owned [V1](v1-coverage.md#contextual-confirmation-references) and [V2](v2-coverage.md#contextual-confirmation-references) catalogs retain actual-source examples. Toggles use native switch styling without another glass effect; platform-owned keyboard, permission and share UI keep their system appearance.

## Agent input acceptance

A34–A55 and [Agent input](agent-input.md) add native multiline editing, one-time autofocus, keyboard-safe docking, selected-media/file/camera flows, private closet context and reviewed on-device dictation targets. Test real denial/cancel/interruption, unavailable image/speech capability, retained drafts, attachment readiness, explicit Send, Stop acknowledgement and scrolled-up streaming. Verify the status-label shimmer and static Reduce Motion/VoiceOver variants. OS keyboard/media/permission surfaces are static approximations in Paper; no native build or runtime validation was performed.
