# AQD design system

Visual foundations for the intended app, not proof of implementation. [Status](docs/delivery/implementation-status.md) and [verification](docs/delivery/verification.md) own observed capability and evidence.

## Authority

[iOS Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) owns tokens, component masters and composition; [web Paper](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK) owns landing/admin references. Product releases own phase scope, features own behavior, design contracts own visual/interaction requirements. [Design router](docs/design/README.md) selects the affected branch. Update the affected specification with authorized design changes; static canvas review never establishes native behavior.

## Direction

Premium through restraint: clothing photography, precise alignment, quiet opaque semantic surfaces and native interaction. Owner refinement October16 uses white and warm neutral surfaces, charcoal/light primary actions and restrained muted gold for commit/completion action text. Dark appearance keeps neutral charcoal surfaces with readable warm gold commit text. Brand character comes from content and proportion, not boxes or separators around every explanation. Use photographic pieces/looks, not childish flat garment illustrations. Landing may be expressive; roots prioritize their tasks.

Today · Closet · Planner · Agent · Profile are the shared destination identities. Detailed navigation and source returns belong to [V1 flow](docs/design/v1-flow.md) and [V2 flow](docs/design/v2-flow.md), not this foundation. The Today house glyph remains unchanged.

## Color

| Role / light Paper token | Light | Dark |
| --- | --- | --- |
| Canvas / `--color-canvas` | `#F7F7F5` | `#1C1C1B` |
| Surface / `--color-surface` | `#FFFFFF` | `#2B2B29` |
| Primary text / `--color-ink` | `#242321` | `#F3F1EB` |
| Supporting text / `--color-secondary` | `#6A6863` | `#BCB9B1` |
| Divider / `--color-line` | `#E4E2DC` | `#4A4842` |
| Image ground / `--color-image-ground` | `#F5F4F1` | `#242422` |
| Brand accent / `--color-accent` (logo Q and welcome artwork only) | `#8C6A36` | `#D3B47C` |
| On accent / `--color-on-accent` | `#FFFFFF` | `#1C1C1B` |
| Primary fill / `--color-primary-fill` | `#292826` | `#F2F0EB` |
| On primary / `--color-on-primary` | `#FFFFFF` | `#242321` |
| Collection selection / `--color-segment-selection` | `#E8E8E8` | `#454545` |
| Control boundary / `--color-control-border` | `#807B72` | `#969187` |
| Regular glass / `--color-glass` | `rgb(255 255 255 / 88%)` | `rgb(43 43 41 / 94%)` |
| Glass edge / `--color-glass-edge` | `rgb(255 255 255 / 70%)` | `rgb(255 255 255 / 12%)` |
| Segment track / `--color-segment-track` | `rgb(118 118 128 / 10%)` | `rgb(118 118 128 / 24%)` |
| Control shadow / `--color-shadow` | `rgb(20 20 22 / 8%)` | `rgb(0 0 0 / 22%)` |
| Error / destructive / `--color-error` | `#D4142A` | `#FF6472` |
| Danger fill / `--color-danger-fill` | `#E02335` | `#FF6472` |
| Error surface / `--color-error-soft` | `#FFF0F2` | `#422027` |
| Success / `--color-success` | `#416451` | `#B8D0BF` |
| Success surface / `--color-success-soft` | `#E8EFEA` | `#293B30` |
| Warning / `--color-warning` | `#795B2E` | `#DCC7A2` |
| Warning surface / `--color-warning-soft` | `#F3EEE4` | `#403728` |
| Information / `--color-info` | `#6A6863` | `#BCB9B1` |
| Information surface / `--color-info-soft` | `#F5F4F1` | `#242422` |

Dark partners use `--color-night-*`; existing `--color-dark`, `--color-dark-surface`, `--color-dark-ink`, `--color-dark-secondary` alias night counterparts. Preserve the paired semantic roles and token usage descriptions even without dark phone duplicates. Native dark support remains required.

