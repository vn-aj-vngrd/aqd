# Native Liquid Glass controls

Phase scope: shared native/visual rules apply to both phases. Five-destination base navigation applies to both phases. Full-app E/W/P/S/A/I/U routes, online identity and connected states are V2 references. Complete private themes/planning/Agent are retained in V1. V1 uses only its [dedicated local flow](v1-flow.md) and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

Design refinement, October 1, 2026. [Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) remains the visual source. The supplied ChatGPT screenshots guide the floating composer, capsule controls and anchored menu treatment; they do not establish which private implementation APIs ChatGPT uses.

## Current native target and transparency boundary

[Native iOS](native-ios.md#native-platform-target--october-7-2026) owns deployment/build targets, overload-specific API guards and feasibility acceptance; [primary research](../references/native-ios-materials.md) owns dated publication evidence. This document owns material-role selection. Running OS native appearance and older/opaque fallback remain mandatory; optional model readiness never raises the manual minimum.

Foundations **Transparency · Native iOS** (`10N9-0`) adds role/API reference boards and a [complete native catalog](native-ios.md#complete-aqd-native-component--api--baselineenhancement--foundation-row). Official27 kit resources were inspected/imported; [source repair](evidence/native-dialog-repair.json) and [editable adaptations](evidence/native-dialog-vector-repair.json) own provenance. AQD/SwiftUI/native27 runtime remains unverified. Existing alpha/blur/geometry drawings are illustrative, not rendering instructions. Critical alerts remain native `.alert` with explicit Cancel/destructive; routine source-anchored choices adapt inline on UIKit26+ iPhone/iPad and may omit visible Cancel. Do not force bottom placement or simulate27 optics. All existing phase scenes/control positions and master IDs stay unchanged.

## Control matrix

| Role | V2 native choice | Paper reference / state contract |
| --- | --- | --- |
| Back | System NavigationStack/UINavigationController Back | Glass capsule/circle; retain native back label, history, swipe gesture and restored focus. Never add a duplicate custom Back. |
| Toolbar icon/text actions | Native ToolbarItem/Button/Menu | Regular glass, 44 pt minimum target; labeled SF Symbol. Native grouping owns shared material. |
| Tab bar | TabView/UITabBarController | Native material, named destinations and restored stacks. Avoid custom blur behind an already native glass tab bar. |
| Segmented view | Native segmented Picker/UISegmentedControl | Compact flat reference: neutral track, one opaque selected segment and announced state. Use native segmented behavior without nested custom glass. |
| Primary content action | Native Button / UIButton with solid semantic accent | Flat 50 pt reference, medium label, readable foreground, preserved width/label during progress and genuine disabled state; no decorative blur or shadow. |
| Secondary content action | Native Button with plain content style | Regular-weight action-text label and ≥44 pt target; no border, fill, blur or shadow, except approved flat soft Back/View outfit capsules. |
| Filter action | Native Button with compact flat content style | 32 pt visual, semantic ink and check/fill/selected trait; nonoverlapping ≥44 pt native target. No decorative glass. |
| Every editable input | Native TextField/TextEditor inside one opaque semantic surface shell | Flat 16 pt field shell without decorative border, blur or shadow; persistent label, native focus/keyboard/autofill/selection, validation outside the field. Inner editor has no second glass background. Read-only values remain content. |
| Search | searchable/UISearchController | System glass field, clear/cancel, retained scope/query and keyboard-aware placement. Do not wrap an already glass system search field again. |
| Agent/Inbox/comment composer | Native editor + one glass shell + native Send/Stop | Rounded multiline shell; bounded growth, keyboard safe-area inset, 44 pt Send/Stop, retained failed drafts. No duplicated shell material. |
| Context menu/popover | Native Menu/context menu/popover | Anchor to the source, native material and shape, dismissal and focus restoration. Destructive actions keep system roles. |
| Sheet/alert/dialog | Native presentation | Let the OS own presentation chrome/material, detents and background treatment. Form/content surfaces remain readable. Do not turn the entire screen into transparent glass. |
| Inline reactions, links, disclosure rows, calendar/switch/checkbox | Appropriate native content control | Native plain/content style where that is the system convention; interactive bounds and selected/disabled traits still apply. |
| Sign in with Apple and OS pickers/share UI | Official native control/presentation | Preserve approved appearance and OS behavior. No custom glass replacement. |

## Material and accessibility

Use regular glass by default only for the navigation, search, presentation and scoped composer roles above. Ordinary fields, content actions and compact selection controls follow the flat semantic-surface contract. Clear is reserved for floating controls over rich media when contrast remains readable. Native variants, tint and interactive behavior are the supported design decisions; do not treat whole-view opacity as a native material transparency setting. Paper alpha/blur/edge/shadow tokens are static approximations, not runtime rendering instructions or a universal opacity slider.

The OS adapts to light/dark appearance, Reduce Transparency and Increase Contrast. For app-owned custom shells, provide an opaque semantic surface retaining intent and usable content when transparency is reduced; let native components own their own fallback geometry; stronger boundaries and validation text must remain visible. Keep 44 pt targets, native Dynamic Type, selected/disabled traits and focus order. Group adjacent custom effects with GlassEffectContainer where appropriate. Never apply a second glass modifier to native glass chrome or nest a glass editor background within the composer's glass shell. A native control inside that shell retains its own standard system rendering.

Photographs, wardrobe grids, message bubbles, notices, Markdown responses, review summaries and ordinary grouped content keep their content surfaces. Glass identifies system navigation/presentation chrome and the scoped composer, not every functional control or container.

## Audit and changes

Historical October 1 material pass, superseded for ordinary fields/content actions/filters by the October 6 flat-control decisions in [DESIGN.md](../../DESIGN.md). Counts below describe that earlier checkpoint, not current prescriptions.

Inspected all 226 artboards across ten Paper pages, including 179 canonical screen contracts, component masters, appearance references and V2 flow copies. Applied the shared material reference to 350 navigation/toolbar instances, 97 field/search/comment input shells, 25 composers, 429 standalone/filter actions, 72 tab/segmented containers and two menu references. Send/Stop controls and compact dashboard action shapes were synchronized too. Existing V2 reference screens received visual consistency only; release scope is unchanged.

Reviewed representative new-piece inputs, Agent dark composer/Back, Closet toolbar/tabs/menu, review actions and Reduce Transparency. Corrected dark Back surfaces after the first review. Geometry and routes remain intact. No app code, native build, device rendering, interaction or accessibility runtime validation is implied. No screenshot files were saved.

## Native acceptance before implementation is complete

- Verify actual system material on supported iOS versions; Paper cannot simulate refraction, native interaction or system transparency adaptation.
- Check compact/large iPhone, light/dark, largest accessibility text, Reduce Transparency, Increase Contrast and VoiceOver.
- Keep Back swipe/history, toolbar grouping, menu/popover focus restoration, keyboard insets and draft preservation.
- Test field focus, editing, validation, autofill and multiline growth; disabled/pending controls remain legible and prevent duplicate actions.
- Check performance and scrolling on a physical device; avoid duplicate materials and excessive custom effect layers.

## Apple references

- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) — system components and native adoption.
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views) — glass effects, native button styles and containers.
- [Glass variants](https://developer.apple.com/documentation/swiftui/glass) — regular and clear material choices.
- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials) — functional layer, contrast and system adaptations.

