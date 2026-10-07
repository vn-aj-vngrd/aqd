# AQD design system

Visual foundations for the intended app, not proof of implementation. [Status](docs/delivery/implementation-status.md) and [verification](docs/delivery/verification.md) own observed capability and evidence.

## Authority

[iOS Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) owns tokens, component masters and composition; [web Paper](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK) owns landing/admin references. Product releases own phase scope, features own behavior, design contracts own visual/interaction requirements. [Design router](docs/design/README.md) selects the affected branch. Update the affected specification with authorized design changes; static canvas review never establishes native behavior.

## Direction

Premium through restraint: clothing photography, precise alignment, quiet opaque semantic surfaces and native interaction. Cool neutrals/graphite in light appearance, neutral charcoal in dark; crisp blue for primary actions and selection. Brand character comes from content and proportion, not boxes or separators around every explanation. Use photographic pieces/looks, not childish flat garment illustrations. Landing may be expressive; roots prioritize their tasks.

Today · Closet · Planner · Agent · Profile are the shared destination identities. Detailed navigation and source returns belong to [V1 flow](docs/design/v1-flow.md) and [V2 flow](docs/design/v2-flow.md), not this foundation. The Today house glyph remains unchanged.

## Color

| Role / light Paper token | Light | Dark |
| --- | --- | --- |
| Canvas / `--color-canvas` | `#F5F5F7` | `#1C1C1E` |
| Surface / `--color-surface` | `#FFFFFF` | `#2C2C2E` |
| Primary text / `--color-ink` | `#292C30` | `#F2F2F7` |
| Supporting text / `--color-secondary` | `#686C72` | `#B8B8BD` |
| Divider / `--color-line` | `#E2E5E9` | `#48484A` |
| Image ground / `--color-image-ground` | `#F0F0EE` | `#242426` |
| Primary accent / `--color-accent` | `#006FEE` | `#338EF7` |
| Action text / `--color-action-text` | `#005BC4` | `#66AAF9` |
| On accent / `--color-on-accent` | `#FFFFFF` | `#1C1C1E` |
| Soft selection / `--color-accent-soft` | `#E6F1FE` | `#142B47` |
| Control boundary / `--color-control-border` | `#7B8088` | `#8E8E93` |
| Regular glass / `--color-glass` | `rgb(255 255 255 / 88%)` | `rgb(44 44 46 / 94%)` |
| Prominent glass / `--color-glass-prominent` | `var(--color-accent)` | `var(--color-night-accent)` |
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
| Information / `--color-info` | `#005BC4` | `#66AAF9` |
| Information surface / `--color-info-soft` | `#E6F1FE` | `#142B47` |

Dark partners use `--color-night-*`; existing `--color-dark`, `--color-dark-surface`, `--color-dark-ink`, `--color-dark-secondary` alias night counterparts. Preserve all 25 paired roles and token usage descriptions even without dark phone duplicates. Native dark support remains required.

Primary labels use white on light accent, dark ink on dark accent. Primary content buttons are solid without blur/shadow; secondary actions are plain regular-weight action-text without fill/border/blur/shadow. Soft-blue Back/View outfit capsules retain flat accent-soft treatment. Menus/disabled controls stay neutral. Selection also has check/fill/weight/label. Success means acknowledged completion, warning means risk/unknown requiring reconciliation, destructive intent uses red. Native alerts keep system semantics without injected icons. [Feedback](docs/design/components.md#app-owned-semantic-feedback) owns app-message variants; explanations remain unboxed, related actionable lists use opaque surfaces.

Text targets 4.5:1 (3:1 large), meaningful control boundaries 3:1; color is never the sole cue. Recorded solid ratios: primary 4.66:1 light/5.15:1 dark, action text on soft fill 5.58:1, supporting text >4.5:1, boundaries 3.58:1/4.27:1, status foregrounds >4.5:1 on matching grounds. White/danger-fill 4.71:1; error/soft 4.83:1. These do not certify translucent content. Paper alpha/edge/shadow tokens are approximations; runtime materials own optics and accessibility adaptation.

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
