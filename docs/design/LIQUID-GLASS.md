# Native Liquid Glass controls

Design refinement, October 1, 2026. [Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) remains the visual source. The supplied ChatGPT screenshots guide the floating composer, capsule controls and anchored menu treatment; they do not establish which private implementation APIs ChatGPT uses.

## Control matrix

| Role | V1 native choice | Paper reference / state contract |
| --- | --- | --- |
| Back | System NavigationStack/UINavigationController Back | Glass capsule/circle; retain native back label, history, swipe gesture and restored focus. Never add a duplicate custom Back. |
| Toolbar icon/text actions | Native ToolbarItem/Button/Menu | Regular glass, 44 pt minimum target; labeled SF Symbol. Native grouping owns shared material. |
| Tab bar | TabView/UITabBarController | Native material, named destinations and restored stacks. Avoid custom blur behind an already native glass tab bar. |
| Segmented view | Native segmented Picker/UISegmentedControl | Native selection lens; neutral track, one selected segment and announced state. |
| Standalone primary action | Native Button with glassProminent | AQD tint, readable foreground, preserved width/label during progress and genuine disabled state. |
| Standalone secondary/filter action | Native Button with glass | Regular glass with neutral semantic ink for Cancel/dismiss actions; green is reserved for primary actions and selected states. Selected filters retain checkmark/tint and semantic state. |
| Every editable input | Native TextField/TextEditor inside one regular-glass functional shell when needed | Rounded 16 pt field shell; persistent label, native focus/keyboard/autofill/selection, validation outside the material. Inner editor has no second glass background. Read-only values remain content. |
| Search | searchable/UISearchController | System glass field, clear/cancel, retained scope/query and keyboard-aware placement. Do not wrap an already glass system search field again. |
| Agent/Inbox/comment composer | Native editor + one glass shell + native Send/Stop | Rounded multiline shell; bounded growth, keyboard safe-area inset, 44 pt Send/Stop, retained failed drafts. No duplicated shell material. |
| Context menu/popover | Native Menu/context menu/popover | Anchor to the source, native material and shape, dismissal and focus restoration. Destructive actions keep system roles. |
| Sheet/alert/dialog | Native presentation | Let the OS own presentation chrome/material, detents and background treatment. Form/content surfaces remain readable. Do not turn the entire screen into transparent glass. |
| Inline reactions, links, disclosure rows, calendar/switch/checkbox | Appropriate native content control | Native plain/content style where that is the system convention; interactive bounds and selected/disabled traits still apply. |
| Sign in with Apple and OS pickers/share UI | Official native control/presentation | Preserve approved appearance and OS behavior. No custom glass replacement. |

## Material and accessibility

Use regular glass by default. Clear is reserved for floating controls over rich media when contrast remains readable. Native variants, tint and interactive behavior are the supported design decisions; do not treat whole-view opacity as a native material transparency setting. Paper alpha/blur/edge/shadow tokens are static approximations, not runtime rendering instructions or a universal opacity slider.

The OS adapts to light/dark appearance, Reduce Transparency and Increase Contrast. Provide an opaque semantic surface with the same geometry when transparency is reduced; stronger boundaries and validation text must remain visible. Keep 44 pt targets, native Dynamic Type, selected/disabled traits and focus order. Group adjacent custom effects with GlassEffectContainer where appropriate. Never apply a second glass modifier to native glass chrome or nest a glass editor background within the composer's glass shell. A native control inside that shell retains its own standard system rendering.

Photographs, wardrobe grids, message bubbles, notices, Markdown responses, review summaries and ordinary grouped content keep their content surfaces. Glass identifies functional controls, not every container.

## Audit and changes

Inspected all 226 artboards across ten Paper pages, including 179 canonical screen contracts, component masters, appearance references and V1 flow copies. Applied the shared material reference to 350 navigation/toolbar instances, 97 field/search/comment input shells, 25 composers, 429 standalone/filter actions, 72 tab/segmented containers and two menu references. Send/Stop controls and compact dashboard action shapes were synchronized too. Existing V2 reference screens received visual consistency only; release scope is unchanged.

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

[Native presentations](NATIVE-PRESENTATIONS.md) defines Closet More as a native anchored Menu popup, Add as a native bottom sheet, adaptive wide-layout popovers, editor sheets, confirmations and the full-screen Agent exception. Use native presentation ownership and safe dismissal throughout.

## Navigation consistency follow-up · October 1, 2026

A structural pass across all 227 artboards found generic Frame headers missed by the earlier name-based classification. Checked 215 Back controls; corrected 35 bare shells across Home, Closet search and V1 copies. Wrapped 13 bare toolbar Cancel actions in the shared neutral regular-glass control and synchronized 18 outlined search shells, including the component references and walkthrough. Named navigation headers/Back/search layers consistently to make later audits easier. All checked Back and Cancel controls retain 44-point height; content disclosure chevrons remain plain. Native behavior remains a separate implementation check.
