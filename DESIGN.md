# AQD design system

Authoritative visual foundations, phase scope updated October 5, 2026. This specifies the intended app; implementation and verification are tracked separately.

## Authority

[AQD iOS in Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) is the iOS visual source: edit tokens, page 00 component masters, and screen composition there. This document records roles and native behavior. [Screen map](docs/design/screens.md) owns routes and state coverage; [Components](docs/design/components.md) owns reusable contracts. Product and feature specifications retain behavior and access rules. The former local gallery and renderers have been retired after Paper coverage verification.

The separate [web Paper file](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK) contains designs for the public landing and protected admin apps, with shared AQD brand foundations. [Web design](docs/design/web.md) owns web patterns, proposed routes, app boundaries, and static verification scope. Web controls adapt the brand without copying native iOS material behavior.

For UI work, read this document and the affected screen contract before inspecting implementation. Record divergence from the design as a gap. Update Paper and the relevant specification together when the design changes. Verify actual native behavior separately from static canvas review.

## Direction

Premium through restraint: clothing photography, precise alignment, quiet surfaces, and native interaction. Light surfaces use cool neutrals and graphite; dark surfaces use neutral charcoal. Crisp blue is reserved for primary actions and selection; dark appearance uses a brighter blue. The initial flat garment illustrations were rejected as childish. Use photographic pieces and looks; the AQD wordmark and small crisp blue accent provide the brand.

Root screens prioritize the task. Landing is the expressive introduction. V1 and V2 use Home, Closet, Planner, Agent and Profile with complete Settings; Planner is a dedicated root, not a Closet segment. V2 Home combines Today’s private dashboard with All / Following discovery; Closet is private management. Whitespace and flat semantic surfaces group actionable content. Image grounds support clothing; explanatory prose stays unboxed. Use spacing, not decorative separators, for the refined content/choice/toggle rows. Brand character comes from content and proportion rather than decorations around every element.

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

Primary actions use white on the light accent, dark ink on the dark accent. Native alerts retain semantic system colors. Selection also has a check, fill, weight, or label. Glass responds to content and accessibility settings. Text contrast targets 4.5:1, or 3:1 for large text; soft surfaces do not require soft text.

Dark partners use `--color-night-*`. Existing `--color-dark`, `--color-dark-surface`, `--color-dark-ink` and `--color-dark-secondary` are aliases to their night equivalents. Page 00 **Foundations · Color palette · Crisp blue** shows all 25 light/dark role pairs with live token swatches. Every color token has a usage description. Dark phone duplicates are removed from the current canvas; retain every light role's dark partner and native dark-mode/accessibility requirements rather than removing dark support.

Crisp blue follows the approved Apple/HeroUI-inspired direction; cool neutrals and graphite keep photography prominent. Primary buttons use solid accent fills without blur or shadow. Secondary content actions use plain regular-weight action-text labels, without white fills, borders, blur or shadows. Existing soft-blue Back and View outfit capsules retain their flat accent-soft treatment; selected tab icons retain semantic accent/action tint. Menus and disabled controls remain neutral. Success green is reserved for a confirmed status, never branding; warning uses muted amber, and error/destructive intent uses red. Pair status color with text or a symbol. Information aliases the visual blue family but requires an explicit message so it cannot be confused with selection. Use soft status grounds only when a notice needs containment; explanatory prose remains unboxed, while actionable lists and related controls use opaque semantic surfaces. Native alerts and destructive chrome retain system semantic colors.

Solid-color contrast: primary labels 4.66:1 light / 5.15:1 dark; light secondary action text on soft fill 5.58:1; supporting text exceeds 4.5:1 on light canvas and dark surface; control boundaries 3.58:1 light / 4.27:1 dark. All defined status foregrounds exceed 4.5:1 on their matching soft grounds. These ratios do not certify translucent glass over arbitrary content. Regular glass, edge, track and shadow alpha tokens are static Paper approximations; prominent-glass token names now alias solid accents for compatibility; Reduced Transparency uses opaque semantic surfaces. Native materials own runtime alpha and optics.

## Typography

Use Apple's system font and semantic Dynamic Type styles. SF Pro is the implementation face. Paper previews with Helvetica Neue because SF Pro is unavailable there; it is not a production font dependency.

| Style | Base size / line, pt | Weight | Native role |
| --- | --- | --- | --- |
| Brand introduction | 36 / 40 | Regular | Scaled system text, landing only |
| Root title | 32 / 38 | Medium | Large title |
| Detail title | 20 / 26 | Medium | Navigation title |
| Section | 22 / 28 | Medium | Title 2 |
| Body / action | 17 / 24 | Regular / Medium | Body / headline |
| Supporting | 15 / 21 | Regular | Subheadline |
| Metadata | 13 / 18 | Regular | Footnote |