Primary content labels use white on charcoal in light appearance and dark ink on a light fill in dark appearance. Selected content uses the neutral primary-fill/on-primary pair. Primary content buttons are solid without blur/shadow; secondary actions are plain regular-weight action-text without fill/border/blur/shadow. Soft-neutral Back/View outfit capsules retain flat accent-soft treatment. Menus/disabled controls stay neutral. Selection also has check/fill/weight/label. Success means acknowledged completion, warning means risk/unknown requiring reconciliation, destructive intent uses red. Native alerts keep system semantics without injected icons. [Feedback](docs/design/components.md#app-owned-semantic-feedback) owns app-message variants; explanations remain unboxed, related actionable lists use opaque surfaces.

Text targets 4.5:1 (3:1 large), meaningful control boundaries 3:1; color is never the sole cue. Measured solid token ratios for the owner palette: primary labels14.73:1 light/13.79:1 dark, light gold/white4.96:1, action text/canvas6.12:1 light and9.42:1 dark, action text/soft selection5.88:1 light, supporting text/canvas5.19:1 light, dark gold/surface7.15:1. Destructive/error/success/warning roles retain their existing pairs. These do not certify translucent content. Paper alpha/edge/shadow tokens are approximations; runtime materials own optics and accessibility adaptation.

## Typography

Apple system font and semantic Dynamic Type; SF Pro in implementation, Helvetica Neue only for Paper preview, not a production dependency.

| Style | Base size / line, pt | Weight | Native role |
| --- | --- | --- | --- |
| Brand introduction | 36 / 40 | Regular | Scaled system text, landing only |
| Root title | 32 / 38 | Medium | Large title |
| Detail title | 20 / 26 | Medium | Navigation title |
| Section | 22 / 28 | Medium | Title 2 |
| Body / action | 17 / 24 | Regular / Medium | Body / headline |
| Supporting | 15 / 21 | Regular | Subheadline |
| Metadata | 13 / 18 | Regular | Footnote |

Display tracking `-0.025em`; body system tracking; small wordmark medium with `0.10em`. Native tab labels use OS type. Accessibility text wraps labels, stacks action peers and collapses grids to one column; preserve useful images rather than shrinking the layout.

## Layout and shape

Phone reference 390 × 844 pt with native status/safe areas. Screen inset 20 pt (brand 24). Space scale: 4, 8, 12, 16, 20, 24, 32, 40, 48. Related controls 8–12, groups 16–24, transitions 32–40.

Paper navigation reference: 66-point bar, 16-point side/26-point bottom insets, indicator 8 points above bottom. Five equal slots, centered icons, explicit Today/Closet/Planner/Agent/Profile accessibility names and selected traits. Hit areas ≥44 × 44, nonoverlapping. Anchor chrome to viewport, not content height; keep tour actions above it and final content scroll-reachable. Native uses OS tab bar/safe areas with device, keyboard and accessibility adaptation, not those fixed coordinates.

Photography corners 4 pt; inputs 16 (multiline composer 28); grouped surfaces 12; contained compositions 12–16; sheets system corners. Pills for buttons/filters/native chrome; ordinary content has no shadow/outline. Choose separator or elevation by function, never a trailing separator after the last/only row.

Primary content action: 50-point base height, 17-point medium label, 20-point horizontal padding. Secondary/cancel: plain regular action-text, ≥44 target. One action dominates; loading preserves label/width and prevents duplicate submission. Primary/secondary stacks have a dedicated 12-point gap independent of section spacing. Three-action tertiary alternatives use a plain 50-point safe-area footer, not a competing primary.

Opaque fields use 16 corners/14 padding without decorative border/blur/shadow; preserve focus/invalid/disabled/Increase Contrast. Compact filters are 32-point visuals with 6 vertical/12 horizontal padding, 14/20 labels, 6 inner gap. Segments have a 2-point inset, 32-point segments/36-point rail; only selected segment filled/medium. Visual compactness never shrinks ≥44 native targets; Dynamic Type expands. Selected square checkboxes use accent/white check without gray outline; unchecked uses control-border. [Components](docs/design/components.md) owns reusable rows/settings and detailed states.

## Transparency · Native iOS

Native-first: OS owns controls, material, presentation adaptation and dismissal; AQD owns content, hierarchy and semantic tint. Ordinary content stays opaque; use one justified functional glass shell, never extra glass on native glass or a painted current-OS replica. Reduced Transparency keeps usable opaque semantic surfaces.

[Native iOS](docs/design/native-ios.md) owns deployment/build targets, API guards/fallbacks and icon-only-tab feasibility; [presentations](docs/design/native-presentations.md) owns exits, risk/confirmation and source restoration; [Liquid Glass](docs/design/liquid-glass.md) owns material choices. Native critical confirmations retain explicit Cancel/destructive roles; routine supported cancellation writes nothing. Exact target/impact, typed/auth review, dirty-draft protection and unknown-write reconciliation remain required. Source-kit inspection/import is not AQD runtime certification.

## Apply the foundations

Foundations is the reusable token/component library, not a product funnel. Full phones, feature menus, walkthroughs and accessibility examples belong to phase reference areas. Preserve canonical IDs when moving references. Tokens update live; structural clones require synchronization and rendered review under [procedure](docs/design/rules.md).

Load only the affected [design branch](docs/design/README.md): native API work reads native-ios; materials read Liquid Glass; presentation/exits read native-presentations; motion reads motion policy/assignments; assets read provenance. Shared components own geometry/states/accessibility; feature contracts own behavior.

## Imagery and copy

Use authorized clothing photography and compositions of actual included pieces; preserve proportions/details, full-image Fit until explicitly reviewed crop. Community imagery is explicitly published. Missing media uses quiet category symbol/name. Reference photos/cutouts/names/counts/chats are illustrative, not user records or cleared production assets; [asset mapping](docs/references/assets.md) owns licensing/identity/replacement.

Task copy: Add piece, Build outfit, Review changes, Save outfit, Publish look. Explain privacy at the affected choice. AI output remains a draft until a persisted receipt. Human chat stays separate from Agent. Keep leading AI badges 8 points from task labels; icons follow [catalog](docs/design/icons.md).

## Completion boundary

Releases own phase scope/acceptance, features own behavior; [screen map](docs/design/screens.md) owns canonical route classification and [manifests](docs/design/paper-manifest.json) recorded locators, not runtime proof. Static review does not establish keyboard/accessibility, durability, performance or services. Every changed UI inventory gets [DQ acceptance](docs/design/quality-criteria.md); required implementation acceptance cannot be waived by calling it deferred.

Privacy/release guardrails remain inline: no implicit wear, publication, body-use/AI/weather consent or private-photo uploads; weather-free private journeys stay offline-complete. Numerical weather is blocked until Apple-required assets/legal placement pass; current hidden attribution row/details-only placement is unverified. Withhold numbers rather than treating Paper slots as certified branding. [Weather policy](docs/product/v1-release.md#optional-live-weather-contract) owns budgets/privacy/attribution gates; [weather UI](docs/design/weather-context.md) owns states and caller returns.

## Today and action-field refinement · October7

[Today](docs/design/today.md) owns current customization; [standalone action fields](docs/design/components.md#today-stack-and-standalone-action-fields--current-october7) own reusable geometry. [Original refinement receipt](docs/delivery/archive/design-foundations-2026-10-07.md#today-and-action-field-refinement--october7) is historical provenance only.

### Compact controls and flat forms — October 6, 2026

Current cross-cutting controls are above; [capture](docs/design/capture-photo.md) owns photo/validation behavior. [Original refinement](docs/delivery/archive/design-foundations-2026-10-07.md#compact-controls-and-flat-forms--october-6-2026) preserves detailed historical wording. Other repair/provenance bodies from this foundation are retained in the [dated snapshot](docs/delivery/archive/design-foundations-2026-10-07.md), not routine implementation instructions.

Owner glass selector refinement October16: Closet collection navigation uses one native regular-glass capsule with opaque neutral selected treatment,44-point buttons and announced selection. No glass is added to ordinary cards or native bottom tab chrome. Older OS/Reduce Transparency/Increase Contrast use a semantic-white opaque capsule; Increase Contrast strengthens its boundary and Reduce Motion disables the selected-pill transition. Large accessibility text retains the existing scrollable labelled controls. Native runtime/rendered material acceptance remains #30; Paper reference recoloring is not claimed by native-source updates.

Owner Profile/splash refinement October16: fit post cards use semantic-white outer containers with one continuous warm-neutral imageGround composition interior; full-bleed fit photos keep their existing crop. Splash uses the white surface in light appearance and its paired dark surface, with charcoal/light A/D and gold Q. System launch named colors match those native roles; no additional loading animation or delay.

Owner card surfaces October17: page canvases retain #F7F7F5. Outer content/post cards are white with a near-white warm image/composition interior (#F5F4F1). Profile posts use one continuous inner well with white card padding. Semantic dark partners remain unchanged.

Owner correction October17: restore the existing #F7F7F5 light app canvas; Profile uses that same canvas, with the native navigation/scroll-edge backdrop matching Today. White belongs to the post/content card component. Card artwork interiors are softened to #F5F4F1, with soft selection #F5F2EC; actual gold selection/action ink stays unchanged. This supersedes the earlier broad pure-white page directive as interpreted during this iteration. Remove the visible Profile navigation label while retaining destination accessibility names.

Owner color refinement October17: interactive navigation and selection use neutral ink/secondary tokens. Gold `actionText` is reserved for Save, Done, Apply and equivalent commit/completion controls; review/continue steps use a neutral forward chevron matching Back. Secondary navigation, selected tabs, filters, checkmarks, calendar selection and read-only charts remain neutral. `controlIcon` aliases secondary text for eye/reorder accessories. Existing logo/brand artwork retains its gold identity; success, warning and danger keep semantic colors. Informational content uses secondary text and the neutral image-ground surface.

Decorative icon rule October17: icons paired with visible labels use `controlIcon` (the existing secondary-text gray), including Settings, menu actions, context menus, sheets and widget rows. Shared AccessoryLabel/AccessoryButton preserve that role in native menus without tinting the label. Standalone navigation/actions stay ink; destructive and status symbols retain semantic colors. Top segmented selection uses neutral gray in both appearances to match the bottom navigation style.

Owner tour/navigation refinement October17: Back actions use plain content text without an extra authored background. Forward step controls use the semantic solid primary-fill/on-primary pair, matching Welcome in both appearances; shared toolbar forward controls use this same pair. Compact content-action variants retain a44-point minimum target with Dynamic Type wrapping. Tour uses this compact variant and a quiet close glyph labelled Skip tour for accessibility. This supersedes the tour's filled Back/glass Next treatment; ordinary content primary actions retain the50-point default.

Owner color simplification October17 (supersedes every earlier gold action-text, soft-selection and prominent-glass instruction above and in feature/design contracts): charcoal/light primary-fill and ink are the only control, selection and tint colors, including the app-wide root tint, toggles, pickers and links. Save, Done and equivalent commits use the native prominent capsule filled with primary-fill and labelled on-primary. Gold remains only as the brand accent for the logo Q and welcome artwork; the action-text, soft-selection and prominent-glass tokens are removed. Contrast pairs listing gold above are historical.

Raised surface rule October17: compact tappable white controls (selection chips, Profile Edit profile / Wear insights, Add to theme, round icon buttons) use the one shared `raisedSurface` recipe in `AQD/UI/AppChip.swift`: surface fill, divider hairline and control shadow. Selection chips are the shared `AppChip`; new chips or compact buttons reuse these instead of hand-built backgrounds. Full-width rows, cards and fields stay flat with no shadow.
