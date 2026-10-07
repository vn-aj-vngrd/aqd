# Native iOS handoff

Phase scope: shared native/visual rules apply to both phases. Both phases share Today · Closet · Planner · Agent · Profile as five equal-width icon-only native slots with destination accessibility names and full hit areas ≥44 × 44 pt. Full-app E/W/P/S/A/I/U routes, identity and connected states are V2 references; V2 alone adds persistent Inbox root-toolbar access. Complete private themes/planning/Agent are retained in V1. V1 uses its [dedicated local flow](v1-flow.md), with existing A33 shared under [optional native weather](weather-context.md), and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

## Native platform target · October 7, 2026

Committed specification target: **deployment iOS 18.0; build with published stable Xcode 27 / iOS 27 SDK**, selecting the latest stable maintenance release when implementation begins. [Primary research](../references/native-ios-materials.md) verifies SDK publication, the Xcode deployment range and linked API introduction metadata. Recheck distribution requirements and actual SDK declarations at implementation time. This is not build, device or baseline proof.

The complete manual core fits 18: NavigationStack/PhotosPicker/ShareLink/detents (16), proposed SwiftData/unavailable-state API (17), selected Swift Vision/new Tab API (18). Optional Foundation Models (26 + runtime eligibility), custom glass (26), and optional 27 styles do **not** raise deployment to 26/27. Physical-device model/Vision quality, weather entitlement/network and OS availability are separate capabilities.

Use actual native components: the latest SDK and running OS own automatic appearance; 18 keeps its standard native rendering. Guard custom `glassEffect`/`UIGlassEffect` at 26 and every optional 27 API, with supported baseline/opaque fallback. Never emulate 27 optics on 18. Opaque content remains opaque; no added glass wrapper around native bars, search, menus or decisions.

### Five-tab feasibility boundary

Five destination identities and icon-only intent remain. HIG recommends visible tab labels: this is an explicit AQD exception, not HIG certification. UIKit's public `UITabBarItem(title: nil, image:…, tag:…)` permits title omission and is a **route to test**, not a completed feasibility test. SwiftUI `labelsVisibility` is not documented tab-caption suppression. Verify names/selected traits, full targets, safe areas, equal-slot intent and 18/26/27 adaptation before choosing a bridge; no private subview hacks, offscreen labels or custom glass imitation. SDK-27 selection must always identify a visible/available tab, including Agent launch/return.

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

Private Today’s header is Customize Today, not Search. Closet/global owner-scoped Search still searches private owned records; V2 All/Following retains public Search over authorized community snapshots. Closet always searches owned records. Preserve the actual originating root/mode, query and scroll position; private search never changes to public scope. A toolbar search affordance preserves the five product destinations. On focus, use the native field/keyboard transition and actual keyboard-safe viewport. Field placement follows the native search API and supported OS; do not hard-code a mockup position. Cancel returns to the original content and scroll position. X07 illustrates the active state; its bottom-docked keyboard is an authored layout approximation and the actual keyboard is OS-owned.

Add and Search in Closet are related toolbar controls. Add opens native contextual choices for piece, outfit, theme, or focused assistance. Keep data actions out of a new tab. AQD's pre-existing requirement for a full-screen Agent from the fourth tab is a documented tab-model exception; validate accessibility focus and return-state restoration during implementation.

## Native acceptance matrix

Verify on the minimum supported and current target iOS versions, a compact and a large iPhone, light/dark, largest accessibility text, VoiceOver, keyboard, Reduce Motion, Reduce Transparency and Increase Contrast. Use actual OS components; a screenshot of CSS blur is insufficient.