Display tracking is `-0.025em`; body uses system tracking. The small AQD wordmark uses medium weight and `0.10em` tracking. Native tab labels use OS type. At accessibility sizes, wrap labels, stack action peers, and collapse grids to one column. Preserve useful image sizes instead of shrinking the entire layout.

## Layout and shape

Phone reference: 390 × 844 pt, with native status and safe areas. Screen inset: 20 pt; brand compositions may use 24 pt. Space tokens: 4, 8, 12, 16, 20, 24, 32, 40, 48 pt. Related controls use 8–12, content groups 16–24, major transitions 32–40.

Paper phone navigation uses a consistent 390 × 844 viewport: the 66-point bar has 16-point side insets and a 26-point bottom inset, with the home indicator 8 points above the bottom. V1 and V2 have the same five equal-width slots: Home · Closet · Planner · Agent · Profile. Show icons only, centered within each full slot; preserve Home/Closet/Planner/Agent/Profile accessibility names and the selected trait. Each nonoverlapping hit area is at least 44 × 44 pt. Hiding captions never shrinks targets or removes destination names from assistive technology. Anchor chrome to the phone viewport so content height cannot move it; keep tour controls above the bar and preserve scroll access to final content/actions. These are reference drawing dimensions. Native implementation uses the operating system's tab bar and safe-area layout, including device, keyboard and accessibility adaptations.

Photographic corners: 4 pt. Opaque input shells: 16 pt (multiline composers: 28 pt). Grouped content surfaces: 12 pt. Compositions: 12–16 pt when containment helps. Sheets use system corners. Pills belong to buttons, filters, and native glass chrome. Ordinary content has neither shadow nor outline. Choose separator or elevation according to function.

