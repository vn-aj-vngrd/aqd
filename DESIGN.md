# AQD design system

Design authority, October 1, 2026. This replaces the prototype's monochrome visual direction. It specifies the intended app, not shipped functionality. App code and backend are outside this design pass.

## Authority

[AQD in Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) is the sole visual source: edit tokens, page 00 component masters, and screen composition there. This document records roles and native behavior. [Screen map](docs/design/SCREENS.md) owns routes and state coverage; [Components](docs/COMPONENTS.md) owns reusable contracts. Product and feature specifications retain behavior and access rules. The former local gallery and renderers have been retired after Paper coverage verification.

For UI work, read this document and the affected screen contract before inspecting implementation. Record divergence from the design as a gap. Update Paper and the relevant specification together when the design changes. Verify actual native behavior separately from static canvas review.

## Direction

Premium through restraint: clothing photography, precise alignment, quiet surfaces, and native interaction. Light surfaces use limestone and graphite; dark surfaces use neutral charcoal. Eucalyptus green is reserved for accents and selection. The initial flat garment illustrations were rejected as childish. Use photographic pieces and looks; the AQD wordmark and small eucalyptus accent provide the brand.

Root screens prioritize the task. Landing is the expressive introduction. Home combines Today’s private dashboard with All / Following discovery; Closet is private management. Whitespace and separators group ordinary content. Grouped backgrounds belong to forms/settings; image grounds support clothing. Brand character comes from content and proportion rather than decorations around every element.

## Color

| Role / Paper token | Light | Dark | Use |
| --- | --- | --- | --- |
| Canvas / `--color-canvas` | `#F3F3F1` | `#1C1C1E` | Screen |
| Surface / `--color-surface` | `#FFFFFF` | `#2C2C2E` | Forms and grouped settings |
| Ink / `--color-ink` | `#292C29` | `#F2F2F7` | Text and icons |
| Secondary / `--color-secondary` | `#686E68` | `#B8B8BD` | Supporting text |
| Divider / `--color-line` | `#E5E9E3` | `#48484A` | Separators and fields |
| Accent / `--color-accent` | `#48594F` | `#B8CFBE` | Actions and selection |
| Accent surface / `--color-accent-soft` | `#ECEFEA` | `#34463A` | Selected controls |
| Destructive / `--color-error` | `#A1403A` | `#FFB4AB` | Error and destructive intent |

Primary actions use white on the light accent, dark ink on the dark accent. Native alerts retain semantic system colors. Selection also has a check, fill, weight, or label. Glass responds to content and accessibility settings. Text contrast targets 4.5:1, or 3:1 for large text; soft surfaces do not require soft text.

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

Photographic corners: 4 pt. Input glass shells: 16 pt (multiline composers: 28 pt). Grouped content surfaces: 12 pt. Compositions: 12–16 pt when containment helps. Sheets use system corners. Pills belong to buttons, filters, and native glass chrome. Ordinary content has neither shadow nor outline. Choose separator or elevation according to function.

Touch targets are at least 44 × 44 pt. Primary content action: base 50 pt tall, 17 pt medium label, 20 pt horizontal padding. Cancel and dismiss actions use neutral semantic ink on regular glass (light charcoal / dark light ink). Green is reserved for primary actions and selected states; secondary actions use neutral native controls. One action dominates each task step. Loading preserves control width and blocks duplicate submission.

## Change one place

Edit semantic values in Paper’s token panel. Edit geometry in the page 00 component master, then update affected screen instances. Paper token references update live; clones are snapshots, not linked symbols. There is no second local renderer to synchronize. The [component contracts](docs/COMPONENTS.md) define state and native behavior; update documentation when the contract changes.

## Navigation and materials

Use native components for every platform-capable control, including menus, action/confirmation sheets, alerts, adaptive popovers, switches, pickers, keyboard/edit menus, progress, media selection and sharing. [Native presentations](docs/design/NATIVE-PRESENTATIONS.md) defines the global open-state appearance and per-page V1 content. Page 00 **Components · Native controls and open menus** is the shared static reference. AQD owns task content and supported semantic tint; iOS owns control mechanics and presentation geometry. Native switches retain their system track/thumb without an extra glass wrapper.

