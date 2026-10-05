# AQD design system

Authoritative visual foundations, phase scope updated October 5, 2026. This specifies the intended app; implementation and verification are tracked separately.

## Authority

[AQD iOS in Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) is the iOS visual source: edit tokens, page 00 component masters, and screen composition there. This document records roles and native behavior. [Screen map](docs/design/screens.md) owns routes and state coverage; [Components](docs/design/components.md) owns reusable contracts. Product and feature specifications retain behavior and access rules. The former local gallery and renderers have been retired after Paper coverage verification.

The separate [web Paper file](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK) contains designs for the public landing and protected admin apps, with shared AQD brand foundations. [Web design](docs/design/web.md) owns web patterns, proposed routes, app boundaries, and static verification scope. Web controls adapt the brand without copying native iOS material behavior.

For UI work, read this document and the affected screen contract before inspecting implementation. Record divergence from the design as a gap. Update Paper and the relevant specification together when the design changes. Verify actual native behavior separately from static canvas review.

## Direction

Premium through restraint: clothing photography, precise alignment, quiet surfaces, and native interaction. Light surfaces use limestone and graphite; dark surfaces use neutral charcoal. Heritage blue is reserved for actions and selection; dark appearance uses muted powder blue. The initial flat garment illustrations were rejected as childish. Use photographic pieces and looks; the AQD wordmark and small Heritage blue accent provide the brand.

Root screens prioritize the task. Landing is the expressive introduction. V1 uses Home, Closet, Agent and local Profile with complete Settings; Planner remains in Closet. V2 Home combines Today’s private dashboard with All / Following discovery; Closet is private management. Whitespace and separators group ordinary content. Grouped backgrounds belong to forms/settings; image grounds support clothing. Brand character comes from content and proportion rather than decorations around every element.

## Color

| Role / light Paper token | Light | Dark |
| --- | --- | --- |
| Canvas / `--color-canvas` | `#F3F3F1` | `#1C1C1E` |
| Surface / `--color-surface` | `#FFFFFF` | `#2C2C2E` |
| Primary text / `--color-ink` | `#292C30` | `#F2F2F7` |
| Supporting text / `--color-secondary` | `#686C72` | `#B8B8BD` |
| Divider / `--color-line` | `#E2E5E9` | `#48484A` |
| Image ground / `--color-image-ground` | `#F0F0EE` | `#242426` |
| Primary accent / `--color-accent` | `#285A93` | `#B7C9DE` |
| On accent / `--color-on-accent` | `#FFFFFF` | `#1C1C1E` |
| Soft selection / `--color-accent-soft` | `#E8EDF3` | `#2B394B` |
| Control boundary / `--color-control-border` | `#7B8088` | `#8E8E93` |
| Regular glass / `--color-glass` | `rgb(255 255 255 / 88%)` | `rgb(44 44 46 / 94%)` |
| Prominent glass / `--color-glass-prominent` | `rgb(40 90 147 / 94%)` | `rgb(183 201 222 / 94%)` |
| Glass edge / `--color-glass-edge` | `rgb(255 255 255 / 70%)` | `rgb(255 255 255 / 12%)` |
| Segment track / `--color-segment-track` | `rgb(118 118 128 / 10%)` | `rgb(118 118 128 / 24%)` |
| Control shadow / `--color-shadow` | `rgb(20 20 22 / 8%)` | `rgb(0 0 0 / 22%)` |
| Error / destructive / `--color-error` | `#A1403A` | `#FFB4AB` |
| Error surface / `--color-error-soft` | `#F5E9E7` | `#462F2E` |
| Success / `--color-success` | `#416451` | `#B8D0BF` |
| Success surface / `--color-success-soft` | `#E8EFEA` | `#293B30` |
| Warning / `--color-warning` | `#795B2E` | `#DCC7A2` |
| Warning surface / `--color-warning-soft` | `#F3EEE4` | `#403728` |
| Information / `--color-info` | `#285A93` | `#B7C9DE` |
| Information surface / `--color-info-soft` | `#E8EDF3` | `#2B394B` |

Primary actions use white on the light accent, dark ink on the dark accent. Native alerts retain semantic system colors. Selection also has a check, fill, weight, or label. Glass responds to content and accessibility settings. Text contrast targets 4.5:1, or 3:1 for large text; soft surfaces do not require soft text.

Dark partners use `--color-night-*`. Existing `--color-dark`, `--color-dark-surface`, `--color-dark-ink` and `--color-dark-secondary` are aliases to their night equivalents. Page 00 **Foundations · Color palette · Heritage blue** shows all 23 light/dark role pairs with live token swatches. Every color token has a usage description.

Blue comes from tailored wool; limestone and neutral graphite keep photography prominent. Secondary controls, menus and disabled controls remain neutral. Success green is reserved for a confirmed status, never branding; warning uses muted amber, and error/destructive intent uses red. Pair status color with text or a symbol. Information aliases the visual blue family but requires an explicit message so it cannot be confused with selection. Use soft status grounds only when a notice needs containment; ordinary content remains unboxed. Native alerts and destructive chrome retain system semantic colors.