[Native presentations](native-presentations.md) defines Closet More as a native anchored Menu popup, Add as a native bottom sheet, adaptive wide-layout popovers, editor sheets, confirmations and the full-screen Agent exception. Use native presentation ownership and safe dismissal throughout.

## Navigation consistency follow-up · October 1, 2026

A structural pass across all 227 artboards found generic Frame headers missed by the earlier name-based classification. Checked 215 Back controls; corrected 35 bare shells across Home, Closet search and V2 copies. Wrapped 13 bare toolbar Cancel actions in the shared neutral regular-glass control and synchronized 18 outlined search shells, including the component references and walkthrough. Named navigation headers/Back/search layers consistently to make later audits easier. All checked Back and Cancel controls retain 44-point height; content disclosure chevrons remain plain. Native behavior remains a separate implementation check.

## Agent input material refinement · October 2, 2026

The rich Agent composer has one regular native glass shell, a transparent multiline editor, attachment rail and neutral child controls; only a valid Send or active Stop is prominent. Context/photo/voice sheets and anchored menus use native presentation material. Response prose stays on the ordinary surface. A51 shows opaque neutral equivalents with no blur; A52 demonstrates expanded text and editor. Canonical input instances, D02 and the response/input masters share the updated geometry. See [Agent input](agent-input.md). Static Paper material is illustrative; native optics/focus/keyboard remain unverified.