Five destinations: Home, Closet, Agent, Inbox, Profile. Native labels remain visible, with a selected icon treatment and system selected pill. This replaces the old icon-only requirement. Use SF Symbols and native back/disclosure/search controls; Paper's authored vectors approximate these symbols. Agent has a conversation symbol. The icon catalog in `docs/design/ICONS.md` maps every action to an SF Symbol; active navigation uses semibold weight, tint and the system selection pill.

Agent opens full screen from the center entry or focused assistance, with Back and no bottom bar. Dismissal restores the prior destination and scroll position. The action-like center entry is a product requirement; verify selection restoration against actual native tab behavior during implementation.

Liquid Glass is the default for AQD functional controls: native tab bars and segmented selection, toolbar actions including Back, standalone primary/secondary buttons, filter controls, search, every editable input shell, chat composers, contextual menus and popovers. Use native system components first. Primary actions use native glassProminent with the semantic AQD tint; secondary actions use glass. Plain inline reactions, links and list disclosure rows retain their native content-level style. The official Apple sign-in control retains its approved native appearance. Photographs, messages, notices and content cards stay opaque.

Every TextField/TextEditor retains native editing, keyboard, autofill, selection and validation. Where a system input does not supply glass, wrap its functional shell once in regular native glass; the inner editor has no second material. An Inbox/Agent composer has one glass container and a native Send/Stop control; do not stack duplicate glass modifiers on its shell. Native Back comes from the navigation container, preserving interactive swipe and history; never replace it with a custom chevron solely for appearance.

Use regular glass by default; clear glass is limited to floating controls over media where contrast is verified. Choose native variants and tint; do not fade the entire control or claim a CSS alpha value is a supported native material opacity setting. The OS owns actual optics and adaptations to appearance, Reduce Transparency and Increase Contrast. Paper blur, alpha, edge and shadow are static approximations. See [Liquid Glass control audit](docs/design/LIQUID-GLASS.md) for the role matrix and review scope.