Profile/settings controls share an opaque grouped surface: white surface in light appearance, semantic dark surface in dark appearance, 12-point corners and 14-point inset row separators. Related rows touch within one group; section descriptions and identity summaries remain outside it. Use the same surface/spacing roles in V1, V2 and admin Settings, adapting typography and controls to each platform. [Settings group](docs/design/components.md#reusable-settings-group) owns the shared contract.

Touch targets are at least 44 × 44 pt. Primary content action: base 50 pt tall, 17 pt medium label, 20 pt horizontal padding. Header Back and toolbar controls retain native chrome. Content secondary/cancel actions follow the plain text pattern with action-text labels, at least 44-point targets and regular weight; destructive and disabled states retain their semantic colors. One action dominates each task step. Loading preserves control width and blocks duplicate submission.

## Apply the foundations

Page 00 is a reusable design-system library: semantic color, typography, spacing, shape, iconography, navigation primitives, controls, surfaces and generic component states. Full app screens, feature-specific menus, onboarding/walkthroughs, social feeds and accessibility phone examples belong to their V1/V2 reference areas, not Foundations. Keep the shared primitive and its usage rules here; demonstrate the product flow on its owning phase page. Moving a reference preserves its node IDs and does not make it a new canonical route.

Edit semantic values in Paper’s token panel and geometry in page-00 component masters, then update affected screen clones. Tokens update live; structural clones require synchronization. [Design rules](docs/design/rules.md) owns the review procedure.

V1 and V2 share five equal-width icon-only native destinations: Home · Closet · Planner · Agent · Profile, with explicit accessibility names. Closet segments are only Pieces / Outfits / Themes; Planner is a dedicated root with Week default and Month alternate. Home plan links and outfit Plan actions route to Planner with their date context; Back restores the origin and preserved selection. Agent opens a native full-screen task from the fourth slot or focused assistance; dismissal restores the originating destination, selection and scroll position. V1 Profile follows the [private fit journal contract](docs/design/profile-fit-journal.md); its single More toolbar icon contains Add fit, Edit profile, Style, Wear insights and Settings; none are repeated as toolbar/body actions on the journal root. No V1 social menu, publish action, online identity or Inbox appears. V2 adds a persistent labelled 44-point Inbox root-toolbar entry, not a sixth tab or replacement slot. It opens existing I01, then conversations; Back restores the origin root, scroll and selected tab. Startup/incoming Inbox intents preserve that origin and never invent unread badges. Account setup never gates Planner or private core work. AQD owns content and semantic tint; the operating system owns native controls, material behavior and accessibility adaptation.

Read the contract for the affected branch:

| Work | Authoritative contract |
| --- | --- |
| Shared content, selection, profile or Today modules | [Components](docs/design/components.md) |
| Symbols and selective AI badges | [Icons](docs/design/icons.md) |
| Native control material | [Liquid Glass](docs/design/liquid-glass.md) |
| Menus/sheets, exits and title alignment | [Native presentations](docs/design/native-presentations.md) |
| Animation, loading or feedback | [Motion](docs/design/motion.md) and [coverage](docs/design/motion-coverage.md) |
| First use and authentication | [Entry](docs/design/entry-identity.md) and [entry motion](docs/design/entry-motion.md) |
| Agent response or input | [Experience](docs/design/agent-experience.md) and [input](docs/design/agent-input.md) |
| Search and continued feeds | [Search and feeds](docs/design/search-and-feeds.md) |
| Landing or admin web UI | [Web](docs/design/web.md) |

## Imagery and copy

Use user-selected garment photography and compositions of the actual included pieces. Preserve proportions and identifying details in piece detail. Community imagery is explicitly published by its creator. Missing photos use a quiet category symbol with the piece name.

Paper garment cutouts, reference photographs and names/counts/chats are illustrative fixtures. V1/V2 reuse the canonical asset mapping so each piece label matches its visual and each named look retains its composition. They are not actual user records or bundled production assets. Source URLs and replacement rules live in [Assets](docs/references/assets.md). Implementation uses authorized user media, real data, and honest unavailable states.

Copy names the task: Add piece, Build outfit, Review changes, Save outfit, Publish look. Explain privacy at the choice it affects. AI output stays a draft until a receipt confirms saving. Human chat remains separate from Agent.

## Completion boundary

[V1 flow](docs/design/v1-flow.md) maps page 01 · V1, grouped into nine device-only journeys, starting with the shared native splash. [Screen contracts](docs/design/screens.md), [V2 flow](docs/design/v2-flow.md) and [V2 requirements](docs/design/v2-requirements.md) map the complete connected and expansion paths. The iOS file contains exactly Foundations, V1 and V2, in that order. All connected canonical screens, review strips and expansion requirements live on page 02 · V2, grouped into nine sections. Screen and node IDs are retained; page links follow the consolidated structure. [iOS manifest](docs/design/paper-manifest.json) and [web manifest](docs/design/web-paper-manifest.json) own recorded inventories. [V1 release](docs/product/v1-release.md) and [V2 backlog](docs/product/v2-backlog.md) own scope.

Static Paper review does not establish native keyboard/accessibility behavior, runtime performance or production services. Record actual checks and limits in [verification](docs/delivery/verification.md); provider and policy gates stay in [decisions](docs/product/decisions.md).

### Compact controls and flat forms — October 6, 2026

Fields use opaque surface/night-surface fills, 16-point corners and 14-point padding without decorative borders, blur or shadows. Preserve native focus, invalid, disabled and Increase Contrast feedback. Filter capsules are 32 points tall with 6-point vertical and 12-point horizontal padding, 14/20 labels and 6-point internal gaps. Segmented rails use a 2-point inset around 32-point segments, giving a 36-point visible rail; only the selected segment has an opaque surface fill and medium label. Inactive Themes has no separate fill or glass treatment. Compact visuals still require nonoverlapping native hit bounds of at least 44 points, plus Dynamic Type expansion.

Selected square checkboxes use accent fill and a white check without a gray outline; unchecked boxes use the control-border token. Main Closet outfit suggestions use the primary accent button. AI badges precede the task label with an 8-point gap; the centered group replaces trailing positioning. Capture uses a vertical Photo label, plain photo actions and labelled fields. L04's no-photo state uses one compact full-width opaque Add photo control opening native source options (Choose from Photos / Take photo) in a bottom sheet, adaptively a popover on wide layouts; no separate camera action appears in the form; a centered portrait preview appears only after accepted selection. L79 shares this compact Add photo recovery through L159 with retained fields, validation and disabled Save. V2 capture and connected review copies reuse the same source-sheet-over-draft structure. Destructive buttons use danger-fill with white labels; destructive text uses error. White on danger-fill measures 4.71:1; error on its soft ground measures 4.83:1.

Primary/secondary action pairs share Welcome’s 12-point gap inside a dedicated action stack. Preserve existing centered action bounds, leading AI badges and surrounding content-section spacing. Apply to equivalent V1/V2 detail, form, empty, confirmation and recovery screens and admin forms.

Piece capture starts with an explicit no-photo draft. Every new-piece save needs a photo, name and category; visible labels omit Required/Optional. Use a portrait 3:4 viewport with full-image Fit by default; crop is optional and reviewed in the shared local editor. Portrait/landscape sources retain proportions and the original. PhotoOptions contains replacement/camera/removal; editing confirms a draft, never a saved record. [Capture photo](docs/design/capture-photo.md) owns V1/V2 states and native implementation boundaries.