- Tab switching and Back preserve destination, query, selection, drafts and scroll position. Planner is its own root (Week default/Month alternate); Closet segments are only Pieces/Outfits/Themes. Home plan/outfit Plan links carry date context and preserve return selection; no account gates private core.
- V2's persistent labelled 44-point Inbox root-toolbar entry opens I01 then conversations; Back restores origin root/scroll/selected tab. Startup/incoming intents preserve origin; no fake unread or V1 Inbox. Fourth-slot Agent dismissal restores origin and accessibility focus.
- Search focus/cancel, keyboard dismissal and interactive Back leave no covered controls.
- Sheets and confirmation states present from the actual trigger, dismiss command menus first, avoid stacked unrelated modals, and restore accessibility focus/selection/scroll/draft. Retained canonical confirmation IDs describe STATE references, not compulsory pushes.
- Bounded delete/archive/remove/sign-out/block/draft choices use source-anchored native action sheets/confirmationDialog, with OS-owned placement and supported cancellation. UIKit 26+ can appear inline on iPhone as well as iPad and omit visible Cancel; supported outside dismissal equals safe no-write cancellation. Never omit the anchor to force bottom geometry; independently verify SwiftUI 27 adaptation. Global local erase, replacing restore and account deletion use critical final alerts with safe Cancel and deliberate destructive action; no outside-tap confirmation. V2 YKL-0 must overlay real shared L16 after valid typed ERASE (host clone ZKW-0 / field ZL3-0), holding U09 origin, never present directly from U09. Reference geometry keeps validated input above centered YMF-0 alert; OS owns runtime layout. Forms, typed ERASE/deletion, authentication and unknown-result reconciliation stay real tasks.
- Exercise exact authorized target/count/revision changes while presented; reject stale impact and duplicate commits. Cancel/interruption leaves prior records unchanged; confirmed failure retains records/drafts, unknown completion reconciles one operation ID before retry. Verify transactional restore rollback and account access acknowledgement, not merely dialog dismissal.
- Changed L77/W31 crop exits discard only their photo recipe through Z3U-0, never the whole parent draft. Critical unsaved-loss requires substantial actual dirty diff AND unavailable draft recovery/retention (including autosave/Undo) AND no in-flight/unknown write. V1 ZAS-0 illustrates 10 unsaved date changes October 5–16; V2 XZQ-0 illustrates 12 new dated assignments/12 edited notes October 7–18, Asia/Manila. Counts are examples, not numeric global thresholds; otherwise routine action sheet or direct clean exit. Native behavior remains unverified. Test safe recording interruption without automatic microphone restart or late transcription insertion.
- Linked-publication outfit deletion must present a real [impact review](v2-coverage.md#outfit-deletion-linked-publication-review) with explicit held Keep published / Unpublish choice bound to exact post IDs/revisions in ZMA-0 before Continue ZNK-0 opens XSH-0 over retained review clone ZNN-0. Keep published ZNB-0 / Unpublish ZNF-0 are Paper reference controls, not production keys. Test Cancel preserving review, stale-scope renewal, and unknown local/public reconciliation.
- Unblock uses the selected blocked-record/account association even when identity is unavailable; no invented name/avatar and no confirmation without a resolved stable association. W07 Remove photo is direct draft mutation/YW9-0 result, not another confirmation: retain metadata/prior accepted media, disable Save until valid photo, test dirty exit separately. Memory-media cleanup occurs only after successful commit/reference checks and preserves other memories' media.
- Icon actions have spoken labels; selected and disabled states are communicated beyond color.
- Toolbar geometry and hit targets stay valid with long localized labels and larger text.
- Slow image loads, offline paging, failed saves, unavailable model/service and unknown send results retain useful work.
- Smoothness is measured with Instruments on physical hardware; motion timings in DESIGN.md are targets.

LOCAL-16 adds the [native weather acceptance](weather-context.md#native-release-acceptance): signed entitlement/service and aggregate membership capacity, weather independent of AI/account, pre-action Apple search disclosure, no location prompt for manual city, explicit one-shot When In Use/approximate/denied paths, actual forecast/place/day/timezone/DST bounds, attribution fresh/cached/light/dark/legal, cancellation/selection races, expiry/coalescing/cooldown/off purge and no wardrobe/body/photo/chat payload/background traffic. Home day never shifts to weather city; off/unavailable/manual core stays complete offline. Dynamic Type/VoiceOver announce state/source/time and restore caller focus. These are unverified acceptance targets, not device/entitlement/network passes.

## Sources

- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials): functional glass layer, regular/clear variants, content separation and system adaptations.
- [Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields): toolbar/tab/inline entry and native keyboard placement. Updated June 8, 2026.
- [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars): navigation rather than actions, labels and stable destinations.
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars): logical grouping of commands and navigation.
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass): native frameworks, navigation and search behavior.
- [glassProminent](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glassprominent): context-sensitive native prominent button style.
- [Alta](https://www.altadaily.com/): capture, owned-wardrobe styling, planning and community experience benchmark. Virtual try-on and shopping remain outside AQD's initial scope.

Apple's [Design Resources](https://developer.apple.com/design/resources/) links the official27 kit. Initial Figma retrieval403 is historical: the Apple-linked Sketch resource was subsequently inspected and six genuine27 kit images imported into authority board11H4-0, alongside two generic UIKit26.5 captures. The historical [native repair](evidence/native-dialog-repair.json) captured38 public UIKit26.5 research fixtures. The current [vector repair](evidence/native-dialog-vector-repair.json) hides all38 full-phone raster replacements, restores original editable Paper hosts/title/body/action IDs and keeps technical annotations hidden. Product confirmations and generic masters now use source-derived editable27-kit geometry with adapted copy and available System Sans-Serif; they are not exact kit/runtime pixels. SDK26.5/iOS26.5 build23F77 remains research evidence only, not SwiftUI/AQD or iOS27 runtime proof. [Provenance](../references/native-ios-dialogs.md) separates official27kit import, case-specific26.5 captures and remaining native acceptance.

Additional references: [Segmented controls](https://developer.apple.com/design/human-interface-guidelines/segmented-controls), [SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols), and [Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views).

[Native presentations](native-presentations.md) defines Closet More as a native anchored Menu popup, Add as a native bottom sheet, adaptive wide-layout popovers, editor sheets, confirmations and the full-screen Agent exception. Use native presentation ownership and safe dismissal throughout.

Every native-capable control follows the [global open-state grammar, per-page mapping and native primitive matrix](native-presentations.md). Foundations `4GB-0` contains generic critical-alert `FJ2-1` and action-sheet `ZGG-0` grammar only, not feature UI. Phase-owned [V1](v1-coverage.md#contextual-confirmation-references) and [V2](v2-coverage.md#contextual-confirmation-references) catalogs retain actual-source examples. Toggles use native switch styling without another glass effect; platform-owned keyboard, permission and share UI keep their system appearance.

## Transparency · Native iOS Foundations reference

Page `p-1-0` adds five bounded specification boards plus section header `10N9-0`, adjacent to the existing library at x40–2900, y15300 onward. They are nonroute library references, not phone journeys, controls or OS screenshots. Semantic tokens and all existing glyph/presentation masters remain untouched. [Portable evidence](evidence/native-ios-transparency.json) owns current root/node counts, API coverage, placements and visual provenance.

| Reference board | Foundation node | Ownership / provenance |
| --- | --- | --- |
| Transparent chrome versus opaque content | `10NC-0` | Structure-only OS/API slots; standard native rendering, no optical simulation |
| Critical centered alert | `10ND-0` | Explicit Cancel/destructive, rich preceding review; existing `FJ2-1` is illustrative |
| Routine adaptive choice | `10NK-0` | Actual source; UIKit 26-origin inline mechanics, legacy 18 bottom grammar; existing `ZGG-0` preserved |
| System accessibility states and core input | `10NM-0` | Opaque custom-shell fallback, contrast, motion, semantic text, focus/keyboard; state notes, not native captures |
| Product-relevant native API catalog | `10NL-0` | 25 role rows below; API metadata research, not entire SDK dump |

### App-owned feedback and native alert boundary

The current catalog has26 families: the original25 rows below plus `Label` in Foundations `10S3-0`. SwiftUI [Label](https://developer.apple.com/documentation/swiftui/label) begins at iOS14 and fits deployment18. AQD's neutral/info/success/warning/danger content variants are an app-owned style, not a native five-severity SDK or Toast. [Feedback evidence](evidence/feedback-variants.json) registers three genuine AppKit SF Symbol fixture exports and bounded static checks; these exports do not prove iOS rendering. Current catalog:45 roles/12 aliases including Customize Today; the25-family/41-role checkpoints below remain historical source evidence.

Native iOS alerts and dialogs receive no injected glyph. `dialogIcon(_:)` has iOS17 callable metadata but Apple documents no effect outside macOS/watchOS; UIKit has no documented alert icon/image API and its private hierarchy must not be modified. Keep real platform title/text/actions, no private hacks or glass replicas. See [alert policy](native-presentations.md#native-ios-alert-icon-policy).

### Complete AQD native component → API → baseline/enhancement → Foundation row

Every row supports **AQD deployment 18**. Introduction numbers describe the research-linked SwiftUI symbol/overload unless UIKit is named; an older type does not imply a newer overload back-deploys. [Research §4–5](../references/native-ios-materials.md) supplies individual Apple API URLs and availability metadata; those exact URLs are also recorded in portable evidence. Unnumbered UIKit counterparts are alternatives within the baseline, not a new unsupported minimum claim. Confirm selected declarations in the actual SDK. V2-only sign-in stays outside the manual gate.

| AQD native component | SwiftUI / UIKit | Minimum / 26–27 enhancement and fallback | Foundation row |
| --- | --- | --- | --- |
| Navigation and toolbar | NavigationStack (16), ToolbarItem / UINavigationController, UIBarButtonItem | 18 baseline; ToolbarSpacer 26; toolbarMinimizationBehavior 27 optional, ordinary toolbar fallback | `10P8-0` |
| Five destinations | TabView (13), Tab (18) / UITabBarController, UITabBarItem | 18; 26 minimization/bottom accessory optional; SDK27 visible selection; public nil-title feasibility must be tested | `10PD-0` |
| Search | searchable (15) / UISearchController, UISearchBar | 18; SDK27 UIKit center scopes inline, test localized width; native placement/Cancel | `10PH-0` |
| Actions, favorite, filters | Button (13), borderedProminent (15) / UIButton.Configuration | 18 solid/plain content; glassProminent 26 only for justified chrome, baseline fallback | `10PL-0` |
| Binary preference | Toggle (13) / UISwitch | 18; native appearance, no added glass and no job-as-switch | `10PP-0` |
| One/several choices, packing | Picker/segmented (13), List selection / UISegmentedControl, selectable UITableView/UICollectionView rows | 18 checked/selected traits; TabsPickerStyle 27 optional, ordinary segmented fallback; no universal iOS radio/checkbox drawing mandate | `10PT-0` |
| Date/calendar | DatePicker (13), graphical (14), MultiDatePicker (16) / UIDatePicker, UICalendarView (16) | 18; calendar/locale/date-only timezone; custom week/agenda content retained, no automatic Save | `10PX-0` |
| Forms/lists/scroll | Form, List, ScrollView (13) / grouped UITableView, UIScrollView | 18; opaque content, native scroll/safe-area behavior; no glass-per-row | `10Q1-0` |
| Critical alert | linked alert overload (16) / UIAlertController .alert (8) | 18; explicit Cancel + destructive; native appearance, typed/rich review remains prior task; no custom material | `10Q5-0` |
| Routine intentional choice | linked confirmationDialog overload (16) / UIAlertController .actionSheet (8) | 18; actual source anchor; UIKit26+ inline iPhone/iPad may omit Cancel; supported no-write outside cancellation | `10Q9-0` |
| Command menus | Menu (14), contextMenu / UIMenu, UIAction, UIContextMenuInteraction | 18; selected/disabled/destructive; SDK27 iPad menu-bar image policy not universal iPhone removal | `10QD-0` |
| Rich editor/review sheet | sheet (13), detents (16), interactiveDismissDisabled (15) / UISheetPresentationController (15) | 18; Form + native navigation, dirty protection; delegate for dismissal-attempt callback, full-height opacity system-owned | `10QH-0` |
| Inspector/popover | popover (13) / UIPopoverPresentationController | 18; source anchor and compact adaptation, not fixed desktop geometry | `10QL-0` |
| Focused Agent/task | fullScreenCover (14) / modal full-screen UIViewController | 18; valid visible tab selection, originating stack/draft/focus return | `10QP-0` |
| Progress | ProgressView (14) / UIActivityIndicatorView, UIProgressView | 18; indeterminate vs actual measured progress, prevent duplicate commits; unknown completion reconciles | `10QT-0` |
| Short/secure input | TextField, SecureField (13), axis initializer (16) / UITextField (2) | 18 opaque shell/native content type/autofill; TextInputBorderShape 27 optional, no required new border | `10QX-0` |
| Long input, keyboard/accessory/edit menu | TextEditor (14), FocusState/safeAreaInset (15) / UITextView (2), inputAccessoryView (3.2), UIInputView (7), UIEditMenuInteraction (16) | 18 native editing/focus; SDK27 interactive Text selection and presentation environment reset require gesture/style review; retain draft | `10R1-0` |
| Selected Photos | PhotosPicker (16) / PHPickerViewController (14) | 18; authorized selection/load/copy, no-write Cancel, retained failed draft | `10R5-0` |
| Camera/permission | UIImagePickerController (UIKit 2), OS permission prompts | 18; availability/denial/interruption/manual recovery, not fake OS chrome | `10R9-0` |
| Files import/export | linked fileImporter/fileExporter overloads (14) / UIDocumentPickerViewController | 18; security-scoped access, ready archive/staged restore; new27 async document APIs optional, supported baseline retained | `10RD-0` |
| Share | ShareLink (16) / UIActivityViewController (6) | 18; prepared authorized file/URL + iPad anchor; dismiss does not save/publish | `10RH-0` |
| Unavailable and optional tips | ContentUnavailableView, TipKit.Tip (17) / UIContentUnavailableConfiguration, TipUIView | 18; truthful empty/offline/denied/model state and manual recovery; TipKit optional, tour unchanged | `10RL-0` |
| Appearance/type/accessibility/symbols | ColorScheme/Font/accessibility environments (13) / UIColor, UIFontMetrics, UIAccessibility, SF Symbols | 18; semantic Dynamic Type, Light/Dark, contrast/transparency/motion, VoiceOver/selected traits; 41 masters/12 aliases preserved | `10RP-0` |
| Custom functional material | Material (15), glassEffect/GlassEffectContainer (26) / UIVisualEffectView (8), UIGlassEffect (26) | 18 standard Material or opaque shell; guard custom glass26, never wrap native component | `10RT-0` |
| V2 official Apple sign-in | SignInWithAppleButton / AuthenticationServices | Within 18 baseline; approved native logo/style, not redraw; no V1 account gate | `10RX-0` |

SDK27-specific acceptance additionally checks UIKit scene lifecycle/launch-screen configuration, native menu image policy, visible TabView selection, Text selection conflicts and sheet/popover environment reset. Optional 27 styles/minimization/document conveniences require guards; they do not approve new features or routes. Exact licensed kit inspection/runtime render and physical-device performance remain outstanding.

## Agent input acceptance

A34–A55 and [Agent input](agent-input.md) add native multiline editing, one-time autofocus, keyboard-safe docking, selected-media/file/camera flows, private closet context and reviewed on-device dictation targets. Test real denial/cancel/interruption, unavailable image/speech capability, retained drafts, attachment readiness, explicit Send, Stop acknowledgement and scrolled-up streaming. Verify the status-label shimmer and static Reduce Motion/VoiceOver variants. OS keyboard/media/permission surfaces are static approximations in Paper; no native build or runtime validation was performed.