Apple’s official [iOS and iPadOS 27 design kit](https://www.figma.com/community/file/1651309003795292092/ios-and-ipados-27) was verified on October 1, 2026; its listing identifies a September 15, 2026 update covering Liquid Glass, layout, sidebar colors and scroll-edge effects. Use it as the native visual reference alongside Apple’s documentation. Native SDK availability and supported-device behavior still require implementation checks; a design kit is not an API compatibility guarantee.

## Imagery and copy

Use user-selected garment photography and compositions of the actual included pieces. Preserve proportions and identifying details in piece detail. Community imagery is explicitly published by its creator. Missing photos use a quiet category symbol with the piece name.

Paper reference photographs and names/counts/chats are illustrative fixtures. They are not actual user records or bundled production assets. Source URLs and replacement rules live in [Assets](docs/ASSETS.md). Implementation uses authorized user media, real data, and honest unavailable states.

Copy names the task: Add piece, Build outfit, Review changes, Save outfit, Publish look. Explain privacy at the choice it affects. AI output stays a draft until a receipt confirms saving. Human chat remains separate from Agent.

## Motion and performance

Read [Global motion](docs/design/MOTION.md) before implementing navigation, state transitions, loading, feedback, onboarding or custom animated components. Paper page 00 **Foundations · Global motion** defines the visual policy; [screen coverage](docs/design/MOTION-COVERAGE.md) and the manifest assign every screen/state its recipes. Native iOS controls own navigation, glass, keyboard and presentation timing. AQD custom motion explains local state changes, preserves continuity and never delays a task.

Use one native AQDMotion policy with named press, crossfade, reflow, arrival and reduced-motion values. No per-screen timing overrides, generic page-reveal cascade or competing transition on top of system navigation. Reduce Motion, interruption, VoiceOver focus and actual device frame pacing are required acceptance checks. Static Paper keyframes do not establish runtime smoothness.

## Completion boundary

Coverage includes entry/auth/setup, every destination, detail/edit/create/review routes, planning/history, publication/moderation, Agent proposals, human messaging, and account lifecycle. [Screen map](docs/design/SCREENS.md) records artboards and variants; [Verification](docs/VERIFICATION.md) records rendered checks and native testing still needed.

The [Paper manifest](docs/design/paper-manifest.json) records 227 artboards across ten pages: 179 screen contracts, twenty foundation/component/motion boards, four appearance variants, five offline proposal references, and nineteen V1 flow review boards. Paper owns static appearance and coverage; native accessibility, keyboard behavior, performance and production services require implementation validation.

Identity provider, recovery, messaging retention, moderation, and AI capability remain service decisions. A designed control does not choose a backend or promise an unsupported capability.

## Shared selection and feedback

Page 00 catalogs all shared control, content, feedback, presentation and icon patterns. Page 00 is the visual master catalog, including entry and identity patterns. Filters stay on one horizontal line with 44 pt targets, a soft shadow and a conditional trailing fade. Segmented tabs use a neutral rail and a glass selected capsule; accessibility settings may replace glass with an opaque outlined selection. Empty states group both actions together, with 12 pt between buttons and 24 pt between message and actions.

Static composition previews reserve at least 245 pt for the photo columns. Docked message composers sit outside the scrolling body and above the bottom safe area; native implementations must also accommodate keyboard insets.

## Entry and identity

[Entry flow](docs/design/ENTRY-IDENTITY.md) puts the first private save before optional style preferences. Welcome pairs an outfit with individual pieces and has one primary action. Sign-in separates method choice, email entry and recovery. Public profile setup is contextual; local-account association is explicit. Editable fields use native input behavior within the shared regular-glass functional shell; labels, validation and explanatory content remain opaque.

Welcome has one authored photographic arrival, with a shared-image transition into the first-piece flow. [Entry motion](docs/design/ENTRY-MOTION.md) defines choreography using the global motion values. No looping decoration or blocked actions. Paper keyframes define the target; native implementation remains separate.

## Agent response system

Use the shared response status, composer, action toolbar, task progress, version navigation and feedback patterns on Paper page 00. [Agent experience](docs/design/AGENT-EXPERIENCE.md) owns lifecycle, actual timing, optional evaluation feedback and recovery. Replies remain drafts; review and persisted receipts own writes. Response text is content, not a glass panel. Use native glass for floating functional chrome and opaque neutral equivalents under Reduced Transparency.

Agent replies use the shared Markdown body defined in [Agent experience](docs/design/AGENT-EXPERIENCE.md#markdown-responses), with restrained headings, emphasis, lists, quotes, links and compact data. Formatting shares the existing semantic tokens across streaming, completed and dark variants.

Public profiles use a compact shared identity/action header: 64-point avatar, 44-point Follow/Message controls and a two-column content grid. The [component contract](docs/COMPONENTS.md#compact-profile--owner-and-visitor) owns geometry and accessibility; S06/S13/S14 show Outfits, Pieces and Themes.

Home uses the shared three-segment Today / All / Following control. Today prioritizes an owned planned look, upcoming plans and compact wardrobe actions. All/Following remain public feeds. The dashboard reads the existing Closet/Planner records and changes search scope explicitly.

Owner and visitor Profile share the compact header. Profile bio previews remain a single ellipsized line; a native details sheet reveals the full text. Bio editing is limited to 160 user-perceived characters with a live counter and non-destructive validation.

Today adds a quiet recorded-week summary beneath the planned look, with distinct days recorded and distinct pieces worn. A photographic Wear again module and upcoming plans follow on scroll. Page 00 owns these reusable modules; the [Today contract](docs/features/DISCOVERY-PUBLISHING.md#today-wardrobe-activity) owns calculation, eligibility and empty states.

Today uses a single large Home title, a quiet date and one regular-weight state message. Avoid a repeated dashboard heading; empty wear history is a plain secondary section. The [shared hierarchy](docs/COMPONENTS.md#today-text-hierarchy) applies to first-piece, no-plan and populated states.

Filter chips use a solid eucalyptus selected fill with an on-accent label and checkmark. Pale accent surfaces are not the selected-filter treatment. Unselected chips remain neutral; see the shared filter contract.

The [V1 flow review](docs/design/V1-FLOW.md) connects private capture to a first usable outfit, optional auth, adaptive Today, planning/wear and social/Inbox. W27–W29 and S48 reuse the existing visual system; page 00 owns first-outfit activation primitives. Try-on and shopping remain deferred.