Solid-color contrast: primary labels 7.06:1 light / 10.07:1 dark; supporting text 4.75:1 on light canvas / 7.05:1 on dark surface; control boundaries 3.58:1 light / 4.27:1 dark. All defined status foregrounds exceed 4.5:1 on their matching soft grounds. These ratios do not certify translucent glass over arbitrary content. Regular/prominent glass, edge, track and shadow alpha tokens are static Paper approximations; Reduced Transparency uses opaque semantic surfaces. Native materials own runtime alpha and optics.

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

Paper phone navigation uses a consistent 390 × 844 viewport: the 66-point bar has 16-point side insets and a 26-point bottom inset, with the home indicator 8 points above the bottom. V1 has four equal-width tab slots; V2 has five. Center each icon and label within its slot. Anchor chrome to the phone viewport so content height cannot move it; keep tour controls above the bar and preserve scroll access to final content/actions. These are reference drawing dimensions. Native implementation uses the operating system's tab bar and safe-area layout, including device, keyboard and accessibility adaptations.

Photographic corners: 4 pt. Input glass shells: 16 pt (multiline composers: 28 pt). Grouped content surfaces: 12 pt. Compositions: 12–16 pt when containment helps. Sheets use system corners. Pills belong to buttons, filters, and native glass chrome. Ordinary content has neither shadow nor outline. Choose separator or elevation according to function.

Touch targets are at least 44 × 44 pt. Primary content action: base 50 pt tall, 17 pt medium label, 20 pt horizontal padding. Cancel and dismiss actions use neutral semantic ink on regular glass (light charcoal / dark light ink). Blue is reserved for primary actions and selected states; secondary actions use neutral native controls. One action dominates each task step. Loading preserves control width and blocks duplicate submission.

## Apply the foundations

Edit semantic values in Paper’s token panel and geometry in page-00 component masters, then update affected screen clones. Tokens update live; structural clones require synchronization. [Design rules](docs/design/rules.md) owns the review procedure.

V1 has Home, Closet, Agent and local Profile, with visible native labels. Settings is reached from Profile/toolbar; Planner is inside Closet. Agent has complete local conversation/history and reviewed actions; Profile is private personal information/collections. No social menu, publish action, online identity or Inbox appears. V2 adds connected controls and Inbox to this same foundation. V2 retains Home, Closet, Agent, Inbox and Profile, with visible native labels. V2 Agent opens full screen from the center entry or focused assistance; dismissal restores the prior destination and scroll position. AQD owns content and semantic tint; the operating system owns native controls, material behavior and accessibility adaptation.

Read the contract for the affected branch:

| Work | Authoritative contract |
| --- | --- |
| Shared content, selection, profile or Today modules | [Components](docs/design/components.md) |
| Symbols and selective AI badges | [Icons](docs/design/icons.md) |
| Native control material and input shells | [Liquid Glass](docs/design/liquid-glass.md) |
| Menus/sheets, exits and title alignment | [Native presentations](docs/design/native-presentations.md) |
| Animation, loading or feedback | [Motion](docs/design/motion.md) and [coverage](docs/design/motion-coverage.md) |
| First use and authentication | [Entry](docs/design/entry-identity.md) and [entry motion](docs/design/entry-motion.md) |
| Agent response or input | [Experience](docs/design/agent-experience.md) and [input](docs/design/agent-input.md) |
| Search and continued feeds | [Search and feeds](docs/design/search-and-feeds.md) |
| Landing or admin web UI | [Web](docs/design/web.md) |

## Imagery and copy

Use user-selected garment photography and compositions of the actual included pieces. Preserve proportions and identifying details in piece detail. Community imagery is explicitly published by its creator. Missing photos use a quiet category symbol with the piece name.

Paper reference photographs and names/counts/chats are illustrative fixtures. They are not actual user records or bundled production assets. Source URLs and replacement rules live in [Assets](docs/references/assets.md). Implementation uses authorized user media, real data, and honest unavailable states.

Copy names the task: Add piece, Build outfit, Review changes, Save outfit, Publish look. Explain privacy at the choice it affects. AI output stays a draft until a receipt confirms saving. Human chat remains separate from Agent.

## Completion boundary

[V1 flow](docs/design/v1-flow.md) maps page 01 · V1, grouped into ten device-only flows. [Screen contracts](docs/design/screens.md), [V2 flow](docs/design/v2-flow.md) and [V2 requirements](docs/design/v2-requirements.md) map the complete connected and expansion paths. The iOS file contains exactly Foundations, V1 and V2, in that order. All connected canonical screens, review strips and expansion requirements live on page 02 · V2, grouped into nine sections. Screen and node IDs are retained; page links follow the consolidated structure. [iOS manifest](docs/design/paper-manifest.json) and [web manifest](docs/design/web-paper-manifest.json) own recorded inventories. [V1 release](docs/product/v1-release.md) and [V2 backlog](docs/product/v2-backlog.md) own scope.

Static Paper review does not establish native keyboard/accessibility behavior, runtime performance or production services. Record actual checks and limits in [verification](docs/delivery/verification.md); provider and policy gates stay in [decisions](docs/product/decisions.md).
